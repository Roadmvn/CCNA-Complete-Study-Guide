# EtherChannel - Agregation de Liens

## Vue d'Ensemble

EtherChannel permet de combiner plusieurs liens physiques entre deux switches en un seul lien logique. Cela augmente la bande passante, fournit de la redondance et evite que STP bloque des liens individuels.

---

## Concept d'Agregation de Liens

### Probleme Sans EtherChannel

```
Sans EtherChannel :
STP bloque les liens redondants pour eviter les boucles

Switch-A                    Switch-B
┌─────────┐                ┌─────────┐
│ Gi0/1   │════════════════│ Gi0/1   │  Forwarding (actif)
│ Gi0/2   │────────────────│ Gi0/2   │  BLOCKED par STP
│ Gi0/3   │────────────────│ Gi0/3   │  BLOCKED par STP
│ Gi0/4   │────────────────│ Gi0/4   │  BLOCKED par STP
└─────────┘                └─────────┘

Bande passante effective : 1 Gbps (1 seul lien actif)
3 liens gaspilles !

Avec EtherChannel :
STP voit un seul lien logique, tous les liens physiques sont actifs

Switch-A                    Switch-B
┌─────────┐                ┌─────────┐
│         │  Port-Channel 1│         │
│ Gi0/1   │╔══════════════╗│ Gi0/1   │
│ Gi0/2   │║  EtherChannel║│ Gi0/2   │  Tous actifs
│ Gi0/3   │║  (1 lien     ║│ Gi0/3   │  simultanément
│ Gi0/4   │╚══════════════╝│ Gi0/4   │
└─────────┘                └─────────┘

Bande passante effective : 4 Gbps (4 liens actifs)
```

### Avantages

```
┌────────────────────┬─────────────────────────────────────────┐
│ Avantage           │ Detail                                  │
├────────────────────┼─────────────────────────────────────────┤
│ Bande passante     │ Additive : N liens x vitesse unitaire   │
│                    │ Ex: 4 x 1Gbps = 4 Gbps logique         │
├────────────────────┼─────────────────────────────────────────┤
│ Redondance         │ Si un lien tombe, les autres restent    │
│                    │ actifs (degradation gracieuse)           │
├────────────────────┼─────────────────────────────────────────┤
│ STP compatible     │ STP voit 1 lien = pas de port bloque   │
│                    │ Un seul cout STP pour le bundle          │
├────────────────────┼─────────────────────────────────────────┤
│ Load balancing     │ Trafic reparti sur les liens physiques  │
│                    │ Plusieurs methodes de hash disponibles   │
├────────────────────┼─────────────────────────────────────────┤
│ Convergence        │ Perte d'un lien = pas de recalcul STP  │
│ rapide             │ Le bundle reste actif immediatement     │
└────────────────────┴─────────────────────────────────────────┘
```

---

## LACP vs PAgP

### LACP (Link Aggregation Control Protocol - IEEE 802.3ad)

```
Standard ouvert IEEE, recommande pour les nouveaux deploiements.

Modes LACP :
┌──────────┬───────────────────────────────────────────────────┐
│ Mode     │ Comportement                                      │
├──────────┼───────────────────────────────────────────────────┤
│ active   │ Initie activement la negociation LACP             │
│          │ Envoie des PDUs LACP                              │
├──────────┼───────────────────────────────────────────────────┤
│ passive  │ Repond aux PDUs LACP mais ne les initie pas       │
│          │ Attend qu'un partenaire active initie              │
└──────────┴───────────────────────────────────────────────────┘

Matrice de Formation LACP :
┌──────────────┬──────────┬──────────┐
│ SW-A \ SW-B  │ active   │ passive  │
├──────────────┼──────────┼──────────┤
│ active       │ FORME    │ FORME    │
├──────────────┼──────────┼──────────┤
│ passive      │ FORME    │ PAS forme│
└──────────────┴──────────┴──────────┘

Au moins un cote doit etre "active" pour que le channel se forme.
```

### PAgP (Port Aggregation Protocol - Cisco Proprietaire)

```
Protocole Cisco, uniquement entre equipements Cisco.

Modes PAgP :
┌──────────┬───────────────────────────────────────────────────┐
│ Mode     │ Comportement                                      │
├──────────┼───────────────────────────────────────────────────┤
│ desirable│ Initie activement la negociation PAgP             │
│          │ Envoie des PDUs PAgP                              │
├──────────┼───────────────────────────────────────────────────┤
│ auto     │ Repond aux PDUs PAgP mais ne les initie pas       │
│          │ Attend qu'un partenaire desirable initie           │
└──────────┴───────────────────────────────────────────────────┘

Matrice de Formation PAgP :
┌──────────────┬──────────┬──────────┐
│ SW-A \ SW-B  │ desirable│ auto     │
├──────────────┼──────────┼──────────┤
│ desirable    │ FORME    │ FORME    │
├──────────────┼──────────┼──────────┤
│ auto         │ FORME    │ PAS forme│
└──────────────┴──────────┴──────────┘
```

### Mode Static (On)

```
Mode "on" : Force l'EtherChannel sans negociation

┌──────────┬───────────────────────────────────────────────────┐
│ Mode     │ Comportement                                      │
├──────────┼───────────────────────────────────────────────────┤
│ on       │ Force le channel sans protocole de negociation    │
│          │ Les deux cotes DOIVENT etre "on"                  │
│          │ Pas de detection automatique des erreurs          │
│          │ Deconseille en production                         │
└──────────┴───────────────────────────────────────────────────┘

Matrice avec le mode "on" :
┌──────────────┬──────────┬──────────┬──────────┐
│ SW-A \ SW-B  │ on       │ active   │ desirable│
├──────────────┼──────────┼──────────┼──────────┤
│ on           │ FORME    │ PAS forme│ PAS forme│
├──────────────┼──────────┼──────────┼──────────┤
│ active       │ PAS forme│ FORME    │ FORME    │
├──────────────┼──────────┼──────────┼──────────┤
│ desirable    │ PAS forme│ (N/A)    │ FORME    │
└──────────────┴──────────┴──────────┴──────────┘

"on" n'est compatible qu'avec "on" (pas de protocole = pas de nego)
```

### Comparaison Complete

```
┌────────────────────┬────────────────┬────────────────┬───────────┐
│ Critere            │ LACP           │ PAgP           │ Static    │
├────────────────────┼────────────────┼────────────────┼───────────┤
│ Standard           │ IEEE 802.3ad   │ Cisco proprio. │ Aucun     │
│ Interoperabilite   │ Multi-vendeur  │ Cisco seul     │ Universal │
│ Negociation        │ Oui            │ Oui            │ Non       │
│ Detection erreurs  │ Oui            │ Oui            │ Non       │
│ Max liens actifs   │ 8 (16 total)   │ 8              │ 8         │
│ Hot-standby liens  │ Oui (8 standby)│ Non            │ Non       │
│ Modes              │ active/passive │ desirable/auto │ on        │
│ Recommandation     │ Prefere        │ Legacy Cisco   │ Eviter    │
└────────────────────┴────────────────┴────────────────┴───────────┘
```

---

## Configuration et Verification

### Configuration LACP

```cisco
! Switch-A : Configuration EtherChannel LACP
Switch-A(config)# interface range gigabitethernet 0/1-4
Switch-A(config-if-range)# channel-group 1 mode active
Switch-A(config-if-range)# exit

! Configuration du Port-Channel logique
Switch-A(config)# interface port-channel 1
Switch-A(config-if)# switchport mode trunk
Switch-A(config-if)# switchport trunk allowed vlan 10,20,30,99
Switch-A(config-if)# switchport trunk native vlan 99
Switch-A(config-if)# exit

! Switch-B : Configuration EtherChannel LACP
Switch-B(config)# interface range gigabitethernet 0/1-4
Switch-B(config-if-range)# channel-group 1 mode active
Switch-B(config-if-range)# exit

Switch-B(config)# interface port-channel 1
Switch-B(config-if)# switchport mode trunk
Switch-B(config-if)# switchport trunk allowed vlan 10,20,30,99
Switch-B(config-if)# switchport trunk native vlan 99
Switch-B(config-if)# exit
```

### Configuration PAgP

```cisco
! Switch-A : Configuration EtherChannel PAgP
Switch-A(config)# interface range gigabitethernet 0/1-2
Switch-A(config-if-range)# channel-group 2 mode desirable
Switch-A(config-if-range)# exit

Switch-A(config)# interface port-channel 2
Switch-A(config-if)# switchport mode trunk
Switch-A(config-if)# exit

! Switch-B : Configuration EtherChannel PAgP
Switch-B(config)# interface range gigabitethernet 0/1-2
Switch-B(config-if-range)# channel-group 2 mode auto
Switch-B(config-if-range)# exit

Switch-B(config)# interface port-channel 2
Switch-B(config-if)# switchport mode trunk
Switch-B(config-if)# exit
```

### Configuration EtherChannel Layer 3

```cisco
! EtherChannel roule (L3) entre deux switches L3
Switch-A(config)# interface range gigabitethernet 0/1-2
Switch-A(config-if-range)# no switchport
Switch-A(config-if-range)# channel-group 3 mode active
Switch-A(config-if-range)# exit

Switch-A(config)# interface port-channel 3
Switch-A(config-if)# no switchport
Switch-A(config-if)# ip address 10.1.1.1 255.255.255.252
Switch-A(config-if)# exit
```

### Commandes de Verification

```cisco
! Resume de tous les EtherChannels
Switch# show etherchannel summary

Flags:  D - down        P - bundled in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer 3     S - Layer 2
        U - in use

Group  Port-channel  Protocol    Ports
------+-------------+-----------+------------------------------
1      Po1(SU)       LACP        Gi0/1(P)  Gi0/2(P)
                                 Gi0/3(P)  Gi0/4(P)

! Detail d'un EtherChannel
Switch# show etherchannel 1 detail

! Statistiques du port-channel
Switch# show interfaces port-channel 1

! Status des ports membres
Switch# show etherchannel port-channel

! Verifier le load balancing
Switch# show etherchannel load-balance

! Methode de hash actuelle
Switch# show port-channel load-balance
```

---

## Methodes de Load Balancing

### Algorithmes de Repartition

```
Le trafic est reparti sur les liens membres via un algorithme de hash.
Le hash determine quel lien physique transportera chaque flux.

Methodes disponibles :
┌───────────────┬───────────────────────────────────────────────┐
│ Methode       │ Hash base sur                                 │
├───────────────┼───────────────────────────────────────────────┤
│ src-mac       │ Adresse MAC source                            │
│ dst-mac       │ Adresse MAC destination                       │
│ src-dst-mac   │ Combinaison MAC source + destination          │
│ src-ip        │ Adresse IP source                             │
│ dst-ip        │ Adresse IP destination                        │
│ src-dst-ip    │ Combinaison IP source + destination           │
│ src-port      │ Port TCP/UDP source                           │
│ dst-port      │ Port TCP/UDP destination                      │
│ src-dst-port  │ Combinaison port source + destination         │
└───────────────┴───────────────────────────────────────────────┘

Recommandations :
┌────────────────────────┬─────────────────────────────────────┐
│ Scenario               │ Methode recommandee                 │
├────────────────────────┼─────────────────────────────────────┤
│ Switch L2 (access)     │ src-dst-mac                         │
│ Switch L3 (routing)    │ src-dst-ip                          │
│ Trafic vers serveur    │ src-ip (distribue par client)       │
│ Trafic depuis serveur  │ dst-ip (distribue par client)       │
└────────────────────────┴─────────────────────────────────────┘

Configuration :
Switch(config)# port-channel load-balance src-dst-ip
```

### Fonctionnement du Hash

```
Exemple avec src-dst-mac et 4 liens :

Le switch applique un XOR (OU exclusif) sur les bits de basse
position des adresses MAC pour determiner le lien.

Flux 1 : MAC-A → MAC-X  → Hash = 0  → Lien Gi0/1
Flux 2 : MAC-B → MAC-X  → Hash = 1  → Lien Gi0/2
Flux 3 : MAC-C → MAC-Y  → Hash = 2  → Lien Gi0/3
Flux 4 : MAC-D → MAC-Y  → Hash = 3  → Lien Gi0/4

Un flux specifique utilisera TOUJOURS le meme lien
(pas de repartition par paquet, mais par flux).

4 liens : 2 bits de hash = 4 possibilites (0,1,2,3)
2 liens : 1 bit de hash  = 2 possibilites (0,1)
8 liens : 3 bits de hash = 8 possibilites (0-7)
```

---

## Troubleshooting EtherChannel

### Pre-requis pour la Formation du Channel

```
Tous les ports membres DOIVENT avoir la meme configuration :

┌──────────────────────┬────────────────────────────────────────┐
│ Parametre            │ Exigence                               │
├──────────────────────┼────────────────────────────────────────┤
│ Vitesse              │ Identique sur tous les ports           │
│ Duplex               │ Identique (full-duplex recommande)     │
│ VLAN (mode access)   │ Meme VLAN sur tous les ports           │
│ Trunk mode           │ Meme mode (trunk ou access)            │
│ Allowed VLANs        │ Meme liste sur tous les ports trunk    │
│ Native VLAN          │ Meme Native VLAN sur tous les ports    │
│ STP port cost        │ Ne pas configurer individuellement     │
│ STP port priority    │ Ne pas configurer individuellement     │
└──────────────────────┴────────────────────────────────────────┘

Si un parametre differe : le channel NE SE FORME PAS
ou le port est suspendu (s) du bundle.
```

### Problemes Courants et Diagnostics

```
Probleme 1 : EtherChannel ne se forme pas
──────────────────────────────────────────
Symptome : show etherchannel summary montre (I) stand-alone
Diagnostic :
  Switch# show etherchannel summary
  Switch# show interfaces gi0/1 switchport
  Switch# show interfaces gi0/2 switchport
Causes :
  - Mismatch de protocole (LACP vs PAgP vs on)
  - Mismatch de configuration port (speed, duplex, VLAN)
  - Mismatch de mode (trunk vs access)
  - Modes passifs des deux cotes (passive-passive ou auto-auto)
Solution :
  Verifier et harmoniser la configuration de TOUS les ports membres

Probleme 2 : Port suspendu (s) dans le bundle
──────────────────────────────────────────
Symptome : show etherchannel summary montre Gi0/3(s)
Diagnostic :
  Switch# show etherchannel detail
  Switch# show interfaces gi0/3 switchport
Cause :
  Configuration du port Gi0/3 differente des autres membres
Solution :
  Harmoniser la config du port suspendu avec les autres

Probleme 3 : Un lien physique tombe
──────────────────────────────────────────
Symptome : Bande passante reduite
Diagnostic :
  Switch# show etherchannel summary
  Switch# show interfaces gi0/1 status
Comportement normal :
  Le trafic est redistribue sur les liens restants
  Pas de recalcul STP (le port-channel reste up)
  Verifier le lien physique (cable, SFP, port)

Probleme 4 : Performances inegales
──────────────────────────────────────────
Symptome : Un lien sature, les autres inactifs
Diagnostic :
  Switch# show interfaces port-channel 1 counters
  Switch# show etherchannel load-balance
Cause :
  Methode de load balancing inadaptee au profil de trafic
Solution :
  Switch(config)# port-channel load-balance src-dst-ip
```

### Ordre de Configuration Recommande

```
Etape 1 : Configurer les interfaces physiques
  - Meme speed, duplex, mode switchport
  - Ne PAS configurer le channel-group en premier

Etape 2 : Creer le channel-group
  interface range gi0/1-4
   channel-group 1 mode active

Etape 3 : Configurer le port-channel logique
  interface port-channel 1
   switchport mode trunk
   switchport trunk allowed vlan 10,20,30

Etape 4 : Verifier
  show etherchannel summary
  show etherchannel detail
  show interfaces port-channel 1
```

---

## Schemas Recapitulatifs

### Architecture EtherChannel Multi-Niveaux

```
                    ┌──────────────────┐
                    │    SW-CORE-1     │
                    │                  │
                    │  Po1     Po2     │
                    └──╦═══════╦═══════┘
                       ║       ║
              2x10G    ║       ║  2x10G
              LACP     ║       ║  LACP
                       ║       ║
         ┌─────────────╨──┐ ┌──╨─────────────┐
         │   SW-DIST-1    │ │   SW-DIST-2    │
         │                │ │                │
         │   Po3          │ │   Po3          │
         │   (4xGi LACP)  │ │   (4xGi LACP)  │
         └──╦══════╦══════┘ └══════╦═════╦═══┘
            ║      ║               ║     ║
            ║      ║               ║     ║
      ┌─────╨──┐ ┌─╨────────┐ ┌───╨──┐ ┌╨───────┐
      │SW-ACC1 │ │ SW-ACC2  │ │SW-ACC3│ │SW-ACC4 │
      │        │ │          │ │       │ │        │
      │  Users │ │  Users   │ │ Users │ │ Users  │
      └────────┘ └──────────┘ └───────┘ └────────┘

Resume de la connectivite :
- Core ↔ Distribution : Po1/Po2 (2x10G LACP) = 20 Gbps
- Distribution ↔ Distribution : Po3 (4xGi LACP) = 4 Gbps
- Distribution ↔ Access : Po4 (2xGi LACP) = 2 Gbps
```

---

## Questions de Revision

### Concepts

1. Pourquoi EtherChannel est-il preferable a des liens individuels redondants ?
2. Quelle est la difference fondamentale entre LACP et PAgP ?
3. Pourquoi le mode "on" est-il deconseille en production ?

### Configuration

4. Les deux cotes sont en mode "passive" LACP. Le channel se forme-t-il ?
5. Peut-on mixer des ports a des vitesses differentes dans un EtherChannel ?
6. Ou doit-on configurer le mode trunk : sur les ports physiques ou le port-channel ?

### Troubleshooting

7. Un port affiche (s) dans show etherchannel summary. Que signifie ce flag ?
8. Le channel est forme mais les performances ne s'ameliorent pas. Quelle est la cause probable ?
9. Quelle commande verifie la methode de load balancing actuelle ?

### Reponses

1. Avec des liens individuels, STP bloque les liens redondants. EtherChannel combine tous les liens en un seul lien logique, tous actifs simultanement.
2. LACP est un standard IEEE ouvert (802.3ad), compatible multi-vendeurs. PAgP est proprietaire Cisco, uniquement entre equipements Cisco.
3. Le mode "on" ne negocie pas et ne detecte pas les erreurs de configuration. Un mismatch de configuration peut causer des boucles.
4. Non. Il faut au moins un cote en "active" pour initier la negociation.
5. Non. Tous les ports doivent avoir la meme vitesse et le meme duplex.
6. Sur l'interface port-channel. La configuration se propage automatiquement aux ports membres. Configurer sur les ports physiques individuellement peut causer des inconsistances.
7. Le flag (s) signifie "suspended". Le port est suspendu du bundle a cause d'une incompatibilite de configuration avec les autres membres.
8. Methode de load balancing inadaptee. Si tout le trafic a la meme source/destination, un seul lien sera utilise. Changer la methode de hash (ex: src-dst-ip).
9. `show etherchannel load-balance` ou `show port-channel load-balance`.

---

*Fiche creee pour la revision CCNA*
*Auteur : Tudy Gbaguidi*
