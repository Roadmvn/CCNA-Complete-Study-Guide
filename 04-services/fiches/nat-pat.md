# NAT et PAT - Traduction d'Adresses Reseau

## Vue d'Ensemble

Le NAT (Network Address Translation) permet de traduire des adresses IP privees en adresses IP publiques (et inversement) pour permettre aux hotes internes d'acceder a Internet. C'est un mecanisme fondamental dans les reseaux modernes, car les adresses IPv4 publiques sont limitees.

## Concepts Fondamentaux

### Terminologie NAT

```
                    INSIDE                    OUTSIDE
                  (Reseau prive)            (Internet)

 +---------+     +----------+     +----------+     +-------------+
 |  PC-A    |---->|  Routeur |---->|  ISP     |---->| Serveur Web |
 |10.1.1.10 |     |   NAT    |     |          |     | 93.184.216.34|
 +---------+     +----------+     +----------+     +-------------+

 Inside Local    Inside Global    Outside Local   Outside Global
 10.1.1.10       203.0.113.1      93.184.216.34   93.184.216.34
```

### Les 4 Types d'Adresses NAT

```
+------------------+-----------------------------------------------------+
| Terme            | Definition                                          |
+------------------+-----------------------------------------------------+
| Inside Local     | Adresse IP privee de l'hote interne                |
|                  | (vue depuis le reseau interne)                     |
|                  | Exemple : 10.1.1.10                               |
+------------------+-----------------------------------------------------+
| Inside Global    | Adresse IP publique representant l'hote interne    |
|                  | (vue depuis Internet)                              |
|                  | Exemple : 203.0.113.1                             |
+------------------+-----------------------------------------------------+
| Outside Local    | Adresse IP de l'hote externe vue depuis l'interieur|
|                  | (generalement identique a Outside Global)          |
|                  | Exemple : 93.184.216.34                           |
+------------------+-----------------------------------------------------+
| Outside Global   | Adresse IP publique reelle de l'hote externe      |
|                  | (vue depuis Internet)                              |
|                  | Exemple : 93.184.216.34                           |
+------------------+-----------------------------------------------------+
```

---

## NAT Statique (Static NAT)

### Principe

Mapping permanent 1:1 entre une adresse IP privee et une adresse IP publique. Chaque hote interne a sa propre adresse publique dediee.

### Schema : Traduction NAT Statique

```
AVANT TRADUCTION (paquet sortant) :
+--------------------------------------------------------------+
| Src IP : 10.1.1.10    | Dst IP : 93.184.216.34             |
| Src MAC: AA:AA:AA:AA   | Dst MAC: [MAC routeur]            |
+--------------------------------------------------------------+
         |
         | Routeur NAT consulte la table statique :
         | 10.1.1.10 <--> 203.0.113.1
         v
APRES TRADUCTION (paquet sur Internet) :
+--------------------------------------------------------------+
| Src IP : 203.0.113.1  | Dst IP : 93.184.216.34             |
| Src MAC: [MAC routeur] | Dst MAC: [MAC ISP]                |
+--------------------------------------------------------------+

RETOUR (paquet entrant) :
+--------------------------------------------------------------+
| Src IP : 93.184.216.34 | Dst IP : 203.0.113.1              |
+--------------------------------------------------------------+
         |
         | Routeur NAT traduit en sens inverse :
         | 203.0.113.1 --> 10.1.1.10
         v
APRES TRADUCTION INVERSE :
+--------------------------------------------------------------+
| Src IP : 93.184.216.34 | Dst IP : 10.1.1.10                |
+--------------------------------------------------------------+
```

### Configuration Cisco : NAT Statique

```cisco
! Definir les interfaces inside et outside
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip address 10.1.1.1 255.255.255.0
Router(config-if)# ip nat inside
Router(config-if)# no shutdown
Router(config-if)# exit

Router(config)# interface GigabitEthernet 0/1
Router(config-if)# ip address 203.0.113.1 255.255.255.252
Router(config-if)# ip nat outside
Router(config-if)# no shutdown
Router(config-if)# exit

! Creer le mapping statique : inside local <--> inside global
Router(config)# ip nat inside source static 10.1.1.10 203.0.113.1
Router(config)# ip nat inside source static 10.1.1.20 203.0.113.2
Router(config)# ip nat inside source static 10.1.1.30 203.0.113.3
```

### Cas d'utilisation

- Serveurs internes accessibles depuis Internet (web, mail, FTP)
- Mapping permanent requis pour les connexions entrantes
- Nombre limite d'hotes a traduire

---

## NAT Dynamique (Dynamic NAT)

### Principe

Mapping temporaire entre adresses privees et un pool d'adresses publiques. L'association est creee a la demande et liberee apres un timeout.

### Schema : NAT Dynamique avec Pool

```
Pool d'adresses publiques : 203.0.113.10 a 203.0.113.14 (5 adresses)

Hotes internes :                           Pool NAT :
+-------------+                      +------------------+
| 10.1.1.10   |------+               | 203.0.113.10 [X] | <- attribue a .10
| 10.1.1.20   |------+  +--------+  | 203.0.113.11 [X] | <- attribue a .20
| 10.1.1.30   |------+->| NAT    |->| 203.0.113.12 [ ] | <- disponible
| 10.1.1.40   |------+  | Router |  | 203.0.113.13 [ ] | <- disponible
| 10.1.1.50   |------+  +--------+  | 203.0.113.14 [ ] | <- disponible
| 10.1.1.60   |------+               +------------------+
+-------------+
   6 hotes          Si pool epuise (5 adresses utilisees),
                    le 6eme hote est REFUSE (pas de traduction)
```

### Configuration Cisco : NAT Dynamique

```cisco
! 1. Definir les interfaces inside/outside
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip nat inside
Router(config-if)# exit

Router(config)# interface GigabitEthernet 0/1
Router(config-if)# ip nat outside
Router(config-if)# exit

! 2. Definir le pool d'adresses publiques
Router(config)# ip nat pool POOL-PUBLIC 203.0.113.10 203.0.113.14 netmask 255.255.255.240

! 3. Creer l'ACL qui identifie le trafic a traduire
Router(config)# access-list 1 permit 10.1.1.0 0.0.0.255

! 4. Associer l'ACL au pool NAT
Router(config)# ip nat inside source list 1 pool POOL-PUBLIC
```

---

## PAT / NAT Overload (Port Address Translation)

### Principe

Plusieurs adresses privees partagent UNE SEULE adresse publique. La differenciation se fait par les numeros de port TCP/UDP. C'est le type de NAT le plus utilise en pratique.

### Schema : PAT en Detail

```
AVANT TRADUCTION :

PC-A (10.1.1.10)  port src 50001 --+
PC-B (10.1.1.20)  port src 50002 --+--> Routeur NAT --> Internet
PC-C (10.1.1.30)  port src 50001 --+    (203.0.113.1)

TABLE NAT DU ROUTEUR :
+---------------------------+---------------------------+----------+
| Inside Local              | Inside Global             | Outside  |
+---------------------------+---------------------------+----------+
| 10.1.1.10:50001           | 203.0.113.1:50001         | 80       |
| 10.1.1.20:50002           | 203.0.113.1:50002         | 80       |
| 10.1.1.30:50001           | 203.0.113.1:50003         | 443      |
+---------------------------+---------------------------+----------+
                                          ^
                   Port change de 50001 a 50003 pour eviter le conflit

APRES TRADUCTION (sur Internet) :

Paquet de PC-A : Src = 203.0.113.1:50001  Dst = 93.184.216.34:80
Paquet de PC-B : Src = 203.0.113.1:50002  Dst = 93.184.216.34:80
Paquet de PC-C : Src = 203.0.113.1:50003  Dst = 93.184.216.34:443
```

### Configuration Cisco : PAT avec Interface

```cisco
! Methode 1 : PAT avec adresse de l'interface de sortie (la plus courante)

Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip nat inside
Router(config-if)# exit

Router(config)# interface GigabitEthernet 0/1
Router(config-if)# ip nat outside
Router(config-if)# exit

! ACL pour identifier le trafic interne
Router(config)# access-list 1 permit 10.1.1.0 0.0.0.255
Router(config)# access-list 1 permit 10.1.2.0 0.0.0.255

! PAT avec le mot-cle "overload"
Router(config)# ip nat inside source list 1 interface GigabitEthernet 0/1 overload
```

### Configuration Cisco : PAT avec Pool

```cisco
! Methode 2 : PAT avec pool d'adresses (pour plus de ports disponibles)

Router(config)# ip nat pool PAT-POOL 203.0.113.10 203.0.113.12 netmask 255.255.255.240
Router(config)# access-list 1 permit 10.0.0.0 0.255.255.255
Router(config)# ip nat inside source list 1 pool PAT-POOL overload
```

---

## Comparaison des 3 Types de NAT

```
+-----------------+--------------+--------------+-----------------+
| Critere         | NAT Statique | NAT Dynamique| PAT (Overload)  |
+-----------------+--------------+--------------+-----------------+
| Mapping         | 1:1          | 1:1 temporaire| Many:1          |
|                 | permanent    |              |                 |
+-----------------+--------------+--------------+-----------------+
| Nb IP publiques | 1 par hote   | 1 par session| 1 pour tous     |
| requises        |              |              |                 |
+-----------------+--------------+--------------+-----------------+
| Connexion       | Oui          | Non          | Non             |
| entrante        | (bidirection)|              | (sauf port fwd) |
+-----------------+--------------+--------------+-----------------+
| Cas d'usage     | Serveurs     | Pool limite  | Acces Internet  |
|                 | publics      |              | general         |
+-----------------+--------------+--------------+-----------------+
| Limite          | Nb IP pub.   | Taille pool  | ~65000 ports    |
|                 | = Nb hotes   |              | par IP publique |
+-----------------+--------------+--------------+-----------------+
```

---

## Verification et Troubleshooting NAT

### Commandes de Verification

```cisco
! Voir la table de traduction NAT active
Router# show ip nat translations
Pro  Inside global     Inside local       Outside local      Outside global
tcp  203.0.113.1:50001 10.1.1.10:50001    93.184.216.34:80   93.184.216.34:80
tcp  203.0.113.1:50002 10.1.1.20:50002    93.184.216.34:80   93.184.216.34:80
---  203.0.113.2       10.1.1.30          ---                ---

! Statistiques NAT
Router# show ip nat statistics
Total active translations: 3 (1 static, 2 dynamic; 2 extended)
Peak translations: 15, occurred 00:05:23 ago
Outside interfaces: GigabitEthernet0/1
Inside interfaces: GigabitEthernet0/0
Hits: 1523  Misses: 12

! Debug NAT en temps reel (utiliser avec precaution en production)
Router# debug ip nat
Router# debug ip nat detailed
```

### Troubleshooting : Methode Systematique

```
Probleme : Les hotes internes ne peuvent pas acceder a Internet

Etape 1 : Verifier les interfaces inside/outside
  Router# show ip nat statistics
  -> Verifier que les interfaces sont correctement marquees

Etape 2 : Verifier les traductions
  Router# show ip nat translations
  -> La table est-elle vide ? Des entrees sont-elles presentes ?

Etape 3 : Verifier l'ACL
  Router# show access-lists
  -> L'ACL autorise-t-elle le bon trafic source ?

Etape 4 : Verifier la connectivite de base
  Router# ping [adresse outside]
  -> Le routeur peut-il atteindre Internet ?

Etape 5 : Verifier le routage
  Router# show ip route
  -> Route par defaut presente ?

Erreurs courantes :
+---------------------------------+------------------------------------+
| Probleme                        | Solution                           |
+---------------------------------+------------------------------------+
| Interface inside/outside inversee| Verifier ip nat inside/outside    |
| ACL ne match pas le trafic      | Verifier les wildcard masks       |
| Pool epuise (NAT dynamique)     | Augmenter le pool ou passer a PAT |
| Pas de route par defaut         | ip route 0.0.0.0 0.0.0.0 [next-hop]|
| Oubli du mot-cle overload       | Ajouter overload pour PAT         |
+---------------------------------+------------------------------------+
```

### Effacer les Traductions NAT

```cisco
! Effacer toutes les traductions dynamiques
Router# clear ip nat translation *

! Effacer une traduction specifique
Router# clear ip nat translation inside 10.1.1.10 203.0.113.1
```

---

## Questions de Revision

### Niveau Fondamental
1. Quelle est la difference entre Inside Local et Inside Global ?
2. Combien d'adresses publiques le PAT necessite-t-il au minimum ?
3. Quel type de NAT est necessaire pour rendre un serveur web interne accessible depuis Internet ?

### Niveau Intermediaire
1. Pourquoi le PAT change-t-il parfois le port source du paquet ?
2. Que se passe-t-il quand le pool d'adresses du NAT dynamique est epuise ?
3. Quelle est la commande pour voir les traductions NAT actives ?

### Niveau Avance
1. Un hote interne ne peut pas acceder a Internet malgre une configuration PAT. Detaillez votre methode de depannage.
2. Expliquez pourquoi le NAT statique est bidirectionnel alors que le PAT ne l'est pas par defaut.
3. Comment configurer le port forwarding pour rediriger le port 80 externe vers un serveur interne sur le port 8080 ?

---

*Fiche creee pour la revision CCNA*
*Auteur : Roadmvn*
