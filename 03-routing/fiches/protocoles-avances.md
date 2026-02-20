# Protocoles de Routage Avances - EIGRP, BGP et Redistribution

## Vue d'Ensemble

Ce chapitre couvre les protocoles de routage avances au programme CCNA : EIGRP (protocole hybride Cisco), BGP (routage inter-AS) et les concepts de redistribution entre protocoles.

---

## EIGRP - Enhanced Interior Gateway Routing Protocol

### Concepts Fondamentaux

EIGRP est un protocole de routage avance developpe par Cisco, combine les avantages des protocoles distance-vector et link-state. Il utilise l'algorithme DUAL (Diffusing Update Algorithm) pour garantir des chemins sans boucle.

```
Caracteristiques EIGRP :
+----------------------------------+----------------------------------+
| Propriete                        | Valeur                           |
+----------------------------------+----------------------------------+
| Type                             | Advanced Distance Vector         |
| Algorithme                       | DUAL (Diffusing Update Algorithm)|
| Administrative Distance (interne)| 90                               |
| Administrative Distance (externe)| 170                              |
| Transport                        | Protocole IP 88 (ni TCP ni UDP)  |
| Multicast                        | 224.0.0.10                       |
| Mises a jour                     | Partielles et bornees            |
|                                  | (pas de mises a jour periodiques)|
| Load Balancing                   | Equal-cost et Unequal-cost       |
| Convergence                      | Tres rapide                      |
| Support                          | IPv4 et IPv6                     |
+----------------------------------+----------------------------------+
```

### Algorithme DUAL

DUAL (Diffusing Update Algorithm) calcule les meilleurs chemins sans boucle en maintenant des routes successeur et successeur realisable.

```
Terminologie DUAL :

+------------------------------------------------------------------+
|                                                                  |
| Reported Distance (RD) = Aussi appelee Advertised Distance       |
|   Distance totale annoncee par le VOISIN vers la destination     |
|                                                                  |
| Feasible Distance (FD)                                           |
|   Distance totale depuis CE ROUTEUR vers la destination          |
|   FD = Metrique vers le voisin + RD du voisin                   |
|                                                                  |
| Successor (S)                                                    |
|   Voisin avec la meilleure FD (route principale)                |
|   Installe dans la table de routage                              |
|                                                                  |
| Feasible Successor (FS)                                          |
|   Voisin de secours qui remplit la Feasibility Condition :       |
|   RD du candidat < FD du Successor actuel                       |
|   (Garantit un chemin sans boucle)                               |
|                                                                  |
+------------------------------------------------------------------+

Exemple Concret :

                    Destination : 10.0.0.0/24
                           |
              R1 ----------+
             /    \
           /        \
    R2 (via A)     R3 (via B)
    RD = 20480     RD = 30720
    Metric to R2   Metric to R3
    = 10240        = 10240
         |              |
    FD = 30720     FD = 40960
    (10240+20480)  (10240+30720)

Analyse :
+--------------------------------------------------+
| R2 est le Successor (FD la plus basse = 30720)   |
|                                                  |
| R3 est-il Feasible Successor ?                   |
| Condition : RD(R3) < FD(Successor)               |
|             30720 > 30720  --> NON !              |
|                                                  |
| R3 n'est PAS Feasible Successor                  |
| (Si RD etait 25000 < 30720, il le serait)        |
+--------------------------------------------------+

Quand le Successor tombe :
+--------------------------------------------------+
| Si Feasible Successor existe :                   |
|   Basculement INSTANTANE (pas de recalcul)       |
|                                                  |
| Si PAS de Feasible Successor :                   |
|   Le routeur passe en etat ACTIVE                |
|   et envoie des Queries aux voisins              |
|   (recalcul DUAL = plus lent)                    |
+--------------------------------------------------+
```

### Tables EIGRP

EIGRP maintient 3 tables distinctes :

```
Les 3 Tables EIGRP :

1. Neighbor Table (show ip eigrp neighbors)
+------------------------------------------------------------------+
| Voisin        | Interface  | Hold Time | Uptime   | SRTT  | Q    |
+------------------------------------------------------------------+
| 10.0.0.2      | Gi0/1      | 12 sec    | 01:23:45 | 10 ms | 0    |
| 10.0.1.2      | Gi0/2      | 14 sec    | 00:45:12 | 15 ms | 0    |
+------------------------------------------------------------------+
  Hold Time = Temps avant de declarer le voisin mort
  SRTT = Smooth Round-Trip Time
  Q = Paquets en file d'attente

2. Topology Table (show ip eigrp topology)
+------------------------------------------------------------------+
| Destination    | FD      | Via (Next-Hop)  | RD      | Status    |
+------------------------------------------------------------------+
| 10.0.0.0/24    | 30720   | 10.0.0.2 (S)    | 20480   | Passive   |
|                | 40960   | 10.0.1.2        | 30720   | (non FS)  |
| 192.168.1.0/24 | 28160   | 10.0.0.2 (S)    | 28160   | Passive   |
|                | 33280   | 10.0.1.2 (FS)   | 25600   | Passive   |
+------------------------------------------------------------------+
  (S) = Successor, (FS) = Feasible Successor
  Passive = Route stable, Active = En cours de recalcul

3. Routing Table (show ip route eigrp)
+------------------------------------------------------------------+
| D    10.0.0.0/24 [90/30720] via 10.0.0.2, Gi0/1                 |
| D    192.168.1.0/24 [90/28160] via 10.0.0.2, Gi0/1              |
+------------------------------------------------------------------+
  D = EIGRP, [AD/Metrique]
  Seuls les Successors apparaissent ici
```

### Metriques EIGRP

EIGRP utilise une metrique composite basee sur plusieurs parametres :

```
Formule de la Metrique EIGRP :

Metric = 256 * ( K1*BW + (K2*BW)/(256-Load) + K3*Delay ) * (K5/(K4+Reliability))

Avec les valeurs K par defaut (K1=1, K2=0, K3=1, K4=0, K5=0) :

Metric = 256 * (BW + Delay)

Ou :
  BW    = 10^7 / bandwidth_min_kbps  (plus petit bandwidth du chemin)
  Delay = somme_des_delays / 10      (somme des delays en microsecondes)

+---------------+-------------------+-------------------+
| Parametre     | Utilise (defaut)  | Description       |
+---------------+-------------------+-------------------+
| Bandwidth     | Oui (K1=1)        | BW minimum du     |
|               |                   | chemin en kbps    |
+---------------+-------------------+-------------------+
| Delay         | Oui (K3=1)        | Somme des delays  |
|               |                   | du chemin         |
+---------------+-------------------+-------------------+
| Reliability   | Non (K5=0)        | Fiabilite du lien |
|               |                   | (0-255)           |
+---------------+-------------------+-------------------+
| Load          | Non (K2=0)        | Charge du lien    |
|               |                   | (0-255)           |
+---------------+-------------------+-------------------+
| MTU           | Non               | Reporte mais      |
|               |                   | non utilise       |
+---------------+-------------------+-------------------+

Exemple de calcul :
Interface FastEthernet : BW = 100000 kbps, Delay = 100 usec
  BW component  = 10^7 / 100000 = 100
  Delay component = 100 / 10 = 10
  Metric = 256 * (100 + 10) = 28160

Interface Serial T1 : BW = 1544 kbps, Delay = 20000 usec
  BW component  = 10^7 / 1544 = 6476
  Delay component = 20000 / 10 = 2000
  Metric = 256 * (6476 + 2000) = 2,169,856
```

### Configuration EIGRP

```cisco
! Configuration EIGRP de base
R1(config)# router eigrp 100
R1(config-router)# eigrp router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255
R1(config-router)# network 10.0.0.0 0.0.0.3
R1(config-router)# no auto-summary
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# exit

! EIGRP Named Mode (recommande, plus recent)
R1(config)# router eigrp ENTERPRISE
R1(config-router)# address-family ipv4 unicast autonomous-system 100
R1(config-router-af)# eigrp router-id 1.1.1.1
R1(config-router-af)# network 192.168.1.0 0.0.0.255
R1(config-router-af)# network 10.0.0.0 0.0.0.3
R1(config-router-af)# af-interface GigabitEthernet0/0
R1(config-router-af-interface)# passive-interface
R1(config-router-af-interface)# exit-af-interface
R1(config-router-af)# exit-address-family

! Verification EIGRP
R1# show ip eigrp neighbors
IP-EIGRP neighbors for process 100
H   Address         Interface    Hold  Uptime    SRTT   RTO   Q   Seq
                                 (sec)            (ms)        Cnt  Num
0   10.0.0.2        Gi0/1        12    01:23:45  10     200   0    45

R1# show ip eigrp topology
IP-EIGRP Topology Table for AS(100)/ID(1.1.1.1)

P 10.0.0.0/24, 1 successors, FD is 28160
        via Connected, GigabitEthernet0/1
P 192.168.2.0/24, 1 successors, FD is 30720
        via 10.0.0.2 (30720/28160), GigabitEthernet0/1

R1# show ip route eigrp
D    192.168.2.0/24 [90/30720] via 10.0.0.2, 01:23:45, Gi0/1
```

### Unequal-Cost Load Balancing (Variance)

EIGRP est le seul protocole IGP qui supporte le load balancing sur des chemins de couts differents.

```
Fonctionnement de la Variance :

R1 a deux chemins vers 10.0.0.0/24 :
  Successor : FD = 30720 (via R2)
  FS        : FD = 40960 (via R3)

Sans variance (defaut = 1) :
  Seul le Successor est utilise

Avec variance 2 :
  Tous les FS dont FD < Successor_FD * variance sont utilises
  40960 < 30720 * 2 = 61440 --> OUI, R3 est utilise

Configuration :
R1(config)# router eigrp 100
R1(config-router)# variance 2
! Utilise les chemins jusqu'a 2x la FD du Successor

Le trafic est reparti proportionnellement aux metriques :
  R2 (FD 30720) recoit ~57% du trafic
  R3 (FD 40960) recoit ~43% du trafic
```

---

## BGP - Border Gateway Protocol

### Concepts Fondamentaux

BGP est le protocole de routage utilise entre les Autonomous Systems (AS) sur Internet. C'est le protocole qui fait fonctionner le routage Internet global.

```
Qu'est-ce qu'un Autonomous System (AS) ?

Un AS est un ensemble de reseaux sous une administration unique
avec une politique de routage commune.

Chaque AS a un numero unique (ASN) attribue par un RIR :
  - ASN 16 bits : 1 - 65535
  - ASN 32 bits : 65536 - 4294967295
  - ASN prives : 64512 - 65534 (16 bits), 4200000000 - 4294967294 (32 bits)

Schema : BGP entre Autonomous Systems

+------------------+          +------------------+
|    AS 65001      |          |    AS 65002      |
|                  |          |                  |
|  +-----------+   |   eBGP   |   +-----------+  |
|  |   R1      |---+----------+---|   R3      |  |
|  | (iBGP)    |   |          |   | (iBGP)    |  |
|  +-----+-----+   |          |   +-----+-----+  |
|        |         |          |         |         |
|  +-----+-----+   |          |   +-----+-----+  |
|  |   R2      |   |          |   |   R4      |  |
|  +-----------+   |          |   +-----------+  |
|                  |          |                  |
+------------------+          +------------------+

eBGP = External BGP (entre AS differents)
  - AD = 20
  - TTL = 1 (voisins directement connectes par defaut)
  - Utilise pour echanger des routes entre organisations

iBGP = Internal BGP (dans le meme AS)
  - AD = 200
  - TTL = 255
  - Synchronise les routes BGP au sein de l'AS
  - Necessite full-mesh iBGP ou route reflectors
```

### eBGP vs iBGP

```
+---------------------------+---------------------------+
| eBGP                      | iBGP                      |
+---------------------------+---------------------------+
| Entre AS differents       | Dans le meme AS           |
| AD = 20                   | AD = 200                  |
| TTL = 1 (par defaut)      | TTL = 255                 |
| Next-hop modifie          | Next-hop NON modifie      |
| AS-Path incremente        | AS-Path inchange          |
| Peering direct (general.) | Peut etre via IGP         |
+---------------------------+---------------------------+

Exemple de session BGP :

R1 (AS 65001) <----eBGP----> R3 (AS 65002)
  IP: 10.0.0.1                IP: 10.0.0.2

Configuration R1 :
R1(config)# router bgp 65001
R1(config-router)# bgp router-id 1.1.1.1
R1(config-router)# neighbor 10.0.0.2 remote-as 65002
R1(config-router)# network 192.168.1.0 mask 255.255.255.0

Configuration R3 :
R3(config)# router bgp 65002
R3(config-router)# bgp router-id 3.3.3.3
R3(config-router)# neighbor 10.0.0.1 remote-as 65001
R3(config-router)# network 172.16.0.0 mask 255.255.0.0
```

### BGP Path Attributes

BGP utilise des path attributes (attributs de chemin) pour selectionner la meilleure route parmi plusieurs chemins possibles.

```
Processus de Selection BGP (dans l'ordre) :

+------+---------------------------+-------------------------------------+
| Prio | Attribut                  | Regle de selection                  |
+------+---------------------------+-------------------------------------+
|  1   | Weight (Cisco propriet.)  | Plus ELEVE est prefere (local)      |
|  2   | Local Preference          | Plus ELEVE est prefere (dans l'AS)  |
|  3   | Locally Originated        | Routes locales preferees            |
|  4   | AS-Path Length            | Plus COURT est prefere              |
|  5   | Origin Type               | IGP (i) < EGP (e) < Incomplete (?) |
|  6   | MED (Multi-Exit Disc.)    | Plus BAS est prefere (entre AS)     |
|  7   | eBGP over iBGP            | eBGP prefere a iBGP                 |
|  8   | IGP Metric to Next-Hop    | Plus BAS est prefere                |
|  9   | Router-ID                 | Plus BAS est prefere                |
+------+---------------------------+-------------------------------------+

Attribut AS-Path (le plus important pour la CCNA) :

AS 100 annonce 10.0.0.0/8 :
  Vu par AS 200 : AS-Path = "100"        (1 AS)
  Vu par AS 300 : AS-Path = "200 100"    (2 AS)
  Vu par AS 400 : AS-Path = "300 200 100" (3 AS)

BGP prefere le chemin avec le moins d'AS dans le path

Schema :
AS 100 ----> AS 200 ----> AS 300 ----> AS 400
10.0.0.0/8
  Path: ""    Path: "100"  Path:"200,100" Path:"300,200,100"

AS 400 choisit le chemin le plus court pour atteindre 10.0.0.0/8
```

### Verification BGP

```cisco
! Etat des voisins BGP
R1# show ip bgp summary
BGP router identifier 1.1.1.1, local AS number 65001
Neighbor        V    AS MsgRcvd MsgSent TblVer  InQ OutQ Up/Down  State/PfxRcd
10.0.0.2        4 65002    1234    1200      5    0    0 01:23:45       3

! Table BGP complete
R1# show ip bgp
Network          Next Hop       Metric LocPrf Weight Path
*> 192.168.1.0   0.0.0.0             0         32768 i
*> 172.16.0.0/16 10.0.0.2            0             0 65002 i
*> 10.0.0.0/24   10.0.0.2            0             0 65002 65003 i

! Detail d'un prefixe
R1# show ip bgp 172.16.0.0/16

! Routes BGP dans la table de routage
R1# show ip route bgp
B    172.16.0.0/16 [20/0] via 10.0.0.2, 01:23:45
```

---

## Table Comparative des Administrative Distances

```
+----------------------------+----+---------------------------------------+
| Source de Route             | AD | Quand l'utiliser                      |
+----------------------------+----+---------------------------------------+
| Connected                   |  0 | Interfaces directement connectees     |
| Static                      |  1 | Petits reseaux, routes specifiques    |
| eBGP                        | 20 | Routage inter-AS (Internet)           |
| EIGRP (interne)             | 90 | Reseaux Cisco, convergence rapide     |
| OSPF                        |110 | Standard industrie, multi-vendor      |
| IS-IS                       |115 | Gros ISP, design simple               |
| RIP                         |120 | Legacy, petits reseaux simples        |
| EIGRP (externe)             |170 | Routes redistribuees dans EIGRP       |
| iBGP                        |200 | BGP interne a l'AS                    |
+----------------------------+----+---------------------------------------+

Regle de selection :
Quand un routeur connait une meme destination via plusieurs
protocoles, il installe la route avec l'AD la plus BASSE.

Exemple :
10.0.0.0/24 connu via :
  - OSPF    : AD 110, metrique 20    --> Non installe
  - EIGRP   : AD 90, metrique 30720  --> INSTALLE (AD la plus basse)
  - Static  : AD 1                    --> INSTALLE (priorite sur EIGRP)

Resultat : La route statique est installee (AD 1 < AD 90)
```

---

## Redistribution

### Concept

La redistribution permet d'echanger des routes entre differents protocoles de routage.

```
Schema de Redistribution :

  Domaine OSPF              Domaine EIGRP
+----------------+        +----------------+
|                |        |                |
|  R1 ---- R2   | R3     |   R4 ---- R5   |
|          |    |(ASBR)  |    |            |
|          +----+--------+----+            |
|                |Redistrib.|              |
|                |OSPF <-> EIGRP           |
+----------------+        +----------------+

R3 redistribue :
  - Les routes OSPF dans EIGRP
  - Les routes EIGRP dans OSPF

Configuration R3 :
R3(config)# router ospf 1
R3(config-router)# redistribute eigrp 100 subnets metric-type 1

R3(config)# router eigrp 100
R3(config-router)# redistribute ospf 1 metric 10000 100 255 1 1500
!                                        BW    Delay Rel Load MTU

Points d'attention :
+------------------------------------------------------+
| - Redistribution peut creer des boucles de routage   |
| - Toujours filtrer avec des route-maps               |
| - Les metriques doivent etre definies (seed metric)  |
| - Routes redistribuees ont une AD differente :       |
|   OSPF E2 (default) ou E1                            |
|   EIGRP externe (AD 170)                             |
+------------------------------------------------------+
```

### Redistribution : Points Cles CCNA

```
Routes redistribuees dans OSPF :
  - Type E1 : Metrique = cout interne + cout externe
  - Type E2 : Metrique = cout externe seulement (defaut)
  - E1 est prefere a E2 pour le meme reseau

Routes redistribuees dans EIGRP :
  - Marquees comme External (D EX dans la table)
  - AD = 170 (au lieu de 90 pour les internes)
  - Seed metric obligatoire (sinon infinity)

Verification :
R1# show ip route ospf
O E2  10.0.0.0/24 [110/20] via 10.0.0.3, Gi0/1   <-- Route externe OSPF

R4# show ip route eigrp
D EX  192.168.1.0/24 [170/33280] via 10.0.1.1, Gi0/0  <-- Route externe EIGRP
```

---

## Comparaison des Protocoles de Routage

```
+------------------+--------+--------+---------+--------+
| Caracteristique  | RIP    | EIGRP  | OSPF    | BGP    |
+------------------+--------+--------+---------+--------+
| Type             | DV     | Adv DV | LS      | PV     |
| AD (interne)     | 120    | 90     | 110     | 20(e)  |
| Algorithme       | Bellman| DUAL   | Dijkstra| Best   |
|                  | Ford   |        | (SPF)   | Path   |
| Metrique         | Hop    | Compos.| Cost    | Path   |
|                  | Count  | (BW+DL)| (BW)    | Attr.  |
| Transport        | UDP    | IP 88  | IP 89   | TCP    |
|                  | 520    |        |         | 179    |
| Max Hops         | 15     | 255    | Illimite| Illim. |
| Convergence      | Lente  | Rapide | Rapide  | Lente  |
| VLSM/CIDR        | v2 oui | Oui    | Oui     | Oui    |
| Load Balancing   | Equal  | Equal+ | Equal   | N/A    |
|                  |        |Unequal |         |        |
| Hierarchique     | Non    | Non    | Oui     | Oui    |
|                  |        |        | (areas) | (AS)   |
| Standard/Proprio.| Std    | Cisco* | Std     | Std    |
| IPv6             | RIPng  | EIGRPv6| OSPFv3  | MP-BGP |
+------------------+--------+--------+---------+--------+

DV = Distance Vector, LS = Link-State
PV = Path Vector, Adv DV = Advanced Distance Vector
*EIGRP est maintenant un standard ouvert (RFC 7868)
```

## Questions de Revision

### EIGRP
1. Quelle est la difference entre Feasible Distance et Reported Distance ?
2. Qu'est-ce que la Feasibility Condition et pourquoi est-elle importante ?
3. Quelles metriques EIGRP utilise-t-il par defaut ?
4. Comment fonctionne le load balancing unequal-cost avec la variance ?

### BGP
1. Quelle est la difference entre eBGP et iBGP ?
2. Qu'est-ce que l'AS-Path et comment influence-t-il la selection de route ?
3. Pourquoi BGP utilise-t-il TCP (port 179) alors qu'OSPF et EIGRP non ?

### Redistribution
1. Pourquoi la redistribution peut-elle creer des boucles de routage ?
2. Quelle est la difference entre OSPF External Type 1 et Type 2 ?
3. Que se passe-t-il si on redistribue dans EIGRP sans specifier de seed metric ?

### Comparaison
1. Un routeur recoit la route 10.0.0.0/24 via OSPF (AD 110) et EIGRP (AD 90). Laquelle est installee ?
2. Quand choisir OSPF plutot qu'EIGRP ?
3. Pourquoi EIGRP est-il considere comme "hybride" ?

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
