# Modèle OSI - Les 7 Couches Réseau

## **Vue d'Ensemble**

Le modèle OSI (Open Systems Interconnection) est un modèle conceptuel qui standardise les fonctions de communication d'un système de télécommunication sans se préoccuper de sa structure interne.

## **Architecture des 7 Couches**

```
┌─────────────────────────────────────────────────────┐
│ 7. APPLICATION  │ Interface utilisateur             │
├─────────────────────────────────────────────────────┤
│ 6. PRÉSENTATION │ Chiffrement, Compression          │
├─────────────────────────────────────────────────────┤
│ 5. SESSION      │ Établissement de sessions         │
├─────────────────────────────────────────────────────┤
│ 4. TRANSPORT    │ TCP/UDP - Fiabilité               │
├─────────────────────────────────────────────────────┤
│ 3. RÉSEAU       │ IP - Routage                      │
├─────────────────────────────────────────────────────┤
│ 2. LIAISON      │ Ethernet - Trames                 │
├─────────────────────────────────────────────────────┤
│ 1. PHYSIQUE     │ Bits sur le média                 │
└─────────────────────────────────────────────────────┘
```

## **Détail des Couches**

### **Couche 1 : PHYSIQUE**
**Rôle :**Transmission des bits bruts sur le support physique

**Caractéristiques :**
- Signaux électriques, optiques, radio
- Connecteurs, câbles, répéteurs
- Définit les caractéristiques physiques

**Équipements :**
- Câbles (UTP, Fibre optique)
- Hubs, Répéteurs
- Connecteurs RJ45, SC, ST

**Exemple :**
```
PC1 ─[Câble UTP]─ HUB ─[Câble UTP]─ PC2
     Bits: 1010110111001...
```

### **Couche 2 : LIAISON DE DONNÉES**
**Rôle :**Détection/correction d'erreurs, contrôle de flux local

**Caractéristiques :**
- Adresses MAC (Media Access Control)
- Trames Ethernet
- Détection d'erreurs (CRC)

**Équipements :**
- Switches
- Bridges
- Cartes réseau (NIC)

**Format Trame Ethernet :**
```
┌──────────┬──────────┬──────┬─────────┬─────┐
│ MAC Dest │ MAC Src  │ Type │ Données │ CRC │
│  6 bytes │ 6 bytes  │2 byte│ Variable│4 bit│
└──────────┴──────────┴──────┴─────────┴─────┘
```

### **Couche 3 : RÉSEAU**
**Rôle :**Routage des paquets entre réseaux différents

**Caractéristiques :**
- Adresses IP (IPv4/IPv6)
- Routage inter-réseaux
- Protocoles : IP, ICMP, ARP

**Équipements :**
- Routeurs
- Routeurs de couche 3
- Firewalls

**Exemple de Routage :**
```
PC A (192.168.1.10) 
    ↓
Router 1 (192.168.1.1) ─ [Internet] ─ Router 2 (10.0.0.1)
                                           ↓
                                    PC B (10.0.0.10)
```

### **Couche 4 : TRANSPORT**
**Rôle :**Fiabilité de bout en bout, contrôle de flux

**Protocoles Principaux :**

**TCP (Transmission Control Protocol) :**
- Fiable, orienté connexion
- Contrôle de flux et d'erreurs
- Utilisé pour : HTTP, HTTPS, FTP, SSH

**UDP (User Datagram Protocol) :**
- Non fiable, sans connexion
- Plus rapide, moins d'overhead
- Utilisé pour : DNS, DHCP, Streaming

**Comparaison TCP vs UDP :**
```
TCP                           UDP
┌─────────────┐              ┌─────────────┐
│ SYN         │──────────────│             │
│             │──────────────│ SYN-ACK     │
│ ACK         │──────────────│             │
│ Données     │─────────────│ Données     │
│ Fiable      │               │ Rapide      │
└─────────────┘               └─────────────┘
```

### **Couche 5 : SESSION**
**Rôle :**Établissement, gestion et fermeture de sessions

**Fonctions :**
- Dialogue entre applications
- Synchronisation
- Points de contrôle (checkpoints)

**Protocoles :**
- NetBIOS
- RPC (Remote Procedure Call)
- SQL Sessions

### **Couche 6 : PRÉSENTATION**
**Rôle :**Formatting, chiffrement, compression des données

**Fonctions :**
- Conversion de formats (ASCII, JPEG, MPEG)
- Chiffrement/Déchiffrement (SSL/TLS)
- Compression/Décompression

**Exemples :**
- SSL/TLS (Chiffrement)
- JPEG, GIF (Compression images)
- ASCII, EBCDIC (Formats texte)

### **Couche 7 : APPLICATION**
**Rôle :**Interface directe avec l'utilisateur

**Protocoles Courants :**
- **HTTP/HTTPS** : Navigation web
- **FTP** : Transfert de fichiers
- **SMTP** : Envoi email
- **POP3/IMAP** : Réception email
- **DNS** : Résolution de noms
- **DHCP** : Attribution IP automatique

## **Flux de Communication OSI**

### **Envoi de Données (Encapsulation) :**
```
Application    │ Données utilisateur
Présentation   │ + En-tête présentation
Session        │ + En-tête session  
Transport      │ + En-tête TCP/UDP = SEGMENT
Réseau         │ + En-tête IP = PAQUET
Liaison        │ + En-tête Ethernet = TRAME  
Physique       │ Conversion en bits = BITS
```

### **Réception de Données (Désencapsulation) :**
```
Physique       │ Bits reçus
Liaison        │ Analyse trame Ethernet
Réseau         │ Analyse paquet IP
Transport      │ Analyse segment TCP/UDP
Session        │ Gestion session
Présentation   │ Décompression/Déchiffrement  
Application    │ Données pour l'utilisateur
```

## **Correspondance OSI ↔ TCP/IP**

```
┌──────────────┬─────────────────┬─────────────────┐
│ Modèle OSI   │ Modèle TCP/IP   │ Protocoles      │
├──────────────┼─────────────────┼─────────────────┤
│ Application  │                 │ HTTP, FTP, DNS  │
│ Présentation │   Application   │ SMTP, POP3      │
│ Session      │                 │ Telnet, SSH     │
├──────────────┼─────────────────┼─────────────────┤
│ Transport    │   Transport     │ TCP, UDP        │
├──────────────┼─────────────────┼─────────────────┤
│ Réseau       │   Internet      │ IP, ICMP, ARP   │
├──────────────┼─────────────────┼─────────────────┤
│ Liaison      │   Accès Réseau  │ Ethernet, WiFi  │
│ Physique     │                 │ Câbles, Signaux │
└──────────────┴─────────────────┴─────────────────┘
```

## **Mnémotechniques**

### **Couches 1→7 (Ascendant) :**
**"Please Do Not Throw Sausage Pizza Away"**
- **P**hysique → **D**onnées → **N**etwork → **T**ransport  
- **S**ession → **P**résentation → **A**pplication

### **Couches 7→1 (Descendant) :**
**"All People Seem To Need Data Processing"**
- **A**pplication → **P**résentation → **S**ession → **T**ransport
- **N**etwork → **D**onnées → **P**hysique

## **Exemples Pratiques CCNA**

### **Scénario 1 : Navigation Web (HTTP)**
```
1. Application (7)   : Saisie URL dans navigateur
2. Présentation (6)  : Chiffrement HTTPS/TLS
3. Session (5)       : Établissement session HTTP  
4. Transport (4)     : TCP port 80/443
5. Réseau (3)        : Routage IP vers serveur web
6. Liaison (2)       : Trames Ethernet locales
7. Physique (1)      : Signaux sur câble/WiFi
```

### **Scénario 2 : Ping (ICMP)**
```
1. Application (7)   : Commande "ping 8.8.8.8"
2-3. Présentation/Session : Pas utilisées
4. Transport (4)     : ICMP (pas TCP/UDP)
5. Réseau (3)        : Paquet IP avec ICMP
6. Liaison (2)       : Trame vers passerelle
7. Physique (1)      : Transmission bits
```

## **Questions de Révision**

### **Niveau Fondamental**
1. Citez les 7 couches OSI dans l'ordre
2. Quel est le rôle de la couche Transport ?
3. Différence entre TCP et UDP ?

### **Niveau Intermédiaire**  
1. À quelle couche fonctionne un switch ? Un routeur ?
2. Expliquez l'encapsulation des données
3. Correspondance entre OSI et TCP/IP ?

### **Niveau Avancé**
1. Analysez le flux d'une requête HTTPS complète
2. Pourquoi séparer en couches ? Avantages ?
3. Dépannage : problème couche 1 vs couche 3 ?

## **Liens avec Autres Modules**

- **Module 2 (Switching)** : Couche 2 - VLANs, STP
- **Module 3 (Routing)** : Couche 3 - OSPF, EIGRP  
- **Module 4 (Services)** : Couches 3-7 - NAT, DHCP
- **Module 5 (Sécurité)** : Toutes couches - Firewalls, VPN

---

**Astuce CCNA :**Le modèle OSI est LA référence pour le dépannage réseau. Commencez toujours par la couche 1 (physique) et remontez !

---

*Fiche créée pour la révision CCNA*  
*Auteur : Roadmvn*