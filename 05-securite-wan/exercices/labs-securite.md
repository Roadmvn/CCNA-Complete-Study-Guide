# Labs Pratiques Securite - Exercices CCNA

## Vue d'Ensemble

Cette section propose des labs pratiques couvrant les mecanismes de securite reseau essentiels pour la CCNA : port-security, DHCP snooping, ACLs, VPN, AAA et hardening.

---

## Lab 1 : Port-Security - Configuration et Test des Violations

### Objectif

Configurer la securite des ports sur un switch pour limiter le nombre d'adresses MAC autorisees et tester les differents modes de violation.

### Topologie

```
┌─────────────────────────────────────────────────────────────┐
│                        SW1 (2960)                           │
│                                                             │
│  Fa0/1          Fa0/2          Fa0/3          Fa0/4        │
│  Port-Sec       Port-Sec       Port-Sec       Port-Sec     │
│  max: 1         max: 2         max: 1         max: 1       │
│  sticky         sticky         static         static       │
│  shutdown       restrict       protect         shutdown     │
└──┬──────────────┬──────────────┬──────────────┬────────────┘
   │              │              │              │
┌──┴──┐       ┌──┴──┐       ┌──┴──┐       ┌──┴──┐
│PC-A │       │PC-B │       │PC-C │       │HUB  │
│VLAN │       │VLAN │       │VLAN │       │     │
│ 10  │       │ 10  │       │ 10  │       │ ┌─┴─┐
└─────┘       └─────┘       └─────┘       │PC-D│
                                           │PC-E│ <-- Violation !
                                           └───┘

Adressage :
  PC-A : 192.168.10.10/24   MAC : AAAA.BBBB.0001
  PC-B : 192.168.10.20/24   MAC : AAAA.BBBB.0002
  PC-C : 192.168.10.30/24   MAC : AAAA.BBBB.0003
  PC-D : 192.168.10.40/24   MAC : AAAA.BBBB.0004
  PC-E : 192.168.10.50/24   MAC : AAAA.BBBB.0005
  Gateway : 192.168.10.1/24
```

### Etapes de Configuration

```
! --- Etape 1 : Configuration de base du switch ---
enable
configure terminal
hostname SW1
!
! --- Etape 2 : Port Fa0/1 - Sticky + Shutdown ---
interface fastethernet 0/1
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown
 exit
!
! --- Etape 3 : Port Fa0/2 - Sticky + Restrict ---
interface fastethernet 0/2
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 2
 switchport port-security mac-address sticky
 switchport port-security violation restrict
 exit
!
! --- Etape 4 : Port Fa0/3 - Static MAC + Protect ---
interface fastethernet 0/3
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address AAAA.BBBB.0003
 switchport port-security violation protect
 exit
!
! --- Etape 5 : Port Fa0/4 - Static + Shutdown ---
interface fastethernet 0/4
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address AAAA.BBBB.0004
 switchport port-security violation shutdown
 exit
!
! --- Etape 6 : Auto-recovery err-disabled ---
errdisable recovery cause psecure-violation
errdisable recovery interval 300
end
```

### Tests de Violation

```
! Test 1 : Connecter un 2e PC sur Fa0/1 (max=1)
!   Resultat attendu : Port err-disabled (shutdown)
!   Verification :
show interfaces fastethernet 0/1 status
show port-security interface fastethernet 0/1

! Test 2 : Connecter un 3e PC sur Fa0/2 (max=2)
!   Resultat attendu : Trafic rejete, compteur increment, log genere
show port-security interface fastethernet 0/2

! Test 3 : Connecter un PC avec mauvaise MAC sur Fa0/3
!   Resultat attendu : Trafic silencieusement rejete (pas de log)
show port-security interface fastethernet 0/3

! Test 4 : Connecter PC-E via le HUB sur Fa0/4 (2e MAC)
!   Resultat attendu : Port err-disabled
show interfaces fastethernet 0/4 status
```

### Commandes de Verification

```
show port-security
show port-security interface fa0/1
show port-security address
show interfaces status err-disabled
show errdisable recovery
show mac address-table interface fa0/1
```

### Questions de Revision - Lab 1

1. Quelle est la difference entre les modes shutdown, restrict et protect ?
2. Que signifie "sticky" pour les adresses MAC en port-security ?
3. Comment recuperer un port en etat err-disabled ?
4. Quel est le maximum par defaut de port-security si non precise ?

**Reponses :**
1. **Shutdown** : port err-disabled + log. **Restrict** : trafic rejete + compteur + log. **Protect** : trafic silencieusement rejete, pas de log.
2. Sticky apprend dynamiquement la MAC et la sauvegarde dans la running-config. Elle persiste apres un `write memory`.
3. Manuellement : `shutdown` puis `no shutdown`. Automatiquement : `errdisable recovery cause psecure-violation`.
4. Le maximum par defaut est 1 adresse MAC.

---

## Lab 2 : DHCP Snooping + DAI

### Objectif

Proteger le reseau contre les attaques DHCP rogue et ARP spoofing en configurant DHCP Snooping et Dynamic ARP Inspection.

### Topologie

```
                         ┌──────────────┐
                         │ DHCP Server  │
                         │ 192.168.10.1 │
                         │ Gi0/0        │
                         └──────┬───────┘
                                │
                         ┌──────┴───────┐
                         │    SW1       │
                         │   (Core)     │
                         │              │
                         │ Gi0/1:TRUST  │
                         │              │
                         │ Fa0/1─┐      │
                         │ Fa0/2─┤UNTRUST
                         │ Fa0/3─┘      │
                         │              │
                         │ Fa0/10:      │
                         │ UNTRUST      │
                         └─┬──┬──┬──┬───┘
                           │  │  │  │
              ┌────────────┘  │  │  └────────────┐
              │               │  │               │
         ┌────┴────┐    ┌────┴──┴──┐       ┌────┴────┐
         │  PC-1   │    │  PC-2    │       │ATTACKER │
         │ Legitime│    │ Legitime │       │ Rogue   │
         │.10.10   │    │.10.20    │       │ DHCP    │
         │ Fa0/1   │    │ Fa0/2    │       │ Fa0/10  │
         └─────────┘    └──────────┘       └─────────┘

Adressage :
  DHCP Server : 192.168.10.1/24 (pool: .10 a .100)
  PC-1        : DHCP (recevra .10 a .100)
  PC-2        : DHCP (recevra .10 a .100)
  Attacker    : 192.168.10.200 (tente de se faire passer pour DHCP)
  VLAN 10     : 192.168.10.0/24
```

### Etapes de Configuration

```
! --- Etape 1 : Configuration VLANs ---
enable
configure terminal
hostname SW1
!
vlan 10
 name USERS
 exit
!
! --- Etape 2 : Activer DHCP Snooping ---
ip dhcp snooping
ip dhcp snooping vlan 10
no ip dhcp snooping information option
!
! --- Etape 3 : Configurer les ports TRUSTED ---
interface gigabitethernet 0/1
 description VERS_DHCP_SERVER
 switchport mode access
 switchport access vlan 10
 ip dhcp snooping trust
 exit
!
! --- Etape 4 : Ports UNTRUSTED (par defaut) + rate limit ---
interface range fastethernet 0/1-3
 switchport mode access
 switchport access vlan 10
 ip dhcp snooping limit rate 15
 exit
!
interface fastethernet 0/10
 description PORT_SUSPECT
 switchport mode access
 switchport access vlan 10
 ip dhcp snooping limit rate 10
 exit
!
! --- Etape 5 : Activer DAI (Dynamic ARP Inspection) ---
ip arp inspection vlan 10
!
! Port trusted pour DAI (meme logique que DHCP snooping)
interface gigabitethernet 0/1
 ip arp inspection trust
 exit
!
! --- Etape 6 : Validation ARP supplementaire (optionnel) ---
ip arp inspection validate src-mac dst-mac ip
!
! --- Etape 7 : IP Source Guard (optionnel, par port) ---
interface range fastethernet 0/1-3
 ip verify source
 exit
!
end
write memory
```

### Tests de Validation

```
! Test 1 : PC-1 demande une IP DHCP
!   Attendu : Recoit une IP du serveur DHCP legitime
!   Verifier la binding table :
show ip dhcp snooping binding

! Test 2 : Attacker envoie un DHCP OFFER sur Fa0/10
!   Attendu : Paquet rejete (port untrusted)
show ip dhcp snooping statistics

! Test 3 : Attacker envoie un ARP spoofe sur Fa0/10
!   Attendu : Paquet rejete par DAI
show ip arp inspection statistics vlan 10

! Test 4 : Depasser la rate limit DHCP
!   Attendu : Port err-disabled
show interfaces status err-disabled
```

### Commandes de Verification

```
show ip dhcp snooping
show ip dhcp snooping binding
show ip dhcp snooping statistics
show ip arp inspection vlan 10
show ip arp inspection statistics vlan 10
show ip arp inspection interfaces
show ip verify source
show errdisable recovery
```

### Questions de Revision - Lab 2

1. Quels types de messages DHCP sont bloques sur un port untrusted ?
2. Sur quelle base DAI decide-t-il de bloquer un paquet ARP ?
3. Pourquoi desactiver l'option 82 (`no ip dhcp snooping information option`) dans certains cas ?
4. Quel est le lien entre DHCP Snooping et IP Source Guard ?

**Reponses :**
1. DHCP OFFER et DHCP ACK sont bloques sur les ports untrusted (seul un serveur DHCP envoie ces messages).
2. DAI compare les informations du paquet ARP (MAC source, IP source, port) avec la DHCP Snooping Binding Table.
3. L'option 82 peut poser probleme si le serveur DHCP ne supporte pas le relay agent information. Elle est utile uniquement quand le switch agit comme relay.
4. IP Source Guard utilise la DHCP Snooping Binding Table pour verifier que l'IP source d'un paquet correspond bien a la MAC/port enregistres.

---

## Lab 3 : ACLs Securite (Bloquer Trafic Specifique)

### Objectif

Configurer des ACLs standard et etendues pour controler le trafic reseau et proteger des ressources sensibles.

### Topologie

```
                    ┌──────────────┐
                    │  INTERNET    │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │    R1        │
                    │              │
                    │ Gi0/0: WAN  │
                    │ 203.0.113.1 │
                    │              │
                    │ Gi0/1:      │
                    │ 192.168.10.1│
                    │ (VLAN 10)   │
                    │              │
                    │ Gi0/2:      │
                    │ 192.168.20.1│
                    │ (VLAN 20)   │
                    │              │
                    │ Gi0/3:      │
                    │ 192.168.30.1│
                    │ (VLAN 30)   │
                    └─┬────┬────┬─┘
                      │    │    │
         ┌────────────┘    │    └────────────┐
         │                 │                 │
  ┌──────┴──────┐   ┌─────┴──────┐   ┌──────┴──────┐
  │  VLAN 10    │   │  VLAN 20   │   │  VLAN 30    │
  │ USERS       │   │ SERVERS    │   │ MANAGEMENT  │
  │.10.0/24     │   │.20.0/24    │   │.30.0/24     │
  │             │   │            │   │             │
  │ PC-A .10   │   │ SRV-WEB .10│   │ ADMIN .10   │
  │ PC-B .20   │   │ SRV-DB  .20│   │             │
  │ PC-C .30   │   │ SRV-FTP .30│   │             │
  └─────────────┘   └────────────┘   └─────────────┘

Regles de securite a implementer :
  1. USERS peuvent acceder au web (HTTP/HTTPS) sur SRV-WEB
  2. USERS NE PEUVENT PAS acceder a SRV-DB ni SRV-FTP
  3. MANAGEMENT peut acceder a tout (SSH, HTTP, HTTPS)
  4. Personne ne peut acceder au MANAGEMENT sauf ADMIN
  5. USERS peuvent sortir sur Internet (HTTP/HTTPS/DNS)
  6. Bloquer tout acces entrant depuis Internet sauf reponses
```

### Configuration des ACLs

```
! --- ACL 1 : Proteger les serveurs (ACL etendue) ---
enable
configure terminal
!
ip access-list extended PROTECT-SERVERS
 ! Autoriser HTTP/HTTPS vers SRV-WEB depuis USERS
 permit tcp 192.168.10.0 0.0.0.255 host 192.168.20.10 eq 80
 permit tcp 192.168.10.0 0.0.0.255 host 192.168.20.10 eq 443
 ! Bloquer tout autre trafic USERS vers SERVERS
 deny ip 192.168.10.0 0.0.0.255 192.168.20.0 0.0.0.255 log
 ! Autoriser MANAGEMENT vers tous les serveurs
 permit ip 192.168.30.0 0.0.0.255 192.168.20.0 0.0.0.255
 ! Autoriser les reponses (established)
 permit tcp any 192.168.20.0 0.0.0.255 established
 ! Deny implicite (tout le reste bloque)
 exit
!
! Appliquer sur l'interface vers SERVERS
interface gigabitethernet 0/2
 ip access-group PROTECT-SERVERS out
 exit
!
! --- ACL 2 : Proteger le reseau MANAGEMENT ---
ip access-list extended PROTECT-MANAGEMENT
 ! Seul le reseau MANAGEMENT peut y acceder
 permit ip 192.168.30.0 0.0.0.255 192.168.30.0 0.0.0.255
 ! Bloquer tout le reste vers MANAGEMENT
 deny ip any 192.168.30.0 0.0.0.255 log
 ! Autoriser tout le reste (trafic qui ne va pas vers MGMT)
 permit ip any any
 exit
!
interface gigabitethernet 0/3
 ip access-group PROTECT-MANAGEMENT out
 exit
!
! --- ACL 3 : Filtrer trafic sortant Internet ---
ip access-list extended INTERNET-OUT
 permit tcp 192.168.10.0 0.0.0.255 any eq 80
 permit tcp 192.168.10.0 0.0.0.255 any eq 443
 permit udp 192.168.10.0 0.0.0.255 any eq 53
 permit tcp 192.168.10.0 0.0.0.255 any eq 53
 ! MANAGEMENT acces complet
 permit ip 192.168.30.0 0.0.0.255 any
 deny ip any any log
 exit
!
interface gigabitethernet 0/0
 ip access-group INTERNET-OUT out
 exit
!
! --- ACL 4 : Filtrer trafic entrant Internet ---
ip access-list extended INTERNET-IN
 ! Autoriser les reponses aux connexions initiees
 permit tcp any any established
 ! Bloquer tout le reste
 deny ip any any log
 exit
!
interface gigabitethernet 0/0
 ip access-group INTERNET-IN in
 exit
!
end
```

### Commandes de Verification

```
show access-lists
show ip access-lists
show ip access-lists PROTECT-SERVERS
show ip interface gigabitethernet 0/2
show access-lists | include deny
show logging | include ACL
```

### Questions de Revision - Lab 3

1. Quelle est la difference entre une ACL standard et une ACL etendue ?
2. Ou placer une ACL standard ? Une ACL etendue ?
3. Que signifie le wildcard mask 0.0.0.255 ?
4. Que fait le mot-cle `established` dans une ACL TCP ?
5. Pourquoi y a-t-il un `deny ip any any` implicite a la fin de chaque ACL ?

**Reponses :**
1. **Standard** : filtre uniquement sur IP source (numero 1-99). **Etendue** : filtre sur source, destination, protocole, ports (numero 100-199).
2. **Standard** : pres de la destination (car elle ne distingue pas la destination). **Etendue** : pres de la source (pour bloquer le trafic le plus tot possible).
3. 0.0.0.255 signifie que les 3 premiers octets doivent correspondre exactement et le dernier est ignore. Equivalent a /24.
4. `established` autorise uniquement les paquets TCP avec les flags ACK ou RST, ce qui correspond aux reponses a des connexions deja initiees.
5. Toute ACL Cisco se termine par un `deny ip any any` implicite. Tout trafic non explicitement autorise est bloque.

---

## Lab 4 : VPN Site-to-Site (GRE Tunnel)

### Objectif

Configurer un tunnel GRE entre deux sites distants pour permettre la communication entre les reseaux prives a travers Internet.

### Topologie

```
   SITE A                     INTERNET                    SITE B
   LAN: 10.1.1.0/24                                      LAN: 10.2.2.0/24

   ┌─────────┐          ┌─────────────────┐          ┌─────────┐
   │  PC-A   │          │                 │          │  PC-B   │
   │10.1.1.10│          │   ISP CLOUD     │          │10.2.2.10│
   └────┬────┘          │                 │          └────┬────┘
        │               └────┬───────┬────┘               │
   ┌────┴────┐               │       │               ┌────┴────┐
   │  SW-A   │          ┌────┴──┐ ┌──┴────┐          │  SW-B   │
   └────┬────┘          │ISP-R1│ │ISP-R2 │          └────┬────┘
        │               └───┬──┘ └──┬────┘               │
   ┌────┴──────┐            │       │            ┌───────┴────┐
   │   R1      │            │       │            │    R2      │
   │           ├────────────┘       └────────────┤            │
   │Gi0/0:    │                                  │Gi0/0:     │
   │10.1.1.1  │    ╔════════════════════════╗    │10.2.2.1   │
   │          │    ║  GRE TUNNEL            ║    │           │
   │Gi0/1:    │    ║  Tunnel0               ║    │Gi0/1:    │
   │1.1.1.1/30├────╢  172.16.0.1 <-> .2    ╟────┤2.2.2.1/30│
   │          │    ║  Source: 1.1.1.1       ║    │           │
   │Tunnel0:  │    ║  Dest:   2.2.2.1      ║    │Tunnel0:  │
   │172.16.   │    ╚════════════════════════╝    │172.16.   │
   │0.1/30    │                                  │0.2/30    │
   └──────────┘                                  └──────────┘
```

### Configuration R1 (Site A)

```
enable
configure terminal
hostname R1
!
! --- Interfaces physiques ---
interface gigabitethernet 0/0
 description LAN_SITE_A
 ip address 10.1.1.1 255.255.255.0
 no shutdown
 exit
!
interface gigabitethernet 0/1
 description WAN_VERS_INTERNET
 ip address 1.1.1.1 255.255.255.252
 no shutdown
 exit
!
! --- Tunnel GRE ---
interface tunnel 0
 description GRE_TUNNEL_VERS_SITE_B
 ip address 172.16.0.1 255.255.255.252
 tunnel source gigabitethernet 0/1
 tunnel destination 2.2.2.1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 no shutdown
 exit
!
! --- Route statique vers LAN Site B via le tunnel ---
ip route 10.2.2.0 255.255.255.0 172.16.0.2
!
! --- Route par defaut vers Internet ---
ip route 0.0.0.0 0.0.0.0 1.1.1.2
!
end
```

### Configuration R2 (Site B)

```
enable
configure terminal
hostname R2
!
! --- Interfaces physiques ---
interface gigabitethernet 0/0
 description LAN_SITE_B
 ip address 10.2.2.1 255.255.255.0
 no shutdown
 exit
!
interface gigabitethernet 0/1
 description WAN_VERS_INTERNET
 ip address 2.2.2.1 255.255.255.252
 no shutdown
 exit
!
! --- Tunnel GRE ---
interface tunnel 0
 description GRE_TUNNEL_VERS_SITE_A
 ip address 172.16.0.2 255.255.255.252
 tunnel source gigabitethernet 0/1
 tunnel destination 1.1.1.1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 no shutdown
 exit
!
! --- Route statique vers LAN Site A via le tunnel ---
ip route 10.1.1.0 255.255.255.0 172.16.0.1
!
! --- Route par defaut vers Internet ---
ip route 0.0.0.0 0.0.0.0 2.2.2.2
!
end
```

### Tests de Validation

```
! Sur R1 :
ping 172.16.0.2
ping 10.2.2.1
ping 10.2.2.10

! Sur PC-A :
ping 10.2.2.10

! Verification tunnel :
show interface tunnel 0
show ip route
show ip interface brief
```

### Commandes de Verification

```
show interface tunnel 0
show ip interface brief | include Tunnel
show ip route | include 10.2.2
show ip route static
show running-config interface tunnel 0
```

### Questions de Revision - Lab 4

1. Quel protocole IP est utilise par GRE ?
2. Pourquoi utiliser une interface tunnel plutot qu'un VPN IPsec classique ?
3. Le trafic GRE est-il chiffre par defaut ?
4. Comment fonctionne le routage a travers le tunnel GRE ?

**Reponses :**
1. GRE utilise le protocole IP 47.
2. L'interface tunnel est routable (on peut faire du routage dynamique OSPF/EIGRP dessus) et supporte le multicast, contrairement a IPsec pur qui ne gere que l'unicast.
3. Non, GRE n'offre aucun chiffrement. Il faut combiner GRE avec IPsec (GRE over IPsec) pour la confidentialite.
4. Le routeur encapsule le paquet IP original dans un en-tete GRE, puis dans un nouvel en-tete IP avec les adresses source/destination du tunnel. Le routeur distant decapsule et route normalement.

---

## Lab 5 : Configuration AAA Locale

### Objectif

Configurer l'authentification, l'autorisation et la comptabilite (AAA) en mode local sur un routeur Cisco pour securiser l'acces administratif.

### Topologie

```
                    ┌──────────────┐
                    │    R1        │
                    │              │
                    │  AAA Local   │
                    │  SSH active  │
                    │              │
                    │ Gi0/0:      │
                    │ 192.168.1.1 │
                    │              │
                    │ Console:    │
                    │ AAA local   │
                    │              │
                    │ VTY 0-4:    │
                    │ SSH only    │
                    │ AAA local   │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │   SW1       │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────┴────┐  ┌───┴────┐  ┌────┴────┐
         │ ADMIN   │  │ TECH   │  │ GUEST   │
         │ Level 15│  │ Level 7│  │ Level 1 │
         │ .1.10   │  │ .1.20  │  │ .1.30   │
         └─────────┘  └────────┘  └─────────┘

Utilisateurs :
  admin  : privilege 15 (acces complet)
  tech   : privilege 7  (show + debug limite)
  guest  : privilege 1  (show basique uniquement)
```

### Configuration AAA Locale

```
enable
configure terminal
hostname R1
!
! --- Etape 1 : Activer AAA ---
aaa new-model
!
! --- Etape 2 : Creer les utilisateurs locaux ---
username admin privilege 15 algorithm-type scrypt secret Admin@2024!
username tech privilege 7 algorithm-type scrypt secret Tech@2024!
username guest privilege 1 algorithm-type scrypt secret Guest@2024!
!
! --- Etape 3 : Configurer l'authentification ---
! Methode : local d'abord, puis enable password en backup
aaa authentication login default local
aaa authentication login CONSOLE local
aaa authentication login VTY-AUTH local
!
! --- Etape 4 : Configurer l'autorisation ---
aaa authorization exec default local
aaa authorization commands 7 default local
aaa authorization commands 15 default local
!
! --- Etape 5 : Configurer la comptabilite ---
aaa accounting exec default start-stop group tacacs+
aaa accounting commands 15 default start-stop group tacacs+
!
! Note : comptabilite locale via syslog si pas de serveur TACACS+ :
logging buffered 64000 informational
!
! --- Etape 6 : Configurer SSH ---
ip domain-name lab.local
crypto key generate rsa modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
!
! --- Etape 7 : Configurer la console ---
line console 0
 login authentication CONSOLE
 exec-timeout 5 0
 logging synchronous
 exit
!
! --- Etape 8 : Configurer VTY (SSH uniquement) ---
line vty 0 4
 login authentication VTY-AUTH
 transport input ssh
 exec-timeout 10 0
 logging synchronous
 exit
!
! --- Etape 9 : Commandes par niveau de privilege ---
! Niveau 7 (tech) : acces aux commandes show et debug limites
privilege exec level 7 show running-config
privilege exec level 7 show ip interface brief
privilege exec level 7 show ip route
privilege exec level 7 debug ip icmp
privilege exec level 7 undebug all
!
end
write memory
```

### Tests de Validation

```
! Test 1 : Connexion SSH en tant que admin
! ssh -l admin 192.168.1.1
!   Attendu : Prompt R1# (privilege 15)

! Test 2 : Connexion SSH en tant que tech
! ssh -l tech 192.168.1.1
!   Attendu : Prompt R1> avec acces limite

! Test 3 : Connexion SSH en tant que guest
! ssh -l guest 192.168.1.1
!   Attendu : Prompt R1> avec show basique uniquement

! Test 4 : Tentative Telnet
!   Attendu : Connexion refusee (transport input ssh)

! Test 5 : 3 tentatives echouees
!   Attendu : Connexion fermee apres 3 echecs
```

### Commandes de Verification

```
show aaa sessions
show aaa local user lockout
show privilege
show users
show ssh
show line vty 0 4
show running-config | section aaa
show running-config | section line
show crypto key mypubkey rsa
```

### Questions de Revision - Lab 5

1. Que fait la commande `aaa new-model` ?
2. Quelle est la difference entre authentication et authorization ?
3. Pourquoi utiliser `algorithm-type scrypt` pour les mots de passe ?
4. Quel est l'avantage de SSH v2 sur SSH v1 ?

**Reponses :**
1. `aaa new-model` active le framework AAA et desactive les anciennes methodes d'authentification (login local simple). Toute authentification passe desormais par le modele AAA.
2. **Authentication** : verifie l'identite (qui es-tu ?). **Authorization** : definit les droits (qu'as-tu le droit de faire ?).
3. Scrypt est un algorithme de hachage resistant aux attaques par force brute et dictionnaire (plus securise que MD5 type 5 ou SHA-256 type 8).
4. SSH v2 offre un meilleur chiffrement, une authentification plus robuste et corrige des vulnerabilites connues de SSH v1.

---

## Lab 6 : Hardening Switch/Router (Desactiver Services Inutiles, Banner, SSH)

### Objectif

Securiser un switch et un routeur en desactivant les services inutiles, configurant les bannieres, limitant les acces et appliquant les bonnes pratiques de durcissement.

### Topologie

```
                    ┌──────────────┐
                    │  INTERNET    │
                    └──────┬───────┘
                           │
                    ┌──────┴──────────────────┐
                    │         R1              │
                    │   (Router de bordure)   │
                    │                         │
                    │   Services a desactiver:│
                    │   - CDP sur WAN         │
                    │   - HTTP server         │
                    │   - IP source routing   │
                    │   - Finger              │
                    │   - Bootp server        │
                    │   + NTP, logging, SSH   │
                    └──────┬──────────────────┘
                           │
                    ┌──────┴──────────────────┐
                    │         SW1             │
                    │   (Switch access)       │
                    │                         │
                    │   Services a desactiver:│
                    │   - Ports inutilises    │
                    │   - CDP sur access      │
                    │   - DTP sur access      │
                    │   - VLAN 1 management   │
                    │   + Port-security       │
                    │   + DHCP snooping       │
                    └──────┬──────────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────┴────┐  ┌───┴────┐  ┌────┴────┐
         │  PC-1   │  │ PC-2   │  │  VIDE   │
         │ Fa0/1   │  │ Fa0/2  │  │ Fa0/3-24│
         └─────────┘  └────────┘  └─────────┘
                                   (shutdown)
```

### Hardening Router R1

```
enable
configure terminal
hostname R1
!
! === DESACTIVER LES SERVICES INUTILES ===
!
! Desactiver le serveur HTTP/HTTPS integre
no ip http server
no ip http secure-server
!
! Desactiver CDP sur l'interface WAN (fuite d'information)
interface gigabitethernet 0/0
 description WAN_INTERNET
 no cdp enable
 exit
!
! Desactiver les services reseau dangereux
no ip source-route
no ip finger
no ip bootp server
no service finger
no service pad
no service udp-small-servers
no service tcp-small-servers
no ip gratuitous-arps
!
! Desactiver les redirections ICMP
interface gigabitethernet 0/0
 no ip redirects
 no ip unreachables
 no ip proxy-arp
 exit
!
! === BANNIERES DE SECURITE ===
!
banner motd ^
*************************************************************
*  ACCES RESERVE AU PERSONNEL AUTORISE UNIQUEMENT           *
*  Toute tentative d'acces non autorisee sera poursuivie    *
*  conformement a la legislation en vigueur.                *
*  Les sessions sont enregistrees et surveillees.           *
*************************************************************
^
!
banner login ^
ATTENTION : Systeme prive. Identifiez-vous.
^
!
! === SECURISER LA CONSOLE ===
!
line console 0
 exec-timeout 5 0
 logging synchronous
 login local
 exit
!
! === SECURISER LES LIGNES VTY ===
!
line vty 0 4
 exec-timeout 10 0
 transport input ssh
 login local
 access-class VTY-ACCESS in
 logging synchronous
 exit
!
! ACL pour limiter l'acces SSH
ip access-list standard VTY-ACCESS
 permit 192.168.30.0 0.0.0.255
 deny any log
 exit
!
! === CONFIGURER SSH ===
!
ip domain-name entreprise.local
crypto key generate rsa modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
!
! === CONFIGURER NTP ===
!
ntp server 10.1.1.100
ntp authenticate
ntp authentication-key 1 md5 NTP-Secret2024
ntp trusted-key 1
!
! === CONFIGURER LE LOGGING ===
!
logging buffered 64000 informational
logging console critical
logging trap informational
logging host 192.168.30.50
service timestamps log datetime msec localtime show-timezone
service timestamps debug datetime msec localtime show-timezone
!
! === SECURISER ENABLE ===
!
enable algorithm-type scrypt secret EnableSecret2024!
service password-encryption
!
! === DESACTIVER AUX PORT ===
!
line aux 0
 no exec
 transport input none
 exit
!
end
write memory
```

### Hardening Switch SW1

```
enable
configure terminal
hostname SW1
!
! === DESACTIVER LES PORTS INUTILISES ===
!
interface range fastethernet 0/3-24
 shutdown
 switchport mode access
 switchport access vlan 999
 description UNUSED_PORT_DISABLED
 exit
!
! Creer le VLAN poubelle pour les ports inutilises
vlan 999
 name BLACKHOLE
 exit
!
! === DESACTIVER DTP SUR LES PORTS ACCESS ===
!
interface range fastethernet 0/1-2
 switchport mode access
 switchport nonegotiate
 exit
!
! === CONFIGURER VLAN MANAGEMENT DEDIE ===
! (ne pas utiliser VLAN 1)
!
vlan 99
 name MANAGEMENT
 exit
!
interface vlan 99
 ip address 192.168.99.10 255.255.255.0
 no shutdown
 exit
!
! Desactiver l'interface VLAN 1
interface vlan 1
 shutdown
 exit
!
! === DESACTIVER CDP SUR LES PORTS ACCESS ===
!
interface range fastethernet 0/1-24
 no cdp enable
 exit
!
! Garder CDP sur les uplinks (trunk)
interface range gigabitethernet 0/1-2
 cdp enable
 exit
!
! === CONFIGURER DHCP SNOOPING ===
!
ip dhcp snooping
ip dhcp snooping vlan 10
!
interface gigabitethernet 0/1
 ip dhcp snooping trust
 exit
!
! === SECURISER LES TRUNKS ===
!
interface gigabitethernet 0/1
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 10,20,30,99
 switchport nonegotiate
 exit
!
! === BANNIERES ===
!
banner motd ^
*************************************************************
*  ACCES RESERVE - Switch gere par le service IT            *
*  Sessions enregistrees et surveillees                     *
*************************************************************
^
!
! === DESACTIVER SERVICES INUTILES ===
!
no ip http server
no ip http secure-server
!
end
write memory
```

### Checklist de Verification Hardening

```
! === ROUTER ===
show running-config | include http
show running-config | include cdp
show running-config | include service
show ip ssh
show banner motd
show line console 0
show line vty 0 4
show ntp status
show logging
show access-lists VTY-ACCESS

! === SWITCH ===
show interfaces status
show vlan brief
show interfaces trunk
show ip dhcp snooping
show cdp neighbors
show running-config | include banner
```

### Questions de Revision - Lab 6

1. Pourquoi desactiver CDP sur les interfaces WAN ?
2. Quel est l'interet de placer les ports inutilises dans un VLAN poubelle ?
3. Pourquoi changer le VLAN natif sur les trunks ?
4. Citez 3 services a desactiver sur un routeur de bordure.
5. Pourquoi ne pas utiliser VLAN 1 pour le management ?

**Reponses :**
1. CDP divulgue des informations sensibles (modele, IOS, interfaces, IP) a tout appareil connecte. Sur une interface WAN, un attaquant pourrait collecter ces informations.
2. Les ports dans le VLAN poubelle (VLAN 999) sont isoles. Meme si quelqu'un branche un cable, il n'a acces a aucun reseau de production.
3. Changer le VLAN natif empeche les attaques de type VLAN hopping (double tagging). Par defaut, les trames non taguees sont dans VLAN 1, ce qui est exploitable.
4. HTTP server, finger, ip source-route, bootp server, CDP (sur WAN), small-servers (TCP/UDP).
5. VLAN 1 est le VLAN par defaut sur tous les ports. Il est difficile a securiser car tous les equipements l'utilisent par defaut. Un VLAN dedie (ex: 99) est plus facile a isoler et controler.

---

## Recapitulatif des Labs

```
┌──────┬────────────────────────┬─────────────────────────────────────┐
│ Lab  │ Theme                  │ Competences Acquises                │
├──────┼────────────────────────┼─────────────────────────────────────┤
│  1   │ Port-Security          │ Limiter MAC, modes violation,       │
│      │                        │ sticky, recovery err-disabled       │
├──────┼────────────────────────┼─────────────────────────────────────┤
│  2   │ DHCP Snooping + DAI   │ Trust/untrust, binding table,       │
│      │                        │ bloquer rogue DHCP, ARP spoofing   │
├──────┼────────────────────────┼─────────────────────────────────────┤
│  3   │ ACLs Securite          │ ACL standard/etendue, wildcard,     │
│      │                        │ placement, filtrage trafic          │
├──────┼────────────────────────┼─────────────────────────────────────┤
│  4   │ VPN GRE Tunnel         │ Tunnel GRE, encapsulation,          │
│      │                        │ routage inter-sites                 │
├──────┼────────────────────────┼─────────────────────────────────────┤
│  5   │ AAA Local              │ Authentication, authorization,      │
│      │                        │ privilege levels, SSH               │
├──────┼────────────────────────┼─────────────────────────────────────┤
│  6   │ Hardening              │ Desactiver services, bannieres,     │
│      │                        │ securiser trunks, ports inutilises │
└──────┴────────────────────────┴─────────────────────────────────────┘
```

---

*Exercices crees pour la revision CCNA*
*Auteur : Roadmvn*