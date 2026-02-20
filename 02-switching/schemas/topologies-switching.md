# Topologies Switching - Schemas et Architectures

## Vue d'Ensemble

Cette section presente les topologies de commutation L2 avec des schemas ASCII detailles couvrant STP, EtherChannel, port-security, VLANs multi-switches et la negociation DTP.

---

## Topologie STP Complete

### Election du Root Bridge et Roles des Ports

```
                    Bridge ID = Priority + MAC
                    SW-A: 32768 + AAAA.AAAA.AAAA
                    SW-B: 32768 + BBBB.BBBB.BBBB
                    SW-C: 32768 + CCCC.CCCC.CCCC

                    Root Bridge = SW-A (MAC la plus basse)

                         ┌──────────────────────┐
                         │       SW-A            │
                         │  Bridge ID: 32768     │
                         │  MAC: AAAA.AAAA.AAAA  │
                         │                       │
                         │  **ROOT BRIDGE **     │
                         │                       │
                         │  Fa0/1          Fa0/2 │
                         │  [DP]           [DP]  │
                         └───┬──────────────┬────┘
                             │              │
                   Cost: 19  │              │  Cost: 19
                             │              │
                    ┌────────┴───┐     ┌────┴────────────┐
                    │   SW-B     │     │      SW-C       │
                    │ BID: 32768 │     │  BID: 32768     │
                    │ MAC: BBBB  │     │  MAC: CCCC      │
                    │            │     │                 │
                    │ Fa0/1      │     │ Fa0/1           │
                    │ [RP]       │     │ [RP]            │
                    │            │     │                 │
                    │ Fa0/2      │     │ Fa0/2           │
                    │ [DP]       │     │ [ND/BLK]        │
                    └────┬───────┘     └────┬────────────┘
                         │                  │
                         │    Cost: 19      │
                         └──────────────────┘

Legende des Roles :
[RP]     = Root Port        - Port le plus proche du Root Bridge
[DP]     = Designated Port  - Port qui forwarde vers le segment
[ND/BLK] = Non-Designated   - Port bloque (elimine la boucle)
```

### Flux des BPDUs (Bridge Protocol Data Units)

```
Emission et Propagation des BPDUs :

         ┌──────────────────────┐
         │      SW-A (Root)     │
         │                      │
         │  Emet BPDUs toutes   │
         │  les 2 secondes      │
         │  (Hello Timer)       │
         └───┬──────────────┬───┘
             │              │
   BPDU ─ ─ ▼              ▼ ─ ─ BPDU
   Root ID: SW-A      Root ID: SW-A
   Cost: 0            Cost: 0
   Sender: SW-A       Sender: SW-A
             │              │
    ┌────────┴───┐     ┌────┴────────────┐
    │   SW-B     │     │      SW-C       │
    │            │     │                 │
    │ Recoit     │     │ Recoit          │
    │ BPDU sur   │     │ BPDU sur        │
    │ Fa0/1 (RP) │     │ Fa0/1 (RP)      │
    │            │     │                 │
    │ Relaye     │     │ Relaye          │
    │ BPDU vers  │     │ BPDU vers       │
    │ Fa0/2 (DP) │     │ Fa0/2 (BLK)     │
    └────┬───────┘     └────┬────────────┘
         │                  │
         ▼                  ▼
   BPDU relaye :       BPDU relaye :
   Root ID: SW-A       Root ID: SW-A
   Cost: 19            Cost: 19
   Sender: SW-B        Sender: SW-C

   SW-C compare les BPDUs recus sur Fa0/2 :
   - Via SW-B : Cost 19, Sender BID = BBBB (plus bas)
   - Via direct : Cost 19, Sender BID = CCCC (plus haut)
   => Fa0/2 de SW-C passe en BLOCKED
```

### Etats des Ports STP (Port States)

```
Transition des Etats d'un Port STP :

┌──────────┐   Lien    ┌──────────┐  Forward   ┌──────────┐
│ DISABLED │──actif───│ BLOCKING │──Delay────│LISTENING │
│          │           │          │  (20s)     │          │
│ Port off │           │ Recoit   │            │ Envoie   │
│ Pas de   │           │ BPDUs    │            │ et recoit│
│ BPDU     │           │ seulement│            │ BPDUs    │
└──────────┘           └──────────┘            └─────┬────┘
                                                     │
                                              Forward Delay
                                                 (15s)
                                                     │
                                                     ▼
┌──────────┐                                   ┌──────────┐
│FORWARDING│────────── Forward Delay ─────────│ LEARNING │
│          │               (15s)               │          │
│ Envoie/  │                                   │ Apprend  │
│ recoit   │                                   │ adresses │
│ donnees  │                                   │ MAC      │
│ + BPDUs  │                                   │ + BPDUs  │
└──────────┘                                   └──────────┘

Temps de convergence total STP classique :
Blocking → Listening → Learning → Forwarding
            15s          15s
         = 30 secondes minimum (si port DP ou RP)
         = 50 secondes maximum (avec Max Age 20s)
```

---

## Topologie EtherChannel

### Agregation LACP et PAgP

```
Configuration LACP (IEEE 802.3ad) :

Switch-A                                              Switch-B
┌──────────────────────┐                    ┌──────────────────────┐
│                      │                    │                      │
│  Port-Channel 1      │                    │  Port-Channel 1      │
│  Mode: LACP active   │                    │  Mode: LACP active   │
│                      │                    │                      │
│  Gi0/1 ═══════════════════════════════════ Gi0/1                │
│  Gi0/2 ═══════════════════════════════════ Gi0/2                │
│  Gi0/3 ═══════════════════════════════════ Gi0/3                │
│  Gi0/4 ═══════════════════════════════════ Gi0/4                │
│                      │                    │                      │
│  Bande Passante :    │                    │  Bande Passante :    │
│  4 x 1 Gbps         │                    │  4 x 1 Gbps         │
│  = 4 Gbps logique    │                    │  = 4 Gbps logique    │
│                      │                    │                      │
│  STP voit 1 seul     │                    │  STP voit 1 seul     │
│  lien logique        │                    │  lien logique        │
└──────────────────────┘                    └──────────────────────┘

Comparaison LACP vs PAgP :

┌──────────────────┬───────────────────┬───────────────────┐
│ Critere          │ LACP (802.3ad)    │ PAgP (Cisco)      │
├──────────────────┼───────────────────┼───────────────────┤
│ Standard         │ IEEE ouvert       │ Cisco proprietaire│
│ Modes            │ active / passive  │ desirable / auto  │
│ Max liens        │ 16 (8 actifs)     │ 8                 │
│ Interoperabilite │ Multi-vendeur     │ Cisco uniquement  │
│ Recommandation   │ Prefere           │ Legacy            │
└──────────────────┴───────────────────┴───────────────────┘
```

### Load Balancing EtherChannel

```
Methodes de Load Balancing :

src-mac :
┌─────────┐                              ┌─────────┐
│  PC-A   │──(MAC A)── Gi0/1 ══════════│         │
│  PC-B   │──(MAC B)── Gi0/2 ══════════│ Switch-B│
│  PC-C   │──(MAC C)── Gi0/3 ══════════│         │
│  PC-D   │──(MAC D)── Gi0/4 ══════════│         │
└─────────┘                              └─────────┘
  Chaque source MAC utilise un lien different (hash)

dst-mac :
  Le hash est fait sur l'adresse MAC de destination

src-dst-mac :
  Le hash combine source + destination MAC
  = Meilleure repartition dans la majorite des cas

src-dst-ip :
  Le hash combine source + destination IP
  = Recommande pour les reseaux roules

┌───────────────────────────────────────────────────────────┐
│ Methode         │ Commande                                │
├─────────────────┼─────────────────────────────────────────┤
│ src-mac         │ port-channel load-balance src-mac       │
│ dst-mac         │ port-channel load-balance dst-mac       │
│ src-dst-mac     │ port-channel load-balance src-dst-mac   │
│ src-ip          │ port-channel load-balance src-ip        │
│ dst-ip          │ port-channel load-balance dst-ip        │
│ src-dst-ip      │ port-channel load-balance src-dst-ip    │
└─────────────────┴─────────────────────────────────────────┘
```

---

## Schema Port-Security

### Modes de Violation et Table MAC

```
Port-Security - Fonctionnement :

┌─────────────────────────────────────────────────────────────┐
│                        SWITCH                               │
│                                                             │
│  Table MAC securisee du port Fa0/1 :                       │
│  ┌────────────────────────┬──────────┬────────────────┐    │
│  │ Adresse MAC            │ Type     │ VLAN           │    │
│  ├────────────────────────┼──────────┼────────────────┤    │
│  │ AAAA.BBBB.CCCC         │ Static   │ 10             │    │
│  │ DDDD.EEEE.FFFF         │ Sticky   │ 10             │    │
│  │ (max 2 MAC autorisees) │          │                │    │
│  └────────────────────────┴──────────┴────────────────┘    │
│                                                             │
│  Fa0/1 [port-security]                                     │
│  ├── maximum : 2                                           │
│  ├── violation : shutdown                                   │
│  └── mac-address sticky                                    │
│        │                                                   │
└────────┼───────────────────────────────────────────────────┘
         │
    ┌────┴─────────────────────────────────────┐
    │                                          │
    ▼                                          ▼
┌─────────┐ MAC connue              ┌─────────┐ MAC inconnue
│  PC-A   │ AAAA.BBBB.CCCC         │ PC-X    │ XXXX.XXXX.XXXX
│         │ = AUTORISE              │ Intrus  │ = VIOLATION !
└─────────┘                         └─────────┘


Modes de Violation :

┌──────────┬───────────┬───────────┬──────────┬──────────────┐
│ Mode     │ Trafic    │ Compteur  │ Log/SNMP │ Action Port  │
├──────────┼───────────┼───────────┼──────────┼──────────────┤
│ protect  │ Drop      │ Non       │ Non      │ Reste up     │
│          │ silencieux│           │          │              │
├──────────┼───────────┼───────────┼──────────┼──────────────┤
│ restrict │ Drop      │ Oui       │ Oui      │ Reste up     │
│          │ + alerte  │ incremente│ syslog   │              │
├──────────┼───────────┼───────────┼──────────┼──────────────┤
│ shutdown │ Drop      │ Oui       │ Oui      │ err-disabled │
│ (defaut) │ total     │ incremente│ syslog   │ Port DOWN    │
└──────────┴───────────┴───────────┴──────────┴──────────────┘


Diagramme de Decision Port-Security :

  Trame recue sur port securise
         │
         ▼
  ┌──────────────┐
  │ MAC source   │
  │ dans table ? │
  └──────┬───────┘
         │
    ┌────┴────┐
    │         │
   OUI       NON
    │         │
    ▼         ▼
┌────────┐  ┌──────────────┐
│FORWARD │  │ Nb MAC <     │
│ trame  │  │ maximum ?    │
└────────┘  └──────┬───────┘
                   │
              ┌────┴────┐
              │         │
             OUI       NON
              │         │
              ▼         ▼
        ┌──────────┐  ┌──────────────┐
        │ Apprend  │  │ VIOLATION !  │
        │ nouvelle │  │ Action selon │
        │ MAC      │  │ mode config  │
        │ (sticky/ │  │ (protect/    │
        │  dynamic)│  │  restrict/   │
        └──────────┘  │  shutdown)   │
                      └──────────────┘
```

---

## Topologie Multi-Switch avec VLANs et Trunks

### Infrastructure 3 Switches Interconnectes

```
                        ┌─────────────────────────┐
                        │        SW-CORE          │
                        │    (Distribution)        │
                        │                          │
                        │  VLAN 10: Sales          │
                        │  VLAN 20: IT             │
                        │  VLAN 30: Servers        │
                        │  VLAN 99: Management     │
                        │                          │
                        │  SVI VLAN 10: .10.1/24   │
                        │  SVI VLAN 20: .20.1/24   │
                        │  SVI VLAN 30: .30.1/24   │
                        │  SVI VLAN 99: .99.1/24   │
                        │                          │
                        │  Gi0/1         Gi0/2     │
                        │  [Trunk]       [Trunk]   │
                        └───┬─────────────┬────────┘
                            │             │
              Trunk 802.1Q  │             │  Trunk 802.1Q
              VLANs 10,20,  │             │  VLANs 10,20,
              30,99         │             │  30,99
              Native: 99    │             │  Native: 99
                            │             │
              ┌─────────────┴──┐     ┌────┴─────────────┐
              │   SW-ACCESS-1  │     │   SW-ACCESS-2    │
              │                │     │                  │
              │  Gi0/1 [Trunk] │     │  Gi0/1 [Trunk]   │
              │                │     │                  │
              │  Fa0/1-8       │     │  Fa0/1-8         │
              │  [Access]      │     │  [Access]        │
              │  VLAN 10       │     │  VLAN 10         │
              │                │     │                  │
              │  Fa0/9-16      │     │  Fa0/9-16        │
              │  [Access]      │     │  [Access]        │
              │  VLAN 20       │     │  VLAN 20         │
              │                │     │                  │
              │  Fa0/17-20     │     │  Fa0/17-20       │
              │  [Access]      │     │  [Access]        │
              │  VLAN 30       │     │  VLAN 30         │
              └──┬───┬───┬─────┘     └──┬───┬───┬──────┘
                 │   │   │              │   │   │
                 │   │   │              │   │   │
              ┌──┘   │   └──┐        ┌──┘   │   └──┐
              │      │      │        │      │      │
           ┌──┴──┐┌──┴──┐┌──┴──┐  ┌──┴──┐┌──┴──┐┌──┴──┐
           │PC-S1││PC-I1││SRV-1│  │PC-S2││PC-I2││SRV-2│
           │VL10 ││VL20 ││VL30 │  │VL10 ││VL20 ││VL30 │
           └─────┘└─────┘└─────┘  └─────┘└─────┘└─────┘

Plan d'Adressage :
┌──────────┬────────────────────┬──────────────────┐
│ VLAN     │ Reseau             │ Gateway          │
├──────────┼────────────────────┼──────────────────┤
│ 10 Sales │ 192.168.10.0/24    │ 192.168.10.1     │
│ 20 IT    │ 192.168.20.0/24    │ 192.168.20.1     │
│ 30 Servers│ 192.168.30.0/24   │ 192.168.30.1     │
│ 99 Mgmt  │ 192.168.99.0/24    │ 192.168.99.1     │
└──────────┴────────────────────┴──────────────────┘
```

### Flux de Trafic Inter-VLAN

```
Communication entre PC-S1 (VLAN 10) et SRV-1 (VLAN 30) :

PC-S1                SW-ACCESS-1          SW-CORE              SW-ACCESS-1       SRV-1
(192.168.10.10)                       (Router L3)                             (192.168.30.10)
     │                    │                │                        │              │
     │  1. Trame non      │                │                        │              │
     │  taguee             │                │                        │              │
     ├───────────────────│                │                        │              │
     │  Dst: GW MAC       │                │                        │              │
     │  Src: PC-S1 MAC    │                │                        │              │
     │                    │  2. Tag VLAN 10│                        │              │
     │                    │  sur trunk     │                        │              │
     │                    ├───────────────│                        │              │
     │                    │                │  3. Route inter-VLAN   │              │
     │                    │                │  SVI 10 → SVI 30       │              │
     │                    │                │  Reecrit MAC src/dst   │              │
     │                    │                │                        │              │
     │                    │                │  4. Tag VLAN 30        │              │
     │                    │                │  sur trunk             │              │
     │                    │                ├───────────────────────│              │
     │                    │                │                        │  5. Retire   │
     │                    │                │                        │  tag, forward│
     │                    │                │                        ├─────────────│
     │                    │                │                        │              │
```

---

## Schema DTP (Dynamic Trunking Protocol)

### Matrice de Negociation DTP

```
Resultat de la negociation DTP entre deux ports :

┌────────────┬────────────┬────────────┬────────────┬────────────┐
│ SW-A \ SW-B│  dynamic   │  dynamic   │   trunk    │   access   │
│            │  auto      │  desirable │            │            │
├────────────┼────────────┼────────────┼────────────┼────────────┤
│ dynamic    │            │            │            │            │
│ auto       │  ACCESS    │  TRUNK     │  TRUNK     │  ACCESS    │
├────────────┼────────────┼────────────┼────────────┼────────────┤
│ dynamic    │            │            │            │            │
│ desirable  │  TRUNK     │  TRUNK     │  TRUNK     │  ACCESS    │
├────────────┼────────────┼────────────┼────────────┼────────────┤
│ trunk      │  TRUNK     │  TRUNK     │  TRUNK     │ INCOMPATIBLE│
│            │            │            │            │  (erreur)  │
├────────────┼────────────┼────────────┼────────────┼────────────┤
│ access     │  ACCESS    │  ACCESS    │INCOMPATIBLE│  ACCESS    │
│            │            │            │  (erreur)  │            │
└────────────┴────────────┴────────────┴────────────┴────────────┘

Legende :
- dynamic auto     : Attend une demande, ne l'initie pas
- dynamic desirable: Initie activement la negociation trunk
- trunk            : Force le trunk, envoie DTP
- access           : Force l'access, pas de DTP

Bonne Pratique Securite :
switchport nonegotiate   ← Desactive DTP (recommande)


Schema de Negociation :

SW-A (desirable)                          SW-B (auto)
┌──────────────┐                         ┌──────────────┐
│ Envoie DTP   │────── DTP Request ─────│ Recoit DTP   │
│ "Je veux     │                         │ "OK, je      │
│  trunk"      │                         │  passe en    │
│              │──── DTP Response ──────│  trunk"      │
│ TRUNK actif  │                         │ TRUNK actif  │
└──────────────┘                         └──────────────┘

SW-A (auto)                               SW-B (auto)
┌──────────────┐                         ┌──────────────┐
│ Attend DTP   │                         │ Attend DTP   │
│ Personne     │                         │ Personne     │
│ n'initie     │         (silence)       │ n'initie     │
│              │                         │              │
│ ACCESS mode  │                         │ ACCESS mode  │
└──────────────┘                         └──────────────┘
```

---

## Topologie Complete avec EtherChannel et STP

### Infrastructure Enterprise

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CORE / DISTRIBUTION                         │
│                                                                     │
│    ┌──────────────────┐           ┌──────────────────┐             │
│    │    SW-CORE-1     │           │    SW-CORE-2     │             │
│    │  Root Bridge     │           │  Backup Root     │             │
│    │  Priority: 4096  │           │  Priority: 8192  │             │
│    │                  │           │                  │             │
│    │  Po1       Po2   │           │  Po1       Po2   │             │
│    └──┬─────────┬─────┘           └──┬─────────┬─────┘             │
│       ║         ║                    ║         ║                   │
│       ║ EtherChannel               ║ EtherChannel                │
│       ║ LACP (2xGi)                ║ LACP (2xGi)                 │
│       ║         ║                    ║         ║                   │
│       ║         ║    EtherChannel    ║         ║                   │
│       ║         ║═══Po3 (4xGi)══════║         ║                   │
│       ║         ║    Inter-Core      ║         ║                   │
└───────║─────────║────────────────────║─────────║───────────────────┘
        ║         ║                    ║         ║
┌───────║─────────║────────────────────║─────────║───────────────────┐
│       ║   ACCESS LAYER              ║         ║                   │
│       ║         ║                    ║         ║                   │
│  ┌────╨─────────╨────┐          ┌────╨─────────╨────┐             │
│  │   SW-ACCESS-1     │          │   SW-ACCESS-2     │             │
│  │                   │          │                   │             │
│  │  Po1 (→Core-1)   │          │  Po1 (→Core-1)   │             │
│  │  Po2 (→Core-2)   │          │  Po2 (→Core-2)   │             │
│  │                   │          │                   │             │
│  │  Fa0/1-8  VLAN 10 │          │  Fa0/1-8  VLAN 10 │             │
│  │  Fa0/9-16 VLAN 20 │          │  Fa0/9-16 VLAN 20 │             │
│  │  Fa0/17-24 VLAN 30│          │  Fa0/17-24 VLAN 30│             │
│  │                   │          │                   │             │
│  │  Port-Security:   │          │  Port-Security:   │             │
│  │  max 2, shutdown  │          │  max 2, shutdown  │             │
│  │  PortFast: enable │          │  PortFast: enable │             │
│  │  BPDU Guard: on   │          │  BPDU Guard: on   │             │
│  └───────────────────┘          └───────────────────┘             │
│       │   │   │                      │   │   │                    │
│      PC  PC  SRV                    PC  PC  SRV                   │
└───────────────────────────────────────────────────────────────────┘

STP Convergence dans cette topologie :
- SW-CORE-1 = Root Bridge (priority 4096)
- SW-CORE-2 = Backup Root (priority 8192)
- Tous les Po vers Core-1 = Root Ports sur access
- Tous les Po vers Core-2 = Alternate Ports (RSTP)
- Po3 inter-core = Designated sur Core-1, Root sur Core-2
```

---

## Questions de Revision

### Topologies

1. Dans le schema STP, pourquoi Fa0/2 de SW-C est bloque et pas Fa0/2 de SW-B ?
2. Combien de BPDUs le Root Bridge envoie-t-il par seconde ?
3. Quel est le temps de convergence STP classique d'un port bloque vers forwarding ?

### EtherChannel

4. Pourquoi STP voit-il un EtherChannel comme un seul lien logique ?
5. Quelle methode de load balancing est la plus equilibree pour du trafic route ?
6. Que se passe-t-il si un lien physique du bundle tombe ?

### Port-Security

7. Difference entre les modes protect, restrict et shutdown ?
8. Un port en mode sticky apprend automatiquement les MACs. Ou sont-elles stockees ?
9. Comment reactiver un port en etat err-disabled ?

### Reponses

1. Le Bridge ID de SW-B (MAC BBBB) est inferieur a celui de SW-C (MAC CCCC). Le port de SW-C recoit un BPDU superieur de SW-B, donc SW-C bloque son port.
2. Un BPDU toutes les 2 secondes (Hello Timer par defaut).
3. 30 secondes minimum (Listening 15s + Learning 15s), jusqu'a 50s avec Max Age.
4. STP calcule un seul cout et un seul port ID pour le port-channel. Cela evite que STP bloque des liens individuels du bundle.
5. src-dst-ip offre la meilleure repartition car elle utilise les deux adresses IP pour le hash.
6. Le trafic est redistribue sur les liens restants. La bande passante totale diminue mais la connectivite est maintenue.
7. protect = drop silencieux, restrict = drop + log + compteur, shutdown = port err-disabled (down complet).
8. En running-config. Il faut faire "copy run start" pour les persister dans startup-config.
9. Commandes : `shutdown` puis `no shutdown` sur le port, ou `errdisable recovery cause psecure-violation` pour auto-recovery.

---

*Schemas crees pour la revision CCNA*
*Auteur : Roadmvn*
