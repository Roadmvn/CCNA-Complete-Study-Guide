# VLANs et Trunking - Segmentation Réseau

## **Vue d'Ensemble**

Les VLANs (Virtual Local Area Networks) permettent de segmenter logiquement un réseau physique en plusieurs domaines de broadcast isolés. Le trunking permet de transporter plusieurs VLANs sur une seule liaison.

## **Concepts Fondamentaux**

### **Qu'est-ce qu'un VLAN ?**

```
Réseau Physique Traditionnel :
+-------------------------------------------------------------+
|                    Switch Unique                           |
|  +-----+  +-----+  +-----+  +-----+  +-----+  +-----+    |
|  | PC1 |  | PC2 |  | PC3 |  | PC4 |  | PC5 |  | PC6 |    |
|  +-----+  +-----+  +-----+  +-----+  +-----+  +-----+    |
|                                                             |
| Tous dans le même domaine de broadcast                     |
| = Problèmes de sécurité et performance                     |
+-------------------------------------------------------------+

Segmentation par VLANs :
+-------------------------------------------------------------+
|                Switch avec VLANs                           |
|                                                             |
| VLAN 10 (Sales)    VLAN 20 (IT)     VLAN 30 (Management)  |
| +-----+  +-----+   +-----+  +-----+  +-----+              |
| | PC1 |  | PC2 |   | PC3 |  | PC4 |  | PC5 |              |
| +-----+  +-----+   +-----+  +-----+  +-----+              |
|                                                             |
| 3 domaines de broadcast séparés                            |
| = Sécurité et performance améliorées                       |
+-------------------------------------------------------------+
```

### **Avantages des VLANs**

```
+---------------------+----------------------------------------+
| Avantage            | Explication                            |
+---------------------+----------------------------------------+
| Sécurité            | • Isolation du trafic                 |
|                     | • Contrôle d'accès granulaire         |
+---------------------+----------------------------------------+
| Performance         | • Réduction domaines broadcast        |
|                     | • Optimisation utilisation BP         |
+---------------------+----------------------------------------+
| Flexibilité         | • Groupes logiques vs physiques       |
|                     | • Facilité de gestion                 |
+---------------------+----------------------------------------+
| Économies           | • Moins d'équipements physiques       |
|                     | • Infrastructure partagée             |
+---------------------+----------------------------------------+
```

## **Types de VLANs**

### **Classification par Usage**

```
+-----------------+-------------+--------------------------------+
| Type VLAN       | Plage ID    | Usage Typique                  |
+-----------------+-------------+--------------------------------+
| Data VLAN       | 1-1005      | • Trafic utilisateurs          |
|                 |             | • Applications métier          |
+-----------------+-------------+--------------------------------+
| Voice VLAN      | 1-1005      | • Téléphonie IP                |
|                 |             | • QoS prioritaire              |
+-----------------+-------------+--------------------------------+
| Management VLAN | 1-1005      | • Administration équipements   |
|                 |             | • Monitoring, SNMP             |
+-----------------+-------------+--------------------------------+
| Native VLAN     | Configurable| • Trafic non-tagué sur trunk   |
|                 |             | • Par défaut VLAN 1           |
+-----------------+-------------+--------------------------------+
| Extended VLAN   | 1006-4094   | • Grandes infrastructures      |
|                 |             | • VTP transparent seulement    |
+-----------------+-------------+--------------------------------+
```

### **VLANs Réservés Cisco**

```
VLAN 1      : Default VLAN (tous ports par défaut)
VLAN 1002   : fddi-default  
VLAN 1003   : token-ring-default
VLAN 1004   : fddinet-default
VLAN 1005   : trnet-default
VLAN 4095   : Réservé système

  Bonnes Pratiques :
• Ne jamais utiliser VLAN 1 pour données utilisateur
• Changer native VLAN du défaut (1)
• Utiliser VLAN management dédié
```

## **Types de Ports Switch**

### **Port Access (Mode Access)**

```
Configuration Port Access :
+-------------+      Port Fa0/1      +-------------+
|     PC      |----[Access VLAN 10]---|   Switch    |
|             |     (Non-tagué)       |             |
+-------------+                       +-------------+

Caractéristiques :
• Un seul VLAN par port
• Trafic non-tagué (untagged)
• Utilisé pour équipements finaux
• PC, serveurs, imprimantes
```

**Configuration :**
```cisco
Switch(config)# interface fastethernet 0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# description "PC Sales Department"
Switch(config-if)# exit
```

### **Port Trunk (Mode Trunk)**

```
Configuration Port Trunk :
+-------------+    Port Fa0/24 (Trunk)    +-------------+
|   Switch-A  |-----[VLAN 10,20,30]------|  Switch-B   |
|             |        (Tagué)            |             |
+-------------+                           +-------------+

Caractéristiques :
• Plusieurs VLANs sur un port
• Trafic tagué 802.1Q (sauf native)
• Liaison inter-switches
• Connexions vers routeurs
```

**Configuration :**
```cisco
Switch(config)# interface fastethernet 0/24
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk allowed vlan 10,20,30
Switch(config-if)# switchport trunk native vlan 99
Switch(config-if)# description "Trunk to Switch-B"
Switch(config-if)# exit
```

## **Protocole 802.1Q (Dot1Q)**

### **Structure de la Trame 802.1Q**

```
Trame Ethernet Standard :
+----------+----------+------+---------+-----+
| Dest MAC | Src MAC  | Type | Données | FCS |
| 6 bytes  | 6 bytes  |2 byte| Variable|4 bit|
+----------+----------+------+---------+-----+

Trame 802.1Q (avec tag VLAN) :
+----------+----------+---------+------+---------+-----+
| Dest MAC | Src MAC  |802.1Q Tag| Type | Données | FCS |
| 6 bytes  | 6 bytes  | 4 bytes |2 byte| Variable|4 bit|
+----------+----------+---------+------+---------+-----+

Détail du Tag 802.1Q (4 bytes) :
+---------+-----+--------------+
|  TPID   | TCI |   VLAN ID    |
| 2 bytes | 2 bytes (12 bits) |
+---------+-----+--------------+

TPID = 0x8100 (Tag Protocol Identifier)
TCI  = Tag Control Information
    +- PCP (3 bits) : Priority Code Point
    +- DEI (1 bit)  : Drop Eligible Indicator  
    +- VID (12 bits): VLAN Identifier (0-4095)
```

### **Traitement des Trames**

```
Réception Trame sur Port Trunk :

1. Trame Taguée (802.1Q) :
   +-------------+
   | Trame + Tag | --+
   +-------------+   |
                     v
   +---------------------+
   | Lecture VLAN ID     |
   | Transmission vers   | 
   | ports du VLAN       |
   +---------------------+

2. Trame Non-Taguée :
   +-------------+
   | Trame seule | --+
   +-------------+   |
                     v
   +---------------------+
   | Attribution         |
   | Native VLAN         |
   | (par défaut VLAN 1) |
   +---------------------+

Transmission Trame depuis Port Trunk :

Port de Destination Access :
+-------------+    +--------------+    +-------------+
| Trame +Tag  | --| Suppression  |-- | Trame seule |
|             |    | Tag 802.1Q   |    |             |
+-------------+    +--------------+    +-------------+

Port de Destination Trunk :
+-------------+    +--------------+    +-------------+
| Trame +Tag  | --| Conservation |-- | Trame +Tag  |
|             |    | Tag si ≠     |    |             |
|             |    | Native VLAN  |    |             |
+-------------+    +--------------+    +-------------+
```

## **Configuration des VLANs**

### **Création et Configuration de Base**

```cisco
# Création de VLANs
Switch(config)# vlan 10
Switch(config-vlan)# name Sales
Switch(config-vlan)# exit

Switch(config)# vlan 20  
Switch(config-vlan)# name IT
Switch(config-vlan)# exit

Switch(config)# vlan 30
Switch(config-vlan)# name Servers
Switch(config-vlan)# exit

Switch(config)# vlan 99
Switch(config-vlan)# name Management
Switch(config-vlan)# exit
```

### **Configuration Ports Access**

```cisco
# Configuration individuelle
Switch(config)# interface fastethernet 0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# description "PC Sales-01"
Switch(config-if)# exit

# Configuration par plage
Switch(config)# interface range fastethernet 0/2-8
Switch(config-if-range)# switchport mode access
Switch(config-if-range)# switchport access vlan 10
Switch(config-if-range)# description "Sales Department"
Switch(config-if-range)# exit

Switch(config)# interface range fastethernet 0/9-16
Switch(config-if-range)# switchport mode access
Switch(config-if-range)# switchport access vlan 20
Switch(config-if-range)# description "IT Department"
Switch(config-if-range)# exit
```

### **Configuration Ports Trunk**

```cisco
# Trunk de base
Switch(config)# interface fastethernet 0/24
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk encapsulation dot1q
Switch(config-if)# description "Trunk to Core Switch"
Switch(config-if)# exit

# Trunk avec restrictions
Switch(config)# interface gigabitethernet 0/1
Switch(config-if)# switchport mode trunk
Switch(config-if)# switchport trunk allowed vlan 10,20,30,99
Switch(config-if)# switchport trunk native vlan 99
Switch(config-if)# description "Trunk to Distribution"
Switch(config-if)# exit
```

## **Commandes de Vérification**

### **Vérification VLANs**

```cisco
# Affichage de tous les VLANs
Switch# show vlan brief

VLAN Name                 Status    Ports
---- -------------------- --------- -------------------------------
1    default              active    Fa0/17, Fa0/18, Fa0/19, Fa0/20
                                    Fa0/21, Fa0/22, Fa0/23
10   Sales                active    Fa0/1, Fa0/2, Fa0/3, Fa0/4
20   IT                   active    Fa0/5, Fa0/6, Fa0/7, Fa0/8  
30   Servers              active    Fa0/9, Fa0/10
99   Management           active    

# Détails d'un VLAN spécifique
Switch# show vlan id 10

VLAN Name                 Status    Ports
---- -------------------- --------- -------------------------------
10   Sales                active    Fa0/1, Fa0/2, Fa0/3, Fa0/4

VLAN Type  SAID       MTU   Parent RingNo BridgeNo Stp  BrdgMode Trans1 Trans2
---- ----- ---------- ----- ------ ------ -------- ---- -------- ------ ------
10   enet  100010     1500  -      -      -        -    -        0      0
```

### **Vérification Ports**

```cisco
# État des ports switchport
Switch# show interfaces switchport

Name: Fa0/1
Switchport: Enabled
Administrative Mode: access
Operational Mode: access
Administrative Trunking Encapsulation: dot1q
Operational Trunking Encapsulation: native
Negotiation of Trunking: Off
Access Mode VLAN: 10 (Sales)
Trunking Native Mode VLAN: 1 (default)
Trunking VLANs Enabled: ALL
Trunking VLANs Active: 1,10,20,30,99

# Interface spécifique
Switch# show interfaces fastethernet 0/24 switchport

Name: Fa0/24
Switchport: Enabled
Administrative Mode: trunk
Operational Mode: trunk
Administrative Trunking Encapsulation: dot1q
Operational Trunking Encapsulation: dot1q
Negotiation of Trunking: On
Access Mode VLAN: 1 (default)
Trunking Native Mode VLAN: 99 (Management)
Trunking VLANs Enabled: 10,20,30,99
Trunking VLANs Active: 10,20,30,99
```

### **Vérification Trunk**

```cisco
# Status des trunks
Switch# show interfaces trunk

Port        Mode         Encapsulation  Status        Native vlan
Fa0/24      on           802.1q         trunking      99
Gi0/1       auto         802.1q         trunking      1

Port        Vlans allowed on trunk
Fa0/24      10,20,30,99
Gi0/1       1-4094

Port        Vlans allowed and active in management domain
Fa0/24      10,20,30,99
Gi0/1       1,10,20,30,99

Port        Vlans in spanning tree forwarding state and not pruned
Fa0/24      10,20,30,99
Gi0/1       1,10,20,30,99
```

## **Routing Inter-VLAN**

### **Méthode 1 : Router-on-a-Stick**

```
Topologie Router-on-a-Stick :

+-------------+     Trunk 802.1Q      +-------------+
|   Switch    |-----------------------|   Router    |
|             |   VLANs 10,20,30      |             |
+-------------+                       +-------------+
     |                                 Subinterfaces:
     |                                 • Gi0/0.10 : VLAN 10
+-------------+                        • Gi0/0.20 : VLAN 20  
| PC VLAN 10  |                        • Gi0/0.30 : VLAN 30
| PC VLAN 20  |
| PC VLAN 30  |
+-------------+
```

**Configuration Router :**
```cisco
# Interface physique
Router(config)# interface gigabitethernet 0/0
Router(config-if)# no shutdown
Router(config-if)# exit

# Subinterface VLAN 10
Router(config)# interface gigabitethernet 0/0.10
Router(config-subif)# encapsulation dot1Q 10
Router(config-subif)# ip address 192.168.10.1 255.255.255.0
Router(config-subif)# description "Gateway VLAN 10 - Sales"
Router(config-subif)# exit

# Subinterface VLAN 20
Router(config)# interface gigabitethernet 0/0.20
Router(config-subif)# encapsulation dot1Q 20
Router(config-subif)# ip address 192.168.20.1 255.255.255.0
Router(config-subif)# description "Gateway VLAN 20 - IT"
Router(config-subif)# exit

# Subinterface VLAN 30
Router(config)# interface gigabitethernet 0/0.30
Router(config-subif)# encapsulation dot1Q 30
Router(config-subif)# ip address 192.168.30.1 255.255.255.0
Router(config-subif)# description "Gateway VLAN 30 - Servers"
Router(config-subif)# exit
```

### **Méthode 2 : Switch Layer 3 (SVI)**

```
Switch Layer 3 avec SVIs :

+-------------------------------------------------------------+
|                  Switch Layer 3                            |
|                                                             |
| VLAN 10 <---> SVI 10 (192.168.10.1/24)                      |
| VLAN 20 <---> SVI 20 (192.168.20.1/24)                      |
| VLAN 30 <---> SVI 30 (192.168.30.1/24)                      |
|                                                             |
| Routing inter-VLAN interne                                 |
+-------------------------------------------------------------+
                              |
                    +-------------+
                    |    WAN      |
                    |  Router     |
                    +-------------+
```

**Configuration Switch L3 :**
```cisco
# Activation du routing IP
Switch(config)# ip routing

# Interface VLAN 10 (SVI)
Switch(config)# interface vlan 10
Switch(config-if)# ip address 192.168.10.1 255.255.255.0
Switch(config-if)# description "Gateway for Sales VLAN"
Switch(config-if)# no shutdown
Switch(config-if)# exit

# Interface VLAN 20 (SVI)
Switch(config)# interface vlan 20
Switch(config-if)# ip address 192.168.20.1 255.255.255.0
Switch(config-if)# description "Gateway for IT VLAN"
Switch(config-if)# no shutdown
Switch(config-if)# exit

# Interface VLAN 30 (SVI)
Switch(config)# interface vlan 30
Switch(config-if)# ip address 192.168.30.1 255.255.255.0
Switch(config-if)# description "Gateway for Servers VLAN"
Switch(config-if)# no shutdown
Switch(config-if)# exit
```

## **Dépannage VLANs et Trunking**

### **Problèmes Courants et Solutions**

#### **Problème 1 : Connectivité Intra-VLAN**
```
Symptômes :
• PCs dans même VLAN ne communiquent pas
• Ping échoue entre équipements même VLAN

Diagnostic :
1. Vérifier assignation VLAN des ports
   Switch# show vlan brief
   
2. Vérifier configuration ports
   Switch# show interfaces fa0/1 switchport
   
3. Vérifier état physique
   Switch# show interfaces fa0/1 status

Solutions :
• Port mal configuré en access
• VLAN inexistant ou inactif
• Problème physique (câble, port)
```

#### **Problème 2 : Trunk Non Fonctionnel**
```
Symptômes :
• VLANs ne passent pas entre switches
• Connectivité intermittente

Diagnostic :
1. Vérifier état du trunk
   Switch# show interfaces trunk
   
2. Vérifier négociation DTP
   Switch# show interfaces fa0/24 switchport
   
3. Vérifier VLANs autorisés
   Switch# show interfaces fa0/24 trunk

Solutions :
• Forcer mode trunk (pas auto)
• Vérifier VLANs allowed list
• Problème négociation DTP
• Mismatch native VLAN
```

#### **Problème 3 : Native VLAN Mismatch**
```
Symptômes :
• Messages d'erreur CDP/STP
• Connectivité partielle sur trunk

Diagnostic :
Switch# show interfaces trunk
# Vérifier Native VLAN des deux côtés

Solution :
# Harmoniser native VLAN
Switch(config)# interface fa0/24
Switch(config-if)# switchport trunk native vlan 99
```

### **Outils de Diagnostic**

```cisco
# Tests de connectivité
Switch# ping 192.168.10.1
Switch# ping vlan 10 192.168.10.100

# Monitoring en temps réel
Switch# debug dot1q
Switch# debug sw-vlan vtp events
Switch# debug sw-vlan packets

# Informations détaillées
Switch# show mac address-table vlan 10
Switch# show spanning-tree vlan 10
Switch# show vtp status
```

## **Bonnes Pratiques VLAN**

### **Design et Sécurité**

```
+---------------------+----------------------------------------+
| Pratique            | Justification                          |
+---------------------+----------------------------------------+
| Ne pas utiliser     | • VLAN 1 = trafic management par      |
| VLAN 1 pour données |   défaut                               |
|                     | • Risques sécurité                    |
+---------------------+----------------------------------------+
| Changer Native VLAN | • Éviter attaques VLAN hopping        |
| du défaut           | • Sécuriser trafic non-tagué          |
+---------------------+----------------------------------------+
| Utiliser VLAN       | • Isolation du trafic management      |
| management dédié    | • Sécurité administrative             |
+---------------------+----------------------------------------+
| Limiter VLANs sur   | • Réduire domaine broadcast           |
| trunk               | • Optimiser performance               |
+---------------------+----------------------------------------+
| Documentation       | • Convention nommage claire           |
| cohérente           | • Schémas à jour                      |
+---------------------+----------------------------------------+
```

### **Plan d'Adressage Recommandé**

```
VLAN 10 (Sales)      : 192.168.10.0/24
VLAN 20 (IT)         : 192.168.20.0/24
VLAN 30 (Servers)    : 192.168.30.0/24
VLAN 40 (Voice)      : 192.168.40.0/24
VLAN 50 (WiFi Guest) : 192.168.50.0/24
VLAN 99 (Management) : 192.168.99.0/24

Gateways :
• 192.168.x.1 = Gateway principal
• 192.168.x.2 = Gateway secondaire (HSRP)
• 192.168.x.10-20 = Équipements infrastructure
• 192.168.x.100+ = Utilisateurs/équipements finaux
```

## **Questions de Révision**

### **Concepts de Base**
1. Qu'est-ce qu'un VLAN et pourquoi l'utiliser ?
2. Différence entre port access et trunk ?
3. Comment fonctionne le tagging 802.1Q ?

### **Configuration**
1. Configurez 3 VLANs sur un switch
2. Configurez un trunk avec native VLAN 99
3. Configurez router-on-stick pour 4 VLANs

### **Dépannage**
1. PC ne peut pas pinguer sa gateway - diagnostic ?
2. Trunk ne transporte que VLAN 1 - cause possible ?
3. Comment vérifier qu'un VLAN fonctionne correctement ?

---

**Astuce CCNA :**Maîtrisez parfaitement les commandes show vlan et show interfaces trunk. Elles sont essentielles pour le dépannage quotidien !

---

*Fiche créée pour la révision CCNA*  
*Auteur : Roadmvn*