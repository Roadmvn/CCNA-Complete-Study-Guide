# Monitoring Reseau - NTP, Syslog, SNMP, CDP/LLDP

## Vue d'Ensemble

Le monitoring reseau repose sur plusieurs protocoles complementaires qui permettent de synchroniser l'heure, centraliser les logs, superviser les equipements et decouvrir la topologie. Ces protocoles sont essentiels pour l'administration et le depannage.

---

## NTP - Network Time Protocol

### Pourquoi Synchroniser l'Heure ?

La synchronisation horaire est critique pour :
- **Correlation des logs** : comparer les evenements entre equipements
- **Certificats SSL/TLS** : valides uniquement si l'heure est correcte
- **Protocoles de securite** : Kerberos exige une precision de 5 minutes
- **Forensics** : reconstituer la chronologie d'un incident

### Architecture NTP : Strates (Stratum)

```
Stratum 0 : Sources de reference (horloge atomique, GPS)
            Non directement accessibles sur le reseau
                          │
                          v
Stratum 1 : Serveurs primaires (connectes directement au Stratum 0)
            Exemples : pool.ntp.org, time.google.com
  ┌───────────────────────┼───────────────────────┐
  │                       │                       │
  v                       v                       v
Stratum 2 : Serveurs secondaires (synchronises sur Stratum 1)
            Serveurs NTP d'entreprise
  ┌───────────┼───────────┐
  │           │           │
  v           v           v
Stratum 3 : Clients NTP (routeurs, switches, serveurs)
            Equipements reseau de l'entreprise
  ┌─────┼─────┐
  │     │     │
  v     v     v
Stratum 4 : Clients finaux (PC, telephones IP)

Regle : Plus le stratum est bas, plus la source est precise
        Stratum maximum = 15 (stratum 16 = non synchronise)
```

### Configuration NTP sur Cisco

```cisco
! Configurer le routeur comme client NTP
Router(config)# ntp server 216.239.35.0
Router(config)# ntp server 216.239.35.4 prefer
Router(config)# ntp server 216.239.35.8

! Configurer le fuseau horaire
Router(config)# clock timezone CET 1 0
Router(config)# clock summer-time CEST recurring

! Configurer le routeur comme serveur NTP pour les clients internes
Router(config)# ntp master 3

! Authentification NTP (securite)
Router(config)# ntp authenticate
Router(config)# ntp authentication-key 1 md5 NtpSecretKey
Router(config)# ntp trusted-key 1
Router(config)# ntp server 216.239.35.0 key 1
```

### Verification NTP

```cisco
Router# show ntp status
Clock is synchronized, stratum 3, reference is 216.239.35.4
nominal freq is 250.0000 Hz, actual freq is 250.0000 Hz
reference time is E5A1B2C3.4D5E6F70 (15:30:45.302 CET Fri Feb 20 2026)

Router# show ntp associations
  address         ref clock       st   when   poll reach  delay  offset   disp
*~216.239.35.4    .GPS.            1     23     64   377   15.2    1.34    0.5
+~216.239.35.0    .GPS.            1     45     64   377   18.7    2.01    0.8
 ~216.239.35.8    .GPS.            1     12     64   377   20.1    3.45    1.2

! Symboles :
! * = serveur synchronise (master)
! + = serveur candidat
! - = serveur rejete
! ~ = serveur configure

Router# show clock
15:30:45.302 CET Fri Feb 20 2026
```

---

## Syslog - Journalisation Centralisee

### Niveaux de Severite Syslog

```
┌────────┬────────────────┬──────────────────────────────────────────────┐
│ Niveau │ Nom            │ Description                                  │
├────────┼────────────────┼──────────────────────────────────────────────┤
│   0    │ Emergency      │ Systeme inutilisable                        │
│   1    │ Alert          │ Action immediate requise                    │
│   2    │ Critical       │ Condition critique                          │
│   3    │ Error          │ Condition d'erreur                          │
│   4    │ Warning        │ Condition d'avertissement                   │
│   5    │ Notification   │ Condition normale mais significative        │
│   6    │ Informational  │ Message informatif                          │
│   7    │ Debugging      │ Message de debogage                        │
└────────┴────────────────┴──────────────────────────────────────────────┘

Mnemonique : "Every Awesome Cisco Engineer Will Need Ice-cream Daily"
             Emergency Alert Critical Error Warning Notification Info Debug

IMPORTANT : Configurer un niveau inclut TOUS les niveaux inferieurs
Exemple : "logging trap 4" capture les niveaux 0, 1, 2, 3 et 4
```

### Architecture Syslog

```
Equipements reseau                           Serveur Syslog
┌──────────┐                                ┌───────────────┐
│ Routeur  │───┐                            │               │
└──────────┘   │   UDP port 514             │  Syslog       │
┌──────────┐   ├──────────────────────────> │  Server       │
│ Switch   │───┤                            │               │
└──────────┘   │                            │  Stockage     │
┌──────────┐   │                            │  Analyse      │
│ Firewall │───┘                            │  Alertes      │
└──────────┘                                └───────────────┘

Format d'un message Syslog :
┌──────────────────────────────────────────────────────────────────┐
│ seq no: timestamp: %facility-severity-MNEMONIC: description     │
│                                                                  │
│ Exemple :                                                        │
│ 000045: Feb 20 15:30:45: %LINK-3-UPDOWN: Interface Gi0/1,       │
│         changed state to down                                    │
│                                                                  │
│ Decodage :                                                       │
│ - 000045 = numero de sequence                                   │
│ - Feb 20 15:30:45 = horodatage (importance du NTP !)            │
│ - LINK = facility (type de composant)                           │
│ - 3 = severity (Error)                                          │
│ - UPDOWN = mnemonique (nom de l'evenement)                      │
└──────────────────────────────────────────────────────────────────┘
```

### Configuration Syslog sur Cisco

```cisco
! Activer les timestamps sur les logs
Router(config)# service timestamps log datetime msec localtime show-timezone

! Activer les numeros de sequence
Router(config)# service sequence-numbers

! Configurer le logging vers un serveur Syslog distant
Router(config)# logging host 10.1.1.200
Router(config)# logging trap informational
Router(config)# logging source-interface Loopback0
Router(config)# logging facility local7

! Configurer le logging console
Router(config)# logging console warnings

! Configurer le logging buffer local
Router(config)# logging buffered 16384 informational

! Configurer le logging sur les lignes VTY
Router(config)# logging monitor debugging
```

### Verification Syslog

```cisco
Router# show logging
Syslog logging: enabled (0 messages dropped, 0 flushes, 0 overflows)
    Console logging: level warnings, 45 messages logged
    Monitor logging: level debugging, 120 messages logged
    Buffer logging:  level informational, 890 messages logged
    Logging to 10.1.1.200 (udp port 514, audit disabled,
          link up), 890 messages logged

Router# show logging | include %LINK
000045: Feb 20 15:30:45 CET: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to down
000046: Feb 20 15:31:02 CET: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to up
```

---

## SNMP - Simple Network Management Protocol

### Architecture SNMP

```
┌──────────────────────────────────────────────────────────────────────┐
│                        SNMP Architecture                             │
│                                                                      │
│  ┌────────────────┐         ┌─────────────────┐                     │
│  │  NMS (Network  │         │  SNMP Agent     │                     │
│  │  Management    │ <------>│  (sur chaque     │                     │
│  │  Station)      │ UDP 161 │  equipement)    │                     │
│  │                │         │                  │                     │
│  │  - Monitoring  │ <-------│  TRAP            │                     │
│  │  - Alertes     │ UDP 162 │  (notification   │                     │
│  │  - Graphiques  │         │   non sollicitee)│                     │
│  └────────────────┘         └─────────────────┘                     │
│         │                          │                                 │
│         │                          │                                 │
│         v                          v                                 │
│  ┌─────────────────────────────────────────────┐                    │
│  │              MIB (Management Information     │                    │
│  │                   Base)                      │                    │
│  │                                              │                    │
│  │  Structure arborescente des objets geres :  │                    │
│  │  .1.3.6.1.2.1.1.1.0 = sysDescr             │                    │
│  │  .1.3.6.1.2.1.1.3.0 = sysUpTime            │                    │
│  │  .1.3.6.1.2.1.1.5.0 = sysName              │                    │
│  │  .1.3.6.1.2.1.2.2.1.10 = ifInOctets        │                    │
│  │  .1.3.6.1.2.1.2.2.1.16 = ifOutOctets       │                    │
│  └─────────────────────────────────────────────┘                    │
└──────────────────────────────────────────────────────────────────────┘

Operations SNMP :
┌──────────────┬────────────────────────────────────────────────┐
│ Operation    │ Description                                     │
├──────────────┼────────────────────────────────────────────────┤
│ GET          │ NMS demande la valeur d'un objet a l'agent    │
│ GET-NEXT     │ NMS demande l'objet suivant dans la MIB       │
│ GET-BULK     │ NMS demande plusieurs objets (SNMPv2+)        │
│ SET          │ NMS modifie la valeur d'un objet sur l'agent  │
│ TRAP         │ Agent envoie une notification au NMS           │
│ INFORM       │ Comme TRAP mais avec accusee de reception      │
└──────────────┴────────────────────────────────────────────────┘
```

### Comparaison SNMPv2c vs SNMPv3

```
┌─────────────────┬──────────────────────┬──────────────────────┐
│ Critere         │ SNMPv2c              │ SNMPv3               │
├─────────────────┼──────────────────────┼──────────────────────┤
│ Authentification│ Community string     │ Username/Password    │
│                 │ (texte en clair !)   │ (MD5 ou SHA)         │
├─────────────────┼──────────────────────┼──────────────────────┤
│ Chiffrement     │ Aucun               │ DES, 3DES, AES       │
├─────────────────┼──────────────────────┼──────────────────────┤
│ Controle acces  │ RO / RW             │ Vues, groupes, users │
├─────────────────┼──────────────────────┼──────────────────────┤
│ Securite        │ Faible              │ Elevee               │
├─────────────────┼──────────────────────┼──────────────────────┤
│ Recommandation  │ Labs/tests          │ Production           │
└─────────────────┴──────────────────────┴──────────────────────┘

Niveaux de securite SNMPv3 :
┌──────────────────┬──────────────────┬───────────────────────┐
│ Niveau           │ Authentification │ Chiffrement           │
├──────────────────┼──────────────────┼───────────────────────┤
│ noAuthNoPriv     │ Non              │ Non                   │
│ authNoPriv       │ Oui (MD5/SHA)    │ Non                   │
│ authPriv         │ Oui (MD5/SHA)    │ Oui (AES/DES)        │
└──────────────────┴──────────────────┴───────────────────────┘
```

### Configuration SNMP sur Cisco

```cisco
! --- SNMPv2c ---

! Community string en lecture seule
Router(config)# snmp-server community READONLY ro
! Community string en lecture-ecriture (attention securite)
Router(config)# snmp-server community READWRITE rw

! Restreindre l'acces SNMP avec une ACL
Router(config)# access-list 20 permit 10.1.1.200
Router(config)# snmp-server community READONLY ro 20

! Configurer les traps
Router(config)# snmp-server host 10.1.1.200 version 2c READONLY
Router(config)# snmp-server enable traps snmp linkdown linkup
Router(config)# snmp-server enable traps config

! Informations systeme
Router(config)# snmp-server contact admin@entreprise.local
Router(config)# snmp-server location "Salle serveur, Batiment A"

! --- SNMPv3 (recommande en production) ---

! Creer un groupe SNMPv3
Router(config)# snmp-server group ADMIN-GROUP v3 priv

! Creer un utilisateur SNMPv3
Router(config)# snmp-server user admin ADMIN-GROUP v3 auth sha AuthP@ss123 priv aes 128 PrivP@ss456

! Configurer les traps SNMPv3
Router(config)# snmp-server host 10.1.1.200 version 3 priv admin
Router(config)# snmp-server enable traps
```

### Verification SNMP

```cisco
Router# show snmp
Chassis: FCZ1234A5BC
Contact: admin@entreprise.local
Location: Salle serveur, Batiment A
0 SNMP packets input
    0 Bad SNMP version errors
    0 Unknown community name
    0 Illegal operation for community name supplied
    0 Encoding errors
125 SNMP packets output
    0 Too big errors
    0 No such name errors
    0 Bad values errors
    0 General errors
75 Get-request PDUs
25 Get-next PDUs
0 Set-request PDUs
25 SNMP Trap PDUs

Router# show snmp community
Community name: READONLY
Community Index: READONLY
Community SecurityName: READONLY
storage-type: nonvolatile       active   access-list: 20

Router# show snmp group
Router# show snmp user
```

---

## CDP et LLDP - Decouverte de Voisins

### CDP (Cisco Discovery Protocol)

```
CDP = Protocole proprietaire Cisco
- Fonctionne en couche 2 (Data Link)
- Envoie des annonces toutes les 60 secondes
- Hold time : 180 secondes (3 annonces ratees = voisin supprime)
- Multicast : 01:00:0C:CC:CC:CC

Informations partagees :
┌────────────────────────────────────────────────┐
│ - Nom de l'equipement (hostname)               │
│ - Adresse IP de l'interface                    │
│ - Plateforme (modele : Catalyst 3560, ISR 4321)│
│ - Interface locale et distante                 │
│ - Version IOS                                  │
│ - Capabilities (Router, Switch, Phone...)      │
│ - VLAN natif (sur les switches)                │
│ - Duplex                                       │
└────────────────────────────────────────────────┘
```

### LLDP (Link Layer Discovery Protocol)

```
LLDP = Protocole standard IEEE 802.1AB (multi-vendor)
- Fonctionne en couche 2 (Data Link)
- Envoie des annonces toutes les 30 secondes
- Hold time : 120 secondes
- Multicast : 01:80:C2:00:00:0E

Meme type d'informations que CDP mais compatible avec tous les constructeurs
```

### Comparaison CDP vs LLDP

```
┌──────────────────┬──────────────────────┬──────────────────────┐
│ Critere          │ CDP                  │ LLDP                 │
├──────────────────┼──────────────────────┼──────────────────────┤
│ Standard         │ Proprietaire Cisco   │ IEEE 802.1AB (ouvert)│
│ Timer annonce    │ 60 secondes          │ 30 secondes          │
│ Hold time        │ 180 secondes         │ 120 secondes         │
│ Couche OSI       │ 2 (Data Link)        │ 2 (Data Link)        │
│ Compatibilite    │ Cisco uniquement     │ Multi-vendor         │
│ Actif par defaut │ Oui (Cisco)          │ Non (a activer)      │
└──────────────────┴──────────────────────┴──────────────────────┘
```

### Configuration CDP et LLDP

```cisco
! --- CDP ---

! CDP est active par defaut sur les equipements Cisco

! Desactiver CDP globalement (securite)
Router(config)# no cdp run

! Desactiver CDP sur une interface specifique
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# no cdp enable
Router(config-if)# exit

! Modifier les timers CDP
Router(config)# cdp timer 30
Router(config)# cdp holdtime 120

! --- LLDP ---

! Activer LLDP globalement
Router(config)# lldp run

! Activer/desactiver LLDP par interface
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# lldp transmit
Router(config-if)# lldp receive
Router(config-if)# exit

! Desactiver LLDP sur une interface
Router(config)# interface GigabitEthernet 0/1
Router(config-if)# no lldp transmit
Router(config-if)# no lldp receive
Router(config-if)# exit
```

### Verification CDP et LLDP

```cisco
! Voir les voisins CDP (resume)
Router# show cdp neighbors
Capability Codes: R - Router, T - Trans Bridge, B - Source Route Bridge
                  S - Switch, H - Host, I - IGMP, r - Repeater, P - Phone

Device ID    Local Intrfce   Holdtme    Capability  Platform  Port ID
SW1          Gig 0/0         165            S       WS-C3560  Gig 0/1
R2           Gig 0/1         140            R       ISR4321   Gig 0/0

! Voir les voisins CDP (detail)
Router# show cdp neighbors detail
Device ID: SW1
  IP address: 10.1.1.10
  Platform: cisco WS-C3560-24TS, Capabilities: Switch
  Interface: GigabitEthernet0/0, Port ID (outgoing port): GigabitEthernet0/1
  Version: Cisco IOS Software, C3560 Software (C3560-IPSERVICESK9-M), Version 15.2(4)E7

! Voir les voisins LLDP (resume)
Router# show lldp neighbors

! Voir les voisins LLDP (detail)
Router# show lldp neighbors detail

! Verifier que CDP/LLDP est actif
Router# show cdp
Router# show lldp
```

### Securite : Quand Desactiver CDP/LLDP ?

```
Desactiver CDP/LLDP sur les interfaces exposees :
- Interfaces connectees a Internet ou au WAN
- Interfaces dans des zones non securisees
- Interfaces des switches cote utilisateurs (si non necessaire)

Raison : CDP/LLDP expose des informations sensibles
         (modele, version IOS, adresses IP, topologie)
         Un attaquant peut les exploiter pour cibler des vulnerabilites

Bonne pratique :
- Laisser CDP/LLDP actif entre equipements reseau de confiance
- Desactiver sur les ports d'acces utilisateurs
- Desactiver sur les interfaces WAN/Internet
```

---

## Questions de Revision

### Niveau Fondamental
1. A quoi sert NTP et pourquoi est-il important pour le monitoring ?
2. Citez les 8 niveaux de severite Syslog dans l'ordre.
3. Quelle est la difference entre CDP et LLDP ?

### Niveau Intermediaire
1. Quelle est la difference entre SNMPv2c et SNMPv3 en termes de securite ?
2. Expliquez la notion de stratum dans NTP.
3. Pourquoi devrait-on desactiver CDP sur les interfaces WAN ?

### Niveau Avance
1. Concevez une strategie de monitoring complete pour une entreprise avec 3 sites : quels protocoles, quelle configuration ?
2. Un routeur affiche des logs avec des timestamps incorrects. Detaillez votre diagnostic.
3. Comparez les traps SNMP et les informs. Quand utiliser l'un plutot que l'autre ?

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
