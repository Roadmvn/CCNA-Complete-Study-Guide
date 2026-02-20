# OSPF - Open Shortest Path First

## Vue d'Ensemble

OSPF est un protocole de routage a etat de liens (link-state) utilisant l'algorithme SPF de Dijkstra pour calculer le plus court chemin vers chaque destination. C'est le protocole IGP le plus utilise en entreprise, standardise par l'IETF (RFC 2328).

## Concepts Fondamentaux

### Link-State vs Distance Vector

```
+---------------------------+-------------------------------+
| Distance Vector           | Link-State (OSPF)             |
| (ex: RIP, EIGRP)         |                               |
+---------------------------+-------------------------------+
| Chaque routeur envoie     | Chaque routeur envoie         |
| sa table de routage       | l'etat de ses liens           |
| aux voisins               | a TOUS les routeurs           |
+---------------------------+-------------------------------+
| Vision partielle          | Vision complete               |
| (voisin par voisin)       | (toute la topologie)          |
+---------------------------+-------------------------------+
| Convergence lente         | Convergence rapide            |
| (comptage a l'infini)     | (recalcul SPF immediat)       |
+---------------------------+-------------------------------+
| Facile a configurer       | Plus complexe mais            |
|                           | plus scalable                 |
+---------------------------+-------------------------------+

Fonctionnement OSPF en 3 etapes :

1. Decouverte des voisins (Hello packets)
   R1 ---[Hello]--> R2
   R1 <--[Hello]--- R2
   "Je suis la, voici mon Router-ID"

2. Echange des LSA (Link-State Advertisements)
   R1 ---[LSA]--> R2 ---[LSA]--> R3
   "Voici l'etat de tous mes liens"

3. Calcul SPF (Shortest Path First / Dijkstra)
   Chaque routeur construit un arbre SPF
   et calcule le meilleur chemin vers chaque destination
```

### Router-ID OSPF

Le Router-ID est un identifiant unique de 32 bits (format IP) pour chaque routeur OSPF.

```
Selection du Router-ID (par ordre de priorite) :

1. Commande explicite : router-id X.X.X.X
2. Plus haute IP sur une interface Loopback UP
3. Plus haute IP sur une interface physique UP

Exemple :
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1

Verification :
R1# show ip ospf | include Router ID
 Router with ID (1.1.1.1) (Process ID 1)

Note : Changer le Router-ID necessite :
  clear ip ospf process   (redemarrage du processus OSPF)
```

## OSPF Areas (Zones)

### Concept des Areas

OSPF divise le reseau en zones (areas) pour limiter la taille de la LSDB (Link-State Database) et reduire le trafic de mise a jour.

```
Architecture OSPF Multi-Area :

+------------------------------------------------------------------+
|                                                                  |
|   Area 1                Area 0 (Backbone)           Area 2       |
|   (Regular)             (OBLIGATOIRE)               (Regular)    |
|                                                                  |
|  +--------+         +--------+    +--------+      +--------+    |
|  | R1     |         | ABR-1  |====| ABR-2  |      | R4     |    |
|  |Internal|---------|        |    |        |------| Internal|    |
|  +--------+         +--------+    +--------+      +--------+    |
|       |                  |             |                |        |
|  +--------+         +--------+    +--------+      +--------+    |
|  | R2     |         | R3     |    | R5     |      | R6     |    |
|  |Internal|         |Backbone|    |Backbone|      | Internal|    |
|  +--------+         +--------+    +--------+      +--------+    |
|                          |                                       |
|                     +--------+                                   |
|                     | ASBR   |---- Reseau externe (ex: Internet) |
|                     |(Redistrib)                                 |
|                     +--------+                                   |
|                                                                  |
+------------------------------------------------------------------+

Regles des Areas :
- Area 0 (Backbone) est OBLIGATOIRE
- Toutes les areas doivent etre connectees a Area 0
- Le trafic inter-area transite TOUJOURS par Area 0
```

### Types de Routeurs OSPF

```
+--------------------+---------------------------------------------------+
| Type               | Description                                       |
+--------------------+---------------------------------------------------+
| Internal Router    | Toutes les interfaces dans la meme area           |
|                    | Une seule LSDB                                    |
+--------------------+---------------------------------------------------+
| Backbone Router    | Au moins une interface dans Area 0                |
|                    |                                                   |
+--------------------+---------------------------------------------------+
| ABR (Area Border   | Interfaces dans au moins 2 areas differentes      |
|  Router)           | Maintient une LSDB par area                       |
|                    | Resume les routes entre areas                     |
+--------------------+---------------------------------------------------+
| ASBR (Autonomous   | Redistribue des routes externes dans OSPF         |
|  System Boundary   | (ex: routes statiques, BGP, EIGRP)                |
|  Router)           |                                                   |
+--------------------+---------------------------------------------------+

Schema des roles :

         Reseau Externe
              |
         +----+----+
         |  ASBR   |  <-- Redistribue les routes externes
         +---------+
              |
    +---------+---------+
    |     Area 0        |
    |  Backbone Routers |
    +---------+---------+
         |         |
    +----+----+  +-+--------+
    |  ABR-1  |  |  ABR-2   |  <-- Frontieres entre areas
    +---------+  +----------+
         |            |
    +----+----+  +----+-----+
    | Area 1  |  |  Area 2  |
    | Internal|  | Internal |  <-- Routeurs internes
    +---------+  +----------+
```

## Etats de Voisinage OSPF

L'etablissement d'une adjacence OSPF passe par 7 etats :

```
Diagramme des Etats OSPF :

R1                                              R2
 |                                               |
 |  1. DOWN                                      |
 |  (Aucun Hello recu)                           |
 |                                               |
 |  --------[Hello, seen: none]-------->         |
 |                                               |
 |  2. INIT                            2. INIT   |
 |  (Hello recu mais pas encore vu)              |
 |                                               |
 |  <-------[Hello, seen: R1]----------          |
 |                                               |
 |  3. 2-WAY                           3. 2-WAY  |
 |  (Communication bidirectionnelle)             |
 |  [Election DR/BDR sur multi-access]           |
 |                                               |
 |  --------[DBD (Database Description)]-------> |
 |                                               |
 |  4. EXSTART                                   |
 |  (Negociation Master/Slave)                   |
 |  (Router-ID le plus eleve = Master)           |
 |                                               |
 |  <-------[DBD avec sequence numbers]--------- |
 |                                               |
 |  5. EXCHANGE                                  |
 |  (Echange des DBD - resume de la LSDB)       |
 |                                               |
 |  --------[LSR (Link-State Request)]---------> |
 |                                               |
 |  6. LOADING                                   |
 |  (Demande des LSA manquants)                  |
 |                                               |
 |  <-------[LSU (Link-State Update)]----------- |
 |                                               |
 |  7. FULL                             7. FULL  |
 |  (Adjacence complete, LSDB synchronisees)     |
 |                                               |

Resume des etats :
+----------+------------------------------------------------+
| Etat     | Description                                    |
+----------+------------------------------------------------+
| Down     | Aucun Hello recu du voisin                     |
| Init     | Hello recu mais notre Router-ID absent         |
| 2-Way    | Bidirectionnel confirme, election DR/BDR       |
| ExStart  | Negociation du Master (plus haut Router-ID)    |
| Exchange | Echange des DBD (resumes de LSDB)              |
| Loading  | Requete et reception des LSA manquants         |
| Full     | Bases de donnees synchronisees                 |
+----------+------------------------------------------------+

Note : Sur un segment multi-access (Ethernet) :
- Adjacence FULL uniquement avec le DR et le BDR
- Les autres routeurs restent en etat 2-WAY entre eux
```

## Election DR/BDR

Sur les reseaux multi-access (Ethernet), OSPF elit un Designated Router (DR) et un Backup Designated Router (BDR) pour reduire le nombre d'adjacences.

```
Segment Multi-Access SANS DR :
(Chaque routeur adjacent avec tous les autres = n(n-1)/2 adjacences)

  R1------R2
  |\ ╲   /|
  | \ ╲ / |
  |  \ X  |    5 routeurs = 10 adjacences
  | / ╱ \ |    Beaucoup de trafic OSPF !
  |/ ╱   \|
  R3------R4
     \  /
      R5

Segment Multi-Access AVEC DR/BDR :
(Chaque routeur adjacent uniquement avec DR et BDR)

      DR (R1)                BDR (R2)
      /  |  \               /  |  \
     /   |   \             /   |   \
   R3    R4   R5         R3   R4   R5
   (DROther) (DROther)  (DROther)

   5 routeurs = 8 adjacences (au lieu de 10)
   Avec plus de routeurs, l'economie est encore plus grande

Regles de l'election :
+------------------------------------------------------+
| 1. Plus haute PRIORITE OSPF (defaut: 1)              |
|    - Priorite 0 = ne peut PAS etre DR/BDR            |
|    - Range : 0-255                                   |
|                                                      |
| 2. En cas d'egalite : plus haut ROUTER-ID            |
|                                                      |
| 3. L'election est NON-PREEMPTIVE :                   |
|    - Un nouveau routeur avec priorite plus haute     |
|      ne delogera PAS le DR actuel                    |
|    - Il faut redemarrer OSPF ou attendre une panne   |
+------------------------------------------------------+

Configuration de la priorite :
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip ospf priority 255
! Ce routeur sera prefere comme DR

R2(config)# interface GigabitEthernet0/0
R2(config-if)# ip ospf priority 0
! Ce routeur ne sera JAMAIS DR ni BDR

Verification :
R1# show ip ospf interface GigabitEthernet0/0
  ...
  Designated Router (ID) 1.1.1.1, Interface address 10.0.0.1
  Backup Designated router (ID) 2.2.2.2, Interface address 10.0.0.2

Adresses multicast OSPF :
- 224.0.0.5 = AllSPFRouters (tous les routeurs OSPF)
- 224.0.0.6 = AllDRouters (DR et BDR seulement)
```

## Types de LSA

Les LSA (Link-State Advertisements) sont les unites d'information echangees entre routeurs OSPF.

```
+------+-------------------+-------------------------------------------+
| Type | Nom               | Description                               |
+------+-------------------+-------------------------------------------+
|  1   | Router LSA        | Genere par chaque routeur                 |
|      |                   | Decrit les liens dans une area            |
|      |                   | Reste dans l'area d'origine               |
+------+-------------------+-------------------------------------------+
|  2   | Network LSA       | Genere par le DR                          |
|      |                   | Decrit les routeurs sur un segment        |
|      |                   | multi-access, reste dans l'area           |
+------+-------------------+-------------------------------------------+
|  3   | Summary LSA       | Genere par l'ABR                          |
|      | (Network)         | Resume les routes d'une area              |
|      |                   | pour les autres areas                     |
+------+-------------------+-------------------------------------------+
|  4   | Summary LSA       | Genere par l'ABR                          |
|      | (ASBR)            | Indique le chemin vers un ASBR            |
|      |                   |                                           |
+------+-------------------+-------------------------------------------+
|  5   | External LSA      | Genere par l'ASBR                         |
|      |                   | Routes redistribuees depuis un            |
|      |                   | protocole externe (BGP, static, etc.)     |
|      |                   | Inondees dans tout le domaine OSPF        |
+------+-------------------+-------------------------------------------+
|  7   | NSSA External LSA | Comme LSA 5 mais dans une NSSA            |
|      |                   | (Not-So-Stubby Area)                      |
|      |                   | Converti en LSA 5 par l'ABR               |
+------+-------------------+-------------------------------------------+

Propagation des LSA :

    Area 1              Area 0                Area 2
  +---------+       +-----------+         +---------+
  | LSA 1,2 |       | LSA 1,2   |         | LSA 1,2 |
  | (local) |       | LSA 3,4   |         | (local) |
  |         |       | LSA 5     |         |         |
  +---------+       +-----------+         +---------+
       |    LSA 3        |       LSA 3        |
       +<--------- ABR --------->+            |
       |                 |                     |
       |    LSA 5 (inonde tout le domaine)     |
       +<----------- ASBR --------->+---------+

Verification :
R1# show ip ospf database

            OSPF Router with ID (1.1.1.1) (Process ID 1)

                Router Link States (Area 0)
Link ID         ADV Router      Age  Seq#       Checksum
1.1.1.1         1.1.1.1         523  0x80000005 0x003A2B
2.2.2.2         2.2.2.2         498  0x80000004 0x001A4C

                Net Link States (Area 0)
Link ID         ADV Router      Age  Seq#       Checksum
10.0.0.1        1.1.1.1         523  0x80000002 0x005678

                Summary Net Link States (Area 0)
Link ID         ADV Router      Age  Seq#       Checksum
192.168.1.0     1.1.1.1         200  0x80000001 0x00AB12
```

## Metrique OSPF (Cost)

OSPF utilise le cout (cost) comme metrique. Le cout est base sur la bande passante de l'interface.

```
Formule du Cout OSPF :

                   Reference Bandwidth
    Cost = ────────────────────────────────
                Interface Bandwidth

    Reference Bandwidth par defaut = 100 Mbps (10^8)

+--------------------+------------------+------+
| Type Interface     | Bandwidth        | Cost |
+--------------------+------------------+------+
| Serial (T1)       | 1.544 Mbps       |  64  |
| FastEthernet      | 100 Mbps         |   1  |
| GigabitEthernet   | 1000 Mbps (1G)   |   1  |
| 10 GigabitEthernet| 10000 Mbps (10G) |   1  |
+--------------------+------------------+------+

Probleme : FastEthernet, GigE et 10GigE ont le meme cout !

Solution : Augmenter la reference bandwidth

R1(config)# router ospf 1
R1(config-router)# auto-cost reference-bandwidth 10000
! Reference = 10 Gbps = 10000 Mbps

Nouveaux couts :
+--------------------+------------------+--------+
| Type Interface     | Bandwidth        | Cost   |
+--------------------+------------------+--------+
| Serial (T1)       | 1.544 Mbps       |  6477  |
| FastEthernet      | 100 Mbps         |   100  |
| GigabitEthernet   | 1000 Mbps        |    10  |
| 10 GigabitEthernet| 10000 Mbps       |     1  |
+--------------------+------------------+--------+

Important : Configurer la meme reference bandwidth
sur TOUS les routeurs OSPF du domaine !

Modification manuelle du cout :
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip ospf cost 50
! Force le cout a 50 sur cette interface
```

### Calcul du Meilleur Chemin

```
Exemple de calcul SPF :

R1 ----[Cost 10]---- R2 ----[Cost 10]---- R4
 |                    |                     |
 |                    |                     |
[Cost 10]          [Cost 1]             [Cost 1]
 |                    |                     |
 |                    |                     |
R3 ----[Cost 100]--- R5 ----[Cost 1]------ R6
                                          (Destination)

Chemins possibles de R1 vers R6 :

Chemin 1 : R1 -> R2 -> R4 -> R6
  Cout total = 10 + 10 + 1 = 21

Chemin 2 : R1 -> R2 -> R5 -> R6
  Cout total = 10 + 1 + 1 = 12    <-- MEILLEUR CHEMIN

Chemin 3 : R1 -> R3 -> R5 -> R6
  Cout total = 10 + 100 + 1 = 111

OSPF choisit le Chemin 2 (cout le plus bas = 12)
```

## Configuration OSPF

### OSPF Single-Area

```cisco
! Configuration de base OSPF Single-Area
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255 area 0
R1(config-router)# network 10.0.0.0 0.0.0.3 area 0
R1(config-router)# passive-interface GigabitEthernet0/0
R1(config-router)# auto-cost reference-bandwidth 10000
R1(config-router)# exit

! Methode alternative : configuration par interface
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip ospf 1 area 0
R1(config-if)# exit

R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip ospf 1 area 0
R1(config-if)# exit

! passive-interface : empeche l'envoi de Hello sur les interfaces LAN
! (pas de voisin OSPF sur le LAN, mais le reseau est quand meme annonce)
```

### OSPF Multi-Area

```
Topologie :

   Area 1                 Area 0                Area 2
+---------+         +-------------+         +---------+
|  R1     |         |    R3       |         |  R5     |
| 172.16  |----ABR-1|  10.0.0.0  |ABR-2----|  10.1   |
|  .1.0/24|   (R2)  |    /30     |  (R4)   | .1.0/24 |
+---------+         +-------------+         +---------+

Configuration ABR-1 (R2) :
R2(config)# router ospf 1
R2(config-router)# router-id 2.2.2.2
R2(config-router)# auto-cost reference-bandwidth 10000

! Interface vers Area 1
R2(config-router)# network 172.16.1.0 0.0.0.255 area 1

! Interface vers Area 0
R2(config-router)# network 10.0.0.0 0.0.0.3 area 0

! Verification
R2# show ip ospf interface brief
Interface    PID   Area     IP Address/Mask    Cost  State Nbrs F/C
Gi0/0        1     1        172.16.1.1/24      10    DR    1/1
Gi0/1        1     0        10.0.0.1/30        10    P2P   1/1

R2# show ip ospf border-routers
! Affiche les ABR et ASBR connus
```

### Configuration Wildcard Mask

```
Le wildcard mask est l'INVERSE du masque de sous-reseau :

Masque de sous-reseau : 255.255.255.0
Wildcard mask        : 0.0.0.255

Calcul : 255.255.255.255 - masque = wildcard

Exemples :
+---------------------+-------------------+
| Masque              | Wildcard          |
+---------------------+-------------------+
| 255.255.255.0 /24   | 0.0.0.255         |
| 255.255.255.128 /25 | 0.0.0.127         |
| 255.255.255.252 /30 | 0.0.0.3           |
| 255.255.0.0 /16     | 0.0.255.255       |
| 255.255.255.255 /32 | 0.0.0.0           |
+---------------------+-------------------+

Utilisation dans OSPF :
network 192.168.1.0 0.0.0.255 area 0
        |           |
        Reseau      Wildcard (pas le masque !)
```

## OSPFv3 pour IPv6

OSPFv3 est la version d'OSPF concue pour IPv6 (RFC 5340).

```
Differences OSPFv2 vs OSPFv3 :
+-------------------------+------------------------+------------------------+
| Caracteristique         | OSPFv2 (IPv4)          | OSPFv3 (IPv6)          |
+-------------------------+------------------------+------------------------+
| Protocole IP            | IPv4                   | IPv6                   |
| Configuration           | Sous router ospf       | Par interface          |
| Identification voisins  | Adresse IPv4           | Router-ID (32 bits)    |
| Multicast               | 224.0.0.5 / 224.0.0.6 | FF02::5 / FF02::6     |
| Authentification        | Dans le protocole      | Via IPsec              |
| Network statement       | network X wildcard     | ipv6 ospf area         |
|                         | area Y                 | (sur l'interface)      |
+-------------------------+------------------------+------------------------+

Configuration OSPFv3 :
R1(config)# ipv6 unicast-routing
R1(config)# ipv6 router ospf 1
R1(config-rtr)# router-id 1.1.1.1
R1(config-rtr)# exit

R1(config)# interface GigabitEthernet0/0
R1(config-if)# ipv6 ospf 1 area 0
R1(config-if)# exit

R1(config)# interface GigabitEthernet0/1
R1(config-if)# ipv6 ospf 1 area 0
R1(config-if)# exit

Verification :
R1# show ipv6 ospf neighbor
R1# show ipv6 ospf interface brief
R1# show ipv6 route ospf
```

## Commandes de Verification OSPF

```cisco
! Informations generales OSPF
R1# show ip ospf
  Routing Process "ospf 1" with ID 1.1.1.1
  Reference bandwidth unit is 10000 mbps
  Number of areas in this router is 2

! Liste des voisins
R1# show ip ospf neighbor

Neighbor ID  Pri  State      Dead Time  Address       Interface
2.2.2.2       1  FULL/DR    00:00:38   10.0.0.2      Gi0/1
3.3.3.3       1  FULL/BDR   00:00:35   10.0.0.3      Gi0/1
4.4.4.4       1  2WAY/DROTHER 00:00:39 10.0.0.4      Gi0/1

! Base de donnees OSPF
R1# show ip ospf database

! Detail d'une interface OSPF
R1# show ip ospf interface GigabitEthernet0/0
  GigabitEthernet0/0 is up, line protocol is up
    Internet Address 10.0.0.1/24, Area 0
    Process ID 1, Router ID 1.1.1.1, Network Type BROADCAST, Cost: 10
    Transmit Delay is 1 sec, State DR, Priority 1
    Designated Router (ID) 1.1.1.1
    Backup Designated Router (ID) 2.2.2.2
    Timer intervals configured, Hello 10, Dead 40, Wait 40, Retransmit 5
    Neighbor Count is 3, Adjacent neighbor count is 3

! Resume des interfaces OSPF
R1# show ip ospf interface brief

! Routes OSPF dans la table de routage
R1# show ip route ospf
O     192.168.2.0/24 [110/20] via 10.0.0.2, 00:05:23, Gi0/1
O IA  172.16.0.0/16 [110/30] via 10.0.0.2, 00:05:23, Gi0/1
O E2  0.0.0.0/0 [110/1] via 10.0.0.2, 00:05:23, Gi0/1

! Codes des routes OSPF :
! O    = Intra-area (meme area)
! O IA = Inter-area (autre area, via ABR)
! O E1 = External Type 1 (metrique = interne + externe)
! O E2 = External Type 2 (metrique = externe seulement, defaut)
```

## Depannage OSPF

### Problemes Courants

```
Probleme 1 : Voisins ne forment pas d'adjacence

Verifications :
+------------------------------------------------------+
| Parametre              | Doit etre identique         |
+------------------------------------------------------+
| Area ID                | Meme area sur le lien       |
| Hello/Dead timers      | Hello=10, Dead=40 (defaut)  |
| Authentification       | Meme type et mot de passe   |
| Type de reseau         | Broadcast, point-to-point   |
| Masque de sous-reseau  | Meme subnet sur le lien     |
| MTU                    | Meme MTU (ou mtu-ignore)    |
+------------------------------------------------------+

Commandes de diagnostic :
R1# show ip ospf interface Gi0/0
! Verifier area, timers, network type

R1# show ip ospf neighbor
! Verifier l'etat (doit etre FULL ou 2WAY)

R1# debug ip ospf adj
! Debug adjacences (attention en production !)

---

Probleme 2 : Routes OSPF manquantes

Diagnostic :
R1# show ip ospf database
! Verifier que les LSA sont presents

R1# show ip route ospf
! Verifier les routes installees

R1# show ip ospf border-routers
! Verifier la connectivite aux ABR/ASBR

---

Probleme 3 : Trafic ne prend pas le chemin optimal

Diagnostic :
R1# show ip ospf interface brief
! Verifier les couts par interface

R1# traceroute <destination>
! Verifier le chemin reel

Solution : Ajuster les couts ou la reference bandwidth
```

## Questions de Revision

### Niveau Fondamental
1. Qu'est-ce qu'un protocole link-state ? En quoi differe-t-il de distance-vector ?
2. Quel est le role du Router-ID en OSPF ?
3. Quelle est l'administrative distance d'OSPF ?

### Niveau Intermediaire
1. Decrivez les 7 etats de voisinage OSPF.
2. Pourquoi Area 0 est-elle obligatoire en multi-area ?
3. Comment est calcule le cout OSPF d'un chemin ?
4. Quelle est la difference entre un ABR et un ASBR ?

### Niveau Avance
1. Expliquez le processus complet d'election DR/BDR sur un segment Ethernet avec 5 routeurs ayant des priorites differentes.
2. Un routeur OSPF dans Area 1 recoit un LSA Type 3 pour le reseau 10.0.0.0/24. Quel routeur a genere ce LSA ?
3. Pourquoi devrait-on modifier la reference bandwidth par defaut de 100 Mbps ?

---

*Fiche creee pour la revision CCNA*
*Auteur : Tudy Gbaguidi*
