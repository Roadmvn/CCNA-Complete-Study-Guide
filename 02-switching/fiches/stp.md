# Spanning Tree Protocol (STP) - Fiche Complete

## Vue d'Ensemble

Le Spanning Tree Protocol (IEEE 802.1D) est un protocole de couche 2 qui empeche les boucles de commutation dans les reseaux redondants. Il garantit qu'il n'existe qu'un seul chemin actif entre deux noeuds du reseau.

---

## Probleme des Boucles L2

### Pourquoi les Boucles sont Dangereuses

```
Topologie SANS STP (boucle active) :

         +---------+
         |  SW-A   |
         +---------+
          |       |
     Lien1|       |Lien2
          |       |
     +---------+  |
     |  SW-B   |--+
     +---------+
          |
     +---------+
     |  PC-A   | Envoie un broadcast ARP
     +---------+

Sequence de la Broadcast Storm :

1. PC-A envoie un broadcast
   PC-A --broadcast-- SW-B

2. SW-B forward sur tous ses ports (sauf source)
   SW-B -- SW-A (via Lien1)
   SW-B -- SW-A (via Lien2)

3. SW-A recoit 2 copies, forward chacune
   SW-A -- SW-B (via Lien2, copie de Lien1)
   SW-A -- SW-B (via Lien1, copie de Lien2)

4. SW-B re-forward... et ainsi de suite
   = BOUCLE INFINIE = BROADCAST STORM

Consequences :
+---------------------------------------------------------+
| Probleme               | Impact                         |
+-------------------------+--------------------------------+
| Broadcast Storm         | Saturation totale des liens    |
| Instabilite MAC table   | MAC flapping entre ports       |
| Trames dupliquees       | Applications perturbees        |
| CPU a 100%              | Switch injoignable             |
| Reseau inutilisable     | Perte de service complete      |
+-------------------------+--------------------------------+
```

---

## Algorithme STA (Spanning Tree Algorithm)

### Processus d'Election en 3 Etapes

```
ETAPE 1 : Election du Root Bridge
---------------------------------
Critere : Bridge ID le plus BAS gagne

Bridge ID (8 octets) :
+------------------+--------------------------+
| Bridge Priority  |      MAC Address         |
|   (2 octets)     |      (6 octets)          |
|   0 - 65535      |                          |
|   defaut: 32768  |   Unique par switch      |
+------------------+--------------------------+

Avec PVST+ (Per-VLAN STP) :
+------------------+----------+--------------------------+
| Bridge Priority  | VLAN ID  |      MAC Address         |
|   (4 bits)       |(12 bits) |      (6 octets)          |
|   Multiple de    |          |                          |
|   4096           |          |                          |
+------------------+----------+--------------------------+

Extended System ID = Priority + VLAN ID
Exemple : Priority 32768 + VLAN 10 = 32778

Comparaison pour election :
SW-A: 32768 + VLAN1 + MAC 0001.0001.0001 = BID le plus bas -> ROOT
SW-B: 32768 + VLAN1 + MAC 0002.0002.0002
SW-C: 32768 + VLAN1 + MAC 0003.0003.0003


ETAPE 2 : Election des Root Ports (RP)
---------------------------------------
Chaque switch NON-ROOT choisit 1 Root Port (le meilleur chemin vers Root)

Criteres de selection (dans l'ordre) :
1. Root Path Cost le plus bas
2. Sender Bridge ID le plus bas
3. Sender Port ID le plus bas
4. Receiver Port ID le plus bas

Couts par defaut (IEEE revised) :
+-----------------+----------------+----------------+
| Vitesse du lien | Cout (ancien)  | Cout (revised) |
+-----------------+----------------+----------------+
| 10 Mbps         | 100            | 2,000,000      |
| 100 Mbps        | 19             | 200,000        |
| 1 Gbps          | 4              | 20,000         |
| 10 Gbps         | 2              | 2,000          |
+-----------------+----------------+----------------+


ETAPE 3 : Election des Designated Ports (DP)
---------------------------------------------
Sur chaque segment, 1 seul Designated Port (celui qui forward)

Criteres : memes que Root Port mais perspective du segment
- Le switch avec le Root Path Cost le plus bas vers ce segment
- En cas d'egalite : Bridge ID le plus bas
```

### Exemple Complet d'Election

```
Topologie :
                    +-----------------+
                    |      SW-A       |
                    | BID: 32769      |
                    | MAC: 0001.0001  |
                    | = ROOT BRIDGE   |
                    |                 |
                    | Fa0/1     Fa0/2 |
                    +--+----------+---+
                       |          |
              Cost: 19 |          | Cost: 19
                       |          |
              +--------+--+  +----+----------+
              |   SW-B    |  |     SW-C      |
              | BID: 32769|  | BID: 32769    |
              | MAC: 0002 |  | MAC: 0003     |
              |           |  |               |
              | Fa0/1     |  | Fa0/1         |
              | RPC: 19   |  | RPC: 19       |
              |           |  |               |
              | Fa0/2     |  | Fa0/2         |
              |           |  |               |
              +---+-------+  +---+-----------+
                  |    Cost: 19  |
                  +--------------+

Resolution :

Port         Role        Raison
------------ ----------- ----------------------------------------
SW-A Fa0/1   Designated  Root Bridge : tous ports sont Designated
SW-A Fa0/2   Designated  Root Bridge : tous ports sont Designated
SW-B Fa0/1   Root Port   Chemin direct vers Root (cost 19)
SW-B Fa0/2   Designated  BID SW-B < BID SW-C sur ce segment
SW-C Fa0/1   Root Port   Chemin direct vers Root (cost 19)
SW-C Fa0/2   Non-Desig.  BID SW-C > BID SW-B -> port BLOQUE
```

---

## Roles des Ports

```
+------------------+-------------------------------------------+
| Role             | Description                               |
+------------------+-------------------------------------------+
| Root Port (RP)   | - 1 par switch non-root                  |
|                  | - Meilleur chemin vers le Root Bridge     |
|                  | - Etat : Forwarding                      |
+------------------+-------------------------------------------+
| Designated       | - 1 par segment reseau                   |
| Port (DP)        | - Forward le trafic vers le segment      |
|                  | - Etat : Forwarding                      |
+------------------+-------------------------------------------+
| Non-Designated   | - Ports restants apres election           |
| (Blocked)        | - Ne forward PAS le trafic               |
|                  | - Etat : Blocking                        |
|                  | - Ecoute les BPDUs (surveillance)        |
+------------------+-------------------------------------------+
```

---

## Etats des Ports STP

### Les 5 Etats (STP Classique 802.1D)

```
+------------+----------+----------+----------+----------------+
| Etat       | Recoit   | Envoie   | Apprend  | Forward        |
|            | BPDUs    | BPDUs    | MAC      | Donnees        |
+------------+----------+----------+----------+----------------+
| Disabled   | Non      | Non      | Non      | Non            |
| (admin off)|          |          |          |                |
+------------+----------+----------+----------+----------------+
| Blocking   | OUI      | Non      | Non      | Non            |
| (20s max)  |          |          |          |                |
+------------+----------+----------+----------+----------------+
| Listening  | OUI      | OUI      | Non      | Non            |
| (15s)      |          |          |          |                |
+------------+----------+----------+----------+----------------+
| Learning   | OUI      | OUI      | OUI      | Non            |
| (15s)      |          |          |          |                |
+------------+----------+----------+----------+----------------+
| Forwarding | OUI      | OUI      | OUI      | OUI            |
| (stable)   |          |          |          |                |
+------------+----------+----------+----------+----------------+
```

---

## Timers STP

```
+---------------+----------+-----------------------------------+
| Timer         | Defaut   | Role                              |
+---------------+----------+-----------------------------------+
| Hello Time    | 2 sec    | Intervalle entre BPDUs            |
|               |          | emis par le Root Bridge           |
+---------------+----------+-----------------------------------+
| Forward Delay | 15 sec   | Duree de chaque etat              |
|               |          | Listening et Learning             |
+---------------+----------+-----------------------------------+
| Max Age       | 20 sec   | Duree max sans BPDU avant         |
|               |          | recalcul STP                      |
+---------------+----------+-----------------------------------+

Temps de convergence :
- Cas optimal : 30s (Listening + Learning)
- Cas pire    : 50s (Max Age + Listening + Learning)

Pourquoi c'est lent :
Le STP classique est conservateur pour eviter les boucles
temporaires pendant la reconfiguration.
```

---

## PVST+ et Rapid PVST+ (RSTP)

### Comparaison des Variantes STP

```
+--------------+--------------+--------------+------------------+
| Critere      | STP (802.1D) | PVST+        | RSTP (802.1w)    |
|              |              | (Cisco)      | Rapid PVST+      |
+--------------+--------------+--------------+------------------+
| Standard     | IEEE         | Cisco        | IEEE / Cisco     |
|              |              | proprietaire |                  |
+--------------+--------------+--------------+------------------+
| Instance     | 1 pour tous  | 1 par VLAN   | 1 par VLAN       |
|              | les VLANs    |              | (Rapid PVST+)    |
+--------------+--------------+--------------+------------------+
| Convergence  | 30-50 sec    | 30-50 sec    | < 6 secondes     |
|              |              |              | (souvent < 1s)   |
+--------------+--------------+--------------+------------------+
| Port States  | 5 etats      | 5 etats      | 3 etats          |
|              |              |              | (Disc/Learn/Fwd) |
+--------------+--------------+--------------+------------------+
| Root par     | Non          | OUI          | OUI              |
| VLAN         |              |              |                  |
+--------------+--------------+--------------+------------------+
| Load Balance | Non          | OUI (via     | OUI (via         |
| par VLAN     |              | root/VLAN)   | root/VLAN)       |
+--------------+--------------+--------------+------------------+
```

### RSTP - Roles de Ports Supplementaires

```
RSTP introduit de nouveaux roles :

+------------------+-------------------------------------------+
| Role RSTP        | Description                               |
+------------------+-------------------------------------------+
| Root Port        | Identique au STP classique                |
+------------------+-------------------------------------------+
| Designated Port  | Identique au STP classique                |
+------------------+-------------------------------------------+
| Alternate Port   | Chemin alternatif vers le Root Bridge     |
|                  | (remplace le Root Port en cas de panne)   |
|                  | = Equivalent du Blocked port              |
+------------------+-------------------------------------------+
| Backup Port      | Backup d'un Designated Port               |
|                  | (rare, 2 liens vers meme segment)         |
+------------------+-------------------------------------------+

Convergence RSTP vs STP :

STP Classique (panne de lien) :
Panne -> Max Age (20s) -> Listening (15s) -> Learning (15s) -> FWD
                        = 50 secondes

RSTP (panne de lien) :
Panne -> Alternate Port promu -> Proposal/Agreement -> FWD
                               = < 1 seconde

Mecanisme Proposal/Agreement (RSTP) :
+----------+    Proposal     +----------+
|  SW-A    |----------------|  SW-B    |
|          |                 |          |
|          |    Agreement    | Bloque   |
|          |----------------| ses ports|
|          |                 | non-edge |
| Port FWD |                 | puis     |
|          |                 | Agreement|
+----------+                 +----------+
Resultat : transition quasi-instantanee
```

---

## Mecanismes de Protection STP

### PortFast

```
PortFast : Transition immediate vers Forwarding
(pour les ports access connectes a des hotes)

Sans PortFast :                Avec PortFast :
Blocking (0s)                  -> FORWARDING (immediat)
  v
Listening (15s)                Gain de temps : 30 secondes
  v
Learning (15s)
  v
Forwarding (30s)

Configuration :
interface fa0/1
 spanning-tree portfast
 exit

Configuration globale (tous ports access) :
spanning-tree portfast default

ATTENTION : Ne JAMAIS activer PortFast sur un port trunk
            ou connecte a un switch (risque de boucle !)
```

### BPDU Guard

```
BPDU Guard : Desactive le port si un BPDU est recu
(protection contre les switches non autorises)

                    +--------------+
                    |   Switch     |
                    |              |
                    |  Fa0/1       |
                    |  PortFast    |
                    |  BPDU Guard  |
                    +------+-------+
                           |
                    +------+-------+
                    |   Switch     |  Connecte par erreur
                    |   Rogue      |  ou attaque
                    |              |
                    |  Envoie BPDU |
                    +--------------+

Resultat :
Fa0/1 recoit un BPDU -> Port passe en err-disabled -> DOWN

Configuration :
interface fa0/1
 spanning-tree bpduguard enable
 exit

Configuration globale :
spanning-tree portfast bpduguard default
```

### Root Guard

```
Root Guard : Empeche un switch de devenir Root Bridge
(protege la position du Root actuel)

              +--------------+
              |   SW-A       |
              |   ROOT       |
              |   Priority:  |
              |   4096       |
              +------+-------+
                     |
              +------+-------+
              |   SW-B       |
              |              |
              |   Fa0/2      |
              |  Root Guard  |
              +------+-------+
                     |
              +------+-------+
              |   SW-C       |  Tente de devenir Root
              |   Priority:  |  avec priority 0
              |   0          |
              +--------------+

Sans Root Guard : SW-C deviendrait Root (priority 0 < 4096)
Avec Root Guard : Fa0/2 de SW-B passe en "root-inconsistent"
                  SW-C ne peut PAS devenir Root via ce chemin

Configuration :
interface fa0/2
 spanning-tree guard root
 exit
```

---

## Commandes de Verification

### Commandes show

```cisco
! Afficher l'etat STP global
Switch# show spanning-tree

VLAN0001
  Spanning tree enabled protocol rstp
  Root ID    Priority    32769
             Address     0001.0001.0001
             Cost        19
             Port        1 (FastEthernet0/1)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32769  (priority 32768 sys-id-ext 1)
             Address     0002.0002.0002
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- ----
Fa0/1            Root FWD 19        128.1    P2p
Fa0/2            Desg FWD 19        128.2    P2p
Fa0/3            Altn BLK 19        128.3    P2p


! STP pour un VLAN specifique
Switch# show spanning-tree vlan 10

! Ports bloques
Switch# show spanning-tree blockedports

! Detail d'une interface
Switch# show spanning-tree interface fa0/1 detail

! Resume root bridge
Switch# show spanning-tree root

! Voir les inconsistances
Switch# show spanning-tree inconsistentports
```

### Commandes de Configuration

```cisco
! Forcer un switch comme Root Bridge (methode recommandee)
Switch(config)# spanning-tree vlan 1 root primary
! Equivalent a : priority 24576 (ou 4096 de moins que le root actuel)

! Configurer le Root Bridge secondaire (backup)
Switch(config)# spanning-tree vlan 1 root secondary
! Equivalent a : priority 28672

! Configurer la priority manuellement
Switch(config)# spanning-tree vlan 1 priority 4096
! Valeurs : 0, 4096, 8192, 12288, 16384, 20480, 24576, 28672, 32768...

! Modifier le cout d'un port
Switch(config)# interface fa0/1
Switch(config-if)# spanning-tree cost 10
Switch(config-if)# exit

! Modifier la priorite d'un port
Switch(config)# interface fa0/1
Switch(config-if)# spanning-tree port-priority 64
Switch(config-if)# exit

! Activer Rapid PVST+
Switch(config)# spanning-tree mode rapid-pvst
```

### Commandes de Debug

```cisco
! Debug STP events
Switch# debug spanning-tree events

! Debug BPDUs
Switch# debug spanning-tree bpdu

! Desactiver le debug
Switch# undebug all
```

---

## Optimisation STP

### Manipulation du Root Bridge

```
Scenario : Forcer SW-CORE comme Root pour tous les VLANs

AVANT optimisation :
SW-ACCESS (Root par defaut, MAC basse)
      ↕
  Trafic sub-optimal

APRES optimisation :
SW-CORE (Root force, priority 4096)
      ↕
  Trafic optimal via le coeur de reseau

Configuration :
SW-CORE(config)# spanning-tree vlan 1-100 root primary
SW-BACKUP(config)# spanning-tree vlan 1-100 root secondary
```

### Load Balancing avec PVST+

```
Repartition du trafic par VLAN :

SW-CORE-1 : Root pour VLANs pairs (10, 20, 30...)
SW-CORE-2 : Root pour VLANs impairs (11, 21, 31...)

SW-CORE-1(config)# spanning-tree vlan 10,20,30 priority 4096
SW-CORE-1(config)# spanning-tree vlan 11,21,31 priority 8192

SW-CORE-2(config)# spanning-tree vlan 11,21,31 priority 4096
SW-CORE-2(config)# spanning-tree vlan 10,20,30 priority 8192

Resultat :
            +----------+        +----------+
            | CORE-1   |        | CORE-2   |
            |Root V10  |        |Root V11  |
            |Root V20  |        |Root V21  |
            |Root V30  |        |Root V31  |
            +----+-----+        +----+-----+
                 |                   |
    VLANs pairs  |                   | VLANs impairs
    (forwarding) |                   | (forwarding)
                 |                   |
            +----+-------------------+-----+
            |        SW-ACCESS             |
            |  VLAN 10,20,30 -> via CORE-1  |
            |  VLAN 11,21,31 -> via CORE-2  |
            +------------------------------+
```

---

## Depannage STP

### Problemes Courants

```
Probleme 1 : Root Bridge non optimal
--------------------------------------
Symptome : Un switch access est devenu Root Bridge
Diagnostic :
  Switch# show spanning-tree root
Solution :
  SW-CORE(config)# spanning-tree vlan 1 priority 4096

Probleme 2 : Port reste en Blocking
--------------------------------------
Symptome : Port ne passe jamais en Forwarding
Diagnostic :
  Switch# show spanning-tree interface fa0/1 detail
  Switch# show spanning-tree inconsistentports
Causes :
  - Port non-designated normal (redondance)
  - Root-inconsistent (Root Guard actif)
  - Loop-inconsistent (Loop Guard actif)

Probleme 3 : Broadcast Storm
--------------------------------------
Symptome : CPU 100%, connectivite perdue
Diagnostic :
  Switch# show processes cpu
  Switch# show spanning-tree
  Switch# show interfaces counters
Solution immediate :
  - Identifier et deconnecter le port en boucle
  - Activer BPDU Guard sur les ports access
  - Verifier la configuration STP

Probleme 4 : Port err-disabled (BPDU Guard)
--------------------------------------
Symptome : Port down apres connexion d'un switch
Diagnostic :
  Switch# show interfaces status err-disabled
Solution :
  Switch(config)# interface fa0/1
  Switch(config-if)# shutdown
  Switch(config-if)# no shutdown
  ! Ou configurer auto-recovery :
  Switch(config)# errdisable recovery cause bpduguard
  Switch(config)# errdisable recovery interval 300
```

---

## Questions de Revision

### Concepts

1. Pourquoi STP est-il necessaire dans un reseau avec des liens redondants ?
2. Quels sont les 3 composants du Bridge ID ?
3. Comment un switch determine-t-il son Root Port ?

### Configuration

4. Quelle commande force un switch a devenir Root Bridge ?
5. Quelle est la difference entre PortFast et BPDU Guard ?
6. Pourquoi utiliser Rapid PVST+ plutot que STP classique ?

### Depannage

7. Un port PortFast passe en err-disabled. Quelle est la cause probable ?
8. Le temps de convergence est de 50 secondes. Dans quel etat etait le port avant la panne ?
9. Deux switches ont la meme priority. Comment le Root Bridge est-il elu ?

### Reponses

1. Sans STP, les trames de broadcast circulent indefiniment dans les boucles, causant des broadcast storms et la saturation du reseau.
2. Bridge Priority (2 octets) + Extended System ID (VLAN) + MAC Address (6 octets).
3. En selectionnant le port avec le Root Path Cost le plus bas, puis le Sender BID le plus bas, puis le Sender Port ID le plus bas.
4. `spanning-tree vlan X root primary` ou `spanning-tree vlan X priority 4096`.
5. PortFast fait passer le port directement en Forwarding. BPDU Guard desactive le port si un BPDU est recu. Ils sont souvent utilises ensemble.
6. RSTP converge en moins de 6 secondes contre 30-50 secondes pour STP classique, grace au mecanisme Proposal/Agreement.
7. Un BPDU a ete recu sur le port (un switch a ete connecte). BPDU Guard a desactive le port pour prevenir une boucle.
8. Le port etait en Blocking. Il a du attendre Max Age (20s) avant de passer en Listening (15s) puis Learning (15s).
9. Le switch avec l'adresse MAC la plus basse devient Root Bridge.

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
