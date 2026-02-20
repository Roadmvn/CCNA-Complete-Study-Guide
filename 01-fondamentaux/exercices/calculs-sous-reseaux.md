# Apprendre les Sous-Réseaux : Guide du Débutant

## **Le Problème Concret**

Imagine que tu gères les ordinateurs d'une entreprise de 300 employés dans un grand immeuble :

- **Étage 1** : 50 commerciaux  
- **Étage 2** : 30 comptables  
- **Étage 3** : 20 informaticiens  
- **Sous-sol** : 10 serveurs  

**Question :**Comment organiser le réseau pour que :
- Les commerciaux ne puissent pas voir les données comptables ?
- Les serveurs soient protégés des utilisateurs normaux ?
- Chaque service ait sa propre "zone réseau" ?

**Réponse :**Les **sous-réseaux** ! C'est comme diviser l'immeuble en appartements séparés.

---

## **Qu'est-ce qu'une Adresse IP ?**

### **Analogie Simple : L'Adresse Postale**

Une adresse IP, c'est comme une adresse postale pour ordinateurs :

```
Adresse Postale          |  Adresse IP
123 Rue des Fleurs       |  192.168.1.10
75001 Paris              |  (dans le réseau 192.168.1.0)
France                   |  
```

**Différence importante :** 
- Adresse postale = lettres et chiffres
- Adresse IP = **uniquement des chiffres** (0 à 255)

### **Qu'est-ce qu'un Bit et un Octet ?**

**Un bit** = un interrupteur qui peut être OFF (0) ou ON (1)  
**Un octet** = 8 interrupteurs ensemble = 8 bits

```
Un Octet = 8 Bits
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 1 │ 0 │ 1 │ 1 │ 0 │ 0 │ 0 │ 0 │ ← Valeur du bit (0 ou 1)
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ ← Valeur de position
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 0 │ 32│ 16│ 0 │ 0 │ 0 │ 0 │ ← Valeur retenue (bit × position)
└───┴───┴───┴───┴───┴───┴───┴───┘
         Total : 128 + 32 + 16 = 176
```

**Explication du calcul :**
- Chaque position a une **valeur fixe** : 128, 64, 32, 16, 8, 4, 2, 1
- Si le bit = **1**, on **ajoute** cette valeur
- Si le bit = **0**, on **ignore** cette valeur (= 0)
- **Résultat :** 128 + 0 + 32 + 16 + 0 + 0 + 0 + 0 = **176**

**Pourquoi c'est important ?**Les ordinateurs ne comprennent que les 0 et 1. Pour nous faciliter la vie, on convertit en nombres décimaux (0 à 255 par octet).

---

## **Qu'est-ce qu'un Broadcast ?**

### **Définition Simple**
**Broadcast** = Envoyer un message à **TOUS** les ordinateurs d'un réseau en même temps.

### **Analogie Concrète**
```
Immeuble d'entreprise :
┌─────────────────────────────────┐
│  HAUT-PARLEUR : "Réunion !"   │  ← BROADCAST
├─────────────────────────────────┤
│  Bureau 1 : "J'ai entendu"    │
│  Bureau 2 : "J'ai entendu"    │  
│  Bureau 3 : "J'ai entendu"    │
│  Bureau 4 : "J'ai entendu"    │
└─────────────────────────────────┘
```

### **Dans un Réseau Informatique**
```
Ordinateur A envoie un broadcast :
"Qui connaît l'adresse MAC de 192.168.1.10 ?"

 Message envoyé à l'adresse de broadcast (.255)
    ↓
 TOUS les ordinateurs du réseau le reçoivent
    ↓
 Seul l'ordinateur .10 répond : "C'est moi !"
```

### **Exemples Concrets de Broadcast**
- **DHCP** : "Y a-t-il un serveur DHCP ici ?" → Broadcast pour trouver le serveur
- **ARP** : "Qui a l'IP 192.168.1.10 ?" → Broadcast pour trouver l'adresse MAC
- **Découverte réseau** : "Quels services sont disponibles ?" → Broadcast

### **Pourquoi une Adresse Spéciale ?**
- **Adresse broadcast** = tous les bits hôtes à **1** (11111111 = 255)
- **Exemple /24** : 192.168.1.255 → message reçu par TOUTES les machines 192.168.1.x
- **Exemple /25** : 192.168.1.127 → message reçu par les machines .0 à .126 seulement

### **Problème Sans Sous-Réseaux**
Si 1000 ordinateurs sont dans le même réseau :
- 1 broadcast → **1000 ordinateurs** interrompus !
- Solution : Diviser en sous-réseaux → broadcast limité à chaque zone

**C'est pourquoi on évite les adresses .0 et .255 pour les équipements !**

---

## **Qu'est-ce qu'une Adresse Réseau ?**

### **Définition Simple**
**Adresse réseau** = "Nom" ou "Panneau" qui identifie tout un groupe d'ordinateurs.

### **Analogie Postale**
```
Adresse postale complète : 123 Rue des Fleurs, 75001 Paris
                          ├─────────────────┤ ├────────┤
                           Adresse complète   Code postal
                                             (= zone/quartier)

Adresse IP complète : 192.168.1.50/24
                     ├─────────────┤├┤
                      Adresse complète /24 = taille du "quartier"
                     
Adresse réseau : 192.168.1.0/24  ← "Panneau du quartier"
```

### **Pourquoi tous les bits hôtes à 0 ?**
```
Exemple : PC avec IP 192.168.1.50/24
En binaire : 192.168.1.00110010

Adresse réseau → on met tous les bits hôtes à 0 :
                 192.168.1.00000000 = 192.168.1.0

C'est comme dire : "Ce PC appartient au quartier 192.168.1.0"
```

### **Exemples Concrets**
- **192.168.1.0/24** = Quartier qui contient les machines .1 à .254
- **10.0.0.0/8** = Très grand quartier qui contient 16 millions d'adresses !
- **172.16.50.0/26** = Petit quartier qui contient seulement 62 machines

### **À Quoi Ça Sert ?**
- **Routage** : "Pour aller vers 192.168.1.0/24, passe par ce chemin"
- **Configuration** : "Ce switch gère le réseau 192.168.10.0/24"
- **Dépannage** : "Le problème vient du réseau 172.16.0.0/16"

**L'adresse réseau, c'est l'identité du groupe, pas d'un équipement individuel !**

---

## **Qu'est-ce qu'un Masque de Sous-Réseau ?**

### **Définition Simple**
Un **masque de sous-réseau** est comme un **filtre** qui sépare une adresse IP en deux parties :
- La partie **RÉSEAU** (l'immeuble/le quartier)
- La partie **HÔTE** (l'appartement/la maison)

### **Analogie du Masque**
Imaginez un **code postal** : 75015
- **750** = Ville et arrondissement (partie fixe)
- **15** = Secteur précis (partie variable)

Le masque dit : "Les 3 premiers chiffres identifient la zone, les 2 derniers l'endroit précis"

### **Le Masque en Pratique**

#### **En Décimal (ce qu'on voit habituellement)**
```
Masque courant : 255.255.255.0
┌─────────┬─────────┬─────────┬─────────┐
│   255   │   255   │   255   │    0    │
├─────────┼─────────┼─────────┼─────────┤
│ Réseau  │ Réseau  │ Réseau  │  Hôtes  │
│  Fixe   │  Fixe   │  Fixe   │Variable │
└─────────┴─────────┴─────────┴─────────┘

255 = Tous les bits à 1 = Cette partie appartient au RÉSEAU
0   = Tous les bits à 0 = Cette partie appartient aux HÔTES
```

#### **En Binaire (ce que l'ordinateur comprend)**
```
255.255.255.0 en binaire complet :

Octet 1 : 255 = 11111111
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ ← Tous à 1
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ = 128+64+32+16+8+4+2+1 = 255
└───┴───┴───┴───┴───┴───┴───┴───┘

Octet 4 : 0 = 00000000
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ ← Tous à 0
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ = 0+0+0+0+0+0+0+0 = 0
└───┴───┴───┴───┴───┴───┴───┴───┘
```

**Règle d'Or du Masque :**
- Bits à **1** = Partie **RÉSEAU** (ne change pas)
- Bits à **0** = Partie **HÔTE** (peut varier)

### **Comment le Masque "Filtre" l'IP ?**

#### **Exemple Visuel : 192.168.1.100 avec masque 255.255.255.0**

```
ÉTAPE 1 : L'adresse IP complète
┌─────────┬─────────┬─────────┬─────────┐
│   192   │   168   │    1    │   100   │
└─────────┴─────────┴─────────┴─────────┘

ÉTAPE 2 : Le masque s'applique
┌─────────┬─────────┬─────────┬─────────┐
│   255   │   255   │   255   │    0    │
└─────────┴─────────┴─────────┴─────────┘

ÉTAPE 3 : Résultat du filtrage
┌─────────────────────────────┬─────────┐
│      192.168.1.             │   100   │
├─────────────────────────────┼─────────┤
│    PARTIE RÉSEAU            │  PARTIE │
│   (gardée par 255)          │  HÔTE   │
│   "Le quartier"             │"La maison"│
└─────────────────────────────┴─────────┘

Résultat : Adresse réseau = 192.168.1.0
           Machine n°100 dans ce réseau
```

### **L'Opération AND : La Magie du Masque**

Le masque utilise l'opération logique **AND** (ET) :

```
Règles du AND :
1 AND 1 = 1  (Les deux sont vrais = vrai)
1 AND 0 = 0  (Un seul est vrai = faux)
0 AND 1 = 0  (Un seul est vrai = faux)
0 AND 0 = 0  (Aucun n'est vrai = faux)
```

**Exemple détaillé avec 192.168.1.100 et masque 255.255.255.0 :**
```
                 Octet 1    Octet 2    Octet 3    Octet 4
IP     :      11000000 . 10101000 . 00000001 . 01100100
Masque :      11111111 . 11111111 . 11111111 . 00000000
              ────────────────────────────────────────── AND
Réseau :      11000000 . 10101000 . 00000001 . 00000000
              = 192    . 168      . 1        . 0

 Le masque a "effacé" la partie hôte (100→0) 
   pour ne garder que l'adresse réseau !
```

### **Les Masques Courants et Leur Utilisation**

```
┌────────┬─────────────────┬──────────────┬───────────────────────┐
│ CIDR   │ Masque Décimal  │ Nb d'Hôtes   │ Utilisation Type      │
├────────┼─────────────────┼──────────────┼───────────────────────┤
│ /8     │ 255.0.0.0       │ 16,777,214   │ Très grandes org.     │
│ /16    │ 255.255.0.0     │ 65,534       │ Campus, grande ville  │
│ /24    │ 255.255.255.0   │ 254          │ PME, étage bureau     │
│ /25    │ 255.255.255.128 │ 126          │ Département           │
│ /26    │ 255.255.255.192 │ 62           │ Petit service         │
│ /27    │ 255.255.255.224 │ 30           │ Équipe                │
│ /28    │ 255.255.255.240 │ 14           │ Petit groupe          │
│ /30    │ 255.255.255.252 │ 2            │ Liaison point-à-point │
└────────┴─────────────────┴──────────────┴───────────────────────┘
```

### **Pourquoi le Masque est CRUCIAL ?**

1. **Routage** : Les routeurs utilisent le masque pour savoir où envoyer les paquets
   ```
   "Destination 192.168.1.0/24 ? → Envoie par l'interface eth0"
   ```

2. **Sécurité** : Sépare les réseaux sensibles
   ```
   Comptabilité : 192.168.10.0/24 (masque isole ce réseau)
   Production  : 192.168.20.0/24 (masque isole ce réseau)
   ```

3. **Performance** : Limite la taille des domaines de broadcast
   ```
   Sans masque : 1000 machines qui se parlent = chaos !
   Avec masque : 4 × 250 machines séparées = organisé !
   ```

### **Mini-Exercice : Applique le Masque**

```
Question : IP = 10.5.3.75, Masque = 255.255.255.0
          Quelle est l'adresse réseau ?

Résolution étape par étape :
┌───────────┬───────────┬───────────┬───────────┐
│    10     │     5     │     3     │    75     │ ← IP
│    255    │    255    │    255    │     0     │ ← Masque
├───────────┼───────────┼───────────┼───────────┤
│  10 AND   │  5 AND    │  3 AND    │  75 AND   │
│   255     │   255     │   255     │    0      │
│    =10    │    =5     │    =3     │    =0     │
├───────────┼───────────┼───────────┼───────────┤
│    10     │     5     │     3     │     0     │ ← RÉSEAU
└───────────┴───────────┴───────────┴───────────┘

Réponse : Adresse réseau = 10.5.3.0
```

**Astuce Rapide :**Avec un masque 255.255.255.0, remplace simplement le dernier octet par 0 !

---

**Une adresse IP = 4 octets = 32 bits au total**

## **VISUALISATION COMPLÈTE : Les 32 Bits d'une Adresse IP**

### **Exemple : 192.168.1.100/24**

#### **VUE DÉCIMALE (ce qu'on voit habituellement)**
```
192    .    168    .    1    .    100
┌────────┬────────┬────────┬────────┐
│ Octet1 │ Octet2 │ Octet3 │ Octet4 │
│ 8 bits │ 8 bits │ 8 bits │ 8 bits │
└────────┴────────┴────────┴────────┘
         = 32 bits total
```

#### **VUE BINAIRE COMPLÈTE (les 32 bits détaillés)**
```
Adresse IP : 192.168.1.100

┌──────────────────────────────────────────────────────────────────────────────┐
│                          LES 32 BITS COMPLETS                               │
├──────────────────────────────────────────────────────────────────────────────┤
│ Bit n° : 1  2  3  4  5  6  7  8 │ 9 10 11 12 13 14 15 16 │17 18 19 20 21 22 23 24│25 26 27 28 29 30 31 32│
│ Valeur : 1  1  0  0  0  0  0  0 │ 1  0  1  0  1  0  0  0 │ 0  0  0  0  0  0  0  1│ 0  1  1  0  0  1  0  0│
├──────────────────────────────────┼──────────────────────────┼───────────────────────┼───────────────────────┤
│            11000000              │        10101000          │       00000001        │       01100100        │
│              192                 │          168             │          1            │         100           │
│           Octet 1                │        Octet 2           │       Octet 3         │       Octet 4         │
└──────────────────────────────────┴──────────────────────────┴───────────────────────┴───────────────────────┘
```

#### **CALCUL DÉTAILLÉ DE CHAQUE OCTET**
```
OCTET 1 : 192 = 11000000
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 1 │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ ← Valeur de chaque position
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ ← Valeurs retenues
└───┴───┴───┴───┴───┴───┴───┴───┘
Total : 128 + 64 = 192

OCTET 2 : 168 = 10101000
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 1 │ 0 │ 1 │ 0 │ 1 │ 0 │ 0 │ 0 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 0 │ 32│ 0 │ 8 │ 0 │ 0 │ 0 │
└───┴───┴───┴───┴───┴───┴───┴───┘
Total : 128 + 32 + 8 = 168

OCTET 3 : 1 = 00000001
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │
└───┴───┴───┴───┴───┴───┴───┴───┘
Total : 1

OCTET 4 : 100 = 01100100
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 0 │ 1 │ 1 │ 0 │ 0 │ 1 │ 0 │ 0 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │
├───┼───┼───┼───┼───┼───┼───┼───┤
│ 0 │ 64│ 32│ 0 │ 0 │ 4 │ 0 │ 0 │
└───┴───┴───┴───┴───┴───┴───┴───┘
Total : 64 + 32 + 4 = 100
```

#### **APPLICATION DU MASQUE /24 SUR LES 32 BITS**
```
IP : 192.168.1.100/24 (24 bits réseau, 8 bits hôtes)

Les 32 bits avec le masque appliqué :
┌──────────────────────────────────────────────────────────────────────┐
│ 11000000.10101000.00000001.01100100  ← Adresse IP complète          │
│ 11111111.11111111.11111111.00000000  ← Masque /24                   │
├────────────────────────────┬─────────────────────────────────────────┤
│     24 bits RÉSEAU         │      8 bits HÔTES                       │
│    (partie fixe)           │    (partie variable)                    │
│    192.168.1               │         .100                            │
└────────────────────────────┴─────────────────────────────────────────┘

Résultat après masque (AND) :
11000000.10101000.00000001.00000000 = 192.168.1.0 (adresse réseau)
```

#### **ZOOM SUR LES BITS HÔTES DANS UN /24**
```
Dans 192.168.1.100/24, les 8 derniers bits sont pour les hôtes :

Bit position : 25 26 27 28 29 30 31 32
Bit value   :  0  1  1  0  0  1  0  0  = 100 en décimal

Possibilités avec 8 bits hôtes :
00000000 = 0   → Adresse réseau (interdite)
00000001 = 1   → 1ère IP utilisable
00000010 = 2   → 2e IP utilisable
...
01100100 = 100 → Notre IP (192.168.1.100)
...
11111110 = 254 → Dernière IP utilisable
11111111 = 255 → Broadcast (interdit)
```

**Pourquoi c'est important ?**
- Comprendre les 32 bits aide à visualiser comment le masque "découpe" l'adresse
- On voit clairement pourquoi .0 et .255 sont spéciaux (tous bits à 0 ou 1)
- Les calculs de sous-réseaux deviennent logiques quand on voit les bits

### **Mini-Exercice 1**
**Question :**Combien de bits y a-t-il dans l'adresse 10.0.0.1 ?  
**Réponse :** 32 bits (4 octets × 8 bits chacun)

**As-tu compris ?**Si oui, continue. Sinon, relis cette section ! 

---

## **Pourquoi Diviser un Réseau ?**

### **Problème Sans Sous-Réseaux**

Imagine un immeuble où **tout le monde** partage le même hall d'entrée :

```
 Immeuble = 1 Grand Réseau
┌─────────────────────────────────┐
│   Commerciaux                 │
│   Comptables                  │  
│   Informaticiens              │
│    Serveurs                   │
│                                 │
│ Tout le monde se "voit"         │
│ Tout le monde s'entend          │
│ = PROBLÈMES !                   │
└─────────────────────────────────┘
```

**Traduction réseau :**
- **"Se voir"** = Les ordinateurs peuvent accéder aux fichiers des autres services
- **"S'entendre"** = Tous les messages réseau (broadcast) arrivent chez tout le monde
- **Exemple concret :**Si l'imprimante du service comptable envoie un message "Je suis prête !", TOUS les ordinateurs de l'entreprise le reçoivent → encombrement !

**Problèmes :**
- Les commerciaux peuvent voir les salaires des comptables 
- Si quelqu'un crie (broadcast), **tout l'immeuble** l'entend
- Impossible de mettre des règles par service
- Performance dégradée (trop de "bruit")

### **Solution : Créer des Sous-Réseaux**

```
 Immeuble = 4 Sous-Réseaux Séparés
┌─────────────┬─────────────┐
│ Étage 1   │ Étage 2   │
│Commerciaux  │Comptables   │
│VLAN 10      │VLAN 20      │
├─────────────┼─────────────┤
│ Étage 3   │ Sous-sol  │
│IT           │Serveurs     │
│VLAN 30      │VLAN 40      │
└─────────────┴─────────────┘
```

**Explication technique :**
- **Chaque étage = un sous-réseau** avec ses propres adresses IP
- **VLAN 10** = 192.168.10.0/24 (Commerciaux : .1 à .254)
- **VLAN 20** = 192.168.20.0/24 (Comptables : .1 à .254)  
- **VLAN 30** = 192.168.30.0/24 (IT : .1 à .254)
- **VLAN 40** = 192.168.40.0/24 (Serveurs : .1 à .254)

**Résultat :**Les commerciaux (192.168.10.x) ne peuvent plus accéder directement aux comptables (192.168.20.x) sans autorisation spéciale !

**Avantages :**
-  Chaque service dans sa "bulle"
-  Sécurité renforcée
-  Moins de "bruit" réseau
-  Règles spécifiques par zone

### **Mini-Exercice 2**
**Question :**Dans l'exemple ci-dessus, les comptables peuvent-ils voir directement les données des commerciaux ?  
**Réponse :**Non, ils sont dans des sous-réseaux séparés !

---

## **Qu'est-ce que CIDR ?**

### **Définition Simple**
**CIDR** = façon moderne d'écrire "combien d'ordinateurs peuvent tenir dans ce réseau"

**Format :** `adresse_réseau/nombre`  
**Exemple :** `192.168.1.0/24`

### **Décoder le "/24"**

Le `/24` signifie : "les **24 premiers bits** (sur 32) décrivent le **quartier**, les **8 bits restants** décrivent le **numéro de maison**"

```
192.168.1.0/24
├─────────────┤├─┤
   24 bits      8 bits
   (quartier)  (maisons)

24 bits pour le quartier → 1 seul quartier
8 bits pour les maisons → 2×2×2×2×2×2×2×2 = 256 maisons possibles
```

**Explication concrète :**
- **192.168.1** = Adresse du quartier (fixe pour tous les habitants)
- **0 à 255** = Numéros de maison possibles (variable)
- **Pourquoi 256 ?**Avec 8 bits : 00000000 (=0) à 11111111 (=255) = 256 possibilités
- **En pratique :** .0 = panneau du quartier, .255 = haut-parleur → reste **254 maisons habitables**

### **Analogie Visuelle : L'Immeuble /24**

```
 Immeuble 192.168.1.0/24
┌─────────────────────────────────┐
│ Appartement 192.168.1.1         │
│ Appartement 192.168.1.2         │
│ Appartement 192.168.1.3         │
│ ...                             │
│ Appartement 192.168.1.254       │
├─────────────────────────────────┤
│  .0 = Plaque de l'immeuble    │
│  .255 = Haut-parleur commun   │
└─────────────────────────────────┘

Total : 256 - 2 = 254 appartements habitables
```

**Pourquoi ces 2 adresses sont interdites ?**
- **192.168.1.0** = Adresse du réseau lui-même (comme la plaque "Immeuble Résidentiel")
- **192.168.1.255** = Adresse de broadcast (message à tous : "Réunion dans 10 min !")
- **Exemple concret :**Si tu configures un PC avec l'IP .0 ou .255, ça ne marchera pas !

**Astuce mémorisation :**Dans un /24, tu peux utiliser les IP de **.1 à .254** pour tes équipements.

### **Mini-Exercice 3**
**Question :**Dans un réseau `/25`, combien de bits restent pour les "numéros de maison" ?  
**Réponse :** 32 - 25 = 7 bits → 2^7 = 128 maisons → 128 - 2 = 126 habitables

---

## **Les Formules Expliquées Simplement**

Maintenant que tu comprends les concepts, voici comment calculer :

### **1. Nombre d'Hôtes Possibles - CALCUL DÉTAILLÉ**

**Formule :** `Nombre d'hôtes = 2^(bits_pour_hôtes) - 2`

#### **ÉTAPE 1 : Comprendre les 32 bits d'une IP**
```
Adresse IPv4 = 32 bits TOTAL
┌────────────────────────────────────────────────────────────┐
│ Bits 1-8   │ Bits 9-16  │ Bits 17-24 │ Bits 25-32        │
│ Octet 1    │ Octet 2    │ Octet 3    │ Octet 4           │
└────────────────────────────────────────────────────────────┘

Exemple : 192.168.1.0/24
          /24 signifie : 24 bits pour le RÉSEAU
                        32 - 24 = 8 bits pour les HÔTES
```

#### **ÉTAPE 2 : Calculer 2^(bits_hôtes)**
```
Pour un /24 :
Bits hôtes = 32 - 24 = 8 bits

Calcul de 2^8 :
┌─────────────────────────────────────────────────┐
│ 2^1 = 2    │ 2^5 = 32                           │
│ 2^2 = 4    │ 2^6 = 64                           │
│ 2^3 = 8    │ 2^7 = 128                          │
│ 2^4 = 16   │ 2^8 = 256 ← NOTRE RÉSULTAT         │
└─────────────────────────────────────────────────┘

Pourquoi 2^8 = 256 ?
Chaque bit peut être 0 ou 1 (2 possibilités)
8 bits = 2×2×2×2×2×2×2×2 = 256 combinaisons

En binaire : de 00000000 à 11111111
En décimal : de 0 à 255 = 256 valeurs
```

#### **ÉTAPE 3 : Pourquoi -2 ? EXPLICATION PRÉCISE**
```
Les 256 adresses possibles (de .0 à .255) :

┌──────────────────────────────────────────────────┐
│ Adresse │ Binaire (8 bits) │ Utilisation        │
├─────────┼──────────────────┼────────────────────┤
│ .0      │ 00000000         │  ADRESSE RÉSEAU  │
│ .1      │ 00000001         │  Utilisable      │
│ .2      │ 00000010         │  Utilisable      │
│ .3      │ 00000011         │  Utilisable      │
│ ...     │ ...              │  Utilisable      │
│ .254    │ 11111110         │  Utilisable      │
│ .255    │ 11111111         │  BROADCAST       │
└──────────────────────────────────────────────────┘

RÈGLE ABSOLUE :
- Tous bits à 0 (00000000) = Adresse réseau INTERDITE
- Tous bits à 1 (11111111) = Broadcast INTERDIT
- Donc : 256 - 2 = 254 adresses utilisables
```

#### **EXEMPLES DE CALCULS COMPLETS**
```
┌──────┬──────────────┬────────────┬─────────────────────────┐
│ CIDR │ Bits réseau  │ Bits hôtes │ Calcul détaillé         │
├──────┼──────────────┼────────────┼─────────────────────────┤
│ /24  │ 24 bits      │ 8 bits     │ 2^8 = 256              │
│      │              │            │ 256 - 2 = 254 hôtes    │
├──────┼──────────────┼────────────┼─────────────────────────┤
│ /25  │ 25 bits      │ 7 bits     │ 2^7 = 128              │
│      │              │            │ 128 - 2 = 126 hôtes    │
├──────┼──────────────┼────────────┼─────────────────────────┤
│ /26  │ 26 bits      │ 6 bits     │ 2^6 = 64               │
│      │              │            │ 64 - 2 = 62 hôtes      │
├──────┼──────────────┼────────────┼─────────────────────────┤
│ /27  │ 27 bits      │ 5 bits     │ 2^5 = 32               │
│      │              │            │ 32 - 2 = 30 hôtes      │
├──────┼──────────────┼────────────┼─────────────────────────┤
│ /28  │ 28 bits      │ 4 bits     │ 2^4 = 16               │
│      │              │            │ 16 - 2 = 14 hôtes      │
├──────┼──────────────┼────────────┼─────────────────────────┤
│ /30  │ 30 bits      │ 2 bits     │ 2^2 = 4                │
│      │              │            │ 4 - 2 = 2 hôtes        │
└──────┴──────────────┴────────────┴─────────────────────────┘
```

### **2. Masque de Sous-Réseau - CALCUL BINAIRE PRÉCIS**

#### **COMPRENDRE LE MASQUE EN BINAIRE**
```
Masque /24 = 255.255.255.0

Conversion en binaire :
255 . 255 . 255 . 0
11111111.11111111.11111111.00000000
├────────── 24 bits à 1 ──────────┤├── 8 bits à 0 ──┤
        PARTIE RÉSEAU               PARTIE HÔTES
```

#### **COMMENT LE MASQUE "FILTRE" L'ADRESSE IP**
```
OPÉRATION AND BINAIRE (bit par bit) :

IP :     192.168.1.50    = 11000000.10101000.00000001.00110010
Masque : 255.255.255.0   = 11111111.11111111.11111111.00000000
                           ─────────────────────────────────────
Résultat AND :             11000000.10101000.00000001.00000000
                         = 192.168.1.0 (ADRESSE RÉSEAU)

Règle du AND binaire :
1 AND 1 = 1
1 AND 0 = 0  
0 AND 1 = 0
0 AND 0 = 0
```

#### **TABLEAU DES MASQUES COURANTS**
```
┌──────┬─────────────────┬──────────────────────────────────┬────────────┐
│ CIDR │ Masque Décimal  │ Masque Binaire                   │ Incrément  │
├──────┼─────────────────┼──────────────────────────────────┼────────────┤
│ /24  │ 255.255.255.0   │ 11111111.11111111.11111111.00000000 │ 256     │
│ /25  │ 255.255.255.128 │ 11111111.11111111.11111111.10000000 │ 128     │
│ /26  │ 255.255.255.192 │ 11111111.11111111.11111111.11000000 │ 64      │
│ /27  │ 255.255.255.224 │ 11111111.11111111.11111111.11100000 │ 32      │
│ /28  │ 255.255.255.240 │ 11111111.11111111.11111111.11110000 │ 16      │
│ /29  │ 255.255.255.248 │ 11111111.11111111.11111111.11111000 │ 8       │
│ /30  │ 255.255.255.252 │ 11111111.11111111.11111111.11111100 │ 4       │
└──────┴─────────────────┴──────────────────────────────────┴────────────┘

FORMULE INCRÉMENT : 256 - (valeur dernier octet du masque)
Exemple /26 : 256 - 192 = 64
```

### **3. Table de Référence pour Débutants**

**Comment lire cette table :**Commence par la colonne "Usage" pour trouver ton besoin !

```
┌──────┬───────────────┬─────────────┬──────────────────────────────┐
│ CIDR │ Nb Hôtes      │ Usage Typique│ Analogie                     │
├──────┼───────────────┼─────────────┼──────────────────────────────┤
│ /24  │ 254           │ LAN Bureau  │ Grand immeuble (254 apparts) │
│ /25  │ 126           │ Service     │ 1/2 immeuble (126 apparts)   │
│ /26  │ 62            │ Département │ 1/4 immeuble (62 apparts)    │
│ /27  │ 30            │ Petit Bureau│ 1 étage (30 apparts)         │
│ /28  │ 14            │ Équipe      │ 1/2 étage (14 apparts)       │
│ /29  │ 6             │ Labo Test   │ 1 couloir (6 apparts)        │
│ /30  │ 2             │ Liaison     │ 2 maisons reliées            │
└──────┴───────────────┴─────────────┴──────────────────────────────┘
```

### **Mini-Exercice 4**
**Question :**Tu as besoin de connecter 40 ordinateurs. Quel CIDR choisir ?  
**Réponse :** /26 (62 hôtes) car /27 (30 hôtes) est trop petit !

---

## **Comment Découper un Réseau ? MÉTHODE MATHÉMATIQUE PRÉCISE**

### **PROBLÈME : Diviser 192.168.1.0/24 en 2 sous-réseaux**

#### **ÉTAPE 1 : Analyser le Réseau Original**
```
Réseau : 192.168.1.0/24
┌───────────────────────────────────────────────────────┐
│ /24 = 24 bits réseau + 8 bits hôtes                  │
│ 2^8 = 256 adresses totales                           │
│ 256 - 2 = 254 hôtes utilisables                      │
└───────────────────────────────────────────────────────┘
```

#### **ÉTAPE 2 : Calculer les Bits à Emprunter**
```
Besoin : 2 sous-réseaux
Question : 2^? = 2 sous-réseaux

┌─────────────────────────────────────┐
│ 2^0 = 1  (pas assez)                │
│ 2^1 = 2   EXACTEMENT CE QU'IL FAUT│
│ 2^2 = 4  (trop)                     │
└─────────────────────────────────────┘

Donc : EMPRUNTER 1 BIT aux hôtes
```

#### **ÉTAPE 3 : Nouveau Masque et Calculs**
```
Ancien masque : /24 (24 bits réseau, 8 bits hôtes)
Nouveau masque : /24 + 1 = /25 (25 bits réseau, 7 bits hôtes)

VISUALISATION BINAIRE DU DERNIER OCTET :

Masque /24 (255.255.255.0) :
┌───┬───┬───┬───┬───┬───┬───┬───┐
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ ← Valeurs
├───┼───┼───┼───┼───┼───┼───┼───┤
│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 0
└───┴───┴───┴───┴───┴───┴───┴───┘
     Tous les bits pour les hôtes

Masque /25 (255.255.255.128) :
┌───┬───┬───┬───┬───┬───┬───┬───┐
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ ← Valeurs
├───┼───┼───┼───┼───┼───┼───┼───┤
│ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 128
└───┴───┴───┴───┴───┴───┴───┴───┘
  ↑ Bit emprunté (maintenant réseau)
  
Nouveau masque décimal : 255.255.255.128
Incrément = 256 - 128 = 128
```

#### **ÉTAPE 4 : Calcul Mathématique des Sous-Réseaux**
```
Formule : Réseau_n = Réseau_base + (n × incrément)

Sous-réseau 0 : 192.168.1.0 + (0 × 128) = 192.168.1.0
Sous-réseau 1 : 192.168.1.0 + (1 × 128) = 192.168.1.128

Vérification : Nombre total d'adresses
2 sous-réseaux × 128 adresses = 256 
```

### **Étape 4 : Lister les Sous-Réseaux**
```
Sous-réseau 1 : 192.168.1.0/25   (de .0 à .127)
Sous-réseau 2 : 192.168.1.128/25 (de .128 à .255)
```

**Explication visuelle du découpage :**
```
Avant (1 grand immeuble) :     Après (2 immeubles) :
┌───────────────────────┐      ┌─────────┬─────────┐
│  192.168.1.0/24       │  →   │ .0/25   │.128/25  │
│  (.0 à .255)          │      │(.0-.127)│(.128-.255)│
│  254 appartements     │      │126 appt │126 appt │
└───────────────────────┘      └─────────┴─────────┘
```

**Le secret :**L'incrément (128) nous donne le "pas" entre chaque sous-réseau !

#### **ÉTAPE 5 : Calcul DÉTAILLÉ de Chaque Sous-Réseau**

##### **SOUS-RÉSEAU 1 : 192.168.1.0/25**
```
CALCULS MATHÉMATIQUES :
┌─────────────────────────────────────────────────────────┐
│ Adresse réseau    = 192.168.1.0 (début de plage)       │
│ Adresse broadcast = Prochain_réseau - 1                 │
│                   = 192.168.1.128 - 1                   │
│                   = 192.168.1.127                       │
│                                                         │
│ Première IP utile = Adresse_réseau + 1                 │
│                   = 192.168.1.0 + 1                    │
│                   = 192.168.1.1                        │
│                                                         │
│ Dernière IP utile = Broadcast - 1                      │
│                   = 192.168.1.127 - 1                  │
│                   = 192.168.1.126                      │
│                                                         │
│ Nombre d'hôtes    = 2^7 - 2                           │
│                   = 128 - 2                            │
│                   = 126 hôtes                          │
└─────────────────────────────────────────────────────────┘

REPRÉSENTATION BINAIRE (dernier octet avec valeurs) :
┌───┬───┬───┬───┬───┬───┬───┬───┐
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ ← Valeurs de position
├───┼───┼───┼───┼───┼───┼───┼───┤
│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 0 (Réseau)
│ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ = 1 (1ère IP)
│ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ = 126 (Dernière IP)
│ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ = 127 (Broadcast)
└───┴───┴───┴───┴───┴───┴───┴───┘
Note : Le bit 128 reste à 0 car c'est le bit emprunté pour /25
```

##### **SOUS-RÉSEAU 2 : 192.168.1.128/25**
```
CALCULS MATHÉMATIQUES :
┌─────────────────────────────────────────────────────────┐
│ Adresse réseau    = 192.168.1.128                      │
│                   = Base + (1 × incrément)             │
│                   = 192.168.1.0 + 128                  │
│                                                         │
│ Adresse broadcast = Prochain_réseau - 1                 │
│                   = (192.168.1.128 + 128) - 1          │
│                   = 192.168.1.256 - 1                  │
│                   = 192.168.1.255                      │
│                                                         │
│ Première IP utile = 192.168.1.128 + 1                  │
│                   = 192.168.1.129                      │
│                                                         │
│ Dernière IP utile = 192.168.1.255 - 1                  │
│                   = 192.168.1.254                      │
│                                                         │
│ Nombre d'hôtes    = 126 (identique au subnet 1)       │
└─────────────────────────────────────────────────────────┘

REPRÉSENTATION BINAIRE (dernier octet avec valeurs) :
┌───┬───┬───┬───┬───┬───┬───┬───┐
│128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │ ← Valeurs de position
├───┼───┼───┼───┼───┼───┼───┼───┤
│ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 128 (Réseau)
│ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ = 129 (1ère IP)
│ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ = 254 (Dernière IP)
│ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ = 255 (Broadcast)
└───┴───┴───┴───┴───┴───┴───┴───┘
Note : Le bit 128 reste à 1 car c'est le 2e sous-réseau /25
```

**Formule magique :**Broadcast = Prochain réseau - 1

**Pourquoi le -1 ?**

Imagine les adresses comme une **file d'attente** :
```
Sous-réseau 1 :          Sous-réseau 2 :
.0   = Panneau           .128 = Panneau  
.1   = 1er appartement   .129 = 1er appartement
.2   = 2e appartement    .130 = 2e appartement
...                      ...
.126 = Dernier appart     .254 = Dernier appart
.127 = Haut-parleur      .255 = Haut-parleur
```

**Le broadcast (.127) doit être la DERNIÈRE adresse du sous-réseau !**
- Prochain réseau = .128
- Donc broadcast = .128 - 1 = **.127**

**Analogie :**C'est comme les numéros de maison dans une rue. Si la rue suivante commence au n°128, alors la dernière maison de ta rue est forcément le n°127 !

### **EXERCICE COMPLET : Diviser en 4 Sous-Réseaux**

**Problème :**Diviser `192.168.10.0/24` en **4 sous-réseaux**égaux.

#### **SOLUTION DÉTAILLÉE ÉTAPE PAR ÉTAPE**

##### **1. CALCUL DES BITS À EMPRUNTER**
```
Besoin : 4 sous-réseaux
Question : 2^x = 4

┌────────────────────────────────────────┐
│ 2^0 = 1 sous-réseau  (pas assez)      │
│ 2^1 = 2 sous-réseaux (pas assez)      │
│ 2^2 = 4 sous-réseaux  PARFAIT        │
│ 2^3 = 8 sous-réseaux (trop)           │
└────────────────────────────────────────┘

RÉPONSE : Emprunter 2 bits
```

##### **2. NOUVEAU MASQUE ET INCRÉMENT**
```
Ancien masque : /24 → 11111111.11111111.11111111.00000000
Nouveau masque : /26 → 11111111.11111111.11111111.11000000
                                                 ↑↑
                                         2 bits empruntés

Masque décimal : 255.255.255.192
Calcul incrément : 256 - 192 = 64

Vérification : 4 sous-réseaux × 64 adresses = 256 
```

##### **3. CALCUL DES 4 SOUS-RÉSEAUX**
```
┌────────┬──────────────────┬──────────────────────────────┐
│ Subnet │ Calcul           │ Plage d'adresses             │
├────────┼──────────────────┼──────────────────────────────┤
│ #1     │ Base + 0×64 = 0  │ 192.168.10.0 à .63          │
│ #2     │ Base + 1×64 = 64 │ 192.168.10.64 à .127        │
│ #3     │ Base + 2×64 = 128│ 192.168.10.128 à .191       │
│ #4     │ Base + 3×64 = 192│ 192.168.10.192 à .255       │
└────────┴──────────────────┴──────────────────────────────┘
```

##### **4. DÉTAILS COMPLETS DE CHAQUE SOUS-RÉSEAU**
```
SOUS-RÉSEAU 1 : 192.168.10.0/26
┌─────────────────────────────────────────────────────┐
│ Adresse réseau    : 192.168.10.0                   │
│ 1ère IP utile     : 192.168.10.1                   │
│ Dernière IP utile : 192.168.10.62                  │
│ Broadcast         : 192.168.10.63                  │
│ Nb hôtes          : 2^6 - 2 = 64 - 2 = 62          │
│                                                     │
│ EN BINAIRE (dernier octet avec valeurs) :          │
│ ┌───┬───┬───┬───┬───┬───┬───┬───┐                 │
│ │128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │                 │
│ ├───┼───┼───┼───┼───┼───┼───┼───┤                 │
│ │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 0 (Réseau)    │
│ │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ = 1 (1ère IP)   │
│ │ 0 │ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ = 62 (Dernière) │
│ │ 0 │ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ = 63 (Broadcast)│
│ └───┴───┴───┴───┴───┴───┴───┴───┘                 │
│ Note: Les 2 premiers bits (128,64) = réseau /26   │
└─────────────────────────────────────────────────────┘

SOUS-RÉSEAU 2 : 192.168.10.64/26
┌─────────────────────────────────────────────────────┐
│ Adresse réseau    : 192.168.10.64                  │
│ 1ère IP utile     : 192.168.10.65                  │
│ Dernière IP utile : 192.168.10.126                 │
│ Broadcast         : 192.168.10.127                 │
│ Nb hôtes          : 62                             │
│                                                     │
│ EN BINAIRE (dernier octet avec valeurs) :          │
│ ┌───┬───┬───┬───┬───┬───┬───┬───┐                 │
│ │128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │                 │
│ ├───┼───┼───┼───┼───┼───┼───┼───┤                 │
│ │ 0 │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 64 (Réseau)   │
│ │ 0 │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ = 65 (1ère IP)  │
│ │ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ = 126 (Dernière)│
│ │ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ = 127 (Broadcast)│
│ └───┴───┴───┴───┴───┴───┴───┴───┘                 │
│ Calcul: 64+32+16+8+4+2 = 126, 64+32+16+8+4+2+1 = 127│
└─────────────────────────────────────────────────────┘

SOUS-RÉSEAU 3 : 192.168.10.128/26
┌─────────────────────────────────────────────────────┐
│ Adresse réseau    : 192.168.10.128                 │
│ 1ère IP utile     : 192.168.10.129                 │
│ Dernière IP utile : 192.168.10.190                 │
│ Broadcast         : 192.168.10.191                 │
│ Nb hôtes          : 62                             │
│                                                     │
│ EN BINAIRE (dernier octet avec valeurs) :          │
│ ┌───┬───┬───┬───┬───┬───┬───┬───┐                 │
│ │128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │                 │
│ ├───┼───┼───┼───┼───┼───┼───┼───┤                 │
│ │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 128 (Réseau)  │
│ │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ = 129 (1ère IP) │
│ │ 1 │ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ = 190 (Dernière)│
│ │ 1 │ 0 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ = 191 (Broadcast)│
│ └───┴───┴───┴───┴───┴───┴───┴───┘                 │
│ Calcul: 128+32+16+8+4+2 = 190, 128+32+16+8+4+2+1 = 191│
└─────────────────────────────────────────────────────┘

SOUS-RÉSEAU 4 : 192.168.10.192/26
┌─────────────────────────────────────────────────────┐
│ Adresse réseau    : 192.168.10.192                 │
│ 1ère IP utile     : 192.168.10.193                 │
│ Dernière IP utile : 192.168.10.254                 │
│ Broadcast         : 192.168.10.255                 │
│ Nb hôtes          : 62                             │
│                                                     │
│ EN BINAIRE (dernier octet avec valeurs) :          │
│ ┌───┬───┬───┬───┬───┬───┬───┬───┐                 │
│ │128│ 64│ 32│ 16│ 8 │ 4 │ 2 │ 1 │                 │
│ ├───┼───┼───┼───┼───┼───┼───┼───┤                 │
│ │ 1 │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ = 192 (Réseau)  │
│ │ 1 │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ = 193 (1ère IP) │
│ │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ = 254 (Dernière)│
│ │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ = 255 (Broadcast)│
│ └───┴───┴───┴───┴───┴───┴───┴───┘                 │
│ Calcul: 128+64 = 192, 128+64+32+16+8+4+2 = 254    │
└─────────────────────────────────────────────────────┘
```

**VÉRIFICATION FINALE :** 4 × 62 hôtes = 248 hôtes utiles au total

---

## **Récapitulatif des Acquis**

### **Ce que tu sais maintenant :**

1. **Adresse IP** = adresse postale numérique (4 octets = 32 bits)
2. **CIDR /24** = "24 bits pour le quartier, 8 bits pour les maisons"  
3. **Sous-réseau** = diviser un grand réseau en zones séparées
4. **Masque** = filtre qui sépare "quartier" et "numéro de maison"
5. **Formule hôtes** = 2^(bits_hôtes) - 2
6. **Méthode découpage** = emprunter des bits aux hôtes

### **Es-tu Prêt pour la Suite ?**

**Test Rapide :**
1. Combien d'hôtes dans un /27 ? → **30**
2. Pour 100 hôtes, tu prends /24 ou /25 ? → **/25** (126 hôtes)
3. L'adresse 192.168.1.50/26 est dans quel sous-réseau ? → **192.168.1.0/26** (.0 à .63)

Si tu as **tout juste**, tu peux passer aux **exercices pratiques avancés** !  
Si tu **hésites encore**, relis les sections précédentes. 

---

## **NIVEAU 1 : Exercices Pratiques**

*Maintenant que tu comprends les concepts, voici des exercices pour t'entraîner :*

### **Exercice 1.1 : Analyse Simple**

**Question :**Analyse cette configuration réseau : `192.168.1.150/24`

**Méthode guidée :**
```
1. Identifier le CIDR : /24
2. Calculer les bits hôtes : 32 - 24 = 8 bits
3. Calculer nb hôtes : 2^8 - 2 = 254 hôtes
4. Trouver l'adresse réseau : 192.168.1.0 (dernier octet à 0)
5. Trouver le broadcast : 192.168.1.255 (dernier octet à 255)
```

**Ta réponse :**
-  Adresse réseau : 192.168.1.0/24
-  Première IP utile : 192.168.1.1  
-  Dernière IP utile : 192.168.1.254
-  Adresse broadcast : 192.168.1.255
-  Nombre d'hôtes : 254

### **Exercice 1.2 : Calcul Simple /25**

**Question :**Découpez 192.168.10.0/24 en 2 sous-réseaux égaux

**Méthode :**
```
Réseau original : 192.168.10.0/24 (254 hôtes)
Besoin : 2 sous-réseaux
Bits à emprunter : 1 bit (2^1 = 2 subnets)
Nouveau masque : /24 + 1 = /25

Masque /25 = 255.255.255.128
Incrément = 256 - 128 = 128
```

**Réponse :**
```
Sous-réseau 1 : 192.168.10.0/25
• Réseau : 192.168.10.0
• Première IP : 192.168.10.1  
• Dernière IP : 192.168.10.126
• Broadcast : 192.168.10.127
• Hôtes : 126

Sous-réseau 2 : 192.168.10.128/25
• Réseau : 192.168.10.128
• Première IP : 192.168.10.129
• Dernière IP : 192.168.10.254  
• Broadcast : 192.168.10.255
• Hôtes : 126
```

### **Exercice 1.3 : À Vous !**

**Questions :**
1. Analysez 10.0.0.50/16
2. Découpez 172.16.0.0/16 en 4 sous-réseaux égaux
3. Dans quel sous-réseau est 192.168.100.75/26 ?

## **NIVEAU 2 : Exercices Intermédiaires**

### **Exercice 2.1 : VLSM (Variable Length Subnet Mask)**

**Scénario :**Une entreprise a besoin de :
- Réseau A : 100 hôtes
- Réseau B : 50 hôtes  
- Réseau C : 25 hôtes
- Réseau D : 10 hôtes
- 3 liaisons P2P (2 hôtes chacune)

**Réseau disponible :** 192.168.1.0/24

**Méthode VLSM :**
```
1. Trier par taille décroissante :
   • A : 100 hôtes → besoin /25 (126 hôtes)
   • B : 50 hôtes  → besoin /26 (62 hôtes)
   • C : 25 hôtes  → besoin /27 (30 hôtes)
   • D : 10 hôtes  → besoin /28 (14 hôtes)
   • P2P × 3      → besoin /30 (2 hôtes)

2. Allocation séquentielle :
```

**Solution :**
```
Réseau A (100 hôtes) : 192.168.1.0/25
• Plage : 192.168.1.0 à 192.168.1.127

Réseau B (50 hôtes) : 192.168.1.128/26  
• Plage : 192.168.1.128 à 192.168.1.191

Réseau C (25 hôtes) : 192.168.1.192/27
• Plage : 192.168.1.192 à 192.168.1.223

Réseau D (10 hôtes) : 192.168.1.224/28
• Plage : 192.168.1.224 à 192.168.1.239

Liaison P2P-1 : 192.168.1.240/30
• Plage : 192.168.1.240 à 192.168.1.243

Liaison P2P-2 : 192.168.1.244/30  
• Plage : 192.168.1.244 à 192.168.1.247

Liaison P2P-3 : 192.168.1.248/30
• Plage : 192.168.1.248 à 192.168.1.251

Inutilisé : 192.168.1.252 à 192.168.1.255
```

### **Exercice 2.2 : Analyse d'Erreur**

**Question :**Trouvez l'erreur dans cette configuration :
```
Interface Fa0/0 : 172.16.10.1/26
Interface Fa0/1 : 172.16.10.75/26
```

**Analyse :**
```
/26 = 255.255.255.192
Incrément = 256 - 192 = 64

Sous-réseaux /26 :
• 172.16.10.0/26   (0 à 63)
• 172.16.10.64/26  (64 à 127)  
• 172.16.10.128/26 (128 à 191)
• 172.16.10.192/26 (192 à 255)

IP .1 est dans 172.16.10.0/26 (0-63)
IP .75 est dans 172.16.10.64/26 (64-127)
```

**Erreur :**Les deux interfaces sont dans des sous-réseaux différents !
**Correction :**Utiliser des IPs du même sous-réseau ou des masques appropriés.

## **NIVEAU 3 : Exercices Avancés**

### **Exercice 3.1 : Optimisation Complexe**

**Scénario :**Conception pour un campus avec :
- Bâtiment A : 500 utilisateurs + 50 serveurs
- Bâtiment B : 300 utilisateurs + 20 imprimantes  
- Bâtiment C : 150 utilisateurs + 10 WiFi AP
- DMZ : 20 serveurs publics
- Management : 50 équipements réseau
- 10 liaisons inter-bâtiments

**Réseau disponible :** 172.20.0.0/16

**Solution Optimisée :**
```
Allocation par ordre décroissant :

Bâtiment A Users (500) : 172.20.0.0/23
• Capacité : 510 hôtes (2^9 - 2)
• Plage : 172.20.0.0 à 172.20.1.255

Bâtiment B Users (300) : 172.20.2.0/23  
• Capacité : 510 hôtes
• Plage : 172.20.2.0 à 172.20.3.255

Bâtiment C Users (150) : 172.20.4.0/24
• Capacité : 254 hôtes
• Plage : 172.20.4.0 à 172.20.4.255

Bâtiment A Servers (50) : 172.20.5.0/26
• Capacité : 62 hôtes  
• Plage : 172.20.5.0 à 172.20.5.63

Management (50) : 172.20.5.64/26
• Capacité : 62 hôtes
• Plage : 172.20.5.64 à 172.20.5.127

DMZ Servers (20) : 172.20.5.128/27
• Capacité : 30 hôtes
• Plage : 172.20.5.128 à 172.20.5.159

Bâtiment B Printers (20) : 172.20.5.160/27
• Capacité : 30 hôtes  
• Plage : 172.20.5.160 à 172.20.5.191

Bâtiment C WiFi (10) : 172.20.5.192/28
• Capacité : 14 hôtes
• Plage : 172.20.5.192 à 172.20.5.207

Liaisons P2P (10 × 2 hôtes) : 172.20.5.208/28
• 172.20.5.208/30 (Link-1)
• 172.20.5.212/30 (Link-2)  
• 172.20.5.216/30 (Link-3)
• etc... jusqu'à 172.20.5.244/30
```

### **Exercice 3.2 : Troubleshooting Avancé**

**Problème :**Le réseau ne fonctionne pas correctement :
```
Router R1 :
• Fa0/0 : 10.1.1.1/24 (vers LAN-A)
• Fa0/1 : 10.1.2.1/24 (vers LAN-B)  
• S0/0 : 10.1.100.1/30 (vers R2)

Router R2 :
• S0/0 : 10.1.100.2/30 (vers R1)
• Fa0/0 : 10.1.3.1/24 (vers LAN-C)

PC-A (LAN-A) : 10.1.1.10/24, GW: 10.1.1.1
PC-B (LAN-B) : 10.1.2.10/24, GW: 10.1.2.1  
PC-C (LAN-C) : 10.1.3.10/24, GW: 10.1.3.1

Problème : PC-A peut ping PC-B mais pas PC-C
```

**Diagnostic :**
```
Vérifications :
1. Connectivité L1/L2 : OK (PC-A ping PC-B fonctionne)
2. Adressage IP : OK (configurations correctes)
3. Routing entre R1-R2 : À vérifier

Tests :
• PC-A ping 10.1.1.1 (sa gateway) → OK
• PC-A ping 10.1.100.1 (interface S0/0 R1) → OK  
• PC-A ping 10.1.100.2 (interface S0/0 R2) → ?
• PC-A ping 10.1.3.1 (gateway PC-C) → KO

Cause probable : Pas de route vers 10.1.3.0/24 sur R1
                ou pas de route retour vers 10.1.1.0/24 sur R2
```

**Solution :**
```
Router R1 :
ip route 10.1.3.0 255.255.255.0 10.1.100.2

Router R2 :  
ip route 10.1.1.0 255.255.255.0 10.1.100.1
ip route 10.1.2.0 255.255.255.0 10.1.100.1
```

## **Défis Pratiques**

### **Défi 1 : Reverse Engineering**

**Donnée :**Un host a l'IP 172.16.47.92/22
**Trouvez :**
- Adresse réseau
- Première et dernière IP
- Adresse broadcast
- Nombre d'hôtes total

### **Défi 2 : Optimisation Extrême**

**Mission :**Avec 192.168.0.0/24, créez :
- 1 réseau de 100 hôtes
- 2 réseaux de 25 hôtes chacun
- 4 réseaux de 10 hôtes chacun  
- 6 liaisons P2P
- Minimisez le gaspillage d'adresses !

### **Défi 3 : Dépannage Expert**

**Scénario :**Dans une entreprise, certains VLANs ne communiquent plus entre eux après une reconfiguration. Analysez et corrigez :
```
VLAN 10 : 192.168.10.0/25 (Users)
VLAN 20 : 192.168.10.128/26 (Servers)  
VLAN 30 : 192.168.10.192/27 (Printers)
VLAN 40 : 192.168.10.224/28 (Management)

Interface VLAN 10 : 192.168.10.1/25
Interface VLAN 20 : 192.168.10.129/26
Interface VLAN 30 : 192.168.10.193/27  
Interface VLAN 40 : 192.168.10.225/28
```

## **Solutions des Exercices Niveau 1**

### **Solution 1.3 :**

**1. Analyse de 10.0.0.50/16 :**
```
• Classe : A privée
• Réseau : 10.0.0.0/16
• Masque : 255.255.0.0
• Première IP : 10.0.0.1
• Dernière IP : 10.0.255.254
• Broadcast : 10.0.255.255
• Hôtes : 65,534
```

**2. Découpage 172.16.0.0/16 en 4 :**
```
Bits à emprunter : 2 (2^2 = 4)
Nouveau masque : /18 (255.255.192.0)
Incrément : 256 - 192 = 64 (en /16 = 64×256 = 16384)

Subnet 1 : 172.16.0.0/18 (0.0 à 63.255)
Subnet 2 : 172.16.64.0/18 (64.0 à 127.255)  
Subnet 3 : 172.16.128.0/18 (128.0 à 191.255)
Subnet 4 : 172.16.192.0/18 (192.0 à 255.255)
```

**3. Sous-réseau de 192.168.100.75/26 :**
```
/26 = 255.255.255.192
Incrément = 64

Subnets /26 :
• 192.168.100.0/26 (0-63)
• 192.168.100.64/26 (64-127) ← .75 est ici
• 192.168.100.128/26 (128-191)
• 192.168.100.192/26 (192-255)

Réponse : 192.168.100.64/26
```

## **Auto-Évaluation**

### **Critères de Maîtrise :**

```
┌─────────────────────┬─────────────────────────────────────────┐
│ Niveau              │ Critères de Réussite                   │
├─────────────────────┼─────────────────────────────────────────┤
│ Débutant            │ • Calculs /24, /25, /26 en 5 min       │
│                     │ • Identification classe et masque      │
├─────────────────────┼─────────────────────────────────────────┤
│ Intermédiaire       │ • VLSM simple en 10 min                │
│                     │ • Détection erreurs configuration      │
├─────────────────────┼─────────────────────────────────────────┤
│ Avancé              │ • VLSM complexe en 15 min              │
│                     │ • Optimisation et troubleshooting      │
├─────────────────────┼─────────────────────────────────────────┤
│ Expert              │ • Tous calculs mentalement             │
│                     │ • Design réseau complet               │
└─────────────────────┴─────────────────────────────────────────┘
```

## **Méthodes de Calcul Rapide**

### **Astuce 1 : Méthode Binaire Rapide**
```
Pour /26 dans 192.168.1.0 :
1. /26 = 2 bits hôte → 4 subnets possibles
2. 8-2 = 6 bits réseau dans dernier octet  
3. 2^6 = 64 = incrément
4. Subnets : 0, 64, 128, 192
```

### **Astuce 2 : Vérification Rapide**
```
IP quelconque dans subnet ?
1. IP ÷ Incrément = quotient  
2. Quotient × Incrément = Adresse réseau
3. Adresse réseau + Incrément - 1 = Broadcast

Exemple : 192.168.1.75 dans /26 ?
75 ÷ 64 = 1 reste 11
1 × 64 = 64 → réseau = 192.168.1.64/26
```

---

**Conseil CCNA :**Pratiquez ces calculs quotidiennement jusqu'à les faire mentalement. C'est la base de toute expertise réseau !

---

*Exercices créés pour la révision CCNA*  
*Auteur : Roadmvn*