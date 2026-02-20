# DHCP - Dynamic Host Configuration Protocol

## Vue d'Ensemble

Le DHCP (Dynamic Host Configuration Protocol) permet d'attribuer automatiquement des adresses IP et d'autres parametres reseau aux hotes. Il elimine la necessite de configurer manuellement chaque equipement et centralise la gestion de l'adressage IP.

## Processus DORA

Le DHCP fonctionne en 4 etapes, memorisees par l'acronyme **DORA** :

```
CLIENT                                              SERVEUR DHCP
(0.0.0.0)                                          (10.1.1.1)
   │                                                     │
   │  1. DHCP DISCOVER (Broadcast)                       │
   │  "Y a-t-il un serveur DHCP ici ?"                  │
   │  Src: 0.0.0.0       Dst: 255.255.255.255           │
   │  Src MAC: AA:BB:CC   Dst MAC: FF:FF:FF:FF:FF:FF    │
   │─────────────────────────────────────────────────────>│
   │                                                     │
   │  2. DHCP OFFER (Unicast ou Broadcast)               │
   │  "Oui, je te propose l'IP 10.1.1.50"               │
   │  Contient : IP proposee, masque, bail, gateway, DNS │
   │<─────────────────────────────────────────────────────│
   │                                                     │
   │  3. DHCP REQUEST (Broadcast)                        │
   │  "J'accepte l'IP 10.1.1.50"                        │
   │  Src: 0.0.0.0       Dst: 255.255.255.255           │
   │  (Broadcast car d'autres serveurs DHCP peuvent      │
   │   etre presents et doivent savoir que l'offre       │
   │   n'a pas ete retenue)                              │
   │─────────────────────────────────────────────────────>│
   │                                                     │
   │  4. DHCP ACKNOWLEDGE (Unicast ou Broadcast)         │
   │  "Confirme : 10.1.1.50 est a toi pour 24h"         │
   │  Le client configure son interface                  │
   │<─────────────────────────────────────────────────────│
   │                                                     │
   (10.1.1.50)                                           │
   Client configure                                      │
```

### Contenu des Messages DHCP

```
┌────────────────────┬────────────────────────────────────────────┐
│ Message            │ Contenu Principal                          │
├────────────────────┼────────────────────────────────────────────┤
│ DISCOVER           │ - MAC du client                            │
│ (client -> serveur)│ - Identifiant de transaction (XID)         │
│                    │ - Options demandees (masque, GW, DNS)      │
├────────────────────┼────────────────────────────────────────────┤
│ OFFER              │ - IP proposee (yiaddr)                     │
│ (serveur -> client)│ - Masque de sous-reseau                    │
│                    │ - Passerelle par defaut                    │
│                    │ - Serveurs DNS                             │
│                    │ - Duree du bail (lease time)               │
│                    │ - IP du serveur DHCP                       │
├────────────────────┼────────────────────────────────────────────┤
│ REQUEST            │ - IP demandee (celle de l'OFFER)           │
│ (client -> serveur)│ - Identifiant du serveur DHCP choisi       │
│                    │ - Identifiant de transaction (XID)         │
├────────────────────┼────────────────────────────────────────────┤
│ ACKNOWLEDGE        │ - Confirmation de l'IP                     │
│ (serveur -> client)│ - Tous les parametres reseau               │
│                    │ - Duree du bail confirmee                  │
└────────────────────┴────────────────────────────────────────────┘
```

### Renouvellement du Bail

```
Duree du bail : 24 heures (exemple)

Temps 0h          12h (50%)           18h (87.5%)        24h
  │                  │                    │                │
  │  Bail obtenu     │  T1 : Renewal     │  T2 : Rebind   │ Expiration
  │                  │  (Unicast au       │  (Broadcast a  │ (IP perdue)
  │                  │   meme serveur)    │   tout serveur)│
  │                  │                    │                │
  ├──────────────────┼────────────────────┼────────────────┤
  │  Utilisation     │  REQUEST unicast   │  REQUEST bcast │
  │  normale         │  -> ACK = renouvele│  -> ACK = OK   │
  │                  │  -> NACK = rebind  │  -> NACK = stop│
```

---

## Configuration DHCP sur Routeur Cisco

### Serveur DHCP Basique

```cisco
! 1. Exclure les adresses reservees (routeur, serveurs, imprimantes)
Router(config)# ip dhcp excluded-address 10.1.1.1 10.1.1.10

! 2. Creer le pool DHCP
Router(config)# ip dhcp pool LAN-POOL
Router(dhcp-config)# network 10.1.1.0 255.255.255.0
Router(dhcp-config)# default-router 10.1.1.1
Router(dhcp-config)# dns-server 8.8.8.8 8.8.4.4
Router(dhcp-config)# domain-name entreprise.local
Router(dhcp-config)# lease 1 0 0
Router(dhcp-config)# exit
```

### Plusieurs Pools DHCP (Multi-VLAN)

```cisco
! Pool pour VLAN 10 - Utilisateurs
Router(config)# ip dhcp excluded-address 192.168.10.1 192.168.10.10
Router(config)# ip dhcp pool VLAN10-USERS
Router(dhcp-config)# network 192.168.10.0 255.255.255.0
Router(dhcp-config)# default-router 192.168.10.1
Router(dhcp-config)# dns-server 10.1.1.100
Router(dhcp-config)# lease 8 0 0
Router(dhcp-config)# exit

! Pool pour VLAN 20 - Serveurs
Router(config)# ip dhcp excluded-address 192.168.20.1 192.168.20.20
Router(config)# ip dhcp pool VLAN20-SERVERS
Router(dhcp-config)# network 192.168.20.0 255.255.255.0
Router(dhcp-config)# default-router 192.168.20.1
Router(dhcp-config)# dns-server 10.1.1.100
Router(dhcp-config)# lease 30 0 0
Router(dhcp-config)# exit

! Pool pour VLAN 30 - VoIP
Router(config)# ip dhcp excluded-address 192.168.30.1 192.168.30.10
Router(config)# ip dhcp pool VLAN30-VOIP
Router(dhcp-config)# network 192.168.30.0 255.255.255.0
Router(dhcp-config)# default-router 192.168.30.1
Router(dhcp-config)# dns-server 10.1.1.100
Router(dhcp-config)# option 150 ip 10.1.1.200
Router(dhcp-config)# lease 1 0 0
Router(dhcp-config)# exit
```

---

## DHCP Relay Agent (ip helper-address)

### Probleme

Les messages DHCP DISCOVER sont des broadcasts. Ils ne traversent pas les routeurs. Si le serveur DHCP est dans un autre sous-reseau, les clients ne le trouvent pas.

### Solution : ip helper-address

```
VLAN 10 (10.1.10.0/24)              VLAN 20 (10.1.20.0/24)
┌─────────┐                         ┌──────────────┐
│ Client  │                         │ Serveur DHCP │
│ DHCP    │                         │ 10.1.20.100  │
│(0.0.0.0)│                         └──────────────┘
└─────────┘                                │
     │                                     │
     │ 1. DISCOVER                         │
     │    (broadcast)                      │
     v                                     │
┌──────────────────────────────────────────┐
│              ROUTEUR                     │
│                                          │
│ Gi0/0 (10.1.10.1)    Gi0/1 (10.1.20.1) │
│ ip helper-address     Vers serveur DHCP │
│  10.1.20.100                            │
│                                          │
│ Le routeur recoit le broadcast DHCP      │
│ sur Gi0/0 et le retransmet en UNICAST    │
│ vers 10.1.20.100 via Gi0/1              │
└──────────────────────────────────────────┘
     │                                     │
     │ 2. DISCOVER retransmis              │
     │    (unicast vers 10.1.20.100)       │
     │ ──────────────────────────────────> │
     │                                     │
     │ 3. OFFER en unicast                 │
     │ <────────────────────────────────── │
     │                                     │
     │ 4. REQUEST/ACK                      │
     │ <──────────────────────────────────>│
```

### Configuration Cisco : DHCP Relay

```cisco
! Sur le routeur, interface cote client (pas cote serveur)
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip address 10.1.10.1 255.255.255.0
Router(config-if)# ip helper-address 10.1.20.100
Router(config-if)# exit

! Si plusieurs serveurs DHCP (redondance)
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip helper-address 10.1.20.100
Router(config-if)# ip helper-address 10.1.20.101
Router(config-if)# exit
```

### Services relaye par ip helper-address

```
ip helper-address relaye par defaut ces protocoles UDP :
┌──────────────────────┬───────────┐
│ Service              │ Port UDP  │
├──────────────────────┼───────────┤
│ DHCP/BOOTP (client)  │ 67        │
│ DHCP/BOOTP (serveur) │ 68        │
│ DNS                  │ 53        │
│ TFTP                 │ 69        │
│ TACACS               │ 49        │
│ NetBIOS Name Service │ 137       │
│ NetBIOS Datagram     │ 138       │
│ Time Service         │ 37        │
└──────────────────────┴───────────┘
```

---

## DHCPv6

### Modes de Configuration IPv6

```
┌────────────────────────┬──────────────────────┬──────────────────────┐
│ Methode                │ Adresse IPv6          │ Autres Params (DNS..)│
├────────────────────────┼──────────────────────┼──────────────────────┤
│ SLAAC seul             │ Auto-generee (EUI-64)│ Via RA du routeur    │
│ (Stateless)            │                      │ (RDNSS)              │
├────────────────────────┼──────────────────────┼──────────────────────┤
│ SLAAC + DHCPv6         │ Auto-generee (EUI-64)│ Via DHCPv6           │
│ Stateless              │                      │ (O flag = 1)         │
├────────────────────────┼──────────────────────┼──────────────────────┤
│ DHCPv6 Stateful        │ Attribuee par DHCPv6 │ Via DHCPv6           │
│                        │ (M flag = 1)         │                      │
├────────────────────────┼──────────────────────┼──────────────────────┤
│ Manuel                 │ Configuree a la main │ Configure a la main  │
└────────────────────────┴──────────────────────┴──────────────────────┘
```

### SLAAC (Stateless Address Autoconfiguration)

```
Processus SLAAC :

1. Le routeur envoie des Router Advertisements (RA) periodiques
   ou en reponse a un Router Solicitation (RS) du client

2. Le RA contient :
   - Prefixe reseau (ex: 2001:db8:1::/64)
   - Flags M et O
   - Duree de vie du prefixe

3. Le client genere son adresse :
   Prefixe (64 bits) + Interface ID (64 bits via EUI-64 ou aleatoire)

Exemple EUI-64 :
   MAC : AA:BB:CC:DD:EE:FF
   -> Inserer FF:FE au milieu : AA:BB:CC:FF:FE:DD:EE:FF
   -> Inverser le 7e bit : A8:BB:CC:FF:FE:DD:EE:FF

   Adresse finale : 2001:db8:1::a8bb:ccff:fedd:eeff/64

Flags RA :
┌──────┬───────────────────────────────────────────┐
│ Flag │ Signification                              │
├──────┼───────────────────────────────────────────┤
│ M=0  │ Ne pas utiliser DHCPv6 pour l'adresse     │
│ M=1  │ Utiliser DHCPv6 Stateful pour l'adresse   │
│ O=0  │ Ne pas utiliser DHCPv6 pour les options    │
│ O=1  │ Utiliser DHCPv6 Stateless pour les options │
└──────┴───────────────────────────────────────────┘
```

### Configuration DHCPv6 Stateless

```cisco
! Sur le routeur (serveur DHCPv6 stateless)
Router(config)# ipv6 unicast-routing

Router(config)# ipv6 dhcp pool DHCPv6-STATELESS
Router(config-dhcpv6)# dns-server 2001:4860:4860::8888
Router(config-dhcpv6)# domain-name entreprise.local
Router(config-dhcpv6)# exit

Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ipv6 address 2001:db8:1::1/64
Router(config-if)# ipv6 dhcp server DHCPv6-STATELESS
Router(config-if)# ipv6 nd other-config-flag
Router(config-if)# exit
```

### Configuration DHCPv6 Stateful

```cisco
! Sur le routeur (serveur DHCPv6 stateful)
Router(config)# ipv6 unicast-routing

Router(config)# ipv6 dhcp pool DHCPv6-STATEFUL
Router(config-dhcpv6)# address prefix 2001:db8:1::/64
Router(config-dhcpv6)# dns-server 2001:4860:4860::8888
Router(config-dhcpv6)# domain-name entreprise.local
Router(config-dhcpv6)# exit

Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ipv6 address 2001:db8:1::1/64
Router(config-if)# ipv6 dhcp server DHCPv6-STATEFUL
Router(config-if)# ipv6 nd managed-config-flag
Router(config-if)# exit
```

---

## Verification et Troubleshooting DHCP

### Commandes de Verification

```cisco
! Voir les baux DHCP actifs
Router# show ip dhcp binding
Bindings from all pools not associated with VRF:
IP address       Client-ID/              Lease expiration        Type
                 Hardware address/
                 User name
10.1.1.50        0100.1c42.ab30.10       Feb 21 2026 08:30 AM   Automatic
10.1.1.51        0100.1c42.ab30.20       Feb 21 2026 09:15 AM   Automatic

! Voir les statistiques du pool
Router# show ip dhcp pool
Pool LAN-POOL :
 Utilization mark (high/low)    : 100 / 0
 Subnet size (first/next)       : 0 / 0
 Total addresses                : 254
 Leased addresses               : 2
 Pending event                  : none
 1 subnet is currently in the pool :
 Current index        IP address range                    Leased addresses
 10.1.1.52            10.1.1.1     - 10.1.1.254           2

! Voir les conflits d'adresses
Router# show ip dhcp conflict

! Voir les statistiques serveur
Router# show ip dhcp server statistics

! Debug DHCP
Router# debug ip dhcp server events
Router# debug ip dhcp server packet
```

### Troubleshooting DHCP

```
Probleme : Le client ne recoit pas d'adresse IP

Etape 1 : Verifier le service DHCP
  Router# show ip dhcp pool
  -> Pool configure ? Adresses disponibles ?

Etape 2 : Verifier les exclusions
  Router# show running-config | include excluded
  -> Trop d'adresses exclues ?

Etape 3 : Verifier la connectivite L1/L2
  -> Le client est-il physiquement connecte ?

Etape 4 : Verifier le relay agent (si multi-VLAN)
  Router# show running-config interface [intf]
  -> ip helper-address present et correct ?

Etape 5 : Verifier les conflits
  Router# show ip dhcp conflict
  -> Adresses en conflit a resoudre ?

Erreurs courantes :
┌───────────────────────────────────────┬──────────────────────────────────┐
│ Probleme                              │ Solution                         │
├───────────────────────────────────────┼──────────────────────────────────┤
│ Pool epuise                           │ Reduire lease time ou agrandir   │
│ ip helper-address manquant            │ Configurer sur interface client  │
│ ip helper-address sur mauvaise interf.│ Mettre sur interface cote client │
│ Exclusions trop larges                │ Verifier la plage exclue         │
│ Mauvais masque dans le pool           │ Verifier network + masque        │
│ Service DHCP desactive                │ no service dhcp -> service dhcp  │
└───────────────────────────────────────┴──────────────────────────────────┘
```

---

## Questions de Revision

### Niveau Fondamental
1. Que signifie l'acronyme DORA dans le processus DHCP ?
2. Pourquoi le DHCP DISCOVER est-il envoye en broadcast ?
3. Quels parametres reseau le serveur DHCP fournit-il au client ?

### Niveau Intermediaire
1. Pourquoi a-t-on besoin d'un DHCP relay agent ? Quelle commande utiliser ?
2. Quelle est la difference entre DHCPv6 Stateful et Stateless ?
3. A quel moment du bail le client tente-t-il un renouvellement (T1 et T2) ?

### Niveau Avance
1. Un client DHCP obtient une adresse APIPA (169.254.x.x) au lieu d'une adresse du pool. Detaillez votre diagnostic.
2. Expliquez pourquoi le DHCP REQUEST est envoye en broadcast et non en unicast.
3. Comment configurer un environnement multi-VLAN avec un seul serveur DHCP centralise ?

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
