# Labs Pratiques Switching - Exercices Complets

## Vue d'Ensemble

Cette section contient 4 labs pratiques couvrant STP, EtherChannel, port-security et le troubleshooting switching complet. Chaque lab inclut la topologie, les objectifs, les etapes detaillees et les commandes de verification.

---

## Lab 1 : Manipulation du Root Bridge STP

### Topologie

```
                ┌─────────────────────┐
                │       SW-1          │
                │ MAC: 0001.0001.0001 │
                │ Priority: 32769     │
                │                     │
                │ Fa0/1         Fa0/2 │
                └──┬──────────────┬───┘
                   │              │
          Cost: 19 │              │ Cost: 19
                   │              │
          ┌────────┴───┐    ┌─────┴────────┐
          │   SW-2     │    │    SW-3       │
          │ MAC: 0002  │    │ MAC: 0003     │
          │ Pri: 32769 │    │ Pri: 32769    │
          │            │    │               │
          │ Fa0/1      │    │ Fa0/1         │
          │ Fa0/2      │    │ Fa0/2         │
          │ Fa0/3      │    │ Fa0/3         │
          └──┬────┬────┘    └──┬────┬───────┘
             │    │            │    │
             │    └────────────┘    │
             │      Cost: 19       │
             │                     │
          ┌──┴──┐              ┌───┴──┐
          │PC-A │              │PC-B  │
          │VL10 │              │VL10  │
          └─────┘              └──────┘

VLANs :
- VLAN 10 : Users (192.168.10.0/24)
- VLAN 99 : Management (192.168.99.0/24)
```

### Objectifs

- Identifier le Root Bridge actuel
- Modifier la priority pour controler l'election
- Verifier les roles des ports apres modification
- Configurer PortFast et BPDU Guard sur les ports access

### Etape 1 : Configuration de Base

```cisco
! Sur les 3 switches
Switch(config)# hostname SW-X
SW-X(config)# vlan 10
SW-X(config-vlan)# name Users
SW-X(config-vlan)# exit
SW-X(config)# vlan 99
SW-X(config-vlan)# name Management
SW-X(config-vlan)# exit
```

### Etape 2 : Identifier le Root Bridge Actuel

```cisco
! Sur chaque switch
SW-1# show spanning-tree vlan 10

! Identifier :
! - Qui est Root Bridge ? (celui dont le Root ID = Bridge ID)
! - Quels ports sont Root / Designated / Blocked ?

! Commande rapide
SW-1# show spanning-tree root
```

Questions de reflexion :
- Avec les priorities identiques (32768), quel switch est Root ?
- Pourquoi ce switch et pas un autre ?

Reponse attendue : SW-1 est Root car sa MAC (0001.0001.0001) est la plus basse.

### Etape 3 : Forcer SW-3 comme Root Bridge

```cisco
! Methode 1 : Commande root primary
SW-3(config)# spanning-tree vlan 10 root primary

! Methode 2 : Priority manuelle
SW-3(config)# spanning-tree vlan 10 priority 4096

! Configurer SW-1 comme Root secondaire
SW-1(config)# spanning-tree vlan 10 root secondary
! ou
SW-1(config)# spanning-tree vlan 10 priority 8192
```

### Etape 4 : Verifier les Nouveaux Roles

```cisco
! Sur chaque switch
SW-3# show spanning-tree vlan 10

! Resultat attendu :
! SW-3 : Root Bridge (tous ports Designated)
! SW-1 : Fa0/2 = Root Port, Fa0/1 = Designated
! SW-2 : Fa0/2 = Root Port (vers SW-3), Fa0/1 = ?

! Verifier la topologie complete
SW-1# show spanning-tree vlan 10 brief
```

### Etape 5 : Configurer PortFast et BPDU Guard

```cisco
! Sur SW-2 et SW-3 (ports access vers les PCs)
SW-2(config)# interface fa0/3
SW-2(config-if)# spanning-tree portfast
SW-2(config-if)# spanning-tree bpduguard enable
SW-2(config-if)# exit

SW-3(config)# interface fa0/3
SW-3(config-if)# spanning-tree portfast
SW-3(config-if)# spanning-tree bpduguard enable
SW-3(config-if)# exit

! Verification
SW-2# show spanning-tree interface fa0/3 detail
```

### Verification Finale

```cisco
! Commandes de validation
show spanning-tree vlan 10
show spanning-tree root
show spanning-tree blockedports
show spanning-tree interface fa0/3 portfast
```

---

## Lab 2 : Configuration EtherChannel LACP

### Topologie

```
SW-1                                    SW-2
┌──────────────────┐                   ┌──────────────────┐
│                  │  Port-Channel 1   │                  │
│  Gi0/1 ══════════╪═══════════════════╪══════════ Gi0/1  │
│  Gi0/2 ══════════╪═══════════════════╪══════════ Gi0/2  │
│                  │  LACP active      │  LACP active     │
│                  │                   │                  │
│  Fa0/1-8  VL10  │                   │  Fa0/1-8  VL10  │
│  Fa0/9-16 VL20  │                   │  Fa0/9-16 VL20  │
│                  │                   │                  │
│  Fa0/1           │                   │  Fa0/1           │
│  │               │                   │  │               │
└──┼───────────────┘                   └──┼───────────────┘
   │                                      │
┌──┴──┐                               ┌──┴──┐
│PC-A │ VLAN 10                        │PC-B │ VLAN 10
│.10  │ 192.168.10.10                  │.20  │ 192.168.10.20
└─────┘                                └─────┘

Trunk sur Port-Channel 1 :
- VLANs autorises : 10, 20, 99
- Native VLAN : 99
```

### Objectifs

- Configurer un EtherChannel LACP entre deux switches
- Configurer le trunk sur le port-channel
- Verifier la formation du bundle
- Tester la redondance en desactivant un lien

### Etape 1 : Preparer les VLANs

```cisco
! Sur les deux switches
SW-X(config)# vlan 10
SW-X(config-vlan)# name Users
SW-X(config-vlan)# exit
SW-X(config)# vlan 20
SW-X(config-vlan)# name IT
SW-X(config-vlan)# exit
SW-X(config)# vlan 99
SW-X(config-vlan)# name Management
SW-X(config-vlan)# exit
```

### Etape 2 : Configurer EtherChannel LACP

```cisco
! SW-1 : LACP active
SW-1(config)# interface range gigabitethernet 0/1-2
SW-1(config-if-range)# channel-group 1 mode active
SW-1(config-if-range)# exit

! SW-2 : LACP active
SW-2(config)# interface range gigabitethernet 0/1-2
SW-2(config-if-range)# channel-group 1 mode active
SW-2(config-if-range)# exit
```

### Etape 3 : Configurer le Trunk sur Port-Channel

```cisco
! Sur les deux switches
SW-X(config)# interface port-channel 1
SW-X(config-if)# switchport mode trunk
SW-X(config-if)# switchport trunk allowed vlan 10,20,99
SW-X(config-if)# switchport trunk native vlan 99
SW-X(config-if)# exit
```

### Etape 4 : Configurer les Ports Access

```cisco
! SW-1 : PC-A sur VLAN 10
SW-1(config)# interface fa0/1
SW-1(config-if)# switchport mode access
SW-1(config-if)# switchport access vlan 10
SW-1(config-if)# exit

! SW-2 : PC-B sur VLAN 10
SW-2(config)# interface fa0/1
SW-2(config-if)# switchport mode access
SW-2(config-if)# switchport access vlan 10
SW-2(config-if)# exit
```

### Etape 5 : Verification

```cisco
! Verifier la formation du channel
SW-1# show etherchannel summary
! Attendu : Po1(SU) avec Gi0/1(P) Gi0/2(P)
! S=Layer2, U=in use, P=bundled

! Verifier le detail
SW-1# show etherchannel 1 detail

! Verifier le trunk
SW-1# show interfaces trunk
! Attendu : Po1 en trunking

! Tester la connectivite
PC-A> ping 192.168.10.20
! Attendu : succes
```

### Etape 6 : Test de Redondance

```cisco
! Desactiver un lien physique
SW-1(config)# interface gi0/1
SW-1(config-if)# shutdown

! Verifier que le channel reste actif
SW-1# show etherchannel summary
! Attendu : Po1(SU) avec Gi0/2(P), Gi0/1(D)

! Tester la connectivite
PC-A> ping 192.168.10.20
! Attendu : succes (trafic bascule sur Gi0/2)

! Reactiver le lien
SW-1(config)# interface gi0/1
SW-1(config-if)# no shutdown
```

---

## Lab 3 : Configuration Port-Security

### Topologie

```
                    ┌──────────────────────┐
                    │        SW-1          │
                    │                      │
                    │  Fa0/1    Fa0/2      │
                    │  [secure] [secure]   │
                    │  max: 1   max: 2     │
                    │  shutdown  restrict  │
                    │  sticky    static    │
                    │                      │
                    │  Fa0/3               │
                    │  [secure]            │
                    │  max: 1              │
                    │  protect             │
                    └──┬───────┬───────┬───┘
                       │       │       │
                    ┌──┴──┐ ┌──┴──┐ ┌──┴──┐
                    │PC-A │ │PC-B │ │PC-C │
                    │VL10 │ │VL10 │ │VL10 │
                    └─────┘ └─────┘ └─────┘

PC-A MAC : AAAA.AAAA.AAAA
PC-B MAC : BBBB.BBBB.BBBB
PC-C MAC : CCCC.CCCC.CCCC

3 modes de violation configures pour comparaison
```

### Objectifs

- Configurer port-security avec differentes methodes (sticky, static)
- Configurer les 3 modes de violation (shutdown, restrict, protect)
- Tester les violations et observer les comportements
- Recuperer un port en err-disabled

### Etape 1 : Configuration de Base

```cisco
! Creer le VLAN et assigner les ports
SW-1(config)# vlan 10
SW-1(config-vlan)# name Users
SW-1(config-vlan)# exit

SW-1(config)# interface range fa0/1-3
SW-1(config-if-range)# switchport mode access
SW-1(config-if-range)# switchport access vlan 10
SW-1(config-if-range)# exit
```

### Etape 2 : Configurer Port-Security - Mode Shutdown + Sticky

```cisco
! Fa0/1 : Max 1 MAC, mode shutdown, apprentissage sticky
SW-1(config)# interface fa0/1
SW-1(config-if)# switchport port-security
SW-1(config-if)# switchport port-security maximum 1
SW-1(config-if)# switchport port-security violation shutdown
SW-1(config-if)# switchport port-security mac-address sticky
SW-1(config-if)# exit
```

### Etape 3 : Configurer Port-Security - Mode Restrict + Static

```cisco
! Fa0/2 : Max 2 MAC, mode restrict, MAC statique
SW-1(config)# interface fa0/2
SW-1(config-if)# switchport port-security
SW-1(config-if)# switchport port-security maximum 2
SW-1(config-if)# switchport port-security violation restrict
SW-1(config-if)# switchport port-security mac-address BBBB.BBBB.BBBB
SW-1(config-if)# exit
```

### Etape 4 : Configurer Port-Security - Mode Protect

```cisco
! Fa0/3 : Max 1 MAC, mode protect
SW-1(config)# interface fa0/3
SW-1(config-if)# switchport port-security
SW-1(config-if)# switchport port-security maximum 1
SW-1(config-if)# switchport port-security violation protect
SW-1(config-if)# exit
```

### Etape 5 : Verification de la Configuration

```cisco
! Verifier la config port-security
SW-1# show port-security

Secure Port  MaxSecureAddr  CurrentAddr  SecurityViolation  Security Action
-----------  -------------  -----------  -----------------  ---------------
      Fa0/1              1            1                  0         Shutdown
      Fa0/2              2            1                  0         Restrict
      Fa0/3              1            1                  0          Protect

! Detail par interface
SW-1# show port-security interface fa0/1

Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Shutdown
Aging Time                 : 0 mins
Aging Type                 : Absolute
SecureStatic Address Aging : Disabled
Maximum MAC Addresses      : 1
Total MAC Addresses        : 1
Configured MAC Addresses   : 0
Sticky MAC Addresses       : 1
Last Source Address:Vlan   : AAAA.AAAA.AAAA:10
Security Violation Count   : 0

! Voir les adresses MAC securisees
SW-1# show port-security address
```

### Etape 6 : Tester les Violations

```
Test 1 : Brancher un PC inconnu sur Fa0/1 (mode shutdown)
  → Resultat : Port passe en err-disabled, LED orange
  → Verification : show interfaces fa0/1 status

Test 2 : Ajouter une 3eme MAC sur Fa0/2 (mode restrict)
  → Resultat : Trafic de la 3eme MAC droppe, compteur incremente
  → Log syslog genere
  → Port reste UP
  → Verification : show port-security interface fa0/2

Test 3 : Ajouter une 2eme MAC sur Fa0/3 (mode protect)
  → Resultat : Trafic de la 2eme MAC droppe silencieusement
  → Pas de log, pas de compteur
  → Port reste UP
```

### Etape 7 : Recuperation d'un Port err-disabled

```cisco
! Verifier les ports err-disabled
SW-1# show interfaces status err-disabled

Port    Name               Status       Vlan
Fa0/1                      err-disabled 10

! Methode 1 : Recovery manuelle
SW-1(config)# interface fa0/1
SW-1(config-if)# shutdown
SW-1(config-if)# no shutdown
SW-1(config-if)# exit

! Methode 2 : Auto-recovery
SW-1(config)# errdisable recovery cause psecure-violation
SW-1(config)# errdisable recovery interval 300
! Le port sera automatiquement reactive apres 300 secondes
```

---

## Lab 4 : Troubleshooting Switching Complet

### Topologie avec Erreurs

```
                    ┌──────────────────┐
                    │      SW-CORE     │
                    │  (Switch L3)     │
                    │                  │
                    │  SVI VLAN 10:    │
                    │  192.168.10.1/24 │
                    │  SVI VLAN 20:    │
                    │  192.168.20.1/24 │
                    │                  │
                    │  Gi0/1     Gi0/2 │
                    │  [Trunk]  [Trunk]│
                    └──┬────────────┬──┘
                       │            │
              ┌────────┴───┐  ┌─────┴────────┐
              │ SW-ACC-1   │  │  SW-ACC-2    │
              │            │  │              │
              │ Gi0/1      │  │ Gi0/1        │
              │ [Trunk]    │  │ [Trunk]      │
              │            │  │              │
              │ Fa0/1 VL10 │  │ Fa0/1 VL10   │
              │ Fa0/10 VL20│  │ Fa0/10 VL20  │
              └─┬──────┬───┘  └─┬──────┬─────┘
                │      │        │      │
             ┌──┴──┐┌──┴──┐  ┌──┴──┐┌──┴──┐
             │PC-A ││PC-C │  │PC-B ││PC-D │
             │VL10 ││VL20 │  │VL10 ││VL20 │
             │.10  ││.10  │  │.20  ││.20  │
             └─────┘└─────┘  └─────┘└─────┘

Adressage :
PC-A : 192.168.10.10/24, GW: 192.168.10.1
PC-B : 192.168.10.20/24, GW: 192.168.10.1
PC-C : 192.168.20.10/24, GW: 192.168.20.1
PC-D : 192.168.20.20/24, GW: 192.168.20.1
```

### Scenario : 5 Erreurs a Trouver

Les erreurs suivantes ont ete introduites. Trouvez et corrigez chacune.

### Erreur 1 : VLAN non cree sur SW-ACC-2

```
Symptome : PC-B (VLAN 10) ne peut pas pinguer PC-A (VLAN 10)
           mais PC-D (VLAN 20) peut pinguer PC-C (VLAN 20)

Diagnostic :
SW-ACC-2# show vlan brief
! VLAN 10 n'apparait pas dans la liste

SW-ACC-2# show interfaces fa0/1 switchport
! Le port est assigne a VLAN 10 mais le VLAN n'existe pas
! Le port est donc INACTIF

Solution :
SW-ACC-2(config)# vlan 10
SW-ACC-2(config-vlan)# name Users
SW-ACC-2(config-vlan)# exit
```

### Erreur 2 : Native VLAN Mismatch sur le trunk

```
Symptome : Messages CDP/STP mismatch dans les logs

Diagnostic :
SW-CORE# show interfaces trunk
! Native VLAN = 1

SW-ACC-1# show interfaces trunk
! Native VLAN = 99

! Mismatch ! Les deux cotes du trunk doivent avoir la meme Native VLAN

Solution :
SW-CORE(config)# interface gi0/1
SW-CORE(config-if)# switchport trunk native vlan 99
SW-CORE(config-if)# exit
SW-CORE(config)# interface gi0/2
SW-CORE(config-if)# switchport trunk native vlan 99
SW-CORE(config-if)# exit
```

### Erreur 3 : VLAN non autorise sur trunk

```
Symptome : VLAN 20 ne fonctionne pas entre SW-CORE et SW-ACC-1

Diagnostic :
SW-ACC-1# show interfaces gi0/1 trunk
! Allowed VLANs : 10,99
! VLAN 20 n'est PAS dans la liste des VLANs autorises

Solution :
SW-ACC-1(config)# interface gi0/1
SW-ACC-1(config-if)# switchport trunk allowed vlan add 20
SW-ACC-1(config-if)# exit
```

### Erreur 4 : Port en mauvais mode

```
Symptome : Le port Fa0/10 de SW-ACC-2 est en mode "dynamic auto"
           au lieu de "access"

Diagnostic :
SW-ACC-2# show interfaces fa0/10 switchport
! Administrative Mode: dynamic auto
! Operational Mode: access (si pas de partenaire DTP)
! Mais pas securise !

Solution :
SW-ACC-2(config)# interface fa0/10
SW-ACC-2(config-if)# switchport mode access
SW-ACC-2(config-if)# switchport access vlan 20
SW-ACC-2(config-if)# exit
```

### Erreur 5 : SVI VLAN 20 en shutdown

```
Symptome : PC-C et PC-D ne peuvent pas pinguer leur gateway
           (192.168.20.1)

Diagnostic :
SW-CORE# show ip interface brief
! Vlan20    192.168.20.1    YES manual administratively down down

Solution :
SW-CORE(config)# interface vlan 20
SW-CORE(config-if)# no shutdown
SW-CORE(config-if)# exit
```

### Verification Finale

```cisco
! Apres toutes les corrections, verifier :

! 1. VLANs crees partout
SW-ACC-2# show vlan brief

! 2. Trunks operationnels
SW-CORE# show interfaces trunk

! 3. Connectivite intra-VLAN
PC-A> ping 192.168.10.20  (PC-B, meme VLAN)

! 4. Connectivite inter-VLAN
PC-A> ping 192.168.20.10  (PC-C, VLAN different, via routing L3)

! 5. Tous les SVIs up
SW-CORE# show ip interface brief | include Vlan
```

---

## Questions de Revision Generales

### Questions a Choix Multiple

1. Quel est le Bridge ID utilise pour l'election du Root Bridge ?
   - a) MAC Address uniquement
   - b) Priority uniquement
   - c) Priority + MAC Address
   - d) Priority + VLAN ID + MAC Address

2. Un port EtherChannel affiche le flag (s). Que signifie-t-il ?
   - a) Le port est en standby LACP
   - b) Le port est Layer 2
   - c) Le port est suspendu
   - d) Le port est stable

3. Quel mode de violation port-security genere un log syslog ?
   - a) protect
   - b) restrict
   - c) shutdown
   - d) b et c

4. Quel est le temps de convergence STP classique (802.1D) ?
   - a) < 1 seconde
   - b) 6 secondes
   - c) 30 a 50 secondes
   - d) 2 minutes

5. Deux ports LACP sont en mode passive des deux cotes. Resultat ?
   - a) Le channel se forme
   - b) Le channel ne se forme pas
   - c) Erreur de configuration
   - d) Mode on par defaut

### Reponses

1. **d)** Priority + VLAN ID (Extended System ID) + MAC Address
2. **c)** Le port est suspendu du bundle (mismatch configuration)
3. **d)** restrict ET shutdown generent des logs syslog
4. **c)** 30 a 50 secondes (Listening 15s + Learning 15s, plus Max Age si applicable)
5. **b)** Le channel ne se forme pas. Au moins un cote doit etre "active".

### Questions Ouvertes

6. Expliquez pourquoi PortFast ne doit JAMAIS etre active sur un port connecte a un switch.
7. Dans une topologie triangulaire avec 3 switches de meme priority, comment determiner quel port sera bloque ?
8. Un EtherChannel est configure avec 4 liens mais show etherchannel summary ne montre que 2 ports (P). Quelles sont les causes possibles ?

### Reponses aux Questions Ouvertes

6. PortFast fait passer le port directement en Forwarding sans passer par Listening/Learning. Si un switch est connecte, une boucle peut se former avant que STP n'ait le temps de bloquer le port. C'est pourquoi on combine toujours PortFast avec BPDU Guard : si un BPDU est recu, le port est immediatement desactive.

7. Avec la meme priority, le Root Bridge est le switch avec la MAC la plus basse. Ensuite, chaque switch non-root choisit son Root Port (cout le plus bas vers Root). Sur le segment restant, le switch avec le BID le plus bas a le Designated Port, l'autre a le port Blocked. En cas d'egalite de cout, le port avec le Port ID le plus bas du switch envoyeur est prefere.

8. Causes possibles : (a) Les 2 autres ports ont une configuration differente (speed, duplex, VLAN) et sont suspendus. (b) Les 2 autres ports sont physiquement down (cable debranche, erreur hardware). (c) Les ports ne sont pas dans le meme channel-group. Diagnostic : `show etherchannel detail` et comparer la configuration de chaque port membre.

---

*Exercices crees pour la revision CCNA*
*Auteur : Tudy Gbaguidi*
