# Securite Reseau - Port-Security, DHCP Snooping, DAI, 802.1X, AAA

## Vue d'Ensemble

La securite reseau au niveau CCNA couvre la protection de la couche 2 (port-security, DHCP snooping, DAI), l'authentification (802.1X, AAA) et les bases de la securite wireless. Ces mecanismes se completent pour former une defense en profondeur.

---

## 1. Port-Security

### Principe

Port-security limite le nombre d'adresses MAC autorisees sur un port de switch. Cela empeche un attaquant de connecter un hub, un switch non autorise ou de faire du MAC flooding.

### Schema : Fonctionnement Port-Security

```
SWITCH avec Port-Security
+-------------------------------------------------------------+
|                                                             |
|  Port Fa0/1 (port-security active)                         |
|  +-------------------------------------------------------+ |
|  | Table MAC autorisees :                                | |
|  | +---------------------------------------------------+ | |
|  | | MAC 1 : AA:BB:CC:DD:EE:01  (apprise / sticky)     | | |
|  | | MAC 2 : AA:BB:CC:DD:EE:02  (apprise / sticky)     | | |
|  | +---------------------------------------------------+ | |
|  | Maximum : 2 adresses MAC                              | |
|  | Mode violation : shutdown                             | |
|  +-------------------------------------------------------+ |
|                                                             |
|  Scenario 1 : PC autorise (MAC connue)                     |
|  [PC-A MAC:EE:01] ----> Port Fa0/1 ----> AUTORISE          |
|                                                             |
|  Scenario 2 : Intrus (3eme MAC = violation)                |
|  [PC-X MAC:EE:03] ----> Port Fa0/1 ----> VIOLATION !       |
|                         |                                   |
|                         v                                   |
|                 +----------------+                          |
|                 | Mode Violation |                          |
|                 +-------+--------+                          |
|                         |                                   |
|          +--------------+--------------+                    |
|          |              |              |                    |
|     [PROTECT]      [RESTRICT]    [SHUTDOWN]                |
|     Trafic drop    Trafic drop   Port err-disabled         |
|     Pas de log     + Log SNMP    + Log SNMP                |
|     Compteur: non  Compteur: oui Compteur: oui             |
+-------------------------------------------------------------+
```

### Les 3 Modes de Violation

```
+-------------+----------------+----------------+--------------------+
| Mode        | Trafic viole   | Syslog/SNMP    | Port desactive     |
+-------------+----------------+----------------+--------------------+
| protect     | Drop silencieux| Non            | Non                |
| restrict    | Drop           | Oui            | Non                |
| shutdown    | Drop           | Oui            | Oui (err-disabled) |
+-------------+----------------+----------------+--------------------+

Defaut : shutdown (le plus securise)
```

### Sticky MAC Address

```
Fonctionnement du Sticky Learning :

1. Port-security sticky active
   |
   v
2. Switch apprend dynamiquement les MAC sur le port
   |
   v
3. MAC apprise ajoutee a la running-config automatiquement
   |
   v
4. Apres "write memory" : MAC sauvegardee dans startup-config
   |
   v
5. Apres reboot : MAC toujours connue (pas de re-apprentissage)

Avantage : Pas besoin de configurer manuellement chaque MAC
Inconvenient : Si on deplace un PC, il faut nettoyer la config
```

### Configuration Port-Security

```cisco
! Activer port-security sur un port access
Switch(config)# interface fastEthernet 0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport port-security
Switch(config-if)# switchport port-security maximum 2
Switch(config-if)# switchport port-security violation restrict
Switch(config-if)# switchport port-security mac-address sticky

! Configuration avec MAC statique
Switch(config-if)# switchport port-security mac-address AA:BB:CC:DD:EE:01

! Reactiver un port en err-disabled
Switch(config)# interface fastEthernet 0/1
Switch(config-if)# shutdown
Switch(config-if)# no shutdown

! Auto-recovery apres err-disabled (optionnel)
Switch(config)# errdisable recovery cause psecure-violation
Switch(config)# errdisable recovery interval 300
```

### Verification Port-Security

```cisco
Switch# show port-security
Switch# show port-security interface fa0/1
Switch# show port-security address
Switch# show interfaces fa0/1 status
```

### Sortie type : show port-security interface fa0/1

```
Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Restrict
Aging Time                 : 0 mins
Aging Type                 : Absolute
SecureStatic Address Aging : Disabled
Maximum MAC Addresses      : 2
Total MAC Addresses        : 1
Configured MAC Addresses   : 0
Sticky MAC Addresses       : 1
Last Source Address:Vlan   : AA:BB:CC:DD:EE:01:10
Security Violation Count   : 3
```

---

## 2. DHCP Snooping

### Principe

DHCP snooping protege contre les serveurs DHCP malveillants (rogue DHCP). Le switch filtre les messages DHCP en distinguant les ports de confiance (trusted) des ports non fiables (untrusted).

### Schema : DHCP Snooping en Action

```
                   RESEAU AVEC DHCP SNOOPING

[Serveur DHCP]          [Attaquant avec DHCP]
  Legitime                   Rogue DHCP
     |                          |
     v                          v
+----+----+              +------+------+
| Port    |              | Port        |
| Gi0/1   |              | Fa0/10      |
| TRUSTED |              | UNTRUSTED   |
+---------+              +-------------+
     |                          |
+----+--------------------------+-----+
|           SWITCH L2                  |
|                                      |
|  DHCP Snooping : ACTIVE             |
|  VLAN 10 : snooping enabled         |
|                                      |
|  +-------------------------------+   |
|  | DHCP Snooping Binding Table   |   |
|  +-------------------------------+   |
|  | MAC Address  | IP Address     |   |
|  | VLAN | Port  | Lease (sec)    |   |
|  +------+-------+----------------+   |
|  | AA:01| 10.1.1.10 | 10 | Fa0/1|   |
|  | AA:02| 10.1.1.11 | 10 | Fa0/2|   |
|  +-------------------------------+   |
|                                      |
|  Port Fa0/1, Fa0/2 : UNTRUSTED      |
|  (vers les PCs clients)             |
+--------------------------------------+
     |              |
     v              v
  [PC-A]         [PC-B]
  Fa0/1          Fa0/2
  UNTRUSTED      UNTRUSTED

REGLES DE FILTRAGE :
+---------------------+-------------------+-------------------+
| Message DHCP        | Port TRUSTED      | Port UNTRUSTED    |
+---------------------+-------------------+-------------------+
| DHCP Discover       | Autorise          | Autorise          |
| DHCP Request        | Autorise          | Autorise          |
| DHCP Offer          | Autorise          | BLOQUE            |
| DHCP Ack            | Autorise          | BLOQUE            |
+---------------------+-------------------+-------------------+

Resultat : seul le serveur DHCP legitime (port trusted) peut
           envoyer des OFFER et ACK.
```

### Configuration DHCP Snooping

```cisco
! Activer DHCP snooping globalement
Switch(config)# ip dhcp snooping
Switch(config)# ip dhcp snooping vlan 10,20

! Definir le port vers le serveur DHCP comme trusted
Switch(config)# interface gigabitEthernet 0/1
Switch(config-if)# ip dhcp snooping trust

! Les ports clients restent untrusted par defaut

! Limiter le debit DHCP sur les ports untrusted (anti-DoS)
Switch(config)# interface range fastEthernet 0/1 - 24
Switch(config-if-range)# ip dhcp snooping limit rate 10

! Verification
Switch# show ip dhcp snooping
Switch# show ip dhcp snooping binding
Switch# show ip dhcp snooping statistics
```

---

## 3. Dynamic ARP Inspection (DAI)

### Principe

DAI protege contre les attaques ARP spoofing/poisoning. Il utilise la binding table de DHCP snooping pour valider les requetes ARP : si une requete ARP contient une correspondance IP-MAC qui ne figure pas dans la table, elle est rejetee.

### Schema : DAI Protection

```
SANS DAI (vulnerable) :                AVEC DAI (protege) :

[Attaquant]                            [Attaquant]
"Je suis la gateway                    "Je suis la gateway
 10.1.1.1 !"                            10.1.1.1 !"
     |                                      |
     | ARP Reply forge                      | ARP Reply forge
     v                                      v
+---------+                            +---------+
| Switch  | --> Trame relayee          | Switch  | --> VERIFICATION
+---------+     vers la victime        +---------+     contre DHCP
     |                                      |          snooping
     v                                      |          binding table
[Victime]                                   v
Table ARP empoisonnee !               +------------------+
10.1.1.1 = MAC attaquant              | Binding Table    |
     |                                 | 10.1.1.1 = MAC  |
     v                                 |   de la gateway  |
Trafic intercepte par                  | MAC attaquant != |
l'attaquant (MITM)                     |   MAC gateway    |
                                       +------------------+
                                            |
                                            v
                                       ARP REPLY REJETE !
                                       [Victime] protegee
```

### Configuration DAI

```cisco
! Prerequis : DHCP snooping doit etre actif

! Activer DAI sur le VLAN
Switch(config)# ip arp inspection vlan 10

! Le port trunk/uplink vers le routeur doit etre trusted
Switch(config)# interface gigabitEthernet 0/1
Switch(config-if)# ip arp inspection trust

! Pour les hotes avec IP statique (pas dans la binding table DHCP)
Switch(config)# arp access-list STATIC-ARP
Switch(config-arp-nacl)# permit ip host 10.1.1.100 mac host AA:BB:CC:DD:EE:FF
Switch(config)# ip arp inspection filter STATIC-ARP vlan 10

! Verification
Switch# show ip arp inspection
Switch# show ip arp inspection vlan 10
Switch# show ip arp inspection statistics
```

---

## 4. 802.1X Authentication

### Principe

802.1X est un standard d'authentification port-based. Avant d'acceder au reseau, un equipement doit s'authentifier aupres d'un serveur RADIUS via le switch (authenticator). Tant que l'authentification n'est pas reussie, le port ne laisse passer que le trafic EAP.

### Schema : Flux 802.1X Complet

```
802.1X AUTHENTICATION FLOW
===========================

+------------+        +---------------+        +------------------+
|            |        |               |        |                  |
| SUPPLICANT |        | AUTHENTICATOR |        | AUTHENTICATION   |
| (Client)   |        | (Switch)      |        | SERVER (RADIUS)  |
|            |        |               |        |                  |
+-----+------+        +-------+-------+        +--------+---------+
      |                        |                         |
      |  1. Connexion physique |                         |
      |  (link up)             |                         |
      |----------------------->|                         |
      |                        |                         |
      |  2. EAP-Request/       |                         |
      |     Identity           |                         |
      |<-----------------------|                         |
      |                        |                         |
      |  3. EAP-Response/      |                         |
      |     Identity            |                         |
      |     (username)         |                         |
      |----------------------->|                         |
      |                        |                         |
      |                        |  4. RADIUS              |
      |                        |     Access-Request      |
      |                        |  (EAP-Response inclus)  |
      |                        |------------------------>|
      |                        |                         |
      |                        |                         | 5. Verification
      |                        |                         |    credentials
      |                        |                         |    dans la base
      |                        |                         |    (AD, LDAP...)
      |                        |                         |
      |                        |  6. RADIUS              |
      |                        |     Access-Challenge    |
      |                        |<------------------------|
      |                        |                         |
      |  7. EAP-Request        |                         |
      |     (challenge)        |                         |
      |<-----------------------|                         |
      |                        |                         |
      |  8. EAP-Response       |                         |
      |     (credentials)      |                         |
      |----------------------->|                         |
      |                        |                         |
      |                        |  9. RADIUS              |
      |                        |     Access-Request      |
      |                        |------------------------>|
      |                        |                         |
      |                        |  10. RADIUS             |
      |                        |      Access-Accept      |
      |                        |      (+ VLAN, ACL...)   |
      |                        |<------------------------|
      |                        |                         |
      |  11. EAP-Success       |                         |
      |<-----------------------|                         |
      |                        |                         |
      |  PORT AUTORISE         |                         |
      |  Trafic normal passe   |                         |
      |<=======================>                         |

ETATS DU PORT 802.1X :
+--------------------+-------------------------------------+
| Etat               | Description                         |
+--------------------+-------------------------------------+
| Force-authorized   | Port toujours ouvert (pas de 802.1X)|
| Force-unauthorized | Port toujours ferme                 |
| Auto               | Authentification 802.1X requise     |
+--------------------+-------------------------------------+
```

### Les 3 Roles 802.1X

```
+------------------+-------------------------------------------+
| Role             | Description                               |
+------------------+-------------------------------------------+
| Supplicant       | Le client qui veut acceder au reseau      |
|                  | Exemples : PC, telephone IP, imprimante   |
|                  | Logiciel : client 802.1X natif (Windows,  |
|                  |            macOS, Linux)                  |
+------------------+-------------------------------------------+
| Authenticator    | L'equipement reseau intermediaire         |
|                  | En general : le switch d'acces            |
|                  | Role : relayer les messages EAP entre     |
|                  |        supplicant et serveur RADIUS       |
+------------------+-------------------------------------------+
| Authentication   | Le serveur qui valide les credentials     |
| Server           | Protocole : RADIUS (UDP 1812/1813)        |
|                  | Exemples : Cisco ISE, FreeRADIUS,         |
|                  |            Microsoft NPS                  |
+------------------+-------------------------------------------+
```

### Configuration 802.1X sur le Switch

```cisco
! Activer AAA et configurer le serveur RADIUS
Switch(config)# aaa new-model
Switch(config)# radius server ISE-SERVER
Switch(config-radius-server)# address ipv4 10.1.1.100 auth-port 1812 acct-port 1813
Switch(config-radius-server)# key CiscoRadius123
Switch(config)# aaa authentication dot1x default group radius
Switch(config)# aaa authorization network default group radius

! Activer 802.1X globalement
Switch(config)# dot1x system-auth-control

! Configurer le port en mode 802.1X
Switch(config)# interface fastEthernet 0/1
Switch(config-if)# switchport mode access
Switch(config-if)# authentication port-control auto
Switch(config-if)# dot1x pae authenticator

! Verification
Switch# show dot1x all
Switch# show dot1x interface fa0/1
Switch# show authentication sessions
```

---

## 5. AAA (Authentication, Authorization, Accounting)

### Principe

AAA est un framework de securite qui repond a trois questions :
- **Authentication** : Qui es-tu ? (verification d'identite)
- **Authorization** : Que peux-tu faire ? (droits et permissions)
- **Accounting** : Qu'as-tu fait ? (journalisation, audit)

### Schema : Framework AAA

```
FRAMEWORK AAA
=============

+------------------------------------------------------------------+
|                                                                  |
|  1. AUTHENTICATION (Qui es-tu ?)                                |
|  +------------------------------------------------------------+ |
|  | Methodes :                                                  | |
|  | - Local database (username/password sur le switch)          | |
|  | - RADIUS server (centralisee)                               | |
|  | - TACACS+ server (centralisee)                              | |
|  | - Certificats (802.1X avec EAP-TLS)                        | |
|  +------------------------------------------------------------+ |
|                          |                                       |
|                          v                                       |
|  2. AUTHORIZATION (Que peux-tu faire ?)                         |
|  +------------------------------------------------------------+ |
|  | Controle :                                                  | |
|  | - Commandes autorisees (admin vs operateur)                 | |
|  | - VLANs accessibles                                         | |
|  | - ACLs appliquees dynamiquement                             | |
|  | - Bande passante allouee                                    | |
|  +------------------------------------------------------------+ |
|                          |                                       |
|                          v                                       |
|  3. ACCOUNTING (Qu'as-tu fait ?)                                |
|  +------------------------------------------------------------+ |
|  | Journalisation :                                            | |
|  | - Heure de connexion/deconnexion                            | |
|  | - Commandes executees                                       | |
|  | - Volume de donnees transferees                             | |
|  | - Adresse IP utilisee                                       | |
|  +------------------------------------------------------------+ |
|                                                                  |
+------------------------------------------------------------------+
```

### RADIUS vs TACACS+

```
+-----------------------------+-------------------+-------------------+
| Critere                     | RADIUS            | TACACS+           |
+-----------------------------+-------------------+-------------------+
| Protocole transport         | UDP (1812/1813)   | TCP (49)          |
| Chiffrement                 | Mot de passe seul | Paquet entier     |
| Separation AAA              | Combine Auth+Authz| Separe les 3      |
| Support multiprotocole      | Oui               | Non (Cisco only)  |
| Standard                    | RFC 2865/2866     | Proprietaire Cisco|
| Usage typique               | Acces reseau      | Admin equipement  |
|                             | (802.1X, VPN)     | (commandes CLI)   |
| Granularite autorisation    | Par session       | Par commande      |
+-----------------------------+-------------------+-------------------+

Resume :
- RADIUS = acces reseau (utilisateurs, 802.1X, VPN)
- TACACS+ = administration equipements (controle fin des commandes)
```

### Configuration AAA

```cisco
! Activer AAA
Switch(config)# aaa new-model

! Authentication : methode RADIUS puis local en fallback
Switch(config)# aaa authentication login default group radius local

! Authorization : commandes level 15 via TACACS+
Switch(config)# aaa authorization exec default group tacacs+ local
Switch(config)# aaa authorization commands 15 default group tacacs+ local

! Accounting : journaliser les commandes
Switch(config)# aaa accounting exec default start-stop group radius
Switch(config)# aaa accounting commands 15 default start-stop group tacacs+

! Configurer serveur TACACS+
Switch(config)# tacacs server TACACS-SRV
Switch(config-server-tacacs)# address ipv4 10.1.1.200
Switch(config-server-tacacs)# key TacacsKey123

! Verification
Switch# show aaa sessions
Switch# show aaa servers
```

---

## 6. Securite Wireless (WPA2, WPA3)

### Principe

La securite wireless au CCNA couvre les mecanismes de protection des reseaux WiFi. WPA2 est le standard actuel, WPA3 est le nouveau standard avec des ameliorations significatives.

### Schema : Modes de Securite WiFi

```
EVOLUTION DE LA SECURITE WIFI
==============================

+----------+    +----------+    +----------+    +----------+
|   WEP    | -> |   WPA    | -> |  WPA2    | -> |  WPA3    |
| (casse)  |    | (TKIP)   |    | (AES)    |    | (SAE)    |
| NE PLUS  |    | Obsolete |    | Standard |    | Nouveau  |
| UTILISER |    |          |    | actuel   |    | standard |
+----------+    +----------+    +----------+    +----------+

WPA2 - Deux Modes :
+-------------------------------------------------------------------+
|                                                                   |
|  WPA2-Personal (PSK)              WPA2-Enterprise (802.1X)       |
|  +---------------------------+    +---------------------------+   |
|  | - Pre-Shared Key (PSK)   |    | - Serveur RADIUS          |   |
|  | - Mot de passe partage   |    | - Identifiants uniques    |   |
|  | - Meme cle pour tous     |    |   par utilisateur         |   |
|  | - PME, domicile          |    | - Certificats possibles   |   |
|  | - Simple a deployer      |    | - Entreprise, campus      |   |
|  | - AES-CCMP chiffrement   |    | - AES-CCMP chiffrement    |   |
|  +---------------------------+    +---------------------------+   |
|                                                                   |
|  WPA3 - Ameliorations :                                          |
|  +---------------------------+    +---------------------------+   |
|  | WPA3-Personal             |    | WPA3-Enterprise            |   |
|  | - SAE (remplace PSK)     |    | - 192-bit security suite  |   |
|  | - Protection contre       |    | - Chiffrement renforce    |   |
|  |   attaques dictionnaire   |    | - EAP-TLS obligatoire     |   |
|  | - Forward secrecy         |    | - CNSA suite              |   |
|  | - PMF obligatoire         |    |                           |   |
|  +---------------------------+    +---------------------------+   |
|                                                                   |
+-------------------------------------------------------------------+

Termes cles :
- PSK   : Pre-Shared Key (cle partagee)
- SAE   : Simultaneous Authentication of Equals (WPA3)
- AES   : Advanced Encryption Standard
- CCMP  : Counter Mode CBC-MAC Protocol
- PMF   : Protected Management Frames
- EAP   : Extensible Authentication Protocol
```

### Architecture Wireless Entreprise

```
+------------------+
| Controleur WLC   |  (Wireless LAN Controller)
| (Management)     |
+--------+---------+
         |
         | CAPWAP tunnel
         |
+--------+---------+----------+---------+
|                  |                     |
v                  v                     v
+----------+   +----------+        +----------+
| AP-1     |   | AP-2     |        | AP-3     |
| (LWAP)   |   | (LWAP)   |        | (LWAP)   |
+----------+   +----------+        +----------+
     |              |                    |
  [Client]      [Client]            [Client]
  SSID-Corp     SSID-Guest          SSID-Corp

LWAP = Lightweight Access Point
CAPWAP = Control And Provisioning of Wireless Access Points

Modes AP :
- Local mode    : trafic tunnel vers WLC
- FlexConnect   : trafic switch localement (branch office)
- Monitor mode  : detection d'intrusion wireless
```

---

## 7. Resume des Mecanismes de Securite L2

```
DEFENSE EN PROFONDEUR - COUCHE 2
=================================

+--------------------------------------------------------------------+
| Menace                     | Protection          | Couche          |
+--------------------------------------------------------------------+
| MAC flooding               | Port-Security       | Switch port     |
| Rogue DHCP server          | DHCP Snooping       | DHCP messages   |
| ARP spoofing / poisoning   | DAI                 | ARP messages    |
| Acces non autorise         | 802.1X              | Port access     |
| VLAN hopping (switch spoof)| DTP disable         | Trunk negoc.    |
| VLAN hopping (double tag)  | Native VLAN unused  | VLAN tagging    |
| CDP/LLDP reconnaissance    | Disable sur access  | Discovery       |
| STP manipulation           | BPDU Guard          | STP             |
+--------------------------------------------------------------------+

Best Practices sur un port ACCESS :
+--------------------------------------------------------------------+
| Commande                                    | Protection           |
+--------------------------------------------------------------------+
| switchport mode access                      | Anti switch spoofing |
| switchport port-security                    | Anti MAC flooding    |
| ip dhcp snooping                            | Anti rogue DHCP      |
| ip arp inspection vlan X                    | Anti ARP spoofing    |
| dot1x pae authenticator                     | Authentification     |
| spanning-tree portfast                      | Convergence rapide   |
| spanning-tree bpduguard enable              | Anti STP attack      |
| no cdp enable                               | Anti reconnaissance  |
| switchport nonegotiate                      | Anti DTP             |
+--------------------------------------------------------------------+
```

---

## Questions de Revision

### Niveau Fondamental
1. Quels sont les 3 modes de violation port-security et leurs differences ?
2. Quel est le role d'un port trusted en DHCP snooping ?
3. Nommez les 3 acteurs du modele 802.1X.

### Niveau Intermediaire
1. Comment DAI utilise la binding table de DHCP snooping ?
2. Quelle est la difference entre RADIUS et TACACS+ pour l'autorisation ?
3. Comparez WPA2-Personal et WPA2-Enterprise.

### Niveau Avance
1. Un port passe en err-disabled apres une violation port-security. Decrivez la procedure de recovery automatique et manuelle.
2. Concevez une politique de securite L2 complete pour un switch d'acces de 48 ports dans un environnement 802.1X avec fallback MAB.
3. Expliquez pourquoi WPA3-SAE est plus securise que WPA2-PSK contre les attaques offline dictionnaire.

---

*Fiche creee pour la revision CCNA*
*Auteur : Tudy Gbaguidi*
