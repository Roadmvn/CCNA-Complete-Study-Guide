# ACLs - Listes de Controle d'Acces

## Vue d'Ensemble

Les ACLs (Access Control Lists) sont des regles de filtrage appliquees sur les interfaces des routeurs pour controler le trafic reseau. Elles permettent d'autoriser (permit) ou refuser (deny) des paquets selon differents criteres.

## Concepts Fondamentaux

### Fonctionnement General

```
Paquet arrive sur le routeur :

┌────────────┐     ┌──────────────────────────────────────┐
│   Paquet   │────>│          ACL INBOUND (in)            │
│  entrant   │     │                                      │
└────────────┘     │  Regle 1 : permit 10.1.1.0/24 ?     │
                   │    -> Match ? OUI -> PERMIT          │
                   │    -> Match ? NON -> Regle suivante  │
                   │                                      │
                   │  Regle 2 : deny 10.2.0.0/16 ?       │
                   │    -> Match ? OUI -> DENY (drop)     │
                   │    -> Match ? NON -> Regle suivante  │
                   │                                      │
                   │  ...                                 │
                   │                                      │
                   │  Deny implicite (fin de liste) :     │
                   │    -> Tout le reste est REFUSE       │
                   └──────────────────────────────────────┘
                              │
                              v
                   ┌──────────────────┐
                   │ Table de routage │
                   │ (si autorise)    │
                   └──────────────────┘
                              │
                              v
                   ┌──────────────────────────────────────┐
                   │          ACL OUTBOUND (out)          │
                   │  (meme logique de verification)      │
                   └──────────────────────────────────────┘
                              │
                              v
                   ┌────────────┐
                   │   Paquet   │
                   │  sortant   │
                   └────────────┘
```

### Regles Fondamentales des ACLs

```
┌─────────────────────────────────────────────────────────────────────┐
│ REGLES A RETENIR                                                    │
├─────────────────────────────────────────────────────────────────────┤
│ 1. Les regles sont evaluees de HAUT en BAS, dans l'ordre           │
│ 2. Des qu'un match est trouve, l'action est executee (pas de suite)│
│ 3. Il y a un "deny any" IMPLICITE a la fin de chaque ACL          │
│ 4. UNE ACL par interface, par direction, par protocole             │
│ 5. Les ACLs ne filtrent PAS le trafic genere par le routeur        │
│ 6. L'ordre des regles est CRUCIAL (du plus specifique au general)  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ACL Standard

### Caracteristiques

```
┌─────────────────────────────────────────────────────────┐
│ ACL STANDARD                                            │
├─────────────────────────────────────────────────────────┤
│ Numeros       : 1-99 et 1300-1999                      │
│ Critere       : Adresse IP SOURCE uniquement            │
│ Placement     : Le plus PRES de la DESTINATION         │
│ Granularite   : Faible (pas de filtrage par port/proto) │
└─────────────────────────────────────────────────────────┘
```

### Pourquoi Placer Pres de la Destination ?

```
Topologie :
PC-A ──── R1 ──── R2 ──── R3 ──── Serveur
(10.1.1.10)                        (10.1.4.100)

Objectif : Bloquer PC-A vers le Serveur

MAUVAIS placement (sur R1, pres de la source) :
  -> L'ACL standard ne filtre que par IP source
  -> En bloquant 10.1.1.10 sur R1, on bloque PC-A vers TOUTES les destinations
  -> PC-A ne peut plus rien faire du tout !

BON placement (sur R3, pres de la destination) :
  -> On bloque 10.1.1.10 uniquement sur l'interface vers le Serveur
  -> PC-A peut toujours acceder aux autres reseaux
  -> Seul l'acces au Serveur est bloque
```

### Configuration ACL Standard Numerotee

```cisco
! Syntaxe : access-list [numero] {permit|deny} [source] [wildcard]

! Exemple : Autoriser uniquement le reseau 10.1.1.0/24 a acceder au serveur
Router(config)# access-list 10 permit 10.1.1.0 0.0.0.255
Router(config)# access-list 10 deny any
! (le deny any est implicite, mais l'ecrire rend l'ACL plus lisible)

! Appliquer l'ACL sur l'interface (pres de la destination)
Router(config)# interface GigabitEthernet 0/1
Router(config-if)# ip access-group 10 out
Router(config-if)# exit
```

### Configuration ACL Standard Nommee

```cisco
! Syntaxe avec nom (plus lisible et modifiable)
Router(config)# ip access-list standard ALLOW-LAN
Router(config-std-nacl)# permit 10.1.1.0 0.0.0.255
Router(config-std-nacl)# permit 10.1.2.0 0.0.0.255
Router(config-std-nacl)# deny any
Router(config-std-nacl)# exit

! Appliquer l'ACL
Router(config)# interface GigabitEthernet 0/1
Router(config-if)# ip access-group ALLOW-LAN out
Router(config-if)# exit
```

---

## ACL Etendue

### Caracteristiques

```
┌─────────────────────────────────────────────────────────┐
│ ACL ETENDUE                                             │
├─────────────────────────────────────────────────────────┤
│ Numeros       : 100-199 et 2000-2699                   │
│ Criteres      : IP source, IP destination, protocole,  │
│                 port source, port destination           │
│ Placement     : Le plus PRES de la SOURCE              │
│ Granularite   : Elevee (filtrage precis)               │
└─────────────────────────────────────────────────────────┘
```

### Pourquoi Placer Pres de la Source ?

```
Topologie :
PC-A ──── R1 ──── R2 ──── R3 ──── Serveur Web
(10.1.1.10)                        (10.1.4.100:80)

Objectif : Bloquer UNIQUEMENT le HTTP de PC-A vers le Serveur Web

Placement sur R1 (pres de la source) :
  -> L'ACL etendue peut filtrer par source + destination + port
  -> On bloque TCP 10.1.1.10 -> 10.1.4.100 port 80 UNIQUEMENT
  -> Le trafic inutile est elimine au plus tot
  -> Economie de bande passante sur les liens R1-R2 et R2-R3
```

### Configuration ACL Etendue Numerotee

```cisco
! Syntaxe : access-list [numero] {permit|deny} [protocole]
!           [source] [wildcard-src] [operateur port-src]
!           [destination] [wildcard-dst] [operateur port-dst]

! Exemple 1 : Bloquer HTTP de 10.1.1.0/24 vers serveur 10.1.4.100
Router(config)# access-list 100 deny tcp 10.1.1.0 0.0.0.255 host 10.1.4.100 eq 80
Router(config)# access-list 100 permit ip any any

! Exemple 2 : Autoriser uniquement HTTP et HTTPS vers le serveur
Router(config)# access-list 101 permit tcp any host 10.1.4.100 eq 80
Router(config)# access-list 101 permit tcp any host 10.1.4.100 eq 443
Router(config)# access-list 101 deny ip any host 10.1.4.100
Router(config)# access-list 101 permit ip any any

! Appliquer sur l'interface (pres de la source)
Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip access-group 101 in
Router(config-if)# exit
```

### Configuration ACL Etendue Nommee

```cisco
Router(config)# ip access-list extended WEB-FILTER
Router(config-ext-nacl)# permit tcp 10.1.1.0 0.0.0.255 any eq 80
Router(config-ext-nacl)# permit tcp 10.1.1.0 0.0.0.255 any eq 443
Router(config-ext-nacl)# permit tcp 10.1.1.0 0.0.0.255 any eq 53
Router(config-ext-nacl)# permit udp 10.1.1.0 0.0.0.255 any eq 53
Router(config-ext-nacl)# permit icmp 10.1.1.0 0.0.0.255 any
Router(config-ext-nacl)# deny ip any any log
Router(config-ext-nacl)# exit

Router(config)# interface GigabitEthernet 0/0
Router(config-if)# ip access-group WEB-FILTER in
Router(config-if)# exit
```

---

## Wildcard Masks

### Concept

Le wildcard mask est l'inverse du masque de sous-reseau. Un bit a 0 signifie "verifier ce bit" et un bit a 1 signifie "ignorer ce bit".

### Calcul Rapide

```
Methode : Wildcard = 255.255.255.255 - Masque de sous-reseau

Exemples :
┌──────────────────────┬─────────────────┬──────────────────┐
│ Reseau               │ Masque          │ Wildcard         │
├──────────────────────┼─────────────────┼──────────────────┤
│ 10.0.0.0/8           │ 255.0.0.0       │ 0.255.255.255    │
│ 172.16.0.0/16        │ 255.255.0.0     │ 0.0.255.255      │
│ 192.168.1.0/24       │ 255.255.255.0   │ 0.0.0.255        │
│ 192.168.1.0/26       │ 255.255.255.192 │ 0.0.0.63         │
│ 192.168.1.0/28       │ 255.255.255.240 │ 0.0.0.15         │
│ 192.168.1.0/30       │ 255.255.255.252 │ 0.0.0.3          │
└──────────────────────┴─────────────────┴──────────────────┘

Mots-cles speciaux :
┌──────────────────────┬───────────────────────────────────────┐
│ Mot-cle              │ Equivalent                            │
├──────────────────────┼───────────────────────────────────────┤
│ host 10.1.1.10       │ 10.1.1.10 0.0.0.0 (1 seul hote)     │
│ any                  │ 0.0.0.0 255.255.255.255 (tout)        │
└──────────────────────┴───────────────────────────────────────┘
```

### Exemple Visuel du Wildcard

```
ACL : permit 192.168.1.0 0.0.0.255

Adresse :  192.168.1.0
Wildcard : 0  .0  .0  .255

En binaire (dernier octet) :
Wildcard 255 = 11111111

Bit a 0 = DOIT correspondre (verifie)
Bit a 1 = PEU IMPORTE (ignore)

                  Octet 1  Octet 2  Octet 3  Octet 4
Adresse :          192      168       1       xxxxxxxx
Wildcard :         Verifie  Verifie  Verifie  Ignore

Resultats :
  192.168.1.0   -> MATCH (octets 1-3 correspondent)
  192.168.1.50  -> MATCH (octets 1-3 correspondent, octet 4 ignore)
  192.168.1.255 -> MATCH
  192.168.2.0   -> NO MATCH (octet 3 different : 2 != 1)
  10.1.1.50     -> NO MATCH (octet 1 different : 10 != 192)
```

---

## Placement des ACLs : Resume

```
REGLE DE PLACEMENT :

┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│  ACL STANDARD : Placer PRES de la DESTINATION                     │
│  (car elle ne filtre que par source -> eviter de bloquer           │
│   le trafic legitime vers d'autres destinations)                  │
│                                                                    │
│  ACL ETENDUE : Placer PRES de la SOURCE                          │
│  (car elle filtre par source + destination + port ->               │
│   eliminer le trafic non desire au plus tot)                      │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘

Schema de placement sur topologie :

     SOURCE                                          DESTINATION
  ┌──────────┐    ┌────┐    ┌────┐    ┌────┐    ┌──────────┐
  │  PC-A    │────│ R1 │────│ R2 │────│ R3 │────│ Serveur  │
  │10.1.1.10 │    └────┘    └────┘    └────┘    │10.1.4.100│
  └──────────┘      ^                    ^       └──────────┘
                    │                    │
              ACL ETENDUE          ACL STANDARD
              (pres source)        (pres destination)
```

---

## Operateurs de Port (ACLs Etendues)

```
┌────────────┬──────────────────────────────────────────────┐
│ Operateur  │ Signification                                 │
├────────────┼──────────────────────────────────────────────┤
│ eq         │ Equal (egal a) - ex: eq 80                   │
│ neq        │ Not Equal (different de) - ex: neq 23        │
│ gt         │ Greater Than (superieur a) - ex: gt 1023     │
│ lt         │ Less Than (inferieur a) - ex: lt 1024        │
│ range      │ Range (plage) - ex: range 20 21              │
└────────────┴──────────────────────────────────────────────┘

Ports courants a connaitre :
┌──────────────┬──────────┬────────────────────────────────┐
│ Service      │ Port     │ Protocole                      │
├──────────────┼──────────┼────────────────────────────────┤
│ FTP data     │ 20       │ TCP                            │
│ FTP control  │ 21       │ TCP                            │
│ SSH          │ 22       │ TCP                            │
│ Telnet       │ 23       │ TCP                            │
│ SMTP         │ 25       │ TCP                            │
│ DNS          │ 53       │ TCP/UDP                        │
│ DHCP server  │ 67       │ UDP                            │
│ DHCP client  │ 68       │ UDP                            │
│ HTTP         │ 80       │ TCP                            │
│ POP3         │ 110      │ TCP                            │
│ HTTPS        │ 443      │ TCP                            │
│ SNMP         │ 161      │ UDP                            │
│ Syslog       │ 514      │ UDP                            │
│ NTP          │ 123      │ UDP                            │
└──────────────┴──────────┴────────────────────────────────┘
```

---

## Verification et Troubleshooting ACLs

### Commandes de Verification

```cisco
! Voir toutes les ACLs configurees avec compteurs de match
Router# show access-lists
Standard IP access list 10
    10 permit 10.1.1.0, wildcard bits 0.0.0.255 (125 matches)
    20 deny   any (3 matches)

Extended IP access list 100
    10 deny   tcp 10.1.1.0 0.0.0.255 host 10.1.4.100 eq www (15 matches)
    20 permit ip any any (340 matches)

! Voir quelle ACL est appliquee sur une interface
Router# show ip interface GigabitEthernet 0/0
  Inbound access list is WEB-FILTER
  Outgoing access list is not set

! Voir les ACLs dans la running-config
Router# show running-config | section access-list

! Debug ACL (attention en production)
Router# debug ip packet detail
```

### Modification d'une ACL Nommee

```cisco
! Avantage des ACLs nommees : on peut inserer/supprimer des lignes

! Voir les numeros de sequence
Router# show access-lists WEB-FILTER
Extended IP access list WEB-FILTER
    10 permit tcp 10.1.1.0 0.0.0.255 any eq www
    20 permit tcp 10.1.1.0 0.0.0.255 any eq 443
    30 deny ip any any log

! Inserer une regle entre 10 et 20
Router(config)# ip access-list extended WEB-FILTER
Router(config-ext-nacl)# 15 permit tcp 10.1.1.0 0.0.0.255 any eq 53
Router(config-ext-nacl)# exit

! Supprimer une regle specifique
Router(config)# ip access-list extended WEB-FILTER
Router(config-ext-nacl)# no 15
Router(config-ext-nacl)# exit
```

### Troubleshooting ACLs

```
Probleme : Le trafic est bloque alors qu'il ne devrait pas

Etape 1 : Verifier les ACLs appliquees
  Router# show ip interface [intf]
  -> Quelle ACL est appliquee ? En in ou out ?

Etape 2 : Verifier le contenu de l'ACL
  Router# show access-lists
  -> L'ordre des regles est-il correct ?
  -> Le deny implicite bloque-t-il le trafic ?

Etape 3 : Verifier les compteurs
  Router# show access-lists
  -> Quelle regle match le trafic ? (compteur qui augmente)

Etape 4 : Verifier la direction
  -> L'ACL est-elle appliquee en IN ou OUT sur la bonne interface ?

Erreurs courantes :
┌───────────────────────────────────────┬─────────────────────────────────┐
│ Probleme                              │ Solution                        │
├───────────────────────────────────────┼─────────────────────────────────┤
│ Deny implicite oublie                │ Ajouter permit ip any any a la  │
│                                       │ fin si necessaire               │
├───────────────────────────────────────┼─────────────────────────────────┤
│ Ordre des regles incorrect           │ Mettre les regles specifiques   │
│                                       │ avant les regles generales      │
├───────────────────────────────────────┼─────────────────────────────────┤
│ Wildcard mask incorrect              │ Recalculer : 255.255.255.255    │
│                                       │ - subnet mask                   │
├───────────────────────────────────────┼─────────────────────────────────┤
│ ACL sur mauvaise interface           │ Verifier placement standard     │
│                                       │ vs etendue                      │
├───────────────────────────────────────┼─────────────────────────────────┤
│ Direction in/out inversee            │ in = paquet ENTRANT sur intf    │
│                                       │ out = paquet SORTANT de intf    │
├───────────────────────────────────────┼─────────────────────────────────┤
│ ACL vide appliquee                   │ Une ACL vide = deny all         │
│                                       │ (tout est bloque)               │
└───────────────────────────────────────┴─────────────────────────────────┘
```

---

## Questions de Revision

### Niveau Fondamental
1. Quelle est la difference entre une ACL standard et une ACL etendue ?
2. Que se passe-t-il si un paquet ne match aucune regle de l'ACL ?
3. Qu'est-ce qu'un wildcard mask et comment le calculer ?

### Niveau Intermediaire
1. Pourquoi les ACL standard doivent-elles etre placees pres de la destination ?
2. Ecrivez une ACL etendue qui autorise uniquement SSH et HTTPS depuis le reseau 10.1.1.0/24 vers le serveur 172.16.1.100.
3. Comment modifier une ACL nommee sans la supprimer entierement ?

### Niveau Avance
1. Un utilisateur du reseau 10.1.1.0/24 ne peut pas acceder au serveur web 10.1.4.100 malgre une ACL qui devrait l'autoriser. Detaillez votre methode de troubleshooting.
2. Concevez un ensemble d'ACLs pour cette politique de securite :
   - Les utilisateurs (VLAN 10) peuvent acceder au web et au DNS uniquement
   - Les administrateurs (VLAN 20) ont un acces complet
   - Les serveurs (VLAN 30) ne peuvent pas initier de connexion vers les utilisateurs
3. Expliquez pourquoi l'ordre des regles dans une ACL est critique. Donnez un exemple ou un mauvais ordre provoque un blocage inattendu.

---

*Fiche creee pour la revision CCNA*
*Auteur : Tudy Gbaguidi*
