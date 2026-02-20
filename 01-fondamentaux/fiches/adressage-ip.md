# Adressage IPv4 & IPv6

## **Vue d'Ensemble**

L'adressage IP est le système qui permet d'identifier de manière unique chaque équipement sur un réseau. Cette fiche couvre IPv4 (actuel) et IPv6 (futur) avec leurs spécificités techniques.

## Qu'est-ce que la notation CIDR ?

La notation **CIDR (Classless Inter-Domain Routing)** remplace l’ancienne logique « Classes A/B/C ».  
Elle se présente sous la forme **adresse /nombre_de_bits_reseau** :

*Exemple :* `192.168.10.0/24`  
• **/24** signifie que les *24 premiers bits* (sur 32) représentent la partie **réseau**  
• Les **8 bits** restants (32 − 24) servent aux **hôtes**

Avantages :  
1. **Souplesse** : on ne dépend plus des blocs fixes /8 /16 /24 des anciennes classes  
2. **Moins de gaspillage** : on découpe au plus juste selon les besoins  
3. **Routage plus efficace** grâce à l’agrégation de préfixes

Terminologie rapide :  
| Terme | Signification |
|-------|---------------|
| **Préfixe** | Partie réseau (bits à 1 dans le masque) |
| **Masque** | Représentation décimale : `/24` <-> `255.255.255.0` |
| **Slash /x** | Nombre de bits réseau (x) |
| **Bits empruntés** | Bits qu’on déplace du champ hôte vers le champ réseau pour créer de nouveaux sous-réseaux |

---

## **IPv4 - Adressage 32 bits**

### **Structure d'une Adresse IPv4**

```
Adresse IPv4 : 192.168.1.100/24

+----------+----------+----------+----------+
|    192   |   168    |    1     |   100    |
| 11000000 | 10101000 | 00000001 | 01100100 |
+----------+----------+----------+----------+
    Octet 1    Octet 2    Octet 3    Octet 4
     8 bits     8 bits     8 bits     8 bits
              = 32 bits total
```

### **Classes d'Adresses IPv4**

```
+---------+-----------------+-----------------+----------------+
| Classe  | Plage           | Masque Défaut   | Usage          |
+---------+-----------------+-----------------+----------------+
| A       | 1.0.0.0         | 255.0.0.0       | Très gros      |
|         | à 126.255.255.255| (/8)            | réseaux        |
+---------+-----------------+-----------------+----------------+
| B       | 128.0.0.0       | 255.255.0.0     | Moyens         |
|         | à 191.255.255.255| (/16)           | réseaux        |
+---------+-----------------+-----------------+----------------+
| C       | 192.0.0.0       | 255.255.255.0   | Petits         |
|         | à 223.255.255.255| (/24)           | réseaux        |
+---------+-----------------+-----------------+----------------+
| D       | 224.0.0.0       | N/A             | Multicast      |
|         | à 239.255.255.255|                 |                |
+---------+-----------------+-----------------+----------------+
| E       | 240.0.0.0       | N/A             | Expérimental   |
|         | à 255.255.255.255|                 |                |
+---------+-----------------+-----------------+----------------+
```

### **Adresses Privées (RFC 1918)**

```
+---------+---------------------+-----------------+--------------+
| Classe  | Plage Privée        | Masque CIDR     | Nb Adresses  |
+---------+---------------------+-----------------+--------------+
| A       | 10.0.0.0            | /8              | 16,777,214   |
|         | à 10.255.255.255    | (255.0.0.0)     |              |
+---------+---------------------+-----------------+--------------+
| B       | 172.16.0.0          | /12             | 1,048,574    |
|         | à 172.31.255.255    | (255.240.0.0)   |              |
+---------+---------------------+-----------------+--------------+
| C       | 192.168.0.0         | /16             | 65,534       |
|         | à 192.168.255.255   | (255.255.0.0)   |              |
+---------+---------------------+-----------------+--------------+
```

### **Adresses Spéciales IPv4**

```
+---------------------+--------------------------------------+
| Adresse             | Usage                                |
+---------------------+--------------------------------------+
| 127.0.0.0/8         | Loopback (localhost)                 |
| 169.254.0.0/16      | APIPA (Auto-configuration)          |
| 224.0.0.0/4         | Multicast                           |
| 255.255.255.255     | Broadcast limitée                   |
| 0.0.0.0             | Route par défaut                    |
| x.x.x.0             | Adresse réseau                      |
| x.x.x.255           | Adresse broadcast (réseau /24)      |
+---------------------+--------------------------------------+
```

## **Masques de Sous-Réseau**

### **Notation CIDR vs Décimale**

```
+---------+-----------------+------------------+----------------+
| CIDR    | Masque Décimal  | Masque Binaire   | Nb Hôtes       |
+---------+-----------------+------------------+----------------+
| /24     | 255.255.255.0   | 11111111.11111111| 254            |
|         |                 | .11111111.00000000|               |
+---------+-----------------+------------------+----------------+
| /25     | 255.255.255.128 | 11111111.11111111| 126            |
|         |                 | .11111111.10000000|               |
+---------+-----------------+------------------+----------------+
| /26     | 255.255.255.192 | 11111111.11111111| 62             |
|         |                 | .11111111.11000000|               |
+---------+-----------------+------------------+----------------+
| /27     | 255.255.255.224 | 11111111.11111111| 30             |
|         |                 | .11111111.11100000|               |
+---------+-----------------+------------------+----------------+
| /28     | 255.255.255.240 | 11111111.11111111| 14             |
|         |                 | .11111111.11110000|               |
+---------+-----------------+------------------+----------------+
| /30     | 255.255.255.252 | 11111111.11111111| 2              |
|         |                 | .11111111.11111100| (Liens P2P)   |
+---------+-----------------+------------------+----------------+
```

### **Calcul Rapide du Nombre d'Hôtes**

```
Formule : 2^(32-CIDR) - 2

Exemples :
/24 -> 2^(32-24) - 2 = 2^8 - 2 = 256 - 2 = 254 hôtes
/25 -> 2^(32-25) - 2 = 2^7 - 2 = 128 - 2 = 126 hôtes
/26 -> 2^(32-26) - 2 = 2^6 - 2 = 64 - 2 = 62 hôtes
/30 -> 2^(32-30) - 2 = 2^2 - 2 = 4 - 2 = 2 hôtes
```

## **Configuration IPv4 sur Cisco**

### **Configuration Interface Routeur**

```cisco
Router> enable
Router# configure terminal
Router(config)# interface fastethernet 0/0
Router(config-if)# ip address 192.168.1.1 255.255.255.0
Router(config-if)# no shutdown
Router(config-if)# description "LAN Interface"
Router(config-if)# exit

# Vérification
Router# show ip interface brief
Router# show running-config interface fa0/0
```

### **Configuration Interface Switch (SVI)**

```cisco
Switch> enable
Switch# configure terminal
Switch(config)# interface vlan 1
Switch(config-if)# ip address 192.168.1.10 255.255.255.0
Switch(config-if)# no shutdown
Switch(config)# ip default-gateway 192.168.1.1

# Vérification
Switch# show ip interface brief
Switch# ping 192.168.1.1
```

## **IPv6 - Adressage 128 bits**

### **Structure d'une Adresse IPv6**

```
Adresse IPv6 : 2001:0db8:85a3:0000:0000:8a2e:0370:7334

+-------------------------------------------------------------+
| 2001:0db8:85a3:0000:0000:8a2e:0370:7334                   |
|                                                             |
| +---- 64 bits réseau ----++---- 64 bits hôte ----+        |
|                                                             |
| Préfixe Global : 2001:0db8:85a3::/48                       |
| ID Sous-réseau : 0000 (16 bits)                            |
| ID Interface   : 0000:8a2e:0370:7334 (64 bits)            |
+-------------------------------------------------------------+
```

### **Notation IPv6 Compressée**

```
+--------------------------------------+-------------------------+
| Forme Complète                       | Forme Compressée        |
+--------------------------------------+-------------------------+
| 2001:0db8:0000:0000:0000:0000:0000:1| 2001:db8::1            |
| 2001:0db8:85a3:0000:0000:8a2e:0370:7| 2001:db8:85a3::8a2e:   |
|                                      | 370:7334               |
| fe80:0000:0000:0000:0202:b3ff:fe1e:8| fe80::202:b3ff:fe1e:   |
|                                      | 329                    |
| ::1                                  | ::1 (loopback)         |
| ::                                   | :: (toutes zéros)      |
+--------------------------------------+-------------------------+

Règles de compression :
1. Supprimer les zéros de tête dans chaque bloc
2. Remplacer un ou plusieurs blocs de zéros par ::
3. :: ne peut être utilisé qu'une fois par adresse
```

### **Types d'Adresses IPv6**

```
+-----------------+---------------------+----------------------+
| Type            | Plage               | Usage                |
+-----------------+---------------------+----------------------+
| Unicast Global  | 2000::/3            | Internet global      |
| Link-Local      | fe80::/10           | Segment local        |
| Unique Local    | fc00::/7            | Privé (comme RFC1918)|
| Loopback        | ::1/128             | Localhost            |
| Multicast       | ff00::/8            | Diffusion groupe     |
| Anycast         | N/A                 | Plus proche serveur  |
+-----------------+---------------------+----------------------+
```

### **Configuration IPv6 sur Cisco**

```cisco
# Activation IPv6 globalement
Router(config)# ipv6 unicast-routing

# Configuration interface
Router(config)# interface fastethernet 0/0
Router(config-if)# ipv6 address 2001:db8:1::1/64
Router(config-if)# ipv6 address fe80::1 link-local
Router(config-if)# no shutdown

# Auto-configuration
Router(config-if)# ipv6 address autoconfig

# Vérification
Router# show ipv6 interface brief
Router# show ipv6 route
Router# ping ipv6 2001:db8:1::2
```

## **Comparaison IPv4 vs IPv6**

```
+-----------------+---------------------+---------------------+
| Caractéristique | IPv4                | IPv6                |
+-----------------+---------------------+---------------------+
| Taille adresse  | 32 bits             | 128 bits            |
| Notation        | Décimale pointée    | Hexadécimale        |
| Nb adresses     | 4,3 milliards       | 340 undecillions    |
| Header          | Variable (20-60b)   | Fixe (40 bytes)     |
| Fragmentation   | Routeurs & hôtes    | Hôtes seulement     |
| Checksum        | Oui                 | Non                 |
| DHCP            | DHCPv4              | DHCPv6 ou SLAAC     |
| NAT             | Très utilisé        | Pas nécessaire      |
| Configuration   | Manuelle/DHCP       | Auto/Manuelle/DHCP  |
+-----------------+---------------------+---------------------+
```

## **Outils de Diagnostic**

### **Commandes de Base**

```cisco
# IPv4
show ip interface brief
show ip route
ping 192.168.1.1
traceroute 8.8.8.8
show arp

# IPv6  
show ipv6 interface brief
show ipv6 route
ping ipv6 2001:db8::1
traceroute ipv6 2001:db8::1
show ipv6 neighbors
```

### **Wireshark - Filtres Utiles**

```
# IPv4
ip.addr == 192.168.1.1
ip.src == 10.0.0.1 and ip.dst == 10.0.0.2
arp

# IPv6
ipv6.addr == 2001:db8::1
ipv6.src == fe80::1
icmpv6
```

## **Astuces CCNA**

### **Calcul Rapide Sous-Réseaux**

1. **Méthode des Puissances de 2 :**
   - /25 = 128 -> 2^7 = 128 hôtes par subnet
   - Incréments : 0, 128 (256-128)
   - Subnets : 0-127, 128-255

2. **Méthode "Magic Number" :**
   - /26 -> Magic = 256-192 = 64
   - Subnets : 0, 64, 128, 192

### **Vérification Rapide**

```bash
# Test connectivité
ping -c 4 192.168.1.1

# Affichage interface Linux
ip addr show
ip route show

# Windows
ipconfig /all
route print
```

## **Questions de Révision**

### **IPv4**
1. Combien d'hôtes dans un réseau /26 ?
2. Quelle est l'adresse réseau de 172.16.50.75/20 ?
3. Classes d'adresses privées ?

### **IPv6**
1. Compressez : 2001:0db8:0000:0000:0000:0000:0000:0001
2. Différence entre Link-Local et Global Unicast ?
3. Comment fonctionne SLAAC ?

### **Pratique**
1. Configurez IPv4 et IPv6 sur une interface
2. Dépannez un problème d'adressage
3. Planifiez un schéma d'adressage pour 4 sites

---

**Astuce CCNA :**Maîtrisez les calculs de sous-réseaux ! C'est fondamental pour tout le reste de votre parcours réseau.

---

*Fiche créée pour la révision CCNA*  
*Auteur : Roadmvn*