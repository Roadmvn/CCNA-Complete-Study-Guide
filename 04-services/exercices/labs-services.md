# Labs et Exercices - Services Reseau

## Vue d'Ensemble

Cette section contient 5 labs pratiques et des questions de revision type CCNA couvrant NAT/PAT, DHCP, ACLs et le monitoring reseau.

---

## Lab 1 : NAT Statique + PAT

### Topologie

```
  PC-A                                                  Internet
  10.1.1.10/24    ┌───────────────────────┐            ┌──────────┐
  ────────────────>│ R1                    │────────────│  ISP     │
                   │ Gi0/0: 10.1.1.1/24   │            │          │
  PC-B             │ (inside)             │            └──────────┘
  10.1.1.20/24    │                       │
  ────────────────>│ Gi0/1: 203.0.113.2/30│
                   │ (outside)            │
  Serveur Web      │                       │
  10.1.1.100/24   │ NAT statique :        │
  ────────────────>│ 10.1.1.100 <-> 203.0.113.10 │
                   │ PAT pour tout le LAN │
                   └───────────────────────┘
```

### Objectifs

1. Configurer NAT statique pour le serveur web
2. Configurer PAT pour tous les hotes du LAN
3. Verifier les traductions NAT

### Instructions

```cisco
! ETAPE 1 : Configuration des interfaces
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip address 10.1.1.1 255.255.255.0
R1(config-if)# ip nat inside
R1(config-if)# no shutdown
R1(config-if)# exit

R1(config)# interface GigabitEthernet 0/1
R1(config-if)# ip address 203.0.113.2 255.255.255.252
R1(config-if)# ip nat outside
R1(config-if)# no shutdown
R1(config-if)# exit

! ETAPE 2 : Route par defaut vers ISP
R1(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1

! ETAPE 3 : NAT statique pour le serveur web
R1(config)# ip nat inside source static 10.1.1.100 203.0.113.10

! ETAPE 4 : PAT pour le reste du LAN
R1(config)# access-list 1 permit 10.1.1.0 0.0.0.255
R1(config)# ip nat inside source list 1 interface GigabitEthernet 0/1 overload
```

### Verification

```cisco
! Verifier les traductions
R1# show ip nat translations

! Verifier les statistiques
R1# show ip nat statistics

! Tester depuis PC-A (ping vers Internet)
PC-A> ping 8.8.8.8

! Tester l'acces au serveur web depuis Internet
! (simuler une connexion HTTP vers 203.0.113.10)
```

### Questions Lab 1

1. Si vous faites un ping depuis PC-A vers 8.8.8.8, quelle adresse IP source verra le serveur 8.8.8.8 ?
2. Si vous faites un ping depuis Internet vers 203.0.113.10, quel equipement recevra le paquet ?
3. Que se passe-t-il si vous oubliez `ip nat inside` sur Gi0/0 ?

---

## Lab 2 : DHCP Serveur + Relay Agent

### Topologie

```
  VLAN 10                    VLAN 20                  VLAN 30
  10.1.10.0/24               10.1.20.0/24             10.1.30.0/24
  (Utilisateurs)             (Serveurs)               (Invites)
       │                          │                        │
       │                     ┌────┴────┐                   │
       │                     │ Serveur │                   │
       │                     │ DHCP    │                   │
       │                     │10.1.20.100│                  │
       │                     └─────────┘                   │
  ┌────┴──────────────────────────┴────────────────────────┴────┐
  │                         R1                                   │
  │  Gi0/0: 10.1.10.1       Gi0/1: 10.1.20.1   Gi0/2: 10.1.30.1│
  │  ip helper-address      (serveur DHCP       ip helper-address│
  │  10.1.20.100            sur ce segment)     10.1.20.100      │
  └──────────────────────────────────────────────────────────────┘
```

### Objectifs

1. Configurer R1 comme serveur DHCP pour VLAN 10 et VLAN 30
2. Configurer le relay agent (ip helper-address)
3. Verifier les baux DHCP

### Instructions : Methode 1 - R1 comme serveur DHCP

```cisco
! ETAPE 1 : Configuration des interfaces
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip address 10.1.10.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit

R1(config)# interface GigabitEthernet 0/1
R1(config-if)# ip address 10.1.20.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit

R1(config)# interface GigabitEthernet 0/2
R1(config-if)# ip address 10.1.30.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit

! ETAPE 2 : Exclusions (adresses reservees)
R1(config)# ip dhcp excluded-address 10.1.10.1 10.1.10.10
R1(config)# ip dhcp excluded-address 10.1.30.1 10.1.30.10

! ETAPE 3 : Pool DHCP pour VLAN 10
R1(config)# ip dhcp pool VLAN10-USERS
R1(dhcp-config)# network 10.1.10.0 255.255.255.0
R1(dhcp-config)# default-router 10.1.10.1
R1(dhcp-config)# dns-server 8.8.8.8 8.8.4.4
R1(dhcp-config)# domain-name entreprise.local
R1(dhcp-config)# lease 1 0 0
R1(dhcp-config)# exit

! ETAPE 4 : Pool DHCP pour VLAN 30
R1(config)# ip dhcp pool VLAN30-GUESTS
R1(dhcp-config)# network 10.1.30.0 255.255.255.0
R1(dhcp-config)# default-router 10.1.30.1
R1(dhcp-config)# dns-server 8.8.8.8
R1(dhcp-config)# domain-name guest.local
R1(dhcp-config)# lease 0 4 0
R1(dhcp-config)# exit
```

### Instructions : Methode 2 - Serveur DHCP externe avec Relay

```cisco
! Si le serveur DHCP est sur VLAN 20 (10.1.20.100)
! Configurer le relay sur les interfaces cote clients

R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip helper-address 10.1.20.100
R1(config-if)# exit

R1(config)# interface GigabitEthernet 0/2
R1(config-if)# ip helper-address 10.1.20.100
R1(config-if)# exit
```

### Verification

```cisco
R1# show ip dhcp binding
R1# show ip dhcp pool
R1# show ip dhcp server statistics
R1# show ip dhcp conflict

! Debug si probleme
R1# debug ip dhcp server events
```

### Questions Lab 2

1. Pourquoi exclut-on les adresses 10.1.10.1 a 10.1.10.10 du pool ?
2. Si le DHCP relay est mal configure, quelle adresse le client obtiendra-t-il ?
3. Quelle est la difference entre `lease 1 0 0` et `lease 0 4 0` ?

---

## Lab 3 : ACL Standard + Etendue

### Topologie

```
  VLAN 10 - Users            VLAN 20 - Admins           VLAN 30 - Serveurs
  10.1.10.0/24               10.1.20.0/24               10.1.30.0/24
       │                          │                           │
  ┌─────────┐              ┌─────────┐                 ┌─────────────┐
  │ PC-User │              │PC-Admin │                 │ Srv-Web     │
  │10.1.10.50│             │10.1.20.50│                │ 10.1.30.100 │
  └─────────┘              └─────────┘                 │ (HTTP/HTTPS)│
       │                          │                     └─────────────┘
       │                          │                     ┌─────────────┐
  ┌────┴──────────────────────────┴──┐                 │ Srv-FTP     │
  │              R1                   │─────────────────│ 10.1.30.200 │
  │ Gi0/0         Gi0/1      Gi0/2   │                 │ (FTP/SSH)   │
  └───────────────────────────────────┘                 └─────────────┘
```

### Politique de Securite

```
1. Les Users (VLAN 10) peuvent acceder :
   - Au serveur web en HTTP (80) et HTTPS (443)
   - Au DNS (53)
   - Ping autorise (ICMP)
   - Tout autre acces aux serveurs est REFUSE

2. Les Admins (VLAN 20) ont un acces COMPLET

3. Personne ne peut faire Telnet (23) vers les serveurs
```

### Instructions

```cisco
! ETAPE 1 : ACL etendue pour les Users (pres de la source)
R1(config)# ip access-list extended USERS-FILTER
R1(config-ext-nacl)# remark -- Autorise HTTP/HTTPS vers serveurs --
R1(config-ext-nacl)# permit tcp 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255 eq 80
R1(config-ext-nacl)# permit tcp 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255 eq 443
R1(config-ext-nacl)# remark -- Autorise DNS --
R1(config-ext-nacl)# permit udp 10.1.10.0 0.0.0.255 any eq 53
R1(config-ext-nacl)# permit tcp 10.1.10.0 0.0.0.255 any eq 53
R1(config-ext-nacl)# remark -- Autorise ICMP --
R1(config-ext-nacl)# permit icmp 10.1.10.0 0.0.0.255 any
R1(config-ext-nacl)# remark -- Bloque tout autre acces aux serveurs --
R1(config-ext-nacl)# deny ip 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255
R1(config-ext-nacl)# remark -- Autorise tout le reste --
R1(config-ext-nacl)# permit ip any any
R1(config-ext-nacl)# exit

! Appliquer sur interface Users (IN = trafic entrant des users)
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip access-group USERS-FILTER in
R1(config-if)# exit

! ETAPE 2 : ACL pour bloquer Telnet vers serveurs (pres de la destination)
R1(config)# ip access-list extended NO-TELNET-SERVERS
R1(config-ext-nacl)# deny tcp any 10.1.30.0 0.0.0.255 eq 23
R1(config-ext-nacl)# permit ip any any
R1(config-ext-nacl)# exit

R1(config)# interface GigabitEthernet 0/2
R1(config-if)# ip access-group NO-TELNET-SERVERS out
R1(config-if)# exit
```

### Verification

```cisco
! Verifier les ACLs
R1# show access-lists
R1# show ip interface GigabitEthernet 0/0
R1# show ip interface GigabitEthernet 0/2

! Tests de connectivite
! Depuis PC-User :
! - ping 10.1.30.100 -> doit fonctionner (ICMP autorise)
! - HTTP vers 10.1.30.100:80 -> doit fonctionner
! - SSH vers 10.1.30.200:22 -> doit etre bloque
! - Telnet vers 10.1.30.100:23 -> doit etre bloque

! Depuis PC-Admin :
! - Tout doit fonctionner SAUF Telnet vers serveurs
```

### Questions Lab 3

1. Pourquoi l'ACL USERS-FILTER est-elle placee en IN sur Gi0/0 et pas en OUT sur Gi0/2 ?
2. Si on inverse les lignes `deny` et `permit ip any any` dans l'ACL, que se passe-t-il ?
3. Pourquoi faut-il autoriser explicitement le DNS (port 53) dans l'ACL Users ?

---

## Lab 4 : NTP + Syslog + SNMP

### Topologie

```
  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │ NTP Server   │     │ Syslog Server│     │ NMS (SNMP)   │
  │ 10.1.1.100   │     │ 10.1.1.200   │     │ 10.1.1.250   │
  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
         │                    │                     │
    ─────┴────────────────────┴─────────────────────┴─────
                              │
                        ┌─────┴─────┐
                        │    R1     │
                        │ 10.1.1.1  │
                        └─────┬─────┘
                              │
                        ┌─────┴─────┐
                        │    SW1    │
                        │ 10.1.1.10 │
                        └───────────┘
```

### Objectifs

1. Configurer NTP sur R1 et SW1
2. Configurer Syslog vers le serveur distant
3. Configurer SNMPv2c et SNMPv3
4. Configurer CDP et LLDP

### Instructions

```cisco
! === SUR R1 ===

! ETAPE 1 : NTP
R1(config)# clock timezone CET 1 0
R1(config)# ntp server 10.1.1.100
R1(config)# ntp master 3

! ETAPE 2 : Syslog
R1(config)# service timestamps log datetime msec localtime show-timezone
R1(config)# service sequence-numbers
R1(config)# logging host 10.1.1.200
R1(config)# logging trap informational
R1(config)# logging source-interface GigabitEthernet 0/0
R1(config)# logging buffered 32768 informational
R1(config)# logging console warnings

! ETAPE 3 : SNMPv2c
R1(config)# snmp-server community CCNA-RO ro
R1(config)# snmp-server community CCNA-RW rw
R1(config)# snmp-server host 10.1.1.250 version 2c CCNA-RO
R1(config)# snmp-server enable traps snmp linkdown linkup
R1(config)# snmp-server enable traps config
R1(config)# snmp-server contact admin@entreprise.local
R1(config)# snmp-server location "Site Principal - Salle Serveur"

! ETAPE 4 : SNMPv3 (plus securise)
R1(config)# snmp-server group MONITOR-GROUP v3 priv
R1(config)# snmp-server user monitor-user MONITOR-GROUP v3 auth sha MonAuth123 priv aes 128 MonPriv456

! ETAPE 5 : CDP et LLDP
R1(config)# cdp run
R1(config)# lldp run

! === SUR SW1 ===

! NTP pointe vers R1
SW1(config)# ntp server 10.1.1.1

! Syslog
SW1(config)# service timestamps log datetime msec localtime show-timezone
SW1(config)# logging host 10.1.1.200
SW1(config)# logging trap informational

! SNMP
SW1(config)# snmp-server community CCNA-RO ro
SW1(config)# snmp-server host 10.1.1.250 version 2c CCNA-RO
SW1(config)# snmp-server enable traps snmp linkdown linkup
```

### Verification

```cisco
! NTP
R1# show ntp status
R1# show ntp associations
R1# show clock

! Syslog
R1# show logging

! SNMP
R1# show snmp
R1# show snmp community
R1# show snmp group
R1# show snmp user

! CDP / LLDP
R1# show cdp neighbors
R1# show cdp neighbors detail
R1# show lldp neighbors
```

### Questions Lab 4

1. Si R1 est configure comme `ntp master 3`, quel sera le stratum de SW1 ?
2. Si vous configurez `logging trap warnings`, quels niveaux de severite seront envoyes au serveur Syslog ?
3. Pourquoi SNMPv3 est-il prefere a SNMPv2c en production ?

---

## Lab 5 : Troubleshooting Services

### Scenario 1 : NAT Ne Fonctionne Pas

```
Symptome : Les hotes internes ne peuvent pas acceder a Internet

Configuration actuelle :
  interface GigabitEthernet 0/0
   ip address 10.1.1.1 255.255.255.0
   ip nat inside
  interface GigabitEthernet 0/1
   ip address 203.0.113.2 255.255.255.252
  access-list 1 permit 10.1.1.0 0.0.0.255
  ip nat inside source list 1 interface GigabitEthernet 0/1 overload
```

**Diagnostic :** Trouvez les 2 erreurs.

<details>
<summary>Solution</summary>

Erreur 1 : `ip nat outside` manquant sur GigabitEthernet 0/1
Erreur 2 : Pas de route par defaut (`ip route 0.0.0.0 0.0.0.0 203.0.113.1`)

Corrections :
```cisco
R1(config)# interface GigabitEthernet 0/1
R1(config-if)# ip nat outside
R1(config-if)# exit
R1(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1
```
</details>

### Scenario 2 : DHCP Clients Obtiennent 169.254.x.x

```
Symptome : Les clients VLAN 10 obtiennent des adresses APIPA (169.254.x.x)

Configuration :
  ! Sur R1
  ip dhcp pool VLAN10
   network 10.1.10.0 255.255.255.0
   default-router 10.1.10.1
   dns-server 8.8.8.8

  ! Le serveur DHCP est sur 10.1.20.100 (VLAN 20)
  interface GigabitEthernet 0/1
   ip address 10.1.20.1 255.255.255.0
   ip helper-address 10.1.20.100
```

**Diagnostic :** Trouvez l'erreur.

<details>
<summary>Solution</summary>

Erreur : `ip helper-address` est configure sur l'interface VLAN 20 (cote serveur) au lieu de l'interface VLAN 10 (cote client). Le relay doit etre configure sur l'interface ou arrivent les broadcasts DHCP des clients.

Correction :
```cisco
R1(config)# interface GigabitEthernet 0/1
R1(config-if)# no ip helper-address 10.1.20.100
R1(config-if)# exit
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip helper-address 10.1.20.100
R1(config-if)# exit
```
</details>

### Scenario 3 : ACL Bloque Trop de Trafic

```
Symptome : Les utilisateurs ne peuvent acceder a aucun site web

Configuration ACL :
  ip access-list extended WEB-ACCESS
   deny ip 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255
   permit tcp 10.1.10.0 0.0.0.255 any eq 80
   permit tcp 10.1.10.0 0.0.0.255 any eq 443
```

**Diagnostic :** Trouvez l'erreur.

<details>
<summary>Solution</summary>

Erreur : La regle `deny` est AVANT les regles `permit`. Comme les ACLs sont evaluees de haut en bas, la ligne deny bloque tout le trafic vers les serveurs (y compris HTTP/HTTPS) avant que les regles permit ne soient evaluees.

De plus, il manque l'autorisation DNS (sans DNS, pas de resolution de noms, donc pas de navigation web).

Correction :
```cisco
ip access-list extended WEB-ACCESS
 permit tcp 10.1.10.0 0.0.0.255 any eq 80
 permit tcp 10.1.10.0 0.0.0.255 any eq 443
 permit udp 10.1.10.0 0.0.0.255 any eq 53
 permit tcp 10.1.10.0 0.0.0.255 any eq 53
 deny ip 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255
 permit ip any any
```
</details>

### Scenario 4 : Logs avec Mauvais Timestamps

```
Symptome : Les logs affichent des timestamps incorrects ou "no timestamp"

Logs actuels :
  %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to down

Configuration :
  no service timestamps log
```

**Diagnostic :** Comment corriger ?

<details>
<summary>Solution</summary>

1. Activer les timestamps :
```cisco
R1(config)# service timestamps log datetime msec localtime show-timezone
```

2. Configurer NTP pour l'heure exacte :
```cisco
R1(config)# clock timezone CET 1 0
R1(config)# ntp server 10.1.1.100
```

3. Verifier :
```cisco
R1# show clock
R1# show ntp status
```
</details>

---

## Questions de Revision Type CCNA

### Section A : NAT/PAT (10 Questions)

**Q1.** Quel type de NAT associe une adresse privee a une adresse publique de facon permanente ?
- a) NAT dynamique
- b) NAT statique
- c) PAT
- d) NAT overload

<details><summary>Reponse</summary>b) NAT statique</details>

**Q2.** Quelle commande configure PAT avec l'adresse de l'interface de sortie ?
- a) `ip nat inside source list 1 pool POOL`
- b) `ip nat inside source static 10.1.1.10 203.0.113.1`
- c) `ip nat inside source list 1 interface Gi0/1 overload`
- d) `ip nat outside source list 1 interface Gi0/1`

<details><summary>Reponse</summary>c) `ip nat inside source list 1 interface Gi0/1 overload`</details>

**Q3.** Quelle est la difference entre Inside Local et Inside Global ?
- a) Inside Local est l'IP publique, Inside Global est l'IP privee
- b) Inside Local est l'IP privee vue depuis l'interieur, Inside Global est l'IP publique representant l'hote interne
- c) Ce sont deux noms pour la meme adresse
- d) Inside Local est pour IPv6, Inside Global est pour IPv4

<details><summary>Reponse</summary>b) Inside Local est l'IP privee vue depuis l'interieur, Inside Global est l'IP publique representant l'hote interne</details>

**Q4.** Quelle commande affiche les traductions NAT actives ?
- a) `show nat translations`
- b) `show ip nat translations`
- c) `show ip nat statistics`
- d) `show nat table`

<details><summary>Reponse</summary>b) `show ip nat translations`</details>

**Q5.** Combien de sessions simultanees le PAT peut-il theoriquement supporter avec une seule adresse publique ?
- a) 254
- b) 1024
- c) Environ 65 000
- d) Illimite

<details><summary>Reponse</summary>c) Environ 65 000 (nombre de ports disponibles)</details>

### Section B : DHCP (10 Questions)

**Q6.** Dans le processus DORA, quel message est envoye en premier par le client ?
- a) DHCP Offer
- b) DHCP Request
- c) DHCP Discover
- d) DHCP Acknowledge

<details><summary>Reponse</summary>c) DHCP Discover</details>

**Q7.** Pourquoi le DHCP Discover est-il envoye en broadcast ?
- a) C'est plus rapide qu'en unicast
- b) Le client ne connait pas l'adresse du serveur DHCP
- c) Le serveur DHCP l'exige
- d) Pour des raisons de securite

<details><summary>Reponse</summary>b) Le client ne connait pas l'adresse du serveur DHCP (il n'a pas encore d'IP)</details>

**Q8.** Quelle commande configure un relay agent DHCP sur une interface Cisco ?
- a) `dhcp relay 10.1.1.100`
- b) `ip helper-address 10.1.1.100`
- c) `ip dhcp relay 10.1.1.100`
- d) `ip forward-protocol dhcp 10.1.1.100`

<details><summary>Reponse</summary>b) `ip helper-address 10.1.1.100`</details>

**Q9.** A quel pourcentage du bail le client DHCP tente-t-il un renouvellement (T1) ?
- a) 25%
- b) 50%
- c) 75%
- d) 87.5%

<details><summary>Reponse</summary>b) 50% du bail (T1 = Renewal)</details>

**Q10.** Quelle adresse obtient un client si aucun serveur DHCP n'est joignable ?
- a) 0.0.0.0
- b) 255.255.255.255
- c) 169.254.x.x (APIPA)
- d) 127.0.0.1

<details><summary>Reponse</summary>c) 169.254.x.x (APIPA - Automatic Private IP Addressing)</details>

### Section C : ACLs (10 Questions)

**Q11.** Quelle est la plage de numeros des ACL standard ?
- a) 1-99 et 1300-1999
- b) 100-199 et 2000-2699
- c) 1-199
- d) 200-299

<details><summary>Reponse</summary>a) 1-99 et 1300-1999</details>

**Q12.** Ou doit-on placer une ACL standard ?
- a) Pres de la source
- b) Pres de la destination
- c) Au milieu du reseau
- d) Sur tous les routeurs

<details><summary>Reponse</summary>b) Pres de la destination</details>

**Q13.** Quel est le wildcard mask pour le reseau 192.168.1.0/24 ?
- a) 255.255.255.0
- b) 0.0.0.255
- c) 255.0.0.0
- d) 0.0.0.0

<details><summary>Reponse</summary>b) 0.0.0.255 (255.255.255.255 - 255.255.255.0)</details>

**Q14.** Que fait le "deny implicite" a la fin de chaque ACL ?
- a) Autorise tout le trafic restant
- b) Refuse tout le trafic qui ne match aucune regle
- c) Envoie le trafic vers une autre ACL
- d) Journalise le trafic non matche

<details><summary>Reponse</summary>b) Refuse tout le trafic qui ne match aucune regle</details>

**Q15.** Quelle commande applique une ACL sur une interface en direction entrante ?
- a) `ip access-group 100 in`
- b) `ip access-list 100 in`
- c) `access-group 100 inbound`
- d) `ip access-class 100 in`

<details><summary>Reponse</summary>a) `ip access-group 100 in`</details>

### Section D : Monitoring (10 Questions)

**Q16.** Quel est le niveau de severite Syslog pour "Warning" ?
- a) 3
- b) 4
- c) 5
- d) 6

<details><summary>Reponse</summary>b) 4 (Warning)</details>

**Q17.** Quel protocole de couche 2 est proprietaire Cisco pour la decouverte de voisins ?
- a) LLDP
- b) CDP
- c) SNMP
- d) STP

<details><summary>Reponse</summary>b) CDP (Cisco Discovery Protocol)</details>

**Q18.** Quelle version de SNMP offre l'authentification et le chiffrement ?
- a) SNMPv1
- b) SNMPv2c
- c) SNMPv3
- d) Toutes les versions

<details><summary>Reponse</summary>c) SNMPv3 (avec le niveau de securite authPriv)</details>

**Q19.** Quel est le role du stratum dans NTP ?
- a) Definir la frequence de synchronisation
- b) Indiquer la distance par rapport a la source de reference (precision)
- c) Chiffrer les communications NTP
- d) Limiter le nombre de clients NTP

<details><summary>Reponse</summary>b) Indiquer la distance par rapport a la source de reference (plus le stratum est bas, plus la source est precise)</details>

**Q20.** Quelle est la difference entre un SNMP Trap et un SNMP Inform ?
- a) Les Traps sont chiffres, les Informs ne le sont pas
- b) Les Traps n'ont pas d'accusé de reception, les Informs en ont un
- c) Les Traps sont pour SNMPv2, les Informs pour SNMPv3
- d) Aucune difference

<details><summary>Reponse</summary>b) Les Traps n'ont pas d'accusé de reception (fire-and-forget), les Informs sont acquittes par le NMS</details>

---

## Grille d'Evaluation

```
┌────────────────────────────┬───────────────────┐
│ Score                      │ Niveau            │
├────────────────────────────┼───────────────────┤
│ 18-20 correct              │ Expert            │
│ 14-17 correct              │ Avance            │
│ 10-13 correct              │ Intermediaire     │
│ 6-9 correct                │ Debutant          │
│ 0-5 correct                │ A revoir          │
└────────────────────────────┴───────────────────┘
```

---

*Exercices crees pour la revision CCNA*
*Auteur : Roadmvn*
