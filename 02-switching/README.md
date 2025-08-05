# 🔀 Module 2 : Switching & VLANs

## 📋 **Vue d'Ensemble du Module**

Ce module couvre la commutation Ethernet et les VLANs, technologies essentielles de la couche 2. Vous maîtriserez la segmentation réseau, la redondance et l'optimisation du trafic.

## 🎯 **Objectifs d'Apprentissage** *(Semaines 3-4)*

À la fin de ce module, vous serez capable de :

- **Configurer** VLANs et trunking 802.1Q
- **Implémenter** Spanning Tree Protocol (STP)
- **Déployer** EtherChannel pour agrégation de liens
- **Sécuriser** les ports avec port-security
- **Diagnostiquer** problèmes de commutation L2

## 📚 **Contenu du Module**

### **[📖 Fiches de Révision](./fiches/)**
- [VLANs et Trunking](./fiches/vlans-trunking.md)
- [Spanning Tree Protocol](./fiches/spanning-tree.md)
- [EtherChannel](./fiches/etherchannel.md)
- [Sécurité des Ports](./fiches/port-security.md)

### **[🔍 Schémas & Topologies](./schemas/)**
- [Topologies VLAN](./schemas/topologies-vlan.md)
- [Architecture STP](./schemas/architecture-stp.md)
- [Configurations EtherChannel](./schemas/etherchannel-topologies.md)

### **[⚙️ Scripts de Configuration](./scripts/)**
- [Configuration VLANs](./scripts/config-vlans.sh)
- [Setup STP](./scripts/config-stp.sh)
- [Déploiement EtherChannel](./scripts/config-etherchannel.sh)

### **[🎯 Exercices Pratiques](./exercices/)**
- [Labos VLANs](./exercices/labo-vlans.md)
- [Scénarios STP](./exercices/scenarios-stp.md)
- [Tests EtherChannel](./exercices/tests-etherchannel.md)

## ✅ **Checklist de Progression**

### **Semaine 3 : VLANs et Trunking**
- [ ] **VLANs de base** : Création, assignation ports
- [ ] **Trunking 802.1Q** : Configuration, vérification
- [ ] **Routing inter-VLAN** : Router-on-stick, SVI
- [ ] **Troubleshooting** : Problèmes VLAN courants

### **Semaine 4 : STP et Optimisations**
- [ ] **Spanning Tree** : STP, RSTP, PVST+
- [ ] **Optimisation STP** : Root bridge, port cost
- [ ] **EtherChannel** : LACP, PAgP, static
- [ ] **Sécurité L2** : Port-security, BPDU Guard

## 🔧 **Technologies Couvertes**

### **VLANs (Virtual LANs)**
```
┌─────────────────────────────────────────────────────────────┐
│                   VLAN Segmentation                        │
│                                                             │
│ VLAN 10 (Sales)     VLAN 20 (IT)     VLAN 30 (Management) │
│ ┌─────────────┐     ┌─────────────┐   ┌─────────────┐      │
│ │   PC-Sales  │     │    PC-IT    │   │  Management │      │
│ │             │     │             │   │   Station   │      │
│ └─────────────┘     └─────────────┘   └─────────────┘      │
│        │                   │                 │             │
│        └───────────────────┼─────────────────┘             │
│                            │                               │
│                    ┌─────────────┐                         │
│                    │   Switch    │                         │
│                    │   L2/L3     │                         │
│                    └─────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### **Spanning Tree Protocol**
```
Élimination des boucles L2 :

     ┌─────────┐
     │  SW-A   │ (Root Bridge)
     └─────────┘
        │    │
    ┌───┘    └───┐
    │            │
┌─────────┐  ┌─────────┐
│  SW-B   │──│  SW-C   │
└─────────┘  └─────────┘
              Port Blocked
```

### **EtherChannel**
```
Agrégation de bande passante :

Switch-A                    Switch-B
┌─────────┐                ┌─────────┐
│ Port 1  │================│ Port 1  │
│ Port 2  │================│ Port 2  │ EtherChannel
│ Port 3  │================│ Port 3  │ (3 x 1Gbps = 3Gbps)
│ Port 4  │================│ Port 4  │
└─────────┘                └─────────┘
```

## 🛠️ **Outils et Labos Recommandés**

### **Simulations Packet Tracer**
1. **Labo VLAN** : 3 switches, 4 VLANs, inter-VLAN routing
2. **Labo STP** : Topologie avec boucles, optimisation
3. **Labo EtherChannel** : Agrégation de liens redondants
4. **Labo Security** : Port-security, 802.1X

### **Commandes Cisco Essentielles**

#### **VLANs**
```cisco
# Création VLAN
vlan 10
 name Sales
 exit

# Assignation port access
interface fa0/1
 switchport mode access
 switchport access vlan 10
 exit

# Configuration trunk
interface fa0/24
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
 exit
```

#### **STP**
```cisco
# Configuration root bridge
spanning-tree vlan 1 priority 4096

# Optimisation port cost
interface fa0/1
 spanning-tree cost 19
 exit

# Vérification STP
show spanning-tree
show spanning-tree vlan 1
```

#### **EtherChannel**
```cisco
# LACP (dynamique)
interface range fa0/1-2
 channel-group 1 mode active
 exit

# Vérification
show etherchannel summary
show interfaces port-channel 1
```

## 📊 **Scénarios de Dépannage**

### **Problème 1 : VLAN Non Fonctionnel**
```
Symptômes :
• PC dans VLAN 10 ne communique pas
• Autres VLANs fonctionnent

Diagnostic :
1. show vlan brief
2. show interfaces switchport
3. show interfaces trunk

Causes Possibles :
• Port mal assigné au VLAN
• VLAN non autorisé sur trunk
• Erreur de configuration SVI
```

### **Problème 2 : Boucle STP**
```
Symptômes :
• Connectivité intermittente
• Broadcast storms
• CPU élevé sur switches

Diagnostic :
1. show spanning-tree
2. show spanning-tree blockedports
3. debug spanning-tree events

Solution :
• Vérifier câblage physique
• Configurer root bridge optimal
• Activer BPDU Guard
```

## 🎯 **Questions d'Auto-Évaluation**

### **VLANs**
1. Différence entre access et trunk ?
2. Comment fonctionne 802.1Q tagging ?
3. Avantages de la segmentation VLAN ?

### **STP**
1. Pourquoi STP est-il nécessaire ?
2. Comment élire le root bridge ?
3. États des ports STP ?

### **EtherChannel**
1. Différence LACP vs PAgP ?
2. Avantages EtherChannel ?
3. Troubleshooting agrégation échouée ?

## 🚀 **Laboratoires Pratiques**

### **Lab 1 : VLANs Multi-Switches**
```
Objectif : Configurer 3 VLANs sur 2 switches avec trunk

Topologie :
SW1 [Fa0/24] ─── [Fa0/24] SW2
 │                    │
PC1 (VLAN10)      PC2 (VLAN10)
PC3 (VLAN20)      PC4 (VLAN20)

Tâches :
1. Créer VLANs 10, 20, 99
2. Assigner ports access
3. Configurer trunk inter-switches
4. Tester connectivité intra-VLAN
5. Vérifier isolation inter-VLAN
```

### **Lab 2 : Optimisation STP**
```
Objectif : Optimiser STP dans topologie redondante

Topologie en triangle :
    SW1 (Root souhaité)
    /  \
  SW2──SW3

Tâches :
1. Identifier root bridge actuel
2. Forcer SW1 comme root
3. Optimiser coûts des chemins
4. Tester convergence STP
5. Simuler panne et recovery
```

## 📈 **Validation des Compétences**

### **Critères de Maîtrise**
- ✅ **Configuration** : VLANs et trunks sans documentation
- ✅ **Diagnostic** : Identifier problème L2 en 5 minutes
- ✅ **Optimisation** : Ajuster STP pour performance
- ✅ **Sécurité** : Implémenter port-security correctement

### **Mini-Projet Final**
```
Scénario : PME avec 3 départements
• 50 utilisateurs Sales (VLAN 10)
• 30 utilisateurs IT (VLAN 20)  
• 10 serveurs (VLAN 30)
• Management (VLAN 99)

Exigences :
1. Topologie 3 switches avec redondance
2. EtherChannel entre switches core
3. STP optimisé (convergence < 30s)
4. Port-security sur ports utilisateurs
5. Documentation complète
```

## 🔗 **Liens avec Autres Modules**

- **Module 1 (Fondamentaux)** : Couche 2 OSI, adressage
- **Module 3 (Routing)** : Inter-VLAN routing, distribution
- **Module 4 (Services)** : DHCP par VLAN, management
- **Module 5 (Sécurité)** : 802.1X, VLANs de sécurité

## 📞 **Ressources Complémentaires**

- **IEEE 802.1Q** : Standard VLAN tagging
- **IEEE 802.1D** : Spanning Tree Protocol original
- **IEEE 802.1w** : Rapid Spanning Tree (RSTP)
- **IEEE 802.3ad** : Link Aggregation (LACP)

---

**💡 Conseil :** Pratiquez la configuration de VLANs jusqu'à la maîtriser parfaitement. C'est une base quotidienne de l'administration réseau !

---

*Module créé pour la révision CCNA méthodique*  
*Auteur : Tudy Gbaguidi*