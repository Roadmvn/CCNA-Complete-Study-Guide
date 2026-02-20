# Labs Securite et QCM Final Multi-Modules

## Vue d'Ensemble

Cette section contient des labs pratiques de securite, des exercices de troubleshooting et un QCM final de 35 questions couvrant les modules 01 a 05 du programme CCNA 200-301.

---

## Lab 1 : Port-Security + DHCP Snooping

### Topologie

```
[Serveur DHCP] --- Gi0/1 --- [Switch-01] --- Fa0/1 --- [PC-A]
   10.1.1.100                                    Fa0/2 --- [PC-B]
                                                  Fa0/3 --- [PC-C]
                                                  Fa0/10 -- [Attaquant]
```

### Objectifs
- Configurer port-security avec maximum 1 MAC par port (sticky)
- Activer DHCP snooping sur le VLAN 10
- Tester qu'un serveur DHCP rogue est bloque

### Etape 1 : Configuration de base du switch

```cisco
Switch(config)# hostname Switch-01
Switch-01(config)# vlan 10
Switch-01(config-vlan)# name USERS
Switch-01(config-vlan)# exit

! Configurer les ports en mode access VLAN 10
Switch-01(config)# interface range fastEthernet 0/1 - 3
Switch-01(config-if-range)# switchport mode access
Switch-01(config-if-range)# switchport access vlan 10
Switch-01(config-if-range)# no shutdown

! Port vers le serveur DHCP
Switch-01(config)# interface gigabitEthernet 0/1
Switch-01(config-if)# switchport mode access
Switch-01(config-if)# switchport access vlan 10
Switch-01(config-if)# no shutdown
```

### Etape 2 : Configuration port-security

```cisco
! Activer port-security sur les ports utilisateurs
Switch-01(config)# interface range fastEthernet 0/1 - 3
Switch-01(config-if-range)# switchport port-security
Switch-01(config-if-range)# switchport port-security maximum 1
Switch-01(config-if-range)# switchport port-security violation restrict
Switch-01(config-if-range)# switchport port-security mac-address sticky

! Port attaquant : mode shutdown pour detection
Switch-01(config)# interface fastEthernet 0/10
Switch-01(config-if)# switchport mode access
Switch-01(config-if)# switchport access vlan 10
Switch-01(config-if)# switchport port-security
Switch-01(config-if)# switchport port-security maximum 1
Switch-01(config-if)# switchport port-security violation shutdown
```

### Etape 3 : Configuration DHCP snooping

```cisco
! Activer DHCP snooping
Switch-01(config)# ip dhcp snooping
Switch-01(config)# ip dhcp snooping vlan 10

! Port vers le serveur DHCP legitime = trusted
Switch-01(config)# interface gigabitEthernet 0/1
Switch-01(config-if)# ip dhcp snooping trust

! Limiter le debit DHCP sur les ports clients
Switch-01(config)# interface range fastEthernet 0/1 - 3
Switch-01(config-if-range)# ip dhcp snooping limit rate 5

! Port attaquant (reste untrusted par defaut)
```

### Verification

```cisco
Switch-01# show port-security
Switch-01# show port-security interface fa0/1
Switch-01# show port-security address
Switch-01# show ip dhcp snooping
Switch-01# show ip dhcp snooping binding
```

### Tests a effectuer
1. PC-A demande une IP par DHCP -> doit recevoir une IP du serveur legitime
2. Attaquant lance un serveur DHCP rogue -> les DHCP Offer doivent etre bloques
3. Attaquant connecte un hub avec 2 PCs sur Fa0/10 -> port err-disabled

---

## Lab 2 : ACLs de Securite Avancees

### Topologie

```
[VLAN 10 Users]                [VLAN 30 Servers]
  10.1.10.0/24                   10.1.30.0/24
       |                              |
+------+-----+                +------+-----+
|  SVI VLAN10|                | SVI VLAN30 |
| 10.1.10.1  |   [Router L3]  | 10.1.30.1  |
+------+-----+                +------+-----+
       |                              |
       |         [VLAN 20 Guest]      |
       |           10.1.20.0/24       |
       |                |             |
       |          +-----+-----+      |
       |          | SVI VLAN20|      |
       |          | 10.1.20.1 |      |
       |          +-----------+      |
```

### Objectifs
- VLAN 10 (Users) : acces complet aux serveurs et a Internet
- VLAN 20 (Guest) : acces Internet uniquement (HTTP/HTTPS), pas aux serveurs
- VLAN 30 (Servers) : accepte les connexions des Users, refuse les Guests

### Configuration des ACLs

```cisco
! ACL pour le VLAN Guest (appliquee en inbound sur SVI VLAN 20)
Router(config)# ip access-list extended GUEST-RESTRICT
Router(config-ext-nacl)# remark --- Autoriser DNS pour navigation ---
Router(config-ext-nacl)# permit udp 10.1.20.0 0.0.0.255 any eq 53
Router(config-ext-nacl)# remark --- Autoriser HTTP/HTTPS vers Internet ---
Router(config-ext-nacl)# permit tcp 10.1.20.0 0.0.0.255 any eq 80
Router(config-ext-nacl)# permit tcp 10.1.20.0 0.0.0.255 any eq 443
Router(config-ext-nacl)# remark --- Bloquer acces aux VLANs internes ---
Router(config-ext-nacl)# deny ip 10.1.20.0 0.0.0.255 10.1.10.0 0.0.0.255
Router(config-ext-nacl)# deny ip 10.1.20.0 0.0.0.255 10.1.30.0 0.0.0.255
Router(config-ext-nacl)# remark --- Autoriser le reste vers Internet ---
Router(config-ext-nacl)# permit ip 10.1.20.0 0.0.0.255 any

! Appliquer sur l'interface SVI VLAN 20
Router(config)# interface vlan 20
Router(config-if)# ip access-group GUEST-RESTRICT in

! Verification
Router# show access-lists
Router# show ip interface vlan 20
```

### Questions de verification
1. Un guest peut-il pinger un serveur 10.1.30.10 ? Pourquoi ?
2. Un guest peut-il naviguer sur www.cisco.com ? Pourquoi ?
3. Un utilisateur VLAN 10 peut-il acceder au serveur 10.1.30.10 ? Pourquoi ?

### Reponses
1. Non -- l'ACL "deny ip 10.1.20.0 ... 10.1.30.0" bloque le trafic
2. Oui -- "permit tcp ... any eq 443" autorise HTTPS + DNS autorise
3. Oui -- aucune ACL ne filtre le trafic du VLAN 10

---

## Lab 3 : Configuration Tunnel GRE

### Topologie

```
  LAN-A                                           LAN-B
  10.1.1.0/24                                    10.2.2.0/24
      |                                              |
+-----+------+      INTERNET        +------+-----+
|    R1      |                      |    R2      |
| Gi0/0:     |                      | Gi0/0:     |
| 10.1.1.1   |                      | 10.2.2.1   |
| Gi0/1:     |                      | Gi0/1:     |
| 203.0.113.1|                      |198.51.100.1|
| Tunnel0:   |======================| Tunnel0:   |
| 172.16.1.1 |   GRE Tunnel         | 172.16.1.2 |
+------------+                      +------------+
```

### Configuration R1

```cisco
! Interface WAN
Router-R1(config)# interface gigabitEthernet 0/1
Router-R1(config-if)# ip address 203.0.113.1 255.255.255.0
Router-R1(config-if)# no shutdown

! Interface LAN
Router-R1(config)# interface gigabitEthernet 0/0
Router-R1(config-if)# ip address 10.1.1.1 255.255.255.0
Router-R1(config-if)# no shutdown

! Tunnel GRE
Router-R1(config)# interface tunnel 0
Router-R1(config-if)# ip address 172.16.1.1 255.255.255.252
Router-R1(config-if)# tunnel source gigabitEthernet 0/1
Router-R1(config-if)# tunnel destination 198.51.100.1
Router-R1(config-if)# no shutdown

! Route vers le LAN distant via le tunnel
Router-R1(config)# ip route 10.2.2.0 255.255.255.0 172.16.1.2
```

### Configuration R2

```cisco
! Interface WAN
Router-R2(config)# interface gigabitEthernet 0/1
Router-R2(config-if)# ip address 198.51.100.1 255.255.255.0
Router-R2(config-if)# no shutdown

! Interface LAN
Router-R2(config)# interface gigabitEthernet 0/0
Router-R2(config-if)# ip address 10.2.2.1 255.255.255.0
Router-R2(config-if)# no shutdown

! Tunnel GRE
Router-R2(config)# interface tunnel 0
Router-R2(config-if)# ip address 172.16.1.2 255.255.255.252
Router-R2(config-if)# tunnel source gigabitEthernet 0/1
Router-R2(config-if)# tunnel destination 203.0.113.1
Router-R2(config-if)# no shutdown

! Route vers le LAN distant via le tunnel
Router-R2(config)# ip route 10.1.1.0 255.255.255.0 172.16.1.1
```

### Verification

```cisco
! Verifier le tunnel
Router-R1# show interface tunnel 0
Router-R1# show ip route
Router-R1# ping 172.16.1.2

! Test de bout en bout
Router-R1# ping 10.2.2.1 source 10.1.1.1
```

### Troubleshooting courant
- Tunnel down : verifier que les IPs tunnel source/destination sont joignables
- Pas de connectivite LAN-to-LAN : verifier les routes statiques
- MTU issues : configurer "ip mtu 1476" sur le tunnel si fragmentation

---

## Lab 4 : Troubleshooting Securite

### Scenario

Un administrateur a configure la securite sur un switch mais les utilisateurs ne peuvent plus acceder au reseau. Analysez et corrigez les problemes.

### Configuration actuelle (avec erreurs)

```cisco
! Configuration actuelle du switch (contient des erreurs)
Switch# show running-config

interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 ! Probleme 1 : pas de "switchport port-security mac-address sticky"
 ! et le PC a ete remplace (nouvelle MAC)

interface FastEthernet0/5
 switchport mode access
 switchport access vlan 10
 ! Probleme 2 : port-security non active mais
 ! DAI active sur VLAN 10 -> ARP des IPs statiques rejetes

interface GigabitEthernet0/1
 switchport mode trunk
 ! Probleme 3 : port vers serveur DHCP
 ! Pas de "ip dhcp snooping trust"
 ! -> DHCP Offer bloques

ip dhcp snooping
ip dhcp snooping vlan 10
ip arp inspection vlan 10
```

### Diagnostic pas a pas

```cisco
! Verifier l'etat des ports
Switch# show interfaces status
! -> Fa0/1 est en err-disabled (violation port-security)

! Verifier port-security
Switch# show port-security interface fa0/1
! -> Security Violation Count : 1
! -> Last Source Address: nouvelle MAC du PC remplace

! Verifier DHCP snooping
Switch# show ip dhcp snooping
! -> Gi0/1 est untrusted (devrait etre trusted)

! Verifier les bindings DHCP
Switch# show ip dhcp snooping binding
! -> Table vide (aucun bail accorde car DHCP bloque)

! Verifier DAI
Switch# show ip arp inspection statistics vlan 10
! -> ARP drops sur les ports avec IPs statiques
```

### Corrections

```cisco
! Correction 1 : Reactiver le port et activer sticky
Switch(config)# interface fastEthernet 0/1
Switch(config-if)# shutdown
Switch(config-if)# no switchport port-security mac-address
Switch(config-if)# switchport port-security mac-address sticky
Switch(config-if)# no shutdown

! Correction 2 : ARP ACL pour les IPs statiques
Switch(config)# arp access-list STATIC-HOSTS
Switch(config-arp-nacl)# permit ip host 10.1.1.50 mac host BB:CC:DD:EE:FF:05
Switch(config)# ip arp inspection filter STATIC-HOSTS vlan 10

! Correction 3 : Configurer le port DHCP comme trusted
Switch(config)# interface gigabitEthernet 0/1
Switch(config-if)# ip dhcp snooping trust
Switch(config-if)# ip arp inspection trust
```

### Verification post-correction

```cisco
Switch# show interfaces status
! -> Tous les ports up
Switch# show port-security
! -> Pas de violation
Switch# show ip dhcp snooping binding
! -> Bindings presents
Switch# show ip arp inspection statistics vlan 10
! -> Pas de drops inattendus
```

---

## Lab 5 : QCM FINAL Multi-Modules (35 Questions)

### Instructions
- Ce QCM couvre les modules 01 a 05
- Format type examen CCNA 200-301
- Choisissez la meilleure reponse pour chaque question
- Reponses en fin de section

---

### Module 1 : Fondamentaux Reseau

**Q1.** Quel est le protocole de couche 4 qui fournit un transport fiable oriente connexion ?
- A) UDP
- B) ICMP
- C) TCP
- D) ARP

**Q2.** Combien d'hotes utilisables y a-t-il dans un reseau /26 ?
- A) 64
- B) 62
- C) 30
- D) 126

**Q3.** Quelle est l'adresse reseau de l'hote 172.16.45.200/21 ?
- A) 172.16.45.0
- B) 172.16.40.0
- C) 172.16.32.0
- D) 172.16.44.0

**Q4.** Quel protocole utilise le port TCP 443 ?
- A) HTTP
- B) HTTPS
- C) FTP
- D) SSH

**Q5.** Quel est le role de la couche 3 du modele OSI ?
- A) Adressage MAC et trames
- B) Routage des paquets entre reseaux
- C) Transport fiable de bout en bout
- D) Interface utilisateur

---

### Module 2 : Switching

**Q6.** Quel protocole empeche les boucles de couche 2 dans un reseau commute ?
- A) VTP
- B) DTP
- C) STP
- D) CDP

**Q7.** Quel est l'etat STP d'un port qui transmet des trames et apprend les adresses MAC ?
- A) Blocking
- B) Listening
- C) Learning
- D) Forwarding

**Q8.** Combien de VLANs peut transporter un lien trunk 802.1Q ?
- A) 1
- B) 255
- C) 1005
- D) 4094

**Q9.** Quel protocole d'agregation de liens est un standard IEEE ?
- A) PAgP
- B) LACP
- C) DTP
- D) VTP

**Q10.** Quel champ est ajoute dans la trame Ethernet par le trunk 802.1Q ?
- A) Un en-tete GRE
- B) Un tag de 4 octets avec le VLAN ID
- C) Un label MPLS
- D) Un en-tete IPsec

---

### Module 3 : Routing

**Q11.** Quelle est la distance administrative d'une route OSPF ?
- A) 1
- B) 90
- C) 110
- D) 120

**Q12.** Quel type de route apparait avec le code "C" dans la table de routage ?
- A) Route statique
- B) Route connectee directement
- C) Route OSPF
- D) Route par defaut

**Q13.** Quel est le cout OSPF par defaut d'une interface GigabitEthernet (1 Gbps) ?
- A) 1
- B) 10
- C) 100
- D) 1000

**Q14.** Quelle commande configure une route statique par defaut ?
- A) ip route 0.0.0.0 255.255.255.0 10.1.1.1
- B) ip route 0.0.0.0 0.0.0.0 10.1.1.1
- C) ip default-route 10.1.1.1
- D) ip route default 10.1.1.1

**Q15.** Quel est le role du routeur DR en OSPF ?
- A) Elu sur les reseaux point-a-point
- B) Reduire le nombre d'adjacences sur un segment multi-acces
- C) Calculer les routes inter-area
- D) Redistribuer les routes externes

**Q16.** Quel type de paquet OSPF est utilise pour decouvrir les voisins ?
- A) LSA
- B) LSU
- C) Hello
- D) DBD

---

### Module 4 : Services Reseau

**Q17.** Quel type de NAT associe une seule adresse IP publique a plusieurs adresses privees ?
- A) NAT statique
- B) NAT dynamique
- C) PAT (Port Address Translation)
- D) NAT reflexif

**Q18.** Quel est l'ordre des messages DHCP lors d'une attribution initiale ?
- A) Discover, Offer, Request, Acknowledge
- B) Request, Offer, Discover, Acknowledge
- C) Discover, Request, Offer, Acknowledge
- D) Request, Discover, Acknowledge, Offer

**Q19.** Quelle commande affiche les traductions NAT actives ?
- A) show ip nat statistics
- B) show ip nat translations
- C) show running-config | include nat
- D) show ip interface brief

**Q20.** Quel protocole utilise le port UDP 514 pour envoyer des messages de log ?
- A) SNMP
- B) NTP
- C) Syslog
- D) NetFlow

**Q21.** Quelle est la difference principale entre une ACL standard et une ACL etendue ?
- A) La standard filtre par port, l'etendue par IP
- B) La standard filtre par IP source, l'etendue par IP source, destination, port et protocole
- C) La standard est numerotee, l'etendue est nommee
- D) Aucune difference fonctionnelle

---

### Module 5 : Securite, WAN et Automation

**Q22.** Quel mecanisme de securite protege contre les serveurs DHCP malveillants ?
- A) Port-security
- B) DHCP snooping
- C) DAI
- D) 802.1X

**Q23.** Dans le modele 802.1X, quel est le role du switch ?
- A) Supplicant
- B) Authenticator
- C) Authentication server
- D) RADIUS client uniquement

**Q24.** Quel mode de violation port-security desactive le port en err-disabled ?
- A) protect
- B) restrict
- C) shutdown
- D) disable

**Q25.** Quel protocole AAA chiffre le paquet entier (pas seulement le mot de passe) ?
- A) RADIUS
- B) TACACS+
- C) LDAP
- D) Kerberos

**Q26.** Quel protocole VPN permet l'encapsulation de paquets multicast (OSPF, EIGRP) ?
- A) IPsec seul
- B) GRE
- C) SSL VPN
- D) PPTP

**Q27.** Quelle operation MPLS consiste a remplacer un label par un autre ?
- A) PUSH
- B) POP
- C) SWAP
- D) FORWARD

**Q28.** Quel est le role de l'IKE Phase 1 dans IPsec ?
- A) Chiffrer les donnees utilisateur
- B) Etablir un canal securise pour negocier les parametres IPsec
- C) Generer les cles AES
- D) Authentifier les utilisateurs VPN

**Q29.** Dans l'architecture SDN, quelle interface connecte le controleur aux applications ?
- A) Southbound API
- B) Northbound API
- C) Eastbound API
- D) Management API

**Q30.** Quelle methode HTTP REST est utilisee pour creer une nouvelle ressource ?
- A) GET
- B) POST
- C) PUT
- D) DELETE

**Q31.** Quel outil de configuration management est agentless et utilise SSH ?
- A) Puppet
- B) Chef
- C) Ansible
- D) SaltStack

**Q32.** Quel format de donnees est prefere pour les REST APIs modernes ?
- A) XML
- B) YAML
- C) JSON
- D) CSV

**Q33.** Quel code HTTP indique que la ressource demandee n'existe pas ?
- A) 401
- B) 403
- C) 404
- D) 500

**Q34.** Quel protocole de gestion reseau utilise le format XML et des modeles YANG ?
- A) SNMP
- B) NETCONF
- C) Syslog
- D) NetFlow

**Q35.** Quel est l'avantage principal de l'Intent-Based Networking ?
- A) Remplacer tous les equipements par des machines virtuelles
- B) Traduire des intentions business en configurations techniques automatiquement
- C) Supprimer le besoin de routeurs physiques
- D) Utiliser uniquement des protocoles open-source

---

## Reponses du QCM Final

### Module 1 : Fondamentaux
```
Q1  : C) TCP
      TCP est oriente connexion et fiable (3-way handshake, ACK, retransmission).

Q2  : B) 62
      /26 = 32-26 = 6 bits hotes. 2^6 = 64. 64 - 2 = 62 hotes utilisables.

Q3  : B) 172.16.40.0
      /21 = masque 255.255.248.0. Increment = 8 sur le 3eme octet.
      45 / 8 = 5 (entier). 5 * 8 = 40. Reseau = 172.16.40.0/21.

Q4  : B) HTTPS
      HTTPS utilise TCP 443. HTTP utilise TCP 80.

Q5  : B) Routage des paquets entre reseaux
      La couche 3 (Reseau) gere l'adressage IP et le routage.
```

### Module 2 : Switching
```
Q6  : C) STP
      Spanning Tree Protocol empeche les boucles L2.

Q7  : D) Forwarding
      En Forwarding, le port transmet les trames ET apprend les MAC.
      Learning = apprend mais ne transmet pas encore.

Q8  : D) 4094
      802.1Q utilise 12 bits pour le VLAN ID (0-4095).
      VLAN 0 et 4095 reserves = 4094 VLANs utilisables.

Q9  : B) LACP
      LACP = IEEE 802.3ad. PAgP = proprietaire Cisco.

Q10 : B) Un tag de 4 octets avec le VLAN ID
      Le tag 802.1Q contient : TPID (2 octets) + TCI (2 octets avec VLAN ID).
```

### Module 3 : Routing
```
Q11 : C) 110
      AD OSPF = 110. EIGRP = 90. RIP = 120. Statique = 1.

Q12 : B) Route connectee directement
      C = Connected (interfaces directement configurees et up).

Q13 : A) 1
      Cout OSPF = Reference BW / Interface BW = 100 Mbps / 1000 Mbps = 0.1
      Minimum = 1. Donc cout GigabitEthernet = 1.

Q14 : B) ip route 0.0.0.0 0.0.0.0 10.1.1.1
      Route par defaut = destination 0.0.0.0 masque 0.0.0.0.

Q15 : B) Reduire le nombre d'adjacences sur un segment multi-acces
      DR/BDR evitent les adjacences full-mesh sur un segment broadcast.

Q16 : C) Hello
      Les paquets Hello sont envoyes pour decouvrir et maintenir les voisins.
```

### Module 4 : Services
```
Q17 : C) PAT (Port Address Translation)
      PAT = NAT overload. Une IP publique, plusieurs privees, differenciees
      par les numeros de port.

Q18 : A) Discover, Offer, Request, Acknowledge
      DORA : le client Discover, le serveur Offer, le client Request,
      le serveur Acknowledge.

Q19 : B) show ip nat translations
      Affiche la table des traductions NAT actives.

Q20 : C) Syslog
      Syslog utilise UDP 514 pour les messages de log.

Q21 : B) La standard filtre par IP source, l'etendue par IP source,
         destination, port et protocole
      Standard (1-99) = IP source. Etendue (100-199) = src, dst, port, proto.
```

### Module 5 : Securite, WAN et Automation
```
Q22 : B) DHCP snooping
      DHCP snooping bloque les DHCP Offer/Ack sur les ports untrusted,
      empechant un rogue DHCP de repondre.

Q23 : B) Authenticator
      Le switch est l'authenticator : il relaie les messages EAP entre
      le supplicant (PC) et le serveur RADIUS.

Q24 : C) shutdown
      Le mode shutdown desactive le port (err-disabled). Protect = drop
      silencieux. Restrict = drop + log.

Q25 : B) TACACS+
      TACACS+ chiffre le paquet entier. RADIUS ne chiffre que le mot
      de passe dans le paquet Access-Request.

Q26 : B) GRE
      GRE supporte le multicast. IPsec seul ne supporte que l'unicast.
      GRE + IPsec = multicast + securite.

Q27 : C) SWAP
      PUSH = ajouter un label. SWAP = remplacer un label. POP = retirer.

Q28 : B) Etablir un canal securise pour negocier les parametres IPsec
      IKE Phase 1 cree l'ISAKMP SA (canal securise).
      IKE Phase 2 negocie les IPsec SA via ce canal.

Q29 : B) Northbound API
      NB-API = controleur <-> applications. SB-API = controleur <-> infra.

Q30 : B) POST
      POST = Create. GET = Read. PUT = Update (complet). DELETE = Delete.

Q31 : C) Ansible
      Ansible est agentless (push via SSH). Puppet et Chef utilisent
      des agents installes sur les noeuds.

Q32 : C) JSON
      JSON est le format standard des REST APIs modernes.
      Compact, types natifs, parsing rapide.

Q33 : C) 404
      404 = Not Found. 401 = Unauthorized. 403 = Forbidden.
      500 = Internal Server Error.

Q34 : B) NETCONF
      NETCONF utilise XML + YANG sur TCP 830 (SSH).
      SNMP utilise MIBs. Syslog/NetFlow ne sont pas des protocoles
      de configuration.

Q35 : B) Traduire des intentions business en configurations techniques
         automatiquement
      IBN = definir ce qu'on veut (intention), le controleur traduit
      en config et verifie en continu.
```

---

## Grille d'Evaluation

```
+-------------------+-------------------------------------------+
| Score             | Evaluation                                |
+-------------------+-------------------------------------------+
| 32-35 / 35       | Excellent - Pret pour l'examen CCNA       |
| 28-31 / 35       | Bon - Quelques revisions sur les points   |
|                   | manques                                   |
| 24-27 / 35       | Moyen - Revoir les modules concernes      |
| < 24 / 35        | A renforcer - Reprendre les fiches de     |
|                   | revision de chaque module                 |
+-------------------+-------------------------------------------+
```

---

*Exercices crees pour la revision CCNA*
*Auteur : Roadmvn*
