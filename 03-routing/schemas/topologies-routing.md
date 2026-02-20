# Topologies et Schemas de Routage

## Vue d'Ensemble

Cette section regroupe les schemas ASCII detailles pour visualiser les concepts de routage couverts dans le module 3.

---

## 1. Topologie OSPF Multi-Area Complete

```
                              Reseau Externe
                           (Routes statiques, BGP)
                                    |
                                    |
                            +-------+-------+
                            |     ASBR      |
                            |   R-EXTERN    |
                            | RID: 6.6.6.6  |
                            +-------+-------+
                                    |
                              Gi0/0 | 10.0.0.0/30
                                    |
============================================================================
                            AREA 0 - BACKBONE
============================================================================
                                    |
                    +---------------+---------------+
                    |                               |
             +------+------+                 +------+------+
             |    R-CORE1   |                 |    R-CORE2   |
             | RID: 3.3.3.3 |=================| RID: 4.4.4.4 |
             |  Backbone    |  10.0.1.0/30    |  Backbone    |
             +------+------+                 +------+------+
                    |                               |
         Gi0/0     |                               | Gi0/0
       10.0.2.0/30 |                               | 10.0.3.0/30
                    |                               |
============+======+=====+===============+==========+=====+===========
            |            |               |                |
    --------+--------    |       --------+--------        |
    AREA 1 (Regular)     |       AREA 2 (Regular)        |
    --------+--------    |       --------+--------        |
            |            |               |                |
     +------+------+     |        +------+------+         |
     |    ABR-1    |     |        |    ABR-2    |         |
     | RID: 1.1.1.1|-----+        | RID: 2.2.2.2|---------+
     | Area 0 + 1  |              | Area 0 + 2  |
     +------+------+              +------+------+
            |                            |
   Gi0/1   |  172.16.1.0/24    Gi0/1   | 172.16.2.0/24
            |                            |
     +------+------+              +------+------+
     |   R-INT1    |              |   R-INT2    |
     | RID: 5.5.5.5|              | RID: 7.7.7.7|
     |  Area 1     |              |  Area 2     |
     +------+------+              +------+------+
            |                            |
        LAN Area 1                   LAN Area 2
      192.168.1.0/24              192.168.2.0/24


Legende :
  ABR  = Area Border Router (interfaces dans 2+ areas)
  ASBR = Autonomous System Boundary Router (redistribution)
  RID  = Router-ID
  ===  = Liaison backbone haute bande passante
  ---  = Liaison standard

Types de LSA dans cette topologie :
  Area 1 : LSA 1 (Router), LSA 2 (Network si DR), LSA 3 (de ABR-1)
  Area 0 : LSA 1, LSA 2, LSA 3, LSA 4 (chemin vers ASBR), LSA 5 (externes)
  Area 2 : LSA 1, LSA 2, LSA 3 (de ABR-2)
```

---

## 2. Decision de Routage - Longest Prefix Match

```
Table de routage de R1 :
+------+-------------------+-------------------+
| Code | Reseau/Masque     | Next-Hop          |
+------+-------------------+-------------------+
| S    | 10.0.0.0/8        | via 192.168.1.1   |
| O    | 10.1.0.0/16       | via 192.168.1.2   |
| D    | 10.1.1.0/24       | via 192.168.1.3   |
| S    | 10.1.1.128/25     | via 192.168.1.4   |
| C    | 192.168.1.0/24    | Gi0/0             |
+------+-------------------+-------------------+

Paquet destination : 10.1.1.200

Processus de Longest Prefix Match :

  10.1.1.200 correspond a :
  +-------------------------------------------+
  | 10.0.0.0/8       ? OUI  (8 bits match)   |
  | 10.1.0.0/16      ? OUI  (16 bits match)  |
  | 10.1.1.0/24      ? OUI  (24 bits match)  |
  | 10.1.1.128/25    ? OUI  (25 bits match)  | <-- GAGNANT
  +-------------------------------------------+

  Verification 10.1.1.128/25 :
  10.1.1.200 en binaire : 00001010.00000001.00000001.11001000
  10.1.1.128/25         : 00001010.00000001.00000001.1.......
                          |<-------- 25 bits match -------->|
  200 >= 128 et 200 <= 255 --> dans le sous-reseau .128/25

  Resultat : Paquet envoye via 192.168.1.4 (route /25, la plus specifique)


Autre exemple : Paquet vers 10.1.2.50

  10.1.2.50 correspond a :
  +-------------------------------------------+
  | 10.0.0.0/8       ? OUI  (8 bits match)   |
  | 10.1.0.0/16      ? OUI  (16 bits match)  | <-- GAGNANT
  | 10.1.1.0/24      ? NON  (3e octet = 2)   |
  | 10.1.1.128/25    ? NON                    |
  +-------------------------------------------+

  Resultat : Paquet envoye via 192.168.1.2 (route /16)


Regle fondamentale :
+------------------------------------------------------+
| Le routeur choisit TOUJOURS la route avec le         |
| prefixe le plus long (le plus de bits qui matchent)  |
|                                                      |
| /32 > /25 > /24 > /16 > /8 > /0 (default)           |
|                                                      |
| C'est le LONGEST PREFIX MATCH, pas l'AD,             |
| qui determine le choix entre routes de prefixes      |
| differents.                                          |
+------------------------------------------------------+
```

---

## 3. EIGRP Topology Table vs Routing Table

```
Reseau physique :

         10.0.1.0/24          10.0.2.0/24
  R1 ------------------- R2 ------------------- R3
  |     BW=1G, DL=10     |     BW=1G, DL=10     |
  |                       |                       |
  |     10.0.3.0/24       |                       |
  +------ R4 -------------+                       |
     BW=100M, DL=100                              |
                                                  |
                                        192.168.1.0/24
                                          (LAN R3)

=== Vue depuis R1 ===

Topology Table (show ip eigrp topology) :
+------------------------------------------------------------------+
| P 192.168.1.0/24, 1 successors, FD is 3072                      |
|                                                                  |
|   Via R2 (10.0.1.2):                                             |
|     FD = 3072                                                    |
|     RD = 2816                                                    |
|     Status: Successor (S)        <-- Meilleur chemin             |
|                                                                  |
|   Via R4 (10.0.3.2) puis R2:                                     |
|     FD = 33536                                                   |
|     RD = 2816                                                    |
|     Feasibility: RD(2816) < FD_Succ(3072) ? NON                 |
|     Status: Non-Feasible Successor                               |
|                                                                  |
| Note: RD = 2816 n'est PAS < FD = 3072                           |
| (2816 < 3072 est faux car les valeurs sont identiques            |
|  pour le lien direct R2->R3)                                     |
+------------------------------------------------------------------+

Routing Table (show ip route eigrp) :
+------------------------------------------------------------------+
| D  192.168.1.0/24 [90/3072] via 10.0.1.2, Gi0/0                |
|                                                                  |
| Seul le Successor apparait dans la table de routage              |
| Le Feasible Successor (s'il existait) resterait dans             |
| la topology table uniquement                                     |
+------------------------------------------------------------------+

Scenario de panne :
+------------------------------------------------------------------+
| Lien R1-R2 tombe :                                               |
|                                                                  |
| CAS 1 : FS existe                                                |
|   Basculement INSTANTANE vers le FS                              |
|   Pas besoin de Query/Reply                                      |
|   Temps de convergence : millisecondes                           |
|                                                                  |
| CAS 2 : Pas de FS (notre cas)                                   |
|   R1 passe en etat ACTIVE pour 192.168.1.0/24                   |
|   R1 envoie des Queries aux voisins restants (R4)               |
|   R4 repond avec un chemin alternatif                            |
|   R1 recalcule et installe la nouvelle route                    |
|   Temps de convergence : secondes                                |
+------------------------------------------------------------------+
```

---

## 4. BGP Peering entre Autonomous Systems

```
Internet - Peering BGP Multi-AS :

+------------------------------------------------------------------+
|                                                                  |
|  AS 100 (ISP-A)           AS 200 (ISP-B)         AS 300 (ISP-C) |
|  Prefixes:                Prefixes:                Prefixes:     |
|  10.0.0.0/8               172.16.0.0/12           192.168.0.0/16 |
|                                                                  |
|  +---------+    eBGP     +---------+    eBGP     +---------+    |
|  |  R1     |------------|  R3     |------------|  R5     |    |
|  | BGP     |             | BGP     |             | BGP     |    |
|  | Speaker |             | Speaker |             | Speaker |    |
|  +----+----+             +----+----+             +----+----+    |
|       |                       |                       |          |
|     iBGP                    iBGP                    iBGP         |
|       |                       |                       |          |
|  +----+----+             +----+----+             +----+----+    |
|  |  R2     |             |  R4     |             |  R6     |    |
|  | Internal|             | Internal|             | Internal|    |
|  +---------+             +---------+             +---------+    |
|                                                                  |
+------------------------------------------------------------------+

Table BGP vue depuis R5 (AS 300) :

show ip bgp :
+------+------------------+----------+--------+-------+-----------+
|Status| Network          | Next Hop | Metric |LocPrf | Path      |
+------+------------------+----------+--------+-------+-----------+
| *>   | 10.0.0.0/8       | 10.0.2.1 |   0    |       | 200 100   |
| *    | 10.0.0.0/8       | 10.0.3.1 |   0    |       | 200 100   |
| *>   | 172.16.0.0/12    | 10.0.2.1 |   0    |       | 200       |
| *>   | 192.168.0.0/16   | 0.0.0.0  |   0    | 32768 | i         |
+------+------------------+----------+--------+-------+-----------+

Lecture :
  *  = Route valide
  >  = Meilleure route (installee)
  i  = Origine IGP (annoncee localement)

Pour 10.0.0.0/8, R5 voit 2 chemins :
  Path "200 100" = via AS 200 puis AS 100 (2 AS hops)
  Le meilleur est selectionne par les BGP Path Attributes

AS-Path comme mecanisme anti-boucle :
+------------------------------------------------------+
| Si un routeur BGP recoit une route contenant         |
| son propre ASN dans l'AS-Path, il la REJETTE         |
| automatiquement (prevention de boucle)               |
+------------------------------------------------------+
```

---

## 5. Table Administrative Distances

```
Echelle visuelle des Administrative Distances :

AD 0   |======| Connected
AD 1   |=|      Static
AD 20  |====|   eBGP
       |
AD 90  |==================| EIGRP (interne)
AD 110 |======================| OSPF
AD 115 |=======================| IS-IS
AD 120 |========================| RIP
       |
AD 170 |==================================| EIGRP (externe)
AD 200 |========================================| iBGP
       |
AD 255 |===============================================| Unknown (non installe)
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
       0  20 40 60 80 100 120 140 160 180 200 220 240 255


Scenario de selection avec plusieurs protocoles :

R1 connait 10.1.1.0/24 via :

  Static  : AD 1   -----> INSTALLE (plus basse AD)
  eBGP    : AD 20  -----> Non installe
  EIGRP   : AD 90  -----> Non installe
  OSPF    : AD 110 -----> Non installe

  show ip route 10.1.1.0 :
  S    10.1.1.0/24 [1/0] via 192.168.1.1

Si la route statique disparait :
  EIGRP   : AD 90  -----> INSTALLE (prochaine AD la plus basse)
  OSPF    : AD 110 -----> Non installe
  eBGP    : AD 20  -----> INSTALLE (en fait eBGP gagne !)

  Correction : eBGP (AD 20) est installee car 20 < 90

  show ip route 10.1.1.0 :
  B    10.1.1.0/24 [20/0] via 10.0.0.2

Note importante :
+------------------------------------------------------+
| L'AD n'intervient QUE pour comparer des routes       |
| vers le MEME prefixe (/24 vs /24)                   |
|                                                      |
| Le Longest Prefix Match intervient TOUJOURS EN       |
| PREMIER pour des prefixes DIFFERENTS (/24 vs /16)   |
+------------------------------------------------------+
```

---

## 6. Schema de Redistribution

```
Domaine EIGRP AS 100              Domaine OSPF Area 0
+---------------------+          +---------------------+
|                     |          |                     |
|  R1 -------- R2     |    R3    |     R4 -------- R5  |
| 10.1.0.0/24  |      |  (ASBR) |      | 172.16.0.0/16|
|              |      |    |     |      |              |
|         10.2.0.0/24 |    |     | 172.17.0.0/16      |
|                     |    |     |                     |
+----------+----------+    |     +----------+----------+
           |               |                |
           +-------+-------+-------+--------+
                   |               |
               Gi0/0           Gi0/1
             EIGRP side       OSPF side
             10.0.0.0/30     10.0.1.0/30

Configuration R3 (ASBR) :

! EIGRP
router eigrp 100
 network 10.0.0.0 0.0.0.3
 redistribute ospf 1 metric 10000 100 255 1 1500
!                     BW(kbps) DL(10us) Reliab Load MTU

! OSPF
router ospf 1
 network 10.0.1.0 0.0.0.3 area 0
 redistribute eigrp 100 subnets metric-type 1


Tables de routage resultantes :

Sur R1 (EIGRP) :
D     10.1.0.0/24 [90/28160] via Connected
D     10.2.0.0/24 [90/30720] via 10.0.0.1
D EX  172.16.0.0/16 [170/33280] via 10.0.0.2     <-- Redistribue
D EX  172.17.0.0/16 [170/35840] via 10.0.0.2     <-- Redistribue
      ^                ^
      |                AD 170 = routes EIGRP externes
      D EX = EIGRP External

Sur R5 (OSPF) :
O     172.16.0.0/16 [110/10] via Connected
O     172.17.0.0/16 [110/20] via 10.0.1.1
O E1  10.1.0.0/24 [110/30] via 10.0.1.2          <-- Redistribue
O E1  10.2.0.0/24 [110/40] via 10.0.1.2          <-- Redistribue
      ^                ^
      |                Metrique = cout interne + externe (Type 1)
      O E1 = OSPF External Type 1
```

---

## 7. Routage Statique avec Multiple Paths

```
Topologie : Entreprise avec 2 liaisons WAN

                        Internet
                       /        \
                      /          \
              +------+--+     +--+------+
              | ISP-A   |     | ISP-B   |
              +------+--+     +--+------+
                     |           |
            Gi0/0    |           |   Gi0/1
         203.0.113.0/30       198.51.100.0/30
                     |           |
              +------+-----------+------+
              |           R1            |
              |    (Gateway enterprise) |
              +------+--------+--------+
                     |        |
                  Gi0/2    Gi0/3
           192.168.1.0/24  192.168.2.0/24
                     |        |
                  LAN-A     LAN-B


Configuration R1 :

! Route principale vers Internet (via ISP-A, moins cher)
ip route 0.0.0.0 0.0.0.0 203.0.113.1

! Floating static route backup (via ISP-B, AD=210)
ip route 0.0.0.0 0.0.0.0 198.51.100.1 210

! Routes specifiques pour services critiques (via ISP-B pour redondance)
ip route 8.8.8.0 255.255.255.0 198.51.100.1
ip route 8.8.4.0 255.255.255.0 198.51.100.1


Table de routage resultante (etat normal) :

R1# show ip route
S*   0.0.0.0/0 [1/0] via 203.0.113.1         <-- Principale
S    8.8.4.0/24 [1/0] via 198.51.100.1        <-- Specifique ISP-B
S    8.8.8.0/24 [1/0] via 198.51.100.1        <-- Specifique ISP-B
C    192.168.1.0/24 is directly connected, Gi0/2
C    192.168.2.0/24 is directly connected, Gi0/3
C    203.0.113.0/30 is directly connected, Gi0/0
C    198.51.100.0/30 is directly connected, Gi0/1

! La floating static (AD 210) n'apparait PAS quand la principale est active


Table de routage (apres panne ISP-A) :

R1# show ip route
S*   0.0.0.0/0 [210/0] via 198.51.100.1      <-- Floating prend le relais
S    8.8.4.0/24 [1/0] via 198.51.100.1
S    8.8.8.0/24 [1/0] via 198.51.100.1
C    192.168.1.0/24 is directly connected, Gi0/2
C    192.168.2.0/24 is directly connected, Gi0/3
C    198.51.100.0/30 is directly connected, Gi0/1

! L'interface Gi0/0 vers ISP-A n'est plus UP
! La floating static route (AD 210) est maintenant active
```

---

## 8. OSPF Neighbor States Diagram

```
Diagramme de transition des etats OSPF :

+--------+                          +--------+
|  DOWN  |--- Hello envoye ------->|  DOWN  |
| (R1)   |                         | (R2)   |
+---+----+                         +---+----+
    |                                   |
    | Recoit Hello de R2                | Recoit Hello de R1
    | (R1 pas dans la liste)            | (R2 pas dans la liste)
    v                                   v
+--------+                          +--------+
|  INIT  |<--- Hello (seen: R1) ---|  INIT  |
| (R1)   |                         | (R2)   |
+---+----+                         +---+----+
    |                                   |
    | R1 voit son RID dans             |
    | le Hello de R2                    |
    v                                   v
+--------+                          +--------+
| 2-WAY  |<========================>| 2-WAY  |
| (R1)   |  Communication           | (R2)   |
+---+----+  bidirectionnelle         +---+----+
    |                                   |
    |  [Sur multi-access : Election DR/BDR ici]
    |  [Si pas DR/BDR : reste en 2-WAY]
    |  [Si DR ou BDR : continue vers ExStart]
    v                                   v
+---------+                         +---------+
| EXSTART |--- DBD (seq init) ---->| EXSTART |
| (R1)    |<-- DBD (seq init) -----| (R2)    |
+---------+  Negociation Master/   +---------+
    |        Slave (RID le + haut       |
    v        = Master)                  v
+----------+                        +----------+
| EXCHANGE |--- DBD (LSA headers)->| EXCHANGE |
| (R1)     |<-- DBD (LSA headers)--| (R2)     |
+----------+  Echange des resumes  +----------+
    |         de LSDB                   |
    v                                   v
+----------+                        +----------+
| LOADING  |--- LSR (requetes) --->| LOADING  |
| (R1)     |<-- LSU (reponses) ----| (R2)     |
+----------+  Telechargement des   +----------+
    |         LSA manquants             |
    v                                   v
+--------+                          +--------+
|  FULL  |<========================>|  FULL  |
| (R1)   |  Adjacence complete      | (R2)   |
+--------+  LSDB synchronisees      +--------+


Resume visuel des paquets OSPF :

Paquet    | Multicast/Unicast | Usage
----------+-------------------+----------------------------------
Hello     | 224.0.0.5         | Decouverte et maintien voisins
DBD       | Unicast           | Resume de la LSDB
LSR       | Unicast           | Requete de LSA specifiques
LSU       | Unicast/Multicast | Envoi de LSA complets
LSAck     | Unicast/Multicast | Accusé de reception des LSA
```

---

## 9. OSPF Cost Calculation Visual

```
Topologie avec couts OSPF (reference BW = 10000 Mbps) :

                    Cost 1
R1 =============[10G]============= R2
|                                   |
| Cost 10                           | Cost 10
| [1G]                              | [1G]
|                                   |
R3 -------[100M]--------- R4 ------[1G]----- R5
     Cost 100              |    Cost 10       |
                           |                  |
                     Cost 6477               LAN
                     [T1 Serial]          Destination
                           |            192.168.1.0/24
                           R6

Chemins de R1 vers R5 (192.168.1.0/24) :

Chemin A : R1 -> R2 -> R5
  Cout = 1 (R1-R2) + 10 (R2-R5) = 11

Chemin B : R1 -> R3 -> R4 -> R5
  Cout = 10 (R1-R3) + 100 (R3-R4) + 10 (R4-R5) = 120

Chemin C : R1 -> R2 -> R4 -> R5
  Cout = 1 (R1-R2) + 10 (R2-R4) + 10 (R4-R5) = 21

Chemin D : R1 -> R3 -> R4 -> R6 (impossible, pas de lien R6-R5)

OSPF selectionne le Chemin A (cout 11) :

R1# show ip route 192.168.1.0
O    192.168.1.0/24 [110/11] via 10.0.0.2, GigabitEthernet0/0

Reference bandwidth recommandee :
+------------------------------------------------------+
| Si vous avez des liens 10G dans votre reseau :       |
|   auto-cost reference-bandwidth 100000               |
|   (100 Gbps pour anticiper les futures interfaces)   |
|                                                      |
| A configurer sur TOUS les routeurs OSPF !            |
+------------------------------------------------------+
```

---

*Schemas crees pour la revision CCNA*
*Auteur : Roadmvn*
