# VPN et WAN - Technologies WAN, GRE, IPsec, QoS

## Vue d'Ensemble

Ce chapitre couvre les technologies WAN (MPLS, Metro Ethernet, broadband), les VPNs (GRE, IPsec), les bases de PPPoE et l'introduction a la QoS. Ces sujets sont testes dans le domaine "IP Connectivity" et "IP Services" du CCNA 200-301.

---

## 1. Technologies WAN

### Panorama des Technologies WAN

```
CLASSIFICATION DES TECHNOLOGIES WAN
=====================================

+--------------------------------------------------------------------+
|                     TECHNOLOGIES WAN                               |
+--------------------------------------------------------------------+
|                                                                    |
|  CONNEXIONS DEDIEES (Leased Lines)                                |
|  +--------------------------------------------------------------+ |
|  | - T1/E1 (1.544 Mbps / 2.048 Mbps)                           | |
|  | - T3/E3 (44.736 Mbps / 34.368 Mbps)                         | |
|  | - Point-a-point, cout eleve, fiabilite maximale              | |
|  +--------------------------------------------------------------+ |
|                                                                    |
|  COMMUTATION DE PAQUETS                                           |
|  +--------------------------------------------------------------+ |
|  | - MPLS (Multi-Protocol Label Switching)                      | |
|  |   -> Standard actuel pour WAN entreprise                     | |
|  |   -> Labels au lieu de lookup IP a chaque hop                | |
|  |   -> Classes de service (CoS) integrees                      | |
|  | - Metro Ethernet                                              | |
|  |   -> Ethernet etendu sur fibre metropolitaine                | |
|  |   -> Simple, pas de conversion de protocole                  | |
|  |   -> Bande passante flexible (10M a 100G)                    | |
|  +--------------------------------------------------------------+ |
|                                                                    |
|  ACCES BROADBAND (Internet)                                       |
|  +--------------------------------------------------------------+ |
|  | - DSL (Digital Subscriber Line)                              | |
|  |   -> Via ligne telephonique cuivre                           | |
|  |   -> ADSL : asymetrique (download > upload)                  | |
|  |   -> VDSL : plus rapide, distance plus courte               | |
|  | - Cable                                                       | |
|  |   -> Via cable coaxial TV (DOCSIS)                           | |
|  |   -> Partage de bande passante entre abonnes                | |
|  | - Fibre optique (FTTH/FTTP)                                  | |
|  |   -> Debit symetrique eleve                                  | |
|  |   -> GPON / XGS-PON                                          | |
|  | - Satellite                                                   | |
|  |   -> Zones rurales isolees                                   | |
|  |   -> Latence elevee (500+ ms)                                | |
|  | - Cellulaire (4G LTE / 5G)                                   | |
|  |   -> Backup ou sites temporaires                             | |
|  +--------------------------------------------------------------+ |
|                                                                    |
+--------------------------------------------------------------------+
```

### Comparaison des Technologies WAN

```
+-------------------+----------+-----------+-----------+-------------+
| Technologie       | Debit    | Fiabilite | Cout      | Usage       |
+-------------------+----------+-----------+-----------+-------------+
| Leased Line       | 1.5-45M  | Tres haut | Tres eleve| Critical    |
| MPLS              | 1M-10G   | Haut      | Eleve     | Enterprise  |
| Metro Ethernet    | 10M-100G | Haut      | Moyen-haut| Metro/Campus|
| DSL               | 1-100M   | Moyen     | Faible    | Branch/SOHO |
| Cable             | 10-1000M | Moyen     | Faible    | Branch/SOHO |
| Fibre FTTH        | 100M-10G | Haut      | Moyen     | Branch/HQ   |
| 4G/5G             | 10-1000M | Variable  | Moyen     | Backup/Temp |
| Satellite         | 1-100M   | Faible    | Eleve     | Rural/Remote|
+-------------------+----------+-----------+-----------+-------------+
```

---

## 2. MPLS (Multi-Protocol Label Switching)

### Principe

MPLS ajoute un label (etiquette) entre les en-tetes L2 et L3. Les routeurs MPLS (LSR) commutent les paquets en se basant sur le label au lieu de faire un lookup IP complet a chaque hop. Cela permet des performances elevees et des services comme les VPN L3 et L2.

### Schema : MPLS Label Switching

```
MPLS - COMMUTATION PAR LABELS
===============================

  Site A                                                    Site B
  10.1.0.0/16                                              10.2.0.0/16
      |                                                        |
      v                                                        v
+----------+     +----------+     +----------+     +----------+
|   CE-A   |     |  PE-A    |     |  P       |     |  PE-B    |
| (Client  |---->| (Provider|---->| (Provider|---->| (Provider|----> CE-B
|  Edge)   |     |  Edge)   |     |  Core)   |     |  Edge)   |
+----------+     +----------+     +----------+     +----------+

Traitement du paquet a chaque etape :

1. CE-A envoie un paquet IP normal :
   +--------+--------+---------+
   | L2 Hdr | IP Hdr | Payload |
   +--------+--------+---------+

2. PE-A ajoute un label MPLS (PUSH) :
   +--------+-------+--------+---------+
   | L2 Hdr | Label | IP Hdr | Payload |
   |        |  20   |        |         |
   +--------+-------+--------+---------+

3. P commute sur le label (SWAP) :
   +--------+-------+--------+---------+
   | L2 Hdr | Label | IP Hdr | Payload |
   |        |  35   |        |         |
   +--------+-------+--------+---------+

4. PE-B retire le label (POP) et route en IP :
   +--------+--------+---------+
   | L2 Hdr | IP Hdr | Payload |
   +--------+--------+---------+

TERMINOLOGIE MPLS :
+--------+-----------------------------------------------+
| Terme  | Description                                   |
+--------+-----------------------------------------------+
| CE     | Customer Edge - routeur client                |
| PE     | Provider Edge - routeur operateur (bord)      |
| P      | Provider - routeur coeur operateur            |
| LSR    | Label Switch Router                           |
| LSP    | Label Switched Path (chemin MPLS)             |
| FEC    | Forwarding Equivalence Class                  |
| LDP    | Label Distribution Protocol                   |
| PUSH   | Ajouter un label                              |
| SWAP   | Remplacer un label                            |
| POP    | Retirer un label                              |
+--------+-----------------------------------------------+
```

---

## 3. VPN Concepts

### Types de VPN

```
TYPES DE VPN
=============

+--------------------------------------------------------------------+
|                                                                    |
|  1. SITE-TO-SITE VPN                                              |
|  +--------------------------------------------------------------+ |
|  |                                                              | |
|  |  [LAN Site A]                          [LAN Site B]         | |
|  |       |                                     |               | |
|  |  +----+-----+     TUNNEL VPN     +-----+----+              | |
|  |  | Router A |=====================| Router B |              | |
|  |  +----------+     (Internet)      +----------+              | |
|  |                                                              | |
|  |  - Connexion permanente entre 2 sites                       | |
|  |  - Transparent pour les utilisateurs                        | |
|  |  - Technologies : IPsec, GRE over IPsec                    | |
|  |  - Exemple : siege <-> succursale                           | |
|  +--------------------------------------------------------------+ |
|                                                                    |
|  2. REMOTE ACCESS VPN                                             |
|  +--------------------------------------------------------------+ |
|  |                                                              | |
|  |  [Utilisateur distant]                                      | |
|  |       |                                                     | |
|  |  +----+------+    TUNNEL VPN    +----------+               | |
|  |  | PC Client |==================| VPN      |---> [LAN]     | |
|  |  | + logiciel|    (Internet)    | Gateway  |               | |
|  |  +-----------+                  +----------+               | |
|  |                                                              | |
|  |  - Connexion a la demande (utilisateur se connecte)         | |
|  |  - Client VPN requis (AnyConnect, OpenVPN...)               | |
|  |  - Technologies : SSL VPN, IPsec client                    | |
|  |  - Exemple : teletravailleur -> reseau entreprise           | |
|  +--------------------------------------------------------------+ |
|                                                                    |
+--------------------------------------------------------------------+
```

---

## 4. GRE Tunnel (Generic Routing Encapsulation)

### Principe

GRE encapsule des paquets d'un protocole dans un autre. Il cree un tunnel point-a-point entre deux routeurs a travers un reseau intermediaire (typiquement Internet). GRE seul ne chiffre pas : il faut le combiner avec IPsec pour la confidentialite.

### Schema : GRE Tunnel

```
GRE TUNNEL OVER INTERNET
==========================

  LAN-A                                                LAN-B
  10.1.1.0/24                                         10.2.2.0/24
      |                                                    |
      v                                                    v
+----------+          TUNNEL GRE              +----------+
|  R1      |==================================|  R2      |
|          |    Tunnel0: 172.16.1.1/30        |          |
| Gi0/0:   |    <--- Paquet encapsule --->    | Gi0/0:   |
| 10.1.1.1 |    Source: 203.0.113.1           | 10.2.2.1 |
|          |    Dest:   198.51.100.1          |          |
| Gi0/1:   |                                  | Gi0/1:   |
| 203.0.113.1                              198.51.100.1 |
+----------+                                  +----------+
      |                                            |
      |            +----------------+              |
      +----------->|   INTERNET     |<-------------+
                   +----------------+

ENCAPSULATION GRE (ce qui circule sur Internet) :
+----------+----------+----------+----------+---------+
| Delivery | GRE      | Passenger| Passenger| Payload |
| IP Hdr   | Header   | IP Hdr   | TCP/UDP  |         |
| Src:203  |          | Src:10.1 |          |         |
| Dst:198  |          | Dst:10.2 |          |         |
+----------+----------+----------+----------+---------+
  ^                      ^
  |                      |
  IP publique            IP privee originale
  (transport)            (encapsulee dans GRE)

Tunnel0: 172.16.1.1 <---------> 172.16.1.2
         (R1 tunnel)              (R2 tunnel)
```

### Caracteristiques GRE

```
+-------------------------------+----------------------------------+
| Avantages                     | Limitations                      |
+-------------------------------+----------------------------------+
| Supporte multicast (OSPF,    | Pas de chiffrement natif         |
| EIGRP a travers le tunnel)   | (combiner avec IPsec)            |
| Simple a configurer           | Overhead : 24 octets par paquet  |
| Supporte IPv4 et IPv6         | Pas d'authentification native    |
| Protocole IP 47               | Point-a-point uniquement         |
+-------------------------------+----------------------------------+
```

### Configuration GRE

```cisco
! === ROUTEUR R1 ===
Router-R1(config)# interface tunnel 0
Router-R1(config-if)# ip address 172.16.1.1 255.255.255.252
Router-R1(config-if)# tunnel source gigabitEthernet 0/1
Router-R1(config-if)# tunnel destination 198.51.100.1
Router-R1(config-if)# tunnel mode gre ip
Router-R1(config-if)# no shutdown

! Route statique pour joindre le LAN distant via le tunnel
Router-R1(config)# ip route 10.2.2.0 255.255.255.0 172.16.1.2

! === ROUTEUR R2 ===
Router-R2(config)# interface tunnel 0
Router-R2(config-if)# ip address 172.16.1.2 255.255.255.252
Router-R2(config-if)# tunnel source gigabitEthernet 0/1
Router-R2(config-if)# tunnel destination 203.0.113.1
Router-R2(config-if)# tunnel mode gre ip
Router-R2(config-if)# no shutdown

Router-R2(config)# ip route 10.1.1.0 255.255.255.0 172.16.1.1

! === VERIFICATION ===
Router# show interface tunnel 0
Router# show ip route
Router# ping 172.16.1.2 source 172.16.1.1
```

---

## 5. IPsec Basics

### Principe

IPsec est un framework de securite qui fournit confidentialite (chiffrement), integrite (hash) et authentification pour le trafic IP. Il fonctionne en deux phases : IKE Phase 1 (canal securise de negociation) et IKE Phase 2 (tunnel de donnees).

### Schema : IPsec - IKE Phase 1 et Phase 2

```
IPsec NEGOCIATION FLOW
========================

+----------+                                      +----------+
|  R1      |                                      |  R2      |
| (Peer A) |                                      | (Peer B) |
+----+-----+                                      +-----+----+
     |                                                   |
     |           === IKE PHASE 1 (ISAKMP SA) ===        |
     |                                                   |
     |  1. Negociation des parametres :                  |
     |     - Algorithme chiffrement (AES-256)            |
     |     - Algorithme hash (SHA-256)                   |
     |     - Methode authentification (PSK ou cert)      |
     |     - Groupe Diffie-Hellman (DH group 14/19)      |
     |     - Duree de vie SA (86400 sec defaut)          |
     |                                                   |
     |  <-------- Echange parametres -------->           |
     |  <-------- Echange DH (cle partagee) ->           |
     |  <-------- Authentification mutuelle ->            |
     |                                                   |
     |  Resultat : ISAKMP SA etablie                     |
     |  (tunnel securise pour negocier Phase 2)          |
     |                                                   |
     |           === IKE PHASE 2 (IPsec SA) ===          |
     |                                                   |
     |  2. Negociation des parametres IPsec :            |
     |     - Protocole : ESP ou AH                       |
     |     - Algorithme chiffrement (AES-128/256)        |
     |     - Algorithme hash (SHA-256)                   |
     |     - Mode : tunnel ou transport                  |
     |     - Trafic interesse (ACL)                      |
     |     - PFS (Perfect Forward Secrecy) optionnel     |
     |                                                   |
     |  <-------- Quick Mode exchange -------->          |
     |                                                   |
     |  Resultat : IPsec SA (x2 : une par direction)     |
     |                                                   |
     |           === PHASE DATA ===                      |
     |                                                   |
     |  3. Trafic chiffre et authentifie                 |
     |  <========= Donnees protegees ==========>         |
     |                                                   |
+----+-----+                                      +-----+----+
|  R1      |                                      |  R2      |
+----------+                                      +----------+

PROTOCOLES IPsec :
+-------+--------------------------------------------------+
| Proto | Description                                      |
+-------+--------------------------------------------------+
| ESP   | Encapsulating Security Payload (IP protocol 50)  |
|       | Chiffrement + authentification + integrite        |
|       | Le plus utilise                                   |
+-------+--------------------------------------------------+
| AH    | Authentication Header (IP protocol 51)           |
|       | Authentification + integrite seulement            |
|       | PAS de chiffrement                               |
|       | Incompatible avec NAT                            |
+-------+--------------------------------------------------+

MODES IPsec :
+------------+----------------------------------------------+
| Mode       | Description                                  |
+------------+----------------------------------------------+
| Tunnel     | Encapsule le paquet IP entier                |
|            | Nouveau header IP ajoute                     |
|            | Utilise pour site-to-site VPN                |
+------------+----------------------------------------------+
| Transport  | Chiffre uniquement le payload                |
|            | Header IP original conserve                  |
|            | Utilise pour host-to-host                    |
+------------+----------------------------------------------+
```

### Resume des Composants IPsec

```
+--------------------------------------------------------------------+
| Composant            | Options CCNA                                |
+--------------------------------------------------------------------+
| Chiffrement          | DES, 3DES, AES-128, AES-256               |
| Integrite (hash)     | MD5, SHA-1, SHA-256, SHA-384              |
| Authentification     | Pre-Shared Key (PSK), Certificats (PKI)   |
| Echange de cles      | Diffie-Hellman : Group 2, 5, 14, 19, 20  |
| Protocole            | ESP (prefere), AH                         |
| Mode                 | Tunnel (site-to-site), Transport (h2h)    |
+--------------------------------------------------------------------+

Recommandation actuelle (2024+) :
- AES-256 + SHA-256 + DH group 19 (ou 20) + ESP tunnel mode
- Eviter : DES, 3DES, MD5, SHA-1, DH groups 1/2/5
```

---

## 6. PPPoE Basics

### Principe

PPPoE (Point-to-Point Protocol over Ethernet) est utilise par les FAI pour les connexions broadband DSL. Il permet l'authentification de l'abonne, l'attribution d'IP et le comptage du trafic sur une liaison Ethernet.

```
PPPoE - CONNEXION ABONNE
==========================

[PC Abonne] --- [Modem DSL] ----PPPoE---- [DSLAM/BRAS] --- [ISP Network]
                                  |
                      Session PPPoE :
                      1. PADI (PPPoE Active Discovery Initiation)
                      2. PADO (PPPoE Active Discovery Offer)
                      3. PADR (PPPoE Active Discovery Request)
                      4. PADS (PPPoE Active Discovery Session-confirmation)
                      5. Session PPP etablie (auth CHAP/PAP)
                      6. IP attribuee via IPCP
```

### Configuration PPPoE (coté client Cisco)

```cisco
! Interface dialer (logique)
Router(config)# interface dialer 1
Router(config-if)# ip address negotiated
Router(config-if)# encapsulation ppp
Router(config-if)# ppp authentication chap
Router(config-if)# ppp chap hostname MonAbonne
Router(config-if)# ppp chap password MonMotDePasse
Router(config-if)# mtu 1492
Router(config-if)# dialer pool 1

! Interface physique vers le modem DSL
Router(config)# interface gigabitEthernet 0/0
Router(config-if)# no ip address
Router(config-if)# pppoe-client dial-pool-number 1
Router(config-if)# no shutdown

! MTU 1492 car PPPoE ajoute 8 octets d'overhead (1500 - 8 = 1492)

! Verification
Router# show pppoe session
Router# show interface dialer 1
```

---

## 7. QoS Basics (Quality of Service)

### Principe

QoS permet de prioriser certains types de trafic sur le reseau. Sans QoS, tous les paquets sont traites de la meme facon (best-effort). Avec QoS, le trafic voix et video est prioritaire sur le trafic de telechargement par exemple.

### Schema : Pipeline QoS

```
QoS - PIPELINE DE TRAITEMENT
==============================

Trafic entrant
     |
     v
+----+-----+     +----------+     +----------+     +----------+
|          |     |          |     |          |     |          |
| CLASSIF. |---->| MARKING  |---->| POLICING/|---->| QUEUING  |
|          |     |          |     | SHAPING  |     |          |
+----------+     +----------+     +----------+     +----------+
     |                |                |                |
     v                v                v                v
 Identifier       Marquer le      Limiter le       Planifier
 le trafic        paquet          debit            l'envoi

CLASSIFICATION - Identifier le type de trafic :
+--------------------------------------------------------------------+
| Critere          | Exemple                                         |
+--------------------------------------------------------------------+
| Adresse IP       | Trafic venant du serveur VoIP 10.1.1.100       |
| Port TCP/UDP     | Port 5060 (SIP), Port 443 (HTTPS)              |
| Protocole        | RTP (Real-time Transport Protocol)              |
| DSCP/CoS         | Valeur deja marquee par l'equipement source     |
| NBAR             | Deep Packet Inspection (identifie l'application)|
+--------------------------------------------------------------------+

MARKING - Marquer le paquet pour les equipements suivants :
+--------------------------------------------------------------------+
| Champ           | Couche | Valeurs importantes                    |
+--------------------------------------------------------------------+
| CoS (802.1p)    | L2     | 0-7 (3 bits dans le tag 802.1Q)       |
|                 |        | 5 = Voice, 3 = Call-signaling         |
| DSCP            | L3     | 0-63 (6 bits dans le champ ToS IP)    |
|                 |        | EF (46) = Expedited Forwarding (voix) |
|                 |        | AF41 (34) = Video conferencing        |
|                 |        | AF21 (18) = Donnees critiques         |
|                 |        | 0 = Best Effort (defaut)              |
| IP Precedence   | L3     | 0-7 (ancien, remplace par DSCP)       |
+--------------------------------------------------------------------+

QUEUING - Files d'attente de sortie :
+--------------------------------------------------------------------+
| Methode          | Description                                     |
+--------------------------------------------------------------------+
| FIFO             | Premier arrive, premier servi (pas de QoS)     |
| Priority Queue   | File prioritaire (voix, video) servie en 1er   |
| CBWFQ            | Bande passante garantie par classe de trafic   |
| LLQ              | CBWFQ + file stricte prioritaire (voix)        |
| WFQ              | Partage equitable pondere                       |
+--------------------------------------------------------------------+
```

### Modele QoS Cisco pour la Voix

```
RECOMMANDATION CISCO POUR VoIP :
+-----------------------------------------------------------------+
| Type de trafic     | DSCP    | CoS | Bande passante            |
+-----------------------------------------------------------------+
| Voice (RTP)        | EF (46) | 5   | Priority queue (< 33%)   |
| Video conferencing | AF41    | 4   | CBWFQ garantie            |
| Call signaling     | CS3     | 3   | CBWFQ garantie            |
| Network control    | CS6     | 6   | CBWFQ garantie            |
| Best effort        | 0       | 0   | Restant                   |
| Scavenger          | CS1     | 1   | Minimum (P2P, streaming)  |
+-----------------------------------------------------------------+

Regle des 33% : le trafic prioritaire ne doit pas depasser 33%
de la bande passante d'un lien pour eviter de bloquer le reste.
```

### Policing vs Shaping

```
POLICING                           SHAPING
+---------------------------+     +---------------------------+
| Trafic                    |     | Trafic                    |
| ########                  |     | ########                  |
| ############ <- Exces     |     | ############ <- Exces     |
| ########                  |     | ########                  |
+---------------------------+     +---------------------------+
         |                                 |
         v                                 v
+---------------------------+     +---------------------------+
| Drop immediat ou          |     | Buffer (mise en file)     |
| Re-marquer les paquets    |     | Puis envoi lisse          |
| en exces                  |     | Retard ajoute, pas de drop|
+---------------------------+     +---------------------------+
         |                                 |
         v                                 v
+---------------------------+     +---------------------------+
| ########                  |     | ########                  |
| ########  (trafic coupe)  |     | ########  (trafic lisse)  |
| ########                  |     | ########                  |
+---------------------------+     +---------------------------+

Resume :
- Policing = drop brutal (utilise en entree, par l'ISP)
- Shaping  = lissage (utilise en sortie, par le client)
```

---

## Questions de Revision

### Niveau Fondamental
1. Nommez 3 technologies WAN broadband.
2. Quelle est la difference entre un VPN site-to-site et remote access ?
3. Que signifie MPLS et quel est son avantage principal ?

### Niveau Intermediaire
1. Expliquez les operations PUSH, SWAP et POP dans MPLS.
2. Quelle est la difference entre ESP et AH dans IPsec ?
3. Pourquoi le MTU PPPoE est 1492 au lieu de 1500 ?

### Niveau Avance
1. Decrivez les etapes IKE Phase 1 et Phase 2 d'une negociation IPsec.
2. Concevez une architecture WAN pour une entreprise avec 1 siege et 5 succursales en utilisant MPLS principal + VPN Internet backup.
3. Expliquez pourquoi GRE est souvent combine avec IPsec et quels sont les avantages de chaque protocole.

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
