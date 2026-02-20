# Routage Statique - Configuration et Concepts

## Vue d'Ensemble

Le routage statique consiste a configurer manuellement les chemins que les paquets doivent emprunter pour atteindre un reseau distant. C'est la methode de routage la plus simple, utilisee sur les petits reseaux ou en complement des protocoles de routage dynamique.

## Concepts Fondamentaux

### Qu'est-ce que le Routage ?

Le routage est le processus par lequel un routeur determine le meilleur chemin pour acheminer un paquet vers sa destination.

```
Processus de Decision de Routage :

Paquet IP arrive sur une interface du routeur
                    |
                    v
     +------------------------------+
     | 1. Extraire IP destination   |
     |    du header du paquet       |
     +------------------------------+
                    |
                    v
     +------------------------------+
     | 2. Consulter la table        |
     |    de routage (show ip route)|
     +------------------------------+
                    |
                    v
     +------------------------------+
     | 3. Longest Prefix Match      |
     |    Chercher la route la      |
     |    plus specifique           |
     +------------------------------+
                    |
          +---------+---------+
          |                   |
          v                   v
  +---------------+   +---------------+
  | Route trouvee | | Pas de route  |
  | Forward via   |   | Default route |
  | next-hop ou   |   | ou DROP       |
  | exit interface|   |               |
  +---------------+   +---------------+
```

### Table de Routage

La table de routage contient toutes les routes connues par le routeur. Chaque entree comprend :

```
Structure d'une Entree de Route :

+--------+----------------+-----------+------------------+----------+
| Code   | Reseau/Masque  | AD/Metric | Next-Hop         | Interface|
+--------+----------------+-----------+------------------+----------+
| S      | 192.168.2.0/24 | [1/0]     | via 10.0.0.2     | Gi0/1    |
| O      | 172.16.0.0/16  | [110/20]  | via 10.0.0.2     | Gi0/1    |
| C      | 10.0.0.0/30    | [0/0]     | directly connected| Gi0/1   |
+--------+----------------+-----------+------------------+----------+

Codes de la table de routage :
  C = Connected (directement connecte)
  L = Local (adresse IP locale de l'interface)
  S = Static (route statique)
  O = OSPF
  D = EIGRP
  B = BGP
  R = RIP
  S* = Static default route (route par defaut statique)
```

### Administrative Distance (AD)

L'administrative distance determine la fiabilite d'une source de routage. Plus la valeur est basse, plus la route est preferee.

```
+----------------------------+----+
| Source de Route             | AD |
+----------------------------+----+
| Connected (directement)     |  0 |
| Static                      |  1 |
| eBGP                        | 20 |
| EIGRP (interne)             | 90 |
| OSPF                        |110 |
| IS-IS                       |115 |
| RIP                         |120 |
| EIGRP (externe)             |170 |
| iBGP                        |200 |
+----------------------------+----+

Exemple de selection :
Si un routeur connait 10.0.0.0/24 via :
  - OSPF (AD 110) et EIGRP (AD 90)
  - Le routeur choisit EIGRP (90 < 110)
```

## Routes Statiques IPv4

### Route Statique via Next-Hop

Le routeur transmet le paquet a l'adresse IP du prochain routeur (next-hop).

```
Topologie :

PC-A                  R1                    R2                  PC-B
[192.168.1.10]---[Gi0/0    Gi0/1]---[Gi0/0    Gi0/1]---[192.168.2.10]
                 .1    10.0.0.0/30   .2    .1
                 192.168.1.0/24      10.0.0.0/30      192.168.2.0/24

Sur R1, pour atteindre le reseau de PC-B :

R1(config)# ip route 192.168.2.0 255.255.255.0 10.0.0.2
                      |                         |
                      |                         +-- Next-hop : IP de R2
                      +-- Reseau destination + masque

Verification :
R1# show ip route static
S    192.168.2.0/24 [1/0] via 10.0.0.2
```

### Route Statique via Exit Interface

Le routeur transmet le paquet directement via l'interface de sortie specifiee.

```
R1(config)# ip route 192.168.2.0 255.255.255.0 GigabitEthernet0/1
                      |                         |
                      |                         +-- Interface de sortie
                      +-- Reseau destination + masque

Verification :
R1# show ip route static
S    192.168.2.0/24 is directly connected, GigabitEthernet0/1
```

### Comparaison Next-Hop vs Exit Interface

```
+-------------------+------------------------------+------------------------------+
| Critere           | Next-Hop                     | Exit Interface               |
+-------------------+------------------------------+------------------------------+
| Syntaxe           | ip route ... <IP next-hop>   | ip route ... <interface>     |
| Resolution ARP    | Une seule requete ARP        | ARP pour chaque destination  |
|                   | (vers le next-hop)           | (Proxy ARP necessaire)       |
| Usage recommande  | Liaisons Ethernet            | Liaisons point-a-point       |
|                   | (multi-access)               | (Serial, PPP)               |
| Performance       | Meilleure sur Ethernet       | Meilleure sur serial         |
| Table CEF         | Recursive lookup             | Pas de recursive lookup      |
+-------------------+------------------------------+------------------------------+

Combinaison des deux (fully specified) :
R1(config)# ip route 192.168.2.0 255.255.255.0 GigabitEthernet0/1 10.0.0.2
                                                |                   |
                                                Exit interface      Next-hop
```

## Default Route (Route par Defaut)

La default route est la route de dernier recours. Si aucune route plus specifique n'existe dans la table, le paquet est envoye via la default route.

```
Schema : Default Route vers Internet

                         Internet
                            |
                     +------+------+
                     |    ISP      |
                     |  Router     |
                     +------+------+
                            |
                       203.0.113.1
                            |
                     +------+------+
                     |     R1      |
                     |  Gi0/0: .2  |--- 203.0.113.0/30 (vers ISP)
                     |  Gi0/1: .1  |--- 192.168.1.0/24 (LAN)
                     +------+------+
                            |
                    +-------+-------+
                    |       |       |
                  PC-A    PC-B    PC-C
                  .10     .20     .30

Configuration sur R1 :
R1(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1
                      |               |
                      |               +-- Next-hop vers ISP
                      +-- 0.0.0.0/0 = Toutes les destinations

Verification :
R1# show ip route
Gateway of last resort is 203.0.113.1 to network 0.0.0.0

S*   0.0.0.0/0 [1/0] via 203.0.113.1
C    192.168.1.0/24 is directly connected, GigabitEthernet0/1
C    203.0.113.0/30 is directly connected, GigabitEthernet0/0
```

## Floating Static Routes

Une floating static route est une route statique avec une administrative distance volontairement elevee, utilisee comme route de secours (backup).

```
Schema : Floating Static Route

                     +-------------+
                     |   R-ISP-1   | Lien principal
                     +------+------+
                            |
               Gi0/0: 10.0.0.2/30
                     +------+------+
                     |      R1     |
                     +------+------+
               Gi0/1: 10.0.1.2/30
                            |
                     +------+------+
                     |   R-ISP-2   | Lien backup
                     +------+------+

Configuration sur R1 :

! Route principale (AD par defaut = 1)
R1(config)# ip route 0.0.0.0 0.0.0.0 10.0.0.1

! Route de secours (AD = 210, superieure a toute route dynamique)
R1(config)# ip route 0.0.0.0 0.0.0.0 10.0.1.1 210
                                                 |
                                                 +-- AD modifiee

Fonctionnement :
+------------------------------------------------------+
| Etat Normal :                                        |
| Route active : 0.0.0.0/0 via 10.0.0.1 [1/0]        |
| Floating     : 0.0.0.0/0 via 10.0.1.1 [210/0]      |
|                (invisible dans la table de routage)  |
+------------------------------------------------------+
                      |
                      | Panne du lien principal
                      v
+------------------------------------------------------+
| Apres panne :                                        |
| Route active : 0.0.0.0/0 via 10.0.1.1 [210/0]      |
| (la floating static route prend le relais)           |
+------------------------------------------------------+
                      |
                      | Retour du lien principal
                      v
+------------------------------------------------------+
| Retour normal :                                      |
| Route active : 0.0.0.0/0 via 10.0.0.1 [1/0]        |
| Floating     : 0.0.0.0/0 via 10.0.1.1 [210/0]      |
|                (redevient invisible)                 |
+------------------------------------------------------+
```

## Routes Statiques IPv6

La syntaxe est similaire a IPv4 mais utilise la commande `ipv6 route`.

```
Topologie IPv6 :

PC-A                     R1                         R2                     PC-B
[2001:db8:1::10]---[Gi0/0      Gi0/1]---[Gi0/0      Gi0/1]---[2001:db8:2::10]
                   2001:db8:1::1  2001:db8:A::1/64  2001:db8:A::2  2001:db8:2::1
                   /64                                /64            /64

Configuration R1 :

! Activer le routage IPv6
R1(config)# ipv6 unicast-routing

! Route statique IPv6 via next-hop (link-local)
R1(config)# ipv6 route 2001:db8:2::/64 GigabitEthernet0/1 FE80::2

! Route statique IPv6 via next-hop (global unicast)
R1(config)# ipv6 route 2001:db8:2::/64 2001:db8:A::2

! Default route IPv6
R1(config)# ipv6 route ::/0 2001:db8:A::2

! Verification
R1# show ipv6 route static
S   2001:DB8:2::/64 [1/0]
     via FE80::2, GigabitEthernet0/1
```

### Particularites IPv6

```
+----------------------------------+----------------------------------------+
| IPv4                             | IPv6                                   |
+----------------------------------+----------------------------------------+
| ip route                         | ipv6 route                             |
| 0.0.0.0 0.0.0.0 (default)       | ::/0 (default)                         |
| Next-hop = IP unicast            | Next-hop = link-local ou global        |
| Masque en decimal                | Prefixe en /notation                   |
| ip routing (actif par defaut)    | ipv6 unicast-routing (a activer)       |
+----------------------------------+----------------------------------------+

Note importante :
Avec IPv6, si le next-hop est une adresse link-local (fe80::),
il FAUT specifier l'interface de sortie en plus :

ipv6 route 2001:db8:2::/64 GigabitEthernet0/1 FE80::2
                            |                   |
                            Exit interface      Link-local next-hop
                            (obligatoire)
```

## Commandes de Verification

### show ip route

```cisco
R1# show ip route

Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1
       L2 - IS-IS level-2, ia - IS-IS inter area
       * - candidate default

Gateway of last resort is 203.0.113.1 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 203.0.113.1
      10.0.0.0/30 is subnetted, 1 subnets
C        10.0.0.0 is directly connected, GigabitEthernet0/1
L        10.0.0.1/32 is directly connected, GigabitEthernet0/1
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.1.0/24 is directly connected, GigabitEthernet0/0
L        192.168.1.1/32 is directly connected, GigabitEthernet0/0
S     192.168.2.0/24 [1/0] via 10.0.0.2
S     192.168.3.0/24 [1/0] via 10.0.0.2
```

### Autres Commandes Utiles

```cisco
! Afficher uniquement les routes statiques
R1# show ip route static

! Afficher une route specifique
R1# show ip route 192.168.2.0

! Verifier le next-hop
R1# show ip route 192.168.2.0 255.255.255.0 longer-prefixes

! Tester le routage
R1# traceroute 192.168.2.10

! Verifier la connectivite
R1# ping 192.168.2.10

! Table de routage IPv6
R1# show ipv6 route
R1# show ipv6 route static
```

## Depannage du Routage Statique

### Problemes Courants

```
Probleme 1 : Route statique n'apparait pas dans la table

Cause possible :
+-----------------------------------------------+
| L'interface de sortie ou le next-hop           |
| n'est pas joignable (interface down)           |
+-----------------------------------------------+

Diagnostic :
R1# show ip interface brief
! Verifier que l'interface vers le next-hop est UP/UP

R1# ping 10.0.0.2
! Verifier la connectivite vers le next-hop

Solution :
R1(config)# interface GigabitEthernet0/1
R1(config-if)# no shutdown

---

Probleme 2 : Paquet n'atteint pas la destination

Cause possible :
+-----------------------------------------------+
| Route aller OK mais pas de route retour        |
| (asymmetric routing ou route manquante)        |
+-----------------------------------------------+

Diagnostic :
! Sur R1 : route vers 192.168.2.0/24 OK
R1# show ip route 192.168.2.0
S    192.168.2.0/24 [1/0] via 10.0.0.2

! Sur R2 : route retour vers 192.168.1.0/24 ?
R2# show ip route 192.168.1.0
% Network not in table   <-- PROBLEME !

Solution sur R2 :
R2(config)# ip route 192.168.1.0 255.255.255.0 10.0.0.1

---

Probleme 3 : Mauvais next-hop configure

Diagnostic :
R1# show ip route static
R1# traceroute 192.168.2.10
! Observer si les paquets partent dans la bonne direction
```

### Methodologie de Depannage

```
Etape 1 : Verifier la connectivite locale
  ping <gateway locale>

Etape 2 : Verifier la connectivite vers le next-hop
  ping <next-hop>

Etape 3 : Verifier la table de routage
  show ip route
  show ip route <destination>

Etape 4 : Verifier la route retour (sur le routeur distant)
  show ip route <source>

Etape 5 : Traceroute de bout en bout
  traceroute <destination finale>
```

## Bonnes Pratiques

```
+-------------------------------+--------------------------------------------+
| Pratique                      | Justification                              |
+-------------------------------+--------------------------------------------+
| Utiliser next-hop sur         | Evite les problemes de Proxy ARP           |
| segments multi-access         | et les requetes ARP excessives             |
+-------------------------------+--------------------------------------------+
| Utiliser exit interface       | Plus efficace (pas de recursive lookup)    |
| sur liens point-a-point      | Resolution directe                         |
+-------------------------------+--------------------------------------------+
| Toujours configurer les       | Sinon, le trafic de retour ne              |
| routes retour                 | trouvera pas son chemin                    |
+-------------------------------+--------------------------------------------+
| Documenter chaque route       | Facilite la maintenance et le depannage    |
| avec description              |                                            |
+-------------------------------+--------------------------------------------+
| Utiliser floating static      | Assure la continuite de service            |
| pour les liens critiques      | en cas de panne du lien principal          |
+-------------------------------+--------------------------------------------+
| Preferer le routage dynamique | Le routage statique ne s'adapte pas        |
| pour les grands reseaux       | aux changements de topologie               |
+-------------------------------+--------------------------------------------+
```

## Questions de Revision

### Niveau Fondamental
1. Quelle est la difference entre une route statique et une route dynamique ?
2. Quelle commande affiche la table de routage ?
3. Quelle est l'administrative distance par defaut d'une route statique ?

### Niveau Intermediaire
1. Quand utiliser une route statique next-hop vs exit interface ?
2. Expliquez le fonctionnement d'une floating static route.
3. Pourquoi faut-il toujours configurer les routes retour ?

### Niveau Avance
1. Un routeur a les routes suivantes pour 10.1.1.0 :
   - 10.1.1.0/24 via OSPF (AD 110)
   - 10.1.1.0/24 via static (AD 1)
   - 10.1.0.0/16 via EIGRP (AD 90)
   Quel chemin est utilise pour un paquet vers 10.1.1.50 ?
2. Configurez une solution de failover avec floating static routes pour deux liaisons WAN.

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
