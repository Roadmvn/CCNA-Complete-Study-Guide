# 🌐 Module 1 : Fondamentaux Réseau

## 📋 **Vue d'Ensemble du Module**

Ce module couvre les bases essentielles des réseaux informatiques, fondement de toute expertise réseau. Vous maîtriserez les concepts théoriques et pratiques indispensables à la CCNA.

## 🎯 **Objectifs d'Apprentissage** *(Semaines 1-2)*

À la fin de ce module, vous serez capable de :

- **Expliquer** le modèle OSI et TCP/IP avec des exemples concrets
- **Calculer** des sous-réseaux IPv4/IPv6 efficacement  
- **Configurer** l'adressage IP sur équipements Cisco
- **Diagnostiquer** problèmes de connectivité de base
- **Implémenter** protocoles ARP, ICMP, DHCP, DNS

## 📚 **Contenu du Module**

### **[📖 Fiches de Révision](./fiches/)**
- [Modèle OSI - 7 Couches](./fiches/modele-osi.md)
- [Adressage IPv4 & IPv6](./fiches/adressage-ip.md)
- [Sous-réseaux & VLSM](./fiches/sous-reseaux.md)
- [Protocoles de Base](./fiches/protocoles-base.md)

### **[🔍 Schémas & Topologies](./schemas/)**
- [Architecture Réseau Générale](./schemas/architecture-reseau.md)
- [Flux de Communication](./schemas/flux-communication.md)
- [Topologies de Base](./schemas/topologies.md)

### **[⚙️ Scripts de Configuration](./scripts/)**
- [Configuration IP de Base](./scripts/config-ip-base.sh)
- [Tests de Connectivité](./scripts/tests-connectivite.sh)
- [Configuration DHCP](./scripts/config-dhcp.sh)

### **[🎯 Exercices Pratiques](./exercices/)**
- [Calculs de Sous-réseaux](./exercices/calculs-sous-reseaux.md)
- [Configuration d'Adressage](./exercices/config-adressage.md)
- [Dépannage Connectivité](./exercices/depannage-base.md)

## ✅ **Checklist de Progression**

### **Semaine 1 : Théorie Fondamentale**
- [ ] **Modèle OSI** : 7 couches et leurs rôles
- [ ] **TCP/IP** : Correspondance avec OSI
- [ ] **Adressage IPv4** : Classes, masques, notation CIDR
- [ ] **Sous-réseaux** : Calculs de base et VLSM

### **Semaine 2 : Protocoles et Applications**  
- [ ] **IPv6** : Adressage et configuration
- [ ] **ARP** : Résolution adresse MAC
- [ ] **ICMP** : Ping, traceroute, messages d'erreur
- [ ] **DHCP** : Attribution automatique d'adresses
- [ ] **DNS** : Résolution de noms

## 🔧 **Outils et Labos Recommandés**

### **Simulations Packet Tracer**
1. **Labo 1** : Configuration IP basique (3 PC + 1 Switch)
2. **Labo 2** : Sous-réseaux avec routeur (2 réseaux)
3. **Labo 3** : DHCP serveur et client
4. **Labo 4** : Dépannage connectivité multi-réseaux

### **Commandes Cisco Essentielles**
```cisco
# Configuration interface
interface fastethernet 0/1
ip address 192.168.1.1 255.255.255.0
no shutdown

# Tests connectivité
ping 192.168.1.2
traceroute 192.168.1.2
show ip interface brief
show arp
```

## 📊 **Questions d'Auto-Évaluation**

### **Niveau Compréhension**
1. Expliquez la différence entre TCP et UDP avec exemples
2. Comment ARP résout-il une adresse MAC ?
3. Quel est le rôle de chaque couche OSI ?

### **Niveau Application**
1. Calculez les sous-réseaux pour 50 hôtes en /24
2. Configurez une interface avec IP statique
3. Dépannez une perte de connectivité ping

### **Niveau Analyse**
1. Analysez un échange DHCP avec Wireshark
2. Comparez IPv4 vs IPv6 : avantages/inconvénients
3. Optimisez un plan d'adressage d'entreprise

## 🎯 **Validation des Acquis**

**Critères de Réussite :**
- ✅ **Calculs** : Sous-réseaux en moins de 2 minutes
- ✅ **Configuration** : IP statique sans documentation  
- ✅ **Diagnostic** : Identifier source problème connectivité
- ✅ **Théorie** : Expliquer processus ARP/DHCP étape par étape

## 🚀 **Prochaines Étapes**

Une fois ce module maîtrisé :

1. **Auto-évaluation** avec exercices pratiques
2. **Validation** des compétences avec mini-labo
3. **Transition** vers [Module 2 - Switching](../02-switching/README.md)

## 📞 **Ressources Complémentaires**

- **RFC 791** : Internet Protocol IPv4
- **RFC 2460** : Internet Protocol IPv6  
- **Cisco Documentation** : IP Addressing and Subnetting
- **Calculateur Subnets** : subnetmask.info

---

**💡 Conseil :** Maîtrisez parfaitement ce module avant de passer au suivant. Les fondamentaux sont la base de tout le reste !

---

*Module créé pour une révision CCNA méthodique*  
*Auteur : Tudy Gbaguidi*