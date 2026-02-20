# Exercices Pratiques de Routage - CCNA

---

## Lab 1 : Configuration de Routes Statiques et Default Route

### Topologie

```
                    10.0.12.0/30                  10.0.23.0/30
     [LAN-A]          .1    .2          .1    .2          [LAN-C]
  192.168.1.0/24 ---- R1 ------------- R2 ------------- R3 ---- 192.168.3.0/24
                      |                 |                 |
                   Gi0/0             Gi0/0             Gi0/0
                  .1 (LAN)          .1 (LAN)          .1 (LAN)
                      |                 |                 |
                   [LAN-A]          [LAN-B]           [LAN-C]
                192.168.1.0/24   192.168.2.0/24   192.168.3.0/24

Adressage des interfaces serie :
  R1 Se0/0/0 : 10.0.12.1/30   <---->   R2 Se0/0/0 : 10.0.12.2/30
  R2 Se0/0/1 : 10.0.23.1/30   <---->   R3 Se0/0/0 : 10.0.23.2/30
```

### Objectifs

- Configurer des routes statiques next-hop et exit-interface
- Configurer une default route
- Verifier la table de routage

### Etape 1 : Adressage des interfaces

```cisco
! === R1 ===
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip address 192.168.1.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit

R1(config)# interface Serial0/0/0
R1(config-if)# ip address 10.0.12.1 255.255.255.252
R1(config-if)# no shutdown
R1(config-if)# exit

! === R2 ===
R2(config)# interface GigabitEthernet0/0
R2(config-if)# ip address 192.168.2.1 255.255.255.0
R2(config-if)# no shutdown
R2(config-if)# exit

R2(config)# interface Serial0/0/0
R2(config-if)# ip address 10.0.12.2 255.255.255.252
R2(config-if)# no shutdown
R2(config-if)# exit

R2(config)# interface Serial0/0/1
R2(config-if)# ip address 10.0.23.1 255.255.255.252
R2(config-if)# no shutdown
R2(config-if)# exit

! === R3 ===
R3(config)# interface GigabitEthernet0/0
R3(config-if)# ip address 192.168.3.1 255.255.255.0
R3(config-if)# no shutdown
R3(config-if)# exit

R3(config)# interface Serial0/0/0
R3(config-if)# ip address 10.0.23.2 255.255.255.252
R3(config-if)# no shutdown
R3(config-if)# exit
```

### Etape 2 : Routes statiques next-hop sur R1

```cisco
! R1 doit joindre LAN-B et LAN-C via R2
R1(config)# ip route 192.168.2.0 255.255.255.0 10.0.12.2
R1(config)# ip route 192.168.3.0 255.255.255.0 10.0.12.2
R1(config)# ip route 10.0.23.0 255.255.255.252 10.0.12.2
```

### Etape 3 : Routes statiques exit-interface sur R3

```cisco
! R3 doit joindre LAN-A et LAN-B via R2
R3(config)# ip route 192.168.1.0 255.255.255.0 Serial0/0/0
R3(config)# ip route 192.168.2.0 255.255.255.0 Serial0/0/0
R3(config)# ip route 10.0.12.0 255.255.255.252 Serial0/0/0
```

### Etape 4 : Routes statiques sur R2

```cisco
! R2 connait deja LAN-B (directement connecte)
R2(config)# ip route 192.168.1.0 255.255.255.0 10.0.12.1
R2(config)# ip route 192.168.3.0 255.255.255.0 10.0.23.2
```

### Etape 5 : Default route sur R1

```cisco
! Supposons que R2 est la passerelle vers Internet
R1(config)# ip route 0.0.0.0 0.0.0.0 10.0.12.2
```

### Verification

```cisco
R1# show ip route
! Codes : C = connected, S = static, S* = default static

R1# show ip route static
! Affiche uniquement les routes statiques

R1# ping 192.168.3.1
! Doit reussir si toutes les routes sont correctes

R1# traceroute 192.168.3.1
! Doit montrer R2 puis R3
```

### Questions

**Q1 :**Quelle est la difference entre une route next-hop et une route exit-interface ?
**R1 :**La route next-hop specifie l'adresse IP du prochain routeur (ex: `ip route ... 10.0.12.2`). La route exit-interface specifie l'interface de sortie (ex: `ip route ... Serial0/0/0`). L'exit-interface est recommandee sur les liens point-a-point (Serial). Sur les reseaux multi-access (Ethernet), la route next-hop est preferee car l'exit-interface necessite une resolution ARP supplementaire.

**Q2 :**Que se passe-t-il si on supprime la route vers 10.0.23.0/30 sur R1 ?
**R2 :**R1 pourra toujours joindre LAN-C car le trafic vers 192.168.3.0/24 passe par 10.0.12.2 (R2), et R2 connait le lien 10.0.23.0/30 car il y est directement connecte. En revanche, R1 ne pourrait plus faire un ping directement vers 10.0.23.2 (interface de R3).

---

## Lab 2 : OSPF Single-Area (5 routeurs, Area 0)

### Topologie

```
                         Area 0

              10.0.12.0/30        10.0.24.0/30
         .1 ──────────── .2  .2 ──────────── .1
    R1                    R2                    R4
    |Gi0/0           Gi0/0|                Gi0/0|
    |.1                .1 |                  .1 |
    |                     |                     |
 [LAN-1]             [LAN-2]               [LAN-4]
192.168.1.0/24    192.168.2.0/24       192.168.4.0/24
    |
    | 10.0.13.0/30
    |.1
    |           .2
    +──────────R3──────────R5
          Gi0/0|     10.0.35.0/30
            .1 |      .1        .2
               |            Gi0/0|
           [LAN-3]            .1 |
        192.168.3.0/24           |
                             [LAN-5]
                          192.168.5.0/24

Liens :
  R1 Gi0/1 (10.0.12.1) <---> R2 Gi0/1 (10.0.12.2)
  R1 Gi0/2 (10.0.13.1) <---> R3 Gi0/1 (10.0.13.2)
  R2 Gi0/2 (10.0.24.2) <---> R4 Gi0/1 (10.0.24.1)
  R3 Gi0/2 (10.0.35.1) <---> R5 Gi0/1 (10.0.35.2)
```

### Objectifs

- Configurer OSPF dans une seule area
- Definir le Router-ID manuellement
- Configurer les passive-interfaces
- Verifier les voisins et la table de routage OSPF

### Etape 1 : Configuration OSPF sur R1

```cisco
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255 area 0
R1(config-router)# network 10.0.12.0 0.0.0.3 area 0
R1(config-router)# network 10.0.13.0 0.0.0.3 area 0
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# auto-cost reference-bandwidth 10000
R1(config-router)# exit
```

### Etape 2 : Configuration OSPF sur R2

```cisco
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# network 192.168.2.0 0.0.0.255 area 0
R2(config-router)# network 10.0.12.0 0.0.0.3 area 0
R2(config-router)# network 10.0.24.0 0.0.0.3 area 0
R2(config-router)# passive-interface GigabitEthernet0/0
R2(config-router)# auto-cost reference-bandwidth 10000
R2(config-router)# exit
```

### Etape 3 : Configuration OSPF sur R3, R4, R5

```cisco
! === R3 ===
R3(config)# router ospf 1
R3(config-router)# router-id 3.3.3.3
R3(config-router)# network 192.168.3.0 0.0.0.255 area 0
R3(config-router)# network 10.0.13.0 0.0.0.3 area 0
R3(config-router)# network 10.0.35.0 0.0.0.3 area 0
R3(config-router)# passive-interface GigabitEthernet0/0
R3(config-router)# auto-cost reference-bandwidth 10000
R3(config-router)# exit

! === R4 ===
R4(config)# router ospf 1
R4(config-router)# router-id 4.4.4.4
R4(config-router)# network 192.168.4.0 0.0.0.255 area 0
R4(config-router)# network 10.0.24.0 0.0.0.3 area 0
R4(config-router)# passive-interface GigabitEthernet0/0
R4(config-router)# auto-cost reference-bandwidth 10000
R4(config-router)# exit

! === R5 ===
R5(config)# router ospf 1
R5(config-router)# router-id 5.5.5.5
R5(config-router)# network 192.168.5.0 0.0.0.255 area 0
R5(config-router)# network 10.0.35.0 0.0.0.3 area 0
R5(config-router)# passive-interface GigabitEthernet0/0
R5(config-router)# auto-cost reference-bandwidth 10000
R5(config-router)# exit
```

### Verification

```cisco
! Verifier les voisins OSPF
R1# show ip ospf neighbor
Neighbor ID  Pri  State      Dead Time  Address       Interface
2.2.2.2       1  FULL/  -   00:00:38   10.0.12.2     Gi0/1
3.3.3.3       1  FULL/  -   00:00:35   10.0.13.2     Gi0/2

! Verifier les routes OSPF
R1# show ip route ospf
O     192.168.2.0/24 [110/11] via 10.0.12.2, Gi0/1
O     192.168.3.0/24 [110/11] via 10.0.13.2, Gi0/2
O     192.168.4.0/24 [110/21] via 10.0.12.2, Gi0/1
O     192.168.5.0/24 [110/21] via 10.0.13.2, Gi0/2
O     10.0.24.0/30   [110/20] via 10.0.12.2, Gi0/1
O     10.0.35.0/30   [110/20] via 10.0.13.2, Gi0/2

! Verifier les interfaces OSPF
R1# show ip ospf interface brief
Interface    PID   Area   IP Address/Mask    Cost  State Nbrs F/C
Gi0/1        1     0      10.0.12.1/30       10    P2P   1/1
Gi0/2        1     0      10.0.13.1/30       10    P2P   1/1
Gi0/0        1     0      192.168.1.1/24     10    DR    0/0

! Verifier le processus OSPF
R1# show ip ospf
  Routing Process "ospf 1" with ID 1.1.1.1
  Reference bandwidth unit is 10000 mbps
```

### Questions

**Q1 :**Pourquoi configure-t-on `passive-interface` sur Gi0/0 ?
**R1 :**L'interface Gi0/0 est connectee au LAN. Il n'y a pas de routeur OSPF sur ce segment, donc envoyer des paquets Hello est inutile. La passive-interface empeche l'envoi de Hello tout en continuant d'annoncer le reseau dans OSPF.

**Q2 :**Pourquoi utiliser `auto-cost reference-bandwidth 10000` ?
**R2 :**Par defaut, la reference bandwidth est 100 Mbps. Cela donne le meme cout (1) a FastEthernet, GigabitEthernet et 10GigE. En augmentant la reference a 10000 Mbps, les couts deviennent : FastEthernet=100, GigE=10, 10GigE=1. Cela permet a OSPF de choisir les meilleurs chemins en fonction de la bande passante reelle.

**Q3 :**Quel est le cout total de R1 vers LAN-5 (192.168.5.0/24) ?
**R3 :**Le chemin R1 -> R3 -> R5 : cout Gi0/2 (10) + cout R3-R5 (10) + cout LAN-5 (10) = 30. Si les interfaces sont GigabitEthernet avec reference-bandwidth 10000, chaque lien GigE coute 10.

---

## Lab 3 : OSPF Multi-Area avec Election DR/BDR

### Topologie

```
       Area 1                    Area 0                      Area 2
                                (Backbone)

  +-----------+          +----------------+           +-----------+
  |           |          |                |           |           |
  |  R1       |    .1    |  R2 (ABR)      |    .1     |  R4 (ABR) |
  |  Internal |----Gi0/1-|  Router-ID     |----Gi0/2--|  Router-ID|
  |  RID:     |   .2     |  2.2.2.2       |   .2      |  4.4.4.4  |
  |  1.1.1.1  |          |                |           |           |
  +-----------+          |     Gi0/1      |           +-----------+
       |                 |      |.1       |                 |
       | Gi0/1           |      |         |            Gi0/1|
       | .1              | 10.0.0.0/24    |              .1 |
       |                 |  (Segment      |                 |
  +-----------+          |  Multi-Access) |           +-----------+
  |           |          |      |         |           |           |
  |  R6       |          |      |.2       |           |  R5       |
  |  Internal |          |  R3 Backbone   |           |  Internal |
  |  RID:     |          |  RID: 3.3.3.3  |           |  RID:     |
  |  6.6.6.6  |          |                |           |  5.5.5.5  |
  +-----------+          +----------------+           +-----------+

Adressage :
  Area 1 :
    R1 Gi0/0 : 172.16.1.1/24  (LAN-1)
    R6 Gi0/0 : 172.16.6.1/24  (LAN-6)
    R1-R2    : 10.1.12.0/30
    R6-R1    : 10.1.16.0/30

  Area 0 :
    R2 Gi0/1 : 10.0.0.1/24   (segment multi-access)
    R3 Gi0/1 : 10.0.0.2/24   (segment multi-access)
    R2-R4    : 10.0.24.0/30

  Area 2 :
    R4 Gi0/0 : 172.16.4.1/24  (LAN-4)
    R5 Gi0/0 : 172.16.5.1/24  (LAN-5)
    R4-R5    : 10.2.45.0/30
```

### Objectifs

- Configurer OSPF multi-area avec ABR
- Observer et manipuler l'election DR/BDR
- Verifier les LSA de types 1, 2 et 3

### Etape 1 : Configuration ABR R2

```cisco
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# auto-cost reference-bandwidth 10000

! Interfaces dans Area 1
R2(config-router)# network 10.1.12.0 0.0.0.3 area 1

! Interfaces dans Area 0
R2(config-router)# network 10.0.0.0 0.0.0.255 area 0
R2(config-router)# network 10.0.24.0 0.0.0.3 area 0
R2(config-router)# exit
```

### Etape 2 : Configuration ABR R4

```cisco
R4(config)# router ospf 1
R4(config-router)# router-id 4.4.4.4
R4(config-router)# auto-cost reference-bandwidth 10000

! Interfaces dans Area 0
R4(config-router)# network 10.0.24.0 0.0.0.3 area 0

! Interfaces dans Area 2
R4(config-router)# network 172.16.4.0 0.0.0.255 area 2
R4(config-router)# network 10.2.45.0 0.0.0.3 area 2
R4(config-router)# passive-interface GigabitEthernet0/0
R4(config-router)# exit
```

### Etape 3 : Manipulation DR/BDR sur le segment 10.0.0.0/24

```cisco
! Sur le segment multi-access 10.0.0.0/24, forcer R2 comme DR
R2(config)# interface GigabitEthernet0/1
R2(config-if)# ip ospf priority 255
R2(config-if)# exit

! Forcer R3 comme BDR
R3(config)# interface GigabitEthernet0/1
R3(config-if)# ip ospf priority 100
R3(config-if)# exit

! Empecher un autre routeur de devenir DR/BDR
! (si un autre routeur est ajoute au segment)
! R-new(config-if)# ip ospf priority 0

! L'election est non-preemptive : il faut redemarrer OSPF
R2# clear ip ospf process
R3# clear ip ospf process
```

### Verification

```cisco
! Verifier le role DR/BDR
R2# show ip ospf interface GigabitEthernet0/1
  Designated Router (ID) 2.2.2.2, Interface address 10.0.0.1
  Backup Designated Router (ID) 3.3.3.3, Interface address 10.0.0.2

! Verifier les LSA
R2# show ip ospf database

! LSA Type 1 (Router) - generes par chaque routeur dans leur area
! LSA Type 2 (Network) - genere par le DR sur le segment multi-access
! LSA Type 3 (Summary) - generes par les ABR (R2 et R4)

! Verifier les routes inter-area
R1# show ip route ospf
O IA  172.16.4.0/24 [110/31] via 10.1.12.2, Gi0/1
O IA  172.16.5.0/24 [110/41] via 10.1.12.2, Gi0/1
! "O IA" = route OSPF inter-area, passee par un ABR

! Verifier le statut ABR
R2# show ip ospf border-routers
```

### Questions

**Q1 :**Sur le segment 10.0.0.0/24, si R2 a la priorite 255 et R3 la priorite 100, qui est DR et BDR ?
**R1 :**R2 est DR (priorite la plus haute : 255). R3 est BDR (priorite suivante : 100). Tout autre routeur avec la priorite par defaut (1) serait DROther.

**Q2 :**Pourquoi les routes apprises depuis Area 2 apparaissent avec le code "O IA" sur R1 ?
**R2 :**R1 est dans Area 1. Les routes d'Area 2 sont des routes inter-area qui traversent Area 0 via les ABR (R2 et R4). L'ABR genere des LSA Type 3 (Summary) pour annoncer ces routes aux autres areas. Le code "O IA" indique une route OSPF Inter-Area.

**Q3 :**Si on ajoute un routeur R7 sur le segment 10.0.0.0/24 avec une priorite de 255, deviendra-t-il DR ?
**R3 :**Non. L'election DR/BDR est non-preemptive. R7 restera DROther tant que le DR actuel (R2) est operationnel. R7 ne deviendra DR que si R2 et R3 tombent en panne, ou si le processus OSPF est redemarre sur tous les routeurs du segment.

---

## Lab 4 : Configuration et Verification EIGRP

### Topologie

```
              10.0.12.0/30               10.0.23.0/30
         .1 ──────────── .2         .1 ──────────── .2
    R1                    R2                          R3
    |Gi0/0           Gi0/0|                      Gi0/0|
    |.1                .1 |                        .1 |
    |                     |                           |
 [LAN-1]             [LAN-2]                     [LAN-3]
192.168.1.0/24    192.168.2.0/24             192.168.3.0/24
    |                                             |
    |          10.0.14.0/30        10.0.43.0/30   |
    |     .1 ──────────── .2  .1 ──────────── .2  |
    +──── R1              R4                  R3 ──+
                     Gi0/0|
                       .1 |
                          |
                      [LAN-4]
                   192.168.4.0/24

Liens :
  R1 Se0/0/0 (10.0.12.1) <---> R2 Se0/0/0 (10.0.12.2)  BW: 1544 Kbps
  R2 Gi0/1   (10.0.23.1) <---> R3 Gi0/1   (10.0.23.2)  BW: 1 Gbps
  R1 Gi0/1   (10.0.14.1) <---> R4 Gi0/1   (10.0.14.2)  BW: 1 Gbps
  R4 Gi0/2   (10.0.43.1) <---> R3 Gi0/2   (10.0.43.2)  BW: 1 Gbps
```

### Objectifs

- Configurer EIGRP classique et named mode
- Verifier les voisins, la topologie et les routes EIGRP
- Manipuler la bande passante et le delai

### Etape 1 : Configuration EIGRP classique

```cisco
! === R1 ===
R1(config)# router eigrp 100
R1(config-router)# eigrp router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255
R1(config-router)# network 10.0.12.0 0.0.0.3
R1(config-router)# network 10.0.14.0 0.0.0.3
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# no auto-summary
R1(config-router)# exit

! === R2 ===
R2(config)# router eigrp 100
R2(config-router)# eigrp router-id 2.2.2.2
R2(config-router)# network 192.168.2.0 0.0.0.255
R2(config-router)# network 10.0.12.0 0.0.0.3
R2(config-router)# network 10.0.23.0 0.0.0.3
R2(config-router)# passive-interface GigabitEthernet0/0
R2(config-router)# no auto-summary
R2(config-router)# exit

! === R3 ===
R3(config)# router eigrp 100
R3(config-router)# eigrp router-id 3.3.3.3
R3(config-router)# network 192.168.3.0 0.0.0.255
R3(config-router)# network 10.0.23.0 0.0.0.3
R3(config-router)# network 10.0.43.0 0.0.0.3
R3(config-router)# passive-interface GigabitEthernet0/0
R3(config-router)# no auto-summary
R3(config-router)# exit

! === R4 ===
R4(config)# router eigrp 100
R4(config-router)# eigrp router-id 4.4.4.4
R4(config-router)# network 192.168.4.0 0.0.0.255
R4(config-router)# network 10.0.14.0 0.0.0.3
R4(config-router)# network 10.0.43.0 0.0.0.3
R4(config-router)# passive-interface GigabitEthernet0/0
R4(config-router)# no auto-summary
R4(config-router)# exit
```

### Etape 2 : Configuration EIGRP Named Mode (alternative)

```cisco
! === R1 en Named Mode ===
R1(config)# router eigrp ENTERPRISE
R1(config-router)# address-family ipv4 unicast autonomous-system 100
R1(config-router-af)# eigrp router-id 1.1.1.1
R1(config-router-af)# network 192.168.1.0 0.0.0.255
R1(config-router-af)# network 10.0.12.0 0.0.0.3
R1(config-router-af)# network 10.0.14.0 0.0.0.3
R1(config-router-af)# af-interface GigabitEthernet0/0
R1(config-router-af-interface)# passive-interface
R1(config-router-af-interface)# exit-af-interface
R1(config-router-af)# topology base
R1(config-router-af-topology)# exit-af-topology
R1(config-router-af)# exit-address-family
R1(config-router)# exit
```

### Verification

```cisco
! Verifier les voisins EIGRP
R1# show ip eigrp neighbors
IP-EIGRP neighbors for process 100
H   Address         Interface     Hold Uptime   SRTT  RTO   Q   Seq
                                  (sec)         (ms)        Cnt  Num
0   10.0.12.2       Se0/0/0       12   00:05:23 40    240   0   5
1   10.0.14.2       Gi0/1         13   00:05:20 1     200   0   4

! Verifier la topologie EIGRP
R1# show ip eigrp topology
IP-EIGRP Topology Table for AS 100
Codes: P - Passive, A - Active

P 192.168.2.0/24, 1 successors, FD is 2170112
     via 10.0.12.2 (2170112/28160), Serial0/0/0
P 192.168.3.0/24, 1 successors, FD is 3072
     via 10.0.14.2 (3072/2816), GigabitEthernet0/1
P 192.168.4.0/24, 1 successors, FD is 2816
     via 10.0.14.2 (2816/2560), GigabitEthernet0/1

! Verifier les routes EIGRP
R1# show ip route eigrp
D     192.168.2.0/24 [90/2170112] via 10.0.12.2, Se0/0/0
D     192.168.3.0/24 [90/3072] via 10.0.14.2, Gi0/1
D     192.168.4.0/24 [90/2816] via 10.0.14.2, Gi0/1
D     10.0.23.0/30   [90/3072] via 10.0.14.2, Gi0/1
D     10.0.43.0/30   [90/2816] via 10.0.14.2, Gi0/1

! Verifier les interfaces EIGRP
R1# show ip eigrp interfaces
IP-EIGRP interfaces for process 100
Interface     Peers  Xmit Queue  Mean   Pacing Time  Multicast  Pending
                     Un/Reliable  SRTT   Un/Reliable  Flow Timer Routes
Se0/0/0       1      0/0         40     0/15         120        0
Gi0/1         1      0/0         1      0/0          50         0
```

### Questions

**Q1 :**Pourquoi le trafic de R1 vers LAN-3 passe par R4 et non par R2 ?
**R1 :**Le lien R1-R2 est un lien Serial a 1.544 Mbps alors que le chemin R1-R4-R3 utilise des liens GigabitEthernet a 1 Gbps. La metrique EIGRP (composite de bandwidth + delay par defaut) est bien meilleure via les liens Gigabit. Le chemin R1->R4->R3 a une metrique totale plus basse.

**Q2 :**Quelle est la difference entre le mode classique et le Named Mode EIGRP ?
**R2 :**Le Named Mode offre une configuration hierarchique (address-family, af-interface, topology) qui permet de gerer IPv4 et IPv6 sous le meme processus EIGRP. Il supporte aussi des fonctionnalites additionnelles comme les wide metrics. Le mode classique utilise la syntaxe `router eigrp <ASN>` traditionnelle.

---

## Lab 5 : Troubleshooting Routing

### Scenario 1 : Probleme de routes statiques

```
Topologie :
    [PC-A]                              [PC-B]
  192.168.1.10/24                    192.168.2.10/24
       |                                    |
    Gi0/0 (.1)                          Gi0/0 (.1)
      R1 ──── Se0/0/0 (.1) ── (.2) Se0/0/0 ── R2
          10.0.0.0/30

Symptome : PC-A ne peut pas joindre PC-B
```

**Diagnostic :**

```cisco
! Etape 1 : Verifier la connectivite locale
PC-A> ping 192.168.1.1
! Resultat : OK (gateway accessible)

! Etape 2 : Verifier la connectivite du lien serie
R1# ping 10.0.0.2
! Resultat : OK (lien serie fonctionnel)

! Etape 3 : Verifier la table de routage R1
R1# show ip route
! Resultat : Pas de route vers 192.168.2.0/24 !

! Etape 4 : Verifier la table de routage R2
R2# show ip route
! Resultat : Pas de route vers 192.168.1.0/24 !
```

**Cause :**Routes statiques manquantes sur R1 et R2.

**Solution :**

```cisco
R1(config)# ip route 192.168.2.0 255.255.255.0 10.0.0.2
R2(config)# ip route 192.168.1.0 255.255.255.0 10.0.0.1
```

---

### Scenario 2 : Adjacence OSPF qui ne s'etablit pas

```
Topologie :
     R1 ─────── Gi0/0 ─────── R2
     10.0.0.1/24              10.0.0.2/24

Configuration R1 :                Configuration R2 :
  router ospf 1                    router ospf 1
  network 10.0.0.0                 network 10.0.0.0
    0.0.0.255 area 0                0.0.0.255 area 1
  ip ospf hello-interval 10        ip ospf hello-interval 5

Symptome : show ip ospf neighbor est vide sur les deux routeurs
```

**Diagnostic :**

```cisco
R1# show ip ospf interface Gi0/0
  Hello 10, Dead 40
  Area 0

R2# show ip ospf interface Gi0/0
  Hello 5, Dead 20
  Area 1
```

**Causes identifiees (2 problemes) :**

1. Les **areas** ne correspondent pas : R1 est dans Area 0, R2 dans Area 1
2. Les **Hello/Dead timers** ne correspondent pas : R1 Hello=10/Dead=40, R2 Hello=5/Dead=20

**Solution :**

```cisco
! Corriger l'area sur R2
R2(config)# router ospf 1
R2(config-router)# no network 10.0.0.0 0.0.0.255 area 1
R2(config-router)# network 10.0.0.0 0.0.0.255 area 0
R2(config-router)# exit

! Corriger le timer Hello sur R2
R2(config)# interface GigabitEthernet0/0
R2(config-if)# ip ospf hello-interval 10
R2(config-if)# exit

! Verification
R1# show ip ospf neighbor
! Doit maintenant montrer R2 en etat FULL
```

---

### Scenario 3 : Chemin sous-optimal OSPF

```
Topologie :

    R1 ──── Gi0/1 (Cost 10) ──── R2 ──── Gi0/1 (Cost 10) ──── R3
    |                                                            |
    Se0/0/0 (Cost 6477) ──────────────────────────────── Se0/0/0
    |                                                            |
    [LAN-1]                                                 [LAN-3]
 192.168.1.0/24                                        192.168.3.0/24

Symptome : Le trafic R1 vers LAN-3 passe par le lien Serial
           au lieu du chemin R1 -> R2 -> R3 (plus rapide)
```

**Diagnostic :**

```cisco
R1# show ip ospf interface brief
Interface    PID   Area   IP Address/Mask    Cost  State
Gi0/1        1     0      10.0.12.1/30       10    P2P
Se0/0/0      1     0      10.0.13.1/30       64    P2P

! Cost Serial = 64, Cost via R2 = 10 + 10 = 20
! Le lien Serial ne devrait PAS etre prefere...

R1# show ip route 192.168.3.0
  Known via "ospf 1", distance 110, metric 74
    10.0.13.2, via Serial0/0/0

! Le cout affiche est 74 (64 + 10 pour LAN-3)
! Mais le chemin via R2 serait 10 + 10 + 10 = 30
```

**Cause :**La reference-bandwidth n'est pas configuree de maniere uniforme. R2 utilise probablement la reference par defaut (100 Mbps) ce qui donne un cout de 1 au lieu de 10 sur ses interfaces GigE.

**Solution :**

```cisco
! Configurer la meme reference-bandwidth sur TOUS les routeurs
R1(config)# router ospf 1
R1(config-router)# auto-cost reference-bandwidth 10000

R2(config)# router ospf 1
R2(config-router)# auto-cost reference-bandwidth 10000

R3(config)# router ospf 1
R3(config-router)# auto-cost reference-bandwidth 10000

! Verification apres convergence
R1# show ip route 192.168.3.0
  Known via "ospf 1", distance 110, metric 30
    10.0.12.2, via GigabitEthernet0/1
```

---

### Scenario 4 : Routes EIGRP manquantes

```
Topologie :

    R1 (AS 100) ──── R2 (AS 200) ──── R3 (AS 200)

Symptome : R1 ne voit aucun voisin EIGRP
```

**Diagnostic :**

```cisco
R1# show ip eigrp neighbors
! Resultat : vide

R1# show run | section eigrp
router eigrp 100

R2# show run | section eigrp
router eigrp 200
```

**Cause :**Les numeros d'AS (Autonomous System) sont differents. EIGRP necessite le meme numero AS pour former une adjacence.

**Solution :**

```cisco
! Option 1 : Changer l'AS de R1
R1(config)# no router eigrp 100
R1(config)# router eigrp 200
R1(config-router)# network 10.0.0.0 0.0.0.3
R1(config-router)# network 192.168.1.0 0.0.0.255
R1(config-router)# exit

! Option 2 : Changer l'AS de R2 et R3
! (moins recommande si R2-R3 sont deja en production)
```

---

## Questions de Revision avec Reponses Detaillees

### Routage Statique

**Q1 : Quelle est la difference entre une route statique et une route dynamique ?**

Une route statique est configuree manuellement par l'administrateur (`ip route ...`). Elle ne change pas automatiquement si la topologie evolue. Une route dynamique est apprise via un protocole de routage (OSPF, EIGRP, BGP) qui adapte automatiquement les routes en fonction de l'etat du reseau. La route statique a une administrative distance de 1 (priorite haute), tandis qu'OSPF a 110 et EIGRP a 90.

**Q2 : Qu'est-ce qu'une floating static route et a quoi sert-elle ?**

C'est une route statique avec une administrative distance manuellement augmentee (ex: 250). Elle sert de route de secours : tant que la route principale (apprise via OSPF par exemple, AD=110) est presente, la floating static route reste invisible dans la table de routage. Si la route OSPF disparait, la floating static route prend le relais.

```cisco
! Route principale via OSPF (AD=110) - apprise automatiquement
! Route de secours via un lien backup
ip route 192.168.2.0 255.255.255.0 10.0.99.2 250
! AD=250 : n'apparait que si la route OSPF (AD=110) disparait
```

### OSPF

**Q3 : Quels parametres doivent correspondre pour qu'une adjacence OSPF s'etablisse ?**

Les parametres suivants doivent etre identiques sur les deux routeurs du lien :
- Area ID
- Hello interval et Dead interval
- Type d'authentification et mot de passe
- Type de reseau OSPF (broadcast, point-to-point, etc.)
- Masque de sous-reseau (les deux interfaces doivent etre dans le meme sous-reseau)
- Le flag Stub area doit correspondre
- La MTU doit etre identique (sauf si `ip ospf mtu-ignore` est configure)

**Q4 : Expliquez le role du DR et du BDR sur un segment multi-access.**

Sur un segment Ethernet (multi-access), sans DR/BDR, chaque routeur devrait former une adjacence FULL avec tous les autres (n*(n-1)/2 adjacences). Le DR centralise les echanges : tous les routeurs envoient leurs LSA au DR (via 224.0.0.6), et le DR les redistribue a tous (via 224.0.0.5). Le BDR est le remplacant du DR en cas de panne, evitant une nouvelle election complete.

### EIGRP

**Q5 : Quels sont les composants de la metrique EIGRP ?**

La metrique composite EIGRP utilise par defaut la bande passante (bandwidth) et le delai (delay). La formule simplifiee est : `metric = 256 * ((10^7 / BW_min) + somme_des_delais)`. Les K-values par defaut sont K1=1, K2=0, K3=1, K4=0, K5=0. Les parametres de charge (load) et fiabilite (reliability) sont disponibles mais desactives par defaut (K2=0, K4=0, K5=0) car ils sont instables.

**Q6 : Qu'est-ce qu'un Successor et un Feasible Successor en EIGRP ?**

Le **Successor** est le prochain saut vers une destination avec la meilleure metrique (Feasible Distance la plus basse). Le **Feasible Successor** est un chemin de secours pre-calcule dont la Reported Distance (metrique annoncee par le voisin) est inferieure a la Feasible Distance du Successor actuel. Cette condition de faisabilite (feasibility condition) garantit un chemin sans boucle. En cas de panne du Successor, le Feasible Successor prend le relais instantanement, sans recalcul.

---

*Exercices crees pour la revision CCNA*
*Auteur : Roadmvn*
