# Architecture Réseau - Schémas et Topologies

## **Vue d'Ensemble**

Cette section présente les architectures réseau fondamentales avec des schémas ASCII détaillés pour comprendre visuellement les concepts de base de la CCNA.

## **Modèle Réseau Hiérarchique à 3 Niveaux**

### **Architecture Traditionnelle Cisco**

```
+-------------------------------------------------------------+
|                    CORE LAYER                              |
|                 (Commutation Rapide)                       |
|                                                             |
|  +-------------+              +-------------+              |
|  |   Core-01   |=============|   Core-02   |              |
|  |  Switch L3  |              |  Switch L3  |              |
|  +-------------+              +-------------+              |
|         |                           |                      |
|         |                           |                      |
+---------|---------------------------|----------------------+
          |                           |
+---------|---------------------------|----------------------+
|         |     DISTRIBUTION LAYER    |                      |
|         |    (Routage et Politiques)|                      |
|         |                           |                      |
|  +-------------+              +-------------+              |
|  |   Dist-01   |=============|   Dist-02   |              |
|  |  Switch L3  |              |  Switch L3  |              |
|  +-------------+              +-------------+              |
|         |                           |                      |
|         |                           |                      |
+---------|---------------------------|----------------------+
          |                           |
+---------|---------------------------|----------------------+
|         |      ACCESS LAYER         |                      |
|         |   (Connectivité Finale)   |                      |
|         |                           |                      |
|  +-------------+              +-------------+              |
|  |   Acc-01    |--------------|   Acc-02    |              |
|  |  Switch L2  |              |  Switch L2  |              |
|  +-------------+              +-------------+              |
|         |                           |                      |
|    +----+----+                 +---+----+                  |
|    | PC-01   |                 | PC-02  |                  |
|    |         |                 |        |                  |
|    +---------+                 +--------+                  |
+-------------------------------------------------------------+

Légende :
=== Liens haute bande passante (Gigabit/10G)
--- Liens standard (FastEthernet/Gigabit)
|   Liens de redondance
```

### **Rôles par Couche**

```
+-----------------+--------------------------------------------+
| CORE            | • Commutation rapide (hardware)           |
| (Cœur)          | • Redondance maximale                     |
|                 | • Pas de traitement de politiques         |
|                 | • Topologie maillée                       |
+-----------------+--------------------------------------------+
| DISTRIBUTION    | • Routage inter-VLAN                      |
| (Distribution)  | • Application politiques (ACL, QoS)       |
|                 | • Agrégation trafic access                |
|                 | • Point de contrôle sécurité              |
+-----------------+--------------------------------------------+
| ACCESS          | • Connectivité utilisateurs finaux        |
| (Accès)         | • VLANs et sécurité ports                 |
|                 | • PoE pour téléphones/WiFi                |
|                 | • Port-security                           |
+-----------------+--------------------------------------------+
```

## **Modèle Collapsed Core (PME)**

### **Architecture Simplifiée 2 Niveaux**

```
+-------------------------------------------------------------+
|              DISTRIBUTION/CORE LAYER                       |
|            (Fonctions Combinées)                           |
|                                                             |
|  +-------------+              +-------------+              |
|  |   Core-01   |=============|   Core-02   |              |
|  | L3 Switch   |              | L3 Switch   |              |
|  | + Routage   |              | + Routage   |              |
|  | + ACLs      |              | + ACLs      |              |
|  +-------------+              +-------------+              |
|         |                           |                      |
|         |                           |                      |
+---------|---------------------------|----------------------+
          |                           |
+---------|---------------------------|----------------------+
|         |        ACCESS LAYER       |                      |
|         |                           |                      |
|  +-------------+              +-------------+              |
|  |   Acc-01    |--------------|   Acc-02    |              |
|  |  Switch L2  |              |  Switch L2  |              |
|  +-------------+              +-------------+              |
|    |    |    |                   |    |    |                |
|   PC1  PC2  PC3                PC4  PC5  PC6               |
+-------------------------------------------------------------+

Avantages :
• Coût réduit (moins d'équipements)
• Gestion simplifiée
• Adapté PME (< 500 utilisateurs)

Inconvénients :
• Scalabilité limitée
• Point de défaillance unique
• Performance réduite si surcharge
```

## **Topologies de Connectivité**

### **Topologie Étoile (Star)**

```
                    +-------------+
                    |   Switch    |
                    |   Central   |
                    +-------------+
                           |
            +--------------+--------------+
            |              |              |
      +---------+    +---------+    +---------+
      |  PC-A   |    |  PC-B   |    |  PC-C   |
      +---------+    +---------+    +---------+

Avantages :
• Facile à installer et configurer
• Centralisé (gestion simplifiée)
• Une panne affecte qu'un équipement

Inconvénients :
• Point unique de défaillance (switch)
• Coût en câblage
• Performance limitée par switch central
```

### **Topologie Maillée (Mesh)**

```
      +---------+              +---------+
      |Router-A |--------------|Router-B |
      +---------+              +---------+
           |  ╲              ╱  |
           |    ╲          ╱    |
           |      ╲      ╱      |
           |        ╲  ╱        |
           |          ╱╲        |
           |        ╱    ╲      |
           |      ╱        ╲    |
           |    ╱            ╲  |
           |  ╱                ╲|
      +---------+              +---------+
      |Router-C |--------------|Router-D |
      +---------+              +---------+

Maillage Complet (Full Mesh) :
• Chaque nœud connecté à tous les autres
• Redondance maximale
• Coût élevé : n(n-1)/2 liens

Maillage Partiel (Partial Mesh) :
• Connectivité sélective
• Compromis coût/redondance
• Plus courant en pratique
```

## **Architecture Campus Enterprise**

### **Design Typique Grande Entreprise**

```
                        +-------------+
                        |  Internet   |
                        +-------------+
                               |
                        +-------------+
                        |   Router    |
                        |   WAN/ISP   |
                        +-------------+
                               |
+-------------------------------------------------------------+
|                    CORE CAMPUS                              |
|                                                             |
|  +-------------+              +-------------+              |
|  |   Core-A    |=============|   Core-B    |              |
|  |   6500/9K   |              |   6500/9K   |              |
|  +-------------+              +-------------+              |
+-------------------------------------------------------------+
          |                           |
          |                           |
+---------|---------------------------|----------------------+
|         |      DISTRIBUTION         |                      |
|         |                           |                      |
|  +-------------+              +-------------+              |
|  |   Dist-1    |==============|   Dist-2    |              |
|  |   4500/9K   |              |   4500/9K   |              |
|  +-------------+              +-------------+              |
+-------------------------------------------------------------+
     |        |                      |        |
     |        |                      |        |
+----|--------|----------------------|--------|------------+
|    |   ACCESS BLOCK 1         ACCESS BLOCK 2   |        |
|    |                                           |        |
| +------+ +------+              +------+ +------+        |
| |Acc-1A| |Acc-1B|              |Acc-2A| |Acc-2B|        |
| |2960  | |2960  |              |2960  | |2960  |        |
| +------+ +------+              +------+ +------+        |
|    |       |                      |       |            |
|   Users   Users                  Users   Users          |
|  Bldg-A   Bldg-A                Bldg-B   Bldg-B         |
+-------------------------------------------------------------+
```

## **Architecture WAN Entreprise**

### **Connectivité Multi-Sites**

```
                        +-------------+
                        |  Internet   |
                        |   Public    |
                        +-------------+
                               |
                        +-------------+
                        |   MPLS      |
                        |  Provider   |
                        |   Network   |
                        +-------------+
                               |
            +------------------+------------------+
            |                  |                  |
     +-------------+    +-------------+    +-------------+
     |    HQ       |    |   Branch    |    |   Branch    |
     |   (Siège)   |    |   Site-A    |    |   Site-B    |
     |             |    |             |    |             |
     |  Core/Dist  |    |   Router    |    |   Router    |
     |  + Serveurs |    |   + Switch  |    |   + WiFi    |
     |             |    |             |    |             |
     +-------------+    +-------------+    +-------------+
           |                    |                    |
      Data Center        Utilisateurs         Utilisateurs
      + Applications       Locaux              Locaux

Connectivité :
• MPLS (principal)
• Internet VPN (backup)
• Liaison dédiée critique
• 4G/5G (secours mobile)
```

## **Redondance et Haute Disponibilité**

### **Modèle HSR (Hot Standby Routing)**

```
                    +-------------+
                    |  Internet   |
                    +-------------+
                           |
                    +-------------+
                    |   ISP       |
                    |   Router    |
                    +-------------+
                           |
            +--------------+--------------+
            |              |              |
     +-------------+              +-------------+
     |  Router-1   |              |  Router-2   |
     |  (Primary)  |==============| (Standby)   |
     |   HSRP      |              |   HSRP      |
     +-------------+              +-------------+
            |                              |
            |         Virtual IP           |
            |       192.168.1.1           |
            |    (Gateway Partagée)        |
            +--------------+---------------+
                           |
                    +-------------+
                    |   Switch    |
                    |   Access    |
                    +-------------+
                           |
                +----------+----------+
                |          |          |
           +---------+ +---------+ +---------+
           |  PC-1   | |  PC-2   | |  PC-3   |
           |.1.10/24 | |.1.20/24 | |.1.30/24 |
           +---------+ +---------+ +---------+

Configuration Gateway : 192.168.1.1 (IP Virtuelle)
• Router-1 : IP physique .2, priorité 110 (Master)
• Router-2 : IP physique .3, priorité 100 (Backup)
• Basculement automatique si panne Router-1
```

## **Design de Segmentation VLAN**

### **Séparation par Fonction**

```
+-------------------------------------------------------------+
|                 SWITCH CORE L3                              |
|                                                             |
|  VLAN 10 - Management    : 10.1.10.0/24                   |
|  VLAN 20 - Utilisateurs  : 10.1.20.0/24                   |
|  VLAN 30 - Serveurs      : 10.1.30.0/24                   |
|  VLAN 40 - VoIP          : 10.1.40.0/24                   |
|  VLAN 50 - WiFi Invités  : 10.1.50.0/24                   |
|                                                             |
+-------------------------------------------------------------+
                               |
                        +-------------+
                        |   Switch    |
                        |   Access    |
                        +-------------+
                               |
        +----------------------+----------------------+
        |                      |                      |
 +-------------+        +-------------+        +-------------+
 |    PC       |        |  IP Phone   |        | WiFi Access |
 |  VLAN 20    |        |  VLAN 40    |        |   Point     |
 | (Data)      |        |   (Voice)   |        |  VLAN 50    |
 +-------------+        +-------------+        +-------------+

Ports Access Switch :
• Port 1-8   : VLAN 20 (Utilisateurs)
• Port 9-16  : VLAN 30 (Serveurs)  
• Port 17-24 : VLAN 40 (VoIP)
• Port 25-48 : VLAN 20 + Voice VLAN 40
```

## **Bonnes Pratiques Architecture**

### **Principes de Design**

```
+---------------------+----------------------------------------+
| Principe            | Application                            |
+---------------------+----------------------------------------+
| Hiérarchie          | • Core/Distribution/Access            |
|                     | • Séparation des fonctions            |
+---------------------+----------------------------------------+
| Redondance          | • Dual-homing critical links          |
|                     | • HSRP/VRRP pour gateways             |
+---------------------+----------------------------------------+
| Scalabilité         | • Modularité (ajout facile)           |
|                     | • Standards et documentation          |
+---------------------+----------------------------------------+
| Sécurité            | • Segmentation par VLAN               |
|                     | • ACLs aux points de contrôle         |
+---------------------+----------------------------------------+
| Performance         | • Liens haute bande passante          |
|                     | • QoS pour trafic critique            |
+---------------------+----------------------------------------+
```

## **Questions de Révision**

### **Architecture**
1. Quels sont les 3 niveaux du modèle hiérarchique Cisco ?
2. Avantages/inconvénients du Collapsed Core ?
3. Différence entre Full Mesh et Partial Mesh ?

### **Design**
1. Comment assurer la redondance au niveau Core ?
2. Où placer les ACLs dans l'architecture ?
3. Plan d'adressage pour 5 VLANs de 100 utilisateurs ?

### **Mise en Œuvre**
1. Configurez HSRP entre 2 routeurs
2. Dessinez une architecture pour 500 utilisateurs
3. Dépannez une coupure de liaison redondante

---

**Astuce CCNA :**Comprenez d'abord l'architecture avant de plonger dans les détails techniques. La vue d'ensemble est cruciale !

---

*Schémas créés pour la révision CCNA*  
*Auteur : Roadmvn*