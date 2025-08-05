# 🧮 Apprendre les Sous-Réseaux : Guide du Débutant

## 🏢 **Le Problème Concret**

Imagine que tu gères les ordinateurs d'une entreprise de 300 employés dans un grand immeuble :

- **Étage 1** : 50 commerciaux  
- **Étage 2** : 30 comptables  
- **Étage 3** : 20 informaticiens  
- **Sous-sol** : 10 serveurs  

**Question :** Comment organiser le réseau pour que :
- Les commerciaux ne puissent pas voir les données comptables ?
- Les serveurs soient protégés des utilisateurs normaux ?
- Chaque service ait sa propre "zone réseau" ?

**Réponse :** Les **sous-réseaux** ! C'est comme diviser l'immeuble en appartements séparés.

---

## 🎯 **Qu'est-ce qu'une Adresse IP ?**

### **Analogie Simple : L'Adresse Postale**

Une adresse IP, c'est comme une adresse postale pour ordinateurs :

```
Adresse Postale          |  Adresse IP
123 Rue des Fleurs       |  192.168.1.10
75001 Paris             |  (dans le réseau 192.168.1.0)
France                  |  
```

**Différence importante :** 
- Adresse postale = lettres et chiffres
- Adresse IP = **uniquement des chiffres** (0 à 255)

### **Qu'est-ce qu'un Bit et un Octet ?**

**Un bit** = un interrupteur qui peut être OFF (0) ou ON (1)  
**Un octet** = 8 interrupteurs ensemble = 8 bits

```
Un Octet = 8 Bits
┌─┬─┬─┬─┬─┬─┬─┬─┐
│1│0│1│1│0│0│0│0│ = 176 en décimal
└─┴─┴─┴─┴─┴─┴─┴─┘
 128+32+16 = 176
```

**💡 Explication du calcul :**
- Chaque position a une **valeur fixe** : 128, 64, 32, 16, 8, 4, 2, 1
- Si le bit = **1**, on **ajoute** cette valeur
- Si le bit = **0**, on **ignore** cette valeur
- **Résultat :** 1×128 + 0×64 + 1×32 + 1×16 + 0×8 + 0×4 + 0×2 + 0×1 = **176**

**🎯 Pourquoi c'est important ?** Les ordinateurs ne comprennent que les 0 et 1. Pour nous faciliter la vie, on convertit en nombres décimaux (0 à 255 par octet).

---

## 📢 **Qu'est-ce qu'un Broadcast ?**

### **Définition Simple**
**Broadcast** = Envoyer un message à **TOUS** les ordinateurs d'un réseau en même temps.

### **Analogie Concrète**
```
Immeuble d'entreprise :
┌─────────────────────────────────┐
│ 📢 HAUT-PARLEUR : "Réunion !"   │  ← BROADCAST
├─────────────────────────────────┤
│ 👂 Bureau 1 : "J'ai entendu"    │
│ 👂 Bureau 2 : "J'ai entendu"    │  
│ 👂 Bureau 3 : "J'ai entendu"    │
│ 👂 Bureau 4 : "J'ai entendu"    │
└─────────────────────────────────┘
```

### **Dans un Réseau Informatique**
```
Ordinateur A envoie un broadcast :
"Qui connaît l'adresse MAC de 192.168.1.10 ?"

📡 Message envoyé à l'adresse de broadcast (.255)
    ↓
👥 TOUS les ordinateurs du réseau le reçoivent
    ↓
💬 Seul l'ordinateur .10 répond : "C'est moi !"
```

### **Exemples Concrets de Broadcast**
- **DHCP** : "Y a-t-il un serveur DHCP ici ?" → Broadcast pour trouver le serveur
- **ARP** : "Qui a l'IP 192.168.1.10 ?" → Broadcast pour trouver l'adresse MAC
- **Découverte réseau** : "Quels services sont disponibles ?" → Broadcast

### **Pourquoi une Adresse Spéciale ?**
- **Adresse broadcast** = tous les bits hôtes à **1** (11111111 = 255)
- **Exemple /24** : 192.168.1.255 → message reçu par TOUTES les machines 192.168.1.x
- **Exemple /25** : 192.168.1.127 → message reçu par les machines .0 à .126 seulement

### **🎯 Problème Sans Sous-Réseaux**
Si 1000 ordinateurs sont dans le même réseau :
- 1 broadcast → **1000 ordinateurs** interrompus !
- Solution : Diviser en sous-réseaux → broadcast limité à chaque zone

**💡 C'est pourquoi on évite les adresses .0 et .255 pour les équipements !**

---

## 🏠 **Qu'est-ce qu'une Adresse Réseau ?**

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

### **🎯 À Quoi Ça Sert ?**
- **Routage** : "Pour aller vers 192.168.1.0/24, passe par ce chemin"
- **Configuration** : "Ce switch gère le réseau 192.168.10.0/24"
- **Dépannage** : "Le problème vient du réseau 172.16.0.0/16"

**💡 L'adresse réseau, c'est l'identité du groupe, pas d'un équipement individuel !**

**Une adresse IP = 4 octets = 32 bits au total**

```
192    .    168    .    1    .    10
┌────────┬────────┬────────┬────────┐
│ Octet1 │ Octet2 │ Octet3 │ Octet4 │
│ 8 bits │ 8 bits │ 8 bits │ 8 bits │
└────────┴────────┴────────┴────────┘
         = 32 bits total
```

**💡 Décomposition pratique :**
- **192** = 11000000 en binaire (1×128 + 1×64 = 192)
- **168** = 10101000 en binaire (1×128 + 1×32 + 1×8 = 168)  
- **1** = 00000001 en binaire (1×1 = 1)
- **10** = 00001010 en binaire (1×8 + 1×2 = 10)

**🔑 L'astuce :** Tu n'as pas besoin de calculer en binaire au quotidien ! Les nombres décimaux (0-255) suffisent. Mais comprendre que derrière chaque octet il y a 8 bits t'aide pour les masques.

### **🎮 Mini-Exercice 1**
**Question :** Combien de bits y a-t-il dans l'adresse 10.0.0.1 ?  
**Réponse :** 32 bits (4 octets × 8 bits chacun)

**As-tu compris ?** Si oui, continue. Sinon, relis cette section ! 😊

---

## 🏘️ **Pourquoi Diviser un Réseau ?**

### **Problème Sans Sous-Réseaux**

Imagine un immeuble où **tout le monde** partage le même hall d'entrée :

```
🏢 Immeuble = 1 Grand Réseau
┌─────────────────────────────────┐
│  👥 Commerciaux                 │
│  💰 Comptables                  │  
│  💻 Informaticiens              │
│  🖥️  Serveurs                   │
│                                 │
│ Tout le monde se "voit"         │
│ Tout le monde s'entend          │
│ = PROBLÈMES !                   │
└─────────────────────────────────┘
```

**💡 Traduction réseau :**
- **"Se voir"** = Les ordinateurs peuvent accéder aux fichiers des autres services
- **"S'entendre"** = Tous les messages réseau (broadcast) arrivent chez tout le monde
- **Exemple concret :** Si l'imprimante du service comptable envoie un message "Je suis prête !", TOUS les ordinateurs de l'entreprise le reçoivent → encombrement !

**Problèmes :**
- Les commerciaux peuvent voir les salaires des comptables 😱
- Si quelqu'un crie (broadcast), **tout l'immeuble** l'entend
- Impossible de mettre des règles par service
- Performance dégradée (trop de "bruit")

### **Solution : Créer des Sous-Réseaux**

```
🏢 Immeuble = 4 Sous-Réseaux Séparés
┌─────────────┬─────────────┐
│📊 Étage 1   │💰 Étage 2   │
│Commerciaux  │Comptables   │
│VLAN 10      │VLAN 20      │
├─────────────┼─────────────┤
│💻 Étage 3   │🖥️ Sous-sol  │
│IT           │Serveurs     │
│VLAN 30      │VLAN 40      │
└─────────────┴─────────────┘
```

**💡 Explication technique :**
- **Chaque étage = un sous-réseau** avec ses propres adresses IP
- **VLAN 10** = 192.168.10.0/24 (Commerciaux : .1 à .254)
- **VLAN 20** = 192.168.20.0/24 (Comptables : .1 à .254)  
- **VLAN 30** = 192.168.30.0/24 (IT : .1 à .254)
- **VLAN 40** = 192.168.40.0/24 (Serveurs : .1 à .254)

**🔒 Résultat :** Les commerciaux (192.168.10.x) ne peuvent plus accéder directement aux comptables (192.168.20.x) sans autorisation spéciale !

**Avantages :**
- ✅ Chaque service dans sa "bulle"
- ✅ Sécurité renforcée
- ✅ Moins de "bruit" réseau
- ✅ Règles spécifiques par zone

### **🎮 Mini-Exercice 2**
**Question :** Dans l'exemple ci-dessus, les comptables peuvent-ils voir directement les données des commerciaux ?  
**Réponse :** Non, ils sont dans des sous-réseaux séparés !

---

## 🔍 **Qu'est-ce que CIDR ?**

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

**💡 Explication concrète :**
- **192.168.1** = Adresse du quartier (fixe pour tous les habitants)
- **0 à 255** = Numéros de maison possibles (variable)
- **Pourquoi 256 ?** Avec 8 bits : 00000000 (=0) à 11111111 (=255) = 256 possibilités
- **En pratique :** .0 = panneau du quartier, .255 = haut-parleur → reste **254 maisons habitables**

### **Analogie Visuelle : L'Immeuble /24**

```
🏢 Immeuble 192.168.1.0/24
┌─────────────────────────────────┐
│ Appartement 192.168.1.1         │
│ Appartement 192.168.1.2         │
│ Appartement 192.168.1.3         │
│ ...                             │
│ Appartement 192.168.1.254       │
├─────────────────────────────────┤
│ 🚫 .0 = Plaque de l'immeuble    │
│ 🚫 .255 = Haut-parleur commun   │
└─────────────────────────────────┘

Total : 256 - 2 = 254 appartements habitables
```

**💡 Pourquoi ces 2 adresses sont interdites ?**
- **192.168.1.0** = Adresse du réseau lui-même (comme la plaque "Immeuble Résidentiel")
- **192.168.1.255** = Adresse de broadcast (message à tous : "Réunion dans 10 min !")
- **Exemple concret :** Si tu configures un PC avec l'IP .0 ou .255, ça ne marchera pas !

**🎯 Astuce mémorisation :** Dans un /24, tu peux utiliser les IP de **.1 à .254** pour tes équipements.

### **🎮 Mini-Exercice 3**
**Question :** Dans un réseau `/25`, combien de bits restent pour les "numéros de maison" ?  
**Réponse :** 32 - 25 = 7 bits → 2^7 = 128 maisons → 128 - 2 = 126 habitables

---

## 🧮 **Les Formules Expliquées Simplement**

Maintenant que tu comprends les concepts, voici comment calculer :

### **1. Nombre d'Hôtes Possibles**

**Formule :** `2^(bits_pour_hôtes) - 2`

**Pourquoi -2 ?**
- **-1** pour l'adresse réseau (plaque de l'immeuble)
- **-1** pour l'adresse broadcast (haut-parleur commun)

**💡 Explication concrète :**
Dans un /24 (192.168.1.0/24), tu as 256 adresses possibles (.0 à .255).
```
.0   = 🚫 INTERDIT (adresse réseau)
.1   = ✅ 1er ordinateur  
.2   = ✅ 2e ordinateur
...
.254 = ✅ 254e ordinateur
.255 = 🚫 INTERDIT (broadcast)
```

**Résultat :** 256 - 2 interdites = **254 adresses utilisables** pour tes équipements !

**🎯 Astuce :** Les adresses "interdites" (.0 et .255) ont des rôles spéciaux que les ordinateurs ne peuvent pas prendre.

**Exemples :**
```
/24 → 32-24 = 8 bits hôtes → 2^8 - 2 = 256 - 2 = 254 hôtes
/25 → 32-25 = 7 bits hôtes → 2^7 - 2 = 128 - 2 = 126 hôtes  
/26 → 32-26 = 6 bits hôtes → 2^6 - 2 = 64 - 2 = 62 hôtes
```

### **2. Qu'est-ce qu'un Masque de Sous-Réseau ?**

**Analogie Simple :** Le masque, c'est comme un **filtre** qui sépare :
- La partie "adresse du quartier" 
- La partie "numéro de maison"

**Exemple visuel :**
```
Adresse IP : 192.168.1.50
Masque     : 255.255.255.0 (= /24)

Application du masque :
192.168.1.50  (adresse complète)
255.255.255.0 (masque = "garde les 3 premiers octets")
= 192.168.1.0 (adresse du quartier)
```

### **3. Table de Référence pour Débutants**

**Comment lire cette table :** Commence par la colonne "Usage" pour trouver ton besoin !

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

### **🎮 Mini-Exercice 4**
**Question :** Tu as besoin de connecter 40 ordinateurs. Quel CIDR choisir ?  
**Réponse :** /26 (62 hôtes) car /27 (30 hôtes) est trop petit !

---

## 📝 **Comment Découper un Réseau ? (Méthode Simple)**

### **Étape 1 : Le Besoin**
Imagine : tu as `192.168.1.0/24` (254 hôtes) et tu veux créer **2 sous-réseaux** de taille égale.

### **Étape 2 : Combien de Bits Emprunter ?**
- Tu veux **2 sous-réseaux**
- 2 = 2^1, donc tu empruntes **1 bit** aux hôtes
- Nouveau masque : /24 + 1 = **/25**

### **Étape 3 : Calcul de l'Incrément**
**Formule simple :** `256 ÷ nombre_de_sous_réseaux`  
`256 ÷ 2 = 128` → Incrément de 128

### **Étape 4 : Lister les Sous-Réseaux**
```
Sous-réseau 1 : 192.168.1.0/25   (de .0 à .127)
Sous-réseau 2 : 192.168.1.128/25 (de .128 à .255)
```

**💡 Explication visuelle du découpage :**
```
Avant (1 grand immeuble) :     Après (2 immeubles) :
┌───────────────────────┐      ┌─────────┬─────────┐
│  192.168.1.0/24       │  →   │ .0/25   │.128/25  │
│  (.0 à .255)          │      │(.0-.127)│(.128-.255)│
│  254 appartements     │      │126 appt │126 appt │
└───────────────────────┘      └─────────┴─────────┘
```

**🔑 Le secret :** L'incrément (128) nous donne le "pas" entre chaque sous-réseau !

### **Étape 5 : Détail de Chaque Sous-Réseau**
```
📊 Sous-réseau 1 : 192.168.1.0/25
├─ Adresse réseau    : 192.168.1.0
├─ Première IP utile : 192.168.1.1
├─ Dernière IP utile : 192.168.1.126
├─ Adresse broadcast : 192.168.1.127
└─ Nb hôtes         : 126

📊 Sous-réseau 2 : 192.168.1.128/25  
├─ Adresse réseau    : 192.168.1.128
├─ Première IP utile : 192.168.1.129
├─ Dernière IP utile : 192.168.1.254
├─ Adresse broadcast : 192.168.1.255
└─ Nb hôtes         : 126
```

**💡 Comment j'ai trouvé ces valeurs ?**

**Pour le sous-réseau 1 (.0/25) :**
- **Réseau** : 192.168.1.0 (début de la plage)
- **Broadcast** : 192.168.1.127 (fin de la plage, avant le prochain réseau)
- **IPs utiles** : .1 à .126 (entre réseau et broadcast)

**Pour le sous-réseau 2 (.128/25) :**
- **Réseau** : 192.168.1.128 (début de la plage = 0 + incrément)
- **Broadcast** : 192.168.1.255 (fin de la plage, dernière IP possible)
- **IPs utiles** : .129 à .254 (entre réseau et broadcast)

**🎯 Formule magique :** Broadcast = Prochain réseau - 1

**📝 Pourquoi le -1 ?**

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

**Analogie :** C'est comme les numéros de maison dans une rue. Si la rue suivante commence au n°128, alors la dernière maison de ta rue est forcément le n°127 !

### **🎮 Mini-Exercice 5 : À Toi de Jouer !**

**Scénario :** Tu dois diviser `192.168.10.0/24` en **4 sous-réseaux** égaux.

**Questions :**
1. Combien de bits dois-tu emprunter ?
2. Quel sera le nouveau masque CIDR ?
3. Quel est l'incrément ?
4. Liste les 4 sous-réseaux créés

**Réflexion avant de regarder la solution :**
- 4 sous-réseaux = 2^? → 2^2 = 4, donc **2 bits à emprunter**
- Nouveau masque : /24 + 2 = **/26**
- Incrément : 256 ÷ 4 = **64**

**Solution :**
```
Sous-réseau 1 : 192.168.10.0/26   (.0 à .63)
Sous-réseau 2 : 192.168.10.64/26  (.64 à .127)  
Sous-réseau 3 : 192.168.10.128/26 (.128 à .191)
Sous-réseau 4 : 192.168.10.192/26 (.192 à .255)
```

**Bravo !** Si tu as trouvé, tu maîtrises les bases ! 🎉

---

## 🎓 **Récapitulatif des Acquis**

### **✅ Ce que tu sais maintenant :**

1. **Adresse IP** = adresse postale numérique (4 octets = 32 bits)
2. **CIDR /24** = "24 bits pour le quartier, 8 bits pour les maisons"  
3. **Sous-réseau** = diviser un grand réseau en zones séparées
4. **Masque** = filtre qui sépare "quartier" et "numéro de maison"
5. **Formule hôtes** = 2^(bits_hôtes) - 2
6. **Méthode découpage** = emprunter des bits aux hôtes

### **🚀 Es-tu Prêt pour la Suite ?**

**Test Rapide :**
1. Combien d'hôtes dans un /27 ? → **30**
2. Pour 100 hôtes, tu prends /24 ou /25 ? → **/25** (126 hôtes)
3. L'adresse 192.168.1.50/26 est dans quel sous-réseau ? → **192.168.1.0/26** (.0 à .63)

Si tu as **tout juste**, tu peux passer aux **exercices pratiques avancés** !  
Si tu **hésites encore**, relis les sections précédentes. 😊

---

## 🟢 **NIVEAU 1 : Exercices Pratiques**

*Maintenant que tu comprends les concepts, voici des exercices pour t'entraîner :*

### **Exercice 1.1 : Analyse Simple**

**Question :** Analyse cette configuration réseau : `192.168.1.150/24`

**Méthode guidée :**
```
1. Identifier le CIDR : /24
2. Calculer les bits hôtes : 32 - 24 = 8 bits
3. Calculer nb hôtes : 2^8 - 2 = 254 hôtes
4. Trouver l'adresse réseau : 192.168.1.0 (dernier octet à 0)
5. Trouver le broadcast : 192.168.1.255 (dernier octet à 255)
```

**Ta réponse :**
- 🏠 Adresse réseau : 192.168.1.0/24
- 🔢 Première IP utile : 192.168.1.1  
- 🔢 Dernière IP utile : 192.168.1.254
- 📢 Adresse broadcast : 192.168.1.255
- 👥 Nombre d'hôtes : 254

### **Exercice 1.2 : Calcul Simple /25**

**Question :** Découpez 192.168.10.0/24 en 2 sous-réseaux égaux

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

## 🟡 **NIVEAU 2 : Exercices Intermédiaires**

### **Exercice 2.1 : VLSM (Variable Length Subnet Mask)**

**Scénario :** Une entreprise a besoin de :
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

**Question :** Trouvez l'erreur dans cette configuration :
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

**Erreur :** Les deux interfaces sont dans des sous-réseaux différents !
**Correction :** Utiliser des IPs du même sous-réseau ou des masques appropriés.

## 🔴 **NIVEAU 3 : Exercices Avancés**

### **Exercice 3.1 : Optimisation Complexe**

**Scénario :** Conception pour un campus avec :
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

**Problème :** Le réseau ne fonctionne pas correctement :
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

## 🎯 **Défis Pratiques**

### **Défi 1 : Reverse Engineering**

**Donnée :** Un host a l'IP 172.16.47.92/22
**Trouvez :**
- Adresse réseau
- Première et dernière IP
- Adresse broadcast
- Nombre d'hôtes total

### **Défi 2 : Optimisation Extrême**

**Mission :** Avec 192.168.0.0/24, créez :
- 1 réseau de 100 hôtes
- 2 réseaux de 25 hôtes chacun
- 4 réseaux de 10 hôtes chacun  
- 6 liaisons P2P
- Minimisez le gaspillage d'adresses !

### **Défi 3 : Dépannage Expert**

**Scénario :** Dans une entreprise, certains VLANs ne communiquent plus entre eux après une reconfiguration. Analysez et corrigez :
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

## ✅ **Solutions des Exercices Niveau 1**

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

## 📊 **Auto-Évaluation**

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

## 🎓 **Méthodes de Calcul Rapide**

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

**💡 Conseil CCNA :** Pratiquez ces calculs quotidiennement jusqu'à les faire mentalement. C'est la base de toute expertise réseau !

---

*Exercices créés pour la révision CCNA*  
*Auteur : Tudy Gbaguidi*