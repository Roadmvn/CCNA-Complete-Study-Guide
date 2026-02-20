# Topologies Securite et WAN - Schemas ASCII

## Vue d'Ensemble

Cette section presente les topologies de securite reseau et WAN avec des schemas ASCII detailles pour la preparation CCNA. Chaque schema inclut des legendes completes et des annotations techniques.

---

## 1. Topologie Securite Reseau Complete (Firewall, DMZ, Zones)

### Architecture de Securite Multi-Zones

```
                         +-------------+
                         |  INTERNET   |
                         |  (Untrust)  |
                         +------+------+
                                |
                         +------+------+
                         |   ISP       |
                         |   Router    |
                         |  (Border)   |
                         +------+------+
                                | Zone OUTSIDE
                                | 203.0.113.0/24
                         +------+------+
                         |  FIREWALL   |
                         |  (ASA/FW)   |
                         |             |
                         | Outside -+  |
                         | DMZ    --+  |
                         | Inside --+  |
                         +--+---+---+--+
                            |   |   |
             +--------------+   |   +--------------+
             |                  |                  |
      Zone DMZ                  |           Zone INSIDE
      172.16.1.0/24             |           (Trust)
             |                  |           192.168.0.0/16
      +------+------+          |           |
      |   DMZ       |          |    +------+------+
      |   Switch    |          |    |   Core      |
      +------+------+          |    |   Switch    |
             |                 |    +------+------+
   +---------+---------+      |           |
   |         |         |      |    +------+------------------+
+--+--+   +--+--+  +--+--+   |    |         |              |
| Web |   | Mail|  | DNS |   | +--+--+   +--+--+     +-----+-----+
| Srv |   | Srv |  | Srv |   | |VLAN |   |VLAN |     |  VLAN     |
|.10  |   |.20  |  |.30  |   | | 10  |   | 20  |     |  99       |
+-----+   +-----+  +-----+   | |Users|   |Srvs |     |Management |
                              | +--+--+   +--+--+     +-----+-----+
                              |    |         |              |
                              |   PCs     Serveurs     Equipements
                              |                        reseau
                              |
                       Zone GUEST
                       10.10.10.0/24
                              |
                       +------+------+
                       |  WiFi AP    |
                       |  (Invite)   |
                       +------+------+
                              |
                        Smartphones
                        Laptops invites

Legende :
===============================================================
Zone OUTSIDE (Untrust)  : Interface vers Internet, non fiable
Zone DMZ                : Serveurs accessibles depuis Internet
Zone INSIDE (Trust)     : Reseau interne de l'entreprise
Zone GUEST              : Reseau invite isole
---------------------------------------------------------------
Firewall : Filtre le trafic entre toutes les zones
  - Outside -> DMZ    : HTTP/HTTPS/SMTP/DNS uniquement
  - Outside -> Inside : INTERDIT (sauf VPN)
  - Inside  -> DMZ    : Administration + services
  - Inside  -> Outside: NAT + inspection stateful
  - Guest   -> Outside: Internet uniquement (pas d'acces interne)
===============================================================
```

### Matrice de Flux Firewall

```
+----------+----------+----------+----------+----------+
| Source /  | OUTSIDE  |   DMZ    |  INSIDE  |  GUEST   |
| Dest     |          |          |          |          |
+----------+----------+----------+----------+----------+
| OUTSIDE  |   ---    | HTTP/S   | DENY     | DENY     |
|          |          | SMTP/DNS |          |          |
+----------+----------+----------+----------+----------+
| DMZ      | Reponse  |   ---    | DENY     | DENY     |
|          | stateful |          |(sauf log)|          |
+----------+----------+----------+----------+----------+
| INSIDE   | NAT +    | Admin    |   ---    | DENY     |
|          | Inspect  | SSH/RDP  |          |          |
+----------+----------+----------+----------+----------+
| GUEST    | HTTP/S   | DENY     | DENY     |   ---    |
|          | seul     |          |          |          |
+----------+----------+----------+----------+----------+
```

---

## 2. Schema DHCP Snooping + DAI (Dynamic ARP Inspection)

### Fonctionnement DHCP Snooping

```
+---------------------------------------------------------------------+
|                    SWITCH L2 avec DHCP Snooping                    |
|                                                                     |
|  +-------------------------------------------------------------+   |
|  |              DHCP Snooping Binding Table                    |   |
|  |  +---------+--------------+-----------+-------+----------+ |   |
|  |  |  MAC    |     IP       |  VLAN     | Port  | Lease    | |   |
|  |  +---------+--------------+-----------+-------+----------+ |   |
|  |  | AA:BB:01| 192.168.1.10 |  VLAN 10  | Fa0/1 | 86400s   | |   |
|  |  | AA:BB:02| 192.168.1.20 |  VLAN 10  | Fa0/2 | 86400s   | |   |
|  |  | AA:BB:03| 192.168.1.30 |  VLAN 10  | Fa0/3 | 86400s   | |   |
|  |  +---------+--------------+-----------+-------+----------+ |   |
|  +-------------------------------------------------------------+   |
|                                                                     |
|    TRUSTED PORTS                      UNTRUSTED PORTS              |
|    (vers DHCP Server                  (vers clients)               |
|     ou uplink)                                                      |
|                                                                     |
|  +---------+                  +---------+ +---------+ +---------+ |
|  |  Gi0/1  |                  |  Fa0/1  | |  Fa0/2  | |  Fa0/3  | |
|  | TRUSTED |                  |UNTRUSTED| |UNTRUSTED| |UNTRUSTED| |
|  +----+----+                  +----+----+ +----+----+ +----+----+ |
+-------+----------------------------+-----------+-----------+-------+
        |                            |           |           |
        |                            |           |           |
 +------+------+              +------+--+  +-----+---+ +----+----+
 | DHCP Server |              |  PC-1   |  |  PC-2   | |  PC-3   |
 | 192.168.1.1 |              | Legitime|  |Legitime | |Legitime |
 +-------------+              +---------+  +---------+ +---------+


  SCENARIO D'ATTAQUE BLOQUEE :

  +---------------------------------------------------------------+
  |                                                               |
  |  +---------+     DHCP OFFER (faux)      +---------+         |
  |  | Attacker | ----------------------X--> |  PC-1   |         |
  |  | (Rogue   |     BLOQUE par le switch   |         |         |
  |  |  DHCP)   |     (port UNTRUSTED ne     |         |         |
  |  |  Fa0/5   |      peut pas envoyer      |         |         |
  |  +---------+      DHCP OFFER/ACK)       +---------+         |
  |                                                               |
  |  X = Paquet DHCP Server rejete sur port UNTRUSTED            |
  |                                                               |
  +---------------------------------------------------------------+

Legende :
===============================================================
TRUSTED PORT    : Accepte tous les messages DHCP (serveur/uplink)
UNTRUSTED PORT  : Accepte uniquement DHCP DISCOVER et REQUEST
                  Rejette DHCP OFFER et ACK (attaque rogue DHCP)
Binding Table   : Table MAC/IP/VLAN/Port construite dynamiquement
                  a partir des echanges DHCP valides
Rate Limiting   : Limite le nombre de requetes DHCP par seconde
                  sur les ports untrusted (protection DoS)
===============================================================
```

### Dynamic ARP Inspection (DAI)

```
+---------------------------------------------------------------------+
|              SWITCH avec DAI active (utilise DHCP Snooping DB)     |
|                                                                     |
|  Requete ARP entrante sur port UNTRUSTED :                         |
|                                                                     |
|  +---------------------------------------------------------------+ |
|  | ARP Request : "Who has 192.168.1.1 ? Tell 192.168.1.10"      | |
|  | Sender MAC  : AA:BB:CC:DD:EE:01                              | |
|  | Sender IP   : 192.168.1.10                                   | |
|  | Port entrant: Fa0/1                                          | |
|  +---------------------------------------------------------------+ |
|                            |                                        |
|                            v                                        |
|  +---------------------------------------------------------------+ |
|  |              VERIFICATION DAI                                 | |
|  |                                                               | |
|  |  Sender MAC = AA:BB:CC:DD:EE:01                              | |
|  |  Sender IP  = 192.168.1.10                                   | |
|  |                                                               | |
|  |  Binding Table :                                              | |
|  |  MAC AA:BB:CC:DD:EE:01 <-> IP 192.168.1.10 <-> Fa0/1        | |
|  |                                                               | |
|  |  MAC correspond ?  --> OUI                                    | |
|  |  IP  correspond ?  --> OUI                                    | |
|  |  Port correspond ? --> OUI                                    | |
|  |                                                               | |
|  |  RESULTAT : AUTORISE (forward ARP)                           | |
|  +---------------------------------------------------------------+ |
|                                                                     |
|  SCENARIO ARP SPOOFING BLOQUE :                                    |
|  +---------------------------------------------------------------+ |
|  | ARP Reply forge : "192.168.1.1 is-at FF:FF:FF:FF:FF:FF"      | |
|  | Sender MAC  : FF:FF:FF:FF:FF:FF (fausse)                     | |
|  | Sender IP   : 192.168.1.1                                    | |
|  | Port entrant: Fa0/5                                          | |
|  |                                                               | |
|  | Binding Table : Aucune entree pour FF:FF:FF:FF:FF:FF / Fa0/5 | |
|  |                                                               | |
|  | RESULTAT : REJETE + LOG + port err-disabled (optionnel)      | |
|  +---------------------------------------------------------------+ |
+---------------------------------------------------------------------+

Legende :
===============================================================
DAI verifie chaque paquet ARP sur les ports UNTRUSTED :
  1. MAC source dans le paquet ARP correspond a la binding table
  2. IP source dans le paquet ARP correspond a la binding table
  3. Le port d'entree correspond a la binding table
Si une des 3 verifications echoue : paquet rejete
===============================================================
```

---

## 3. Schema 802.1X Authentication

### Architecture 802.1X Detaillee

```
+-----------------------------------------------------------------------------+
|                        PROCESSUS 802.1X (EAP)                              |
|                                                                             |
|  SUPPLICANT           AUTHENTICATOR              AUTHENTICATION SERVER     |
|  (Client)             (Switch/AP)                (RADIUS - ISE/FreeRADIUS) |
|                                                                             |
|  +---------+          +-------------+            +--------------+          |
|  |   PC    |          |   Switch    |            |   RADIUS     |          |
|  | (802.1X |          |   L2        |            |   Server     |          |
|  | client) |          |             |            |              |          |
|  +----+----+          +------+------+            +------+-------+          |
|       |                      |                          |                  |
|       |  1. EAPOL-Start      |                          |                  |
|       |--------------------->|                          |                  |
|       |                      |                          |                  |
|       |  2. EAP-Request/     |                          |                  |
|       |     Identity         |                          |                  |
|       |<---------------------|                          |                  |
|       |                      |                          |                  |
|       |  3. EAP-Response/    |                          |                  |
|       |     Identity         |                          |                  |
|       |     (username)       |                          |                  |
|       |--------------------->|                          |                  |
|       |                      |                          |                  |
|       |                      |  4. RADIUS               |                  |
|       |                      |     Access-Request       |                  |
|       |                      |     (EAP encapsule)      |                  |
|       |                      |------------------------->|                  |
|       |                      |                          |                  |
|       |                      |  5. RADIUS               |                  |
|       |                      |     Access-Challenge      |                  |
|       |                      |     (methode EAP)        |                  |
|       |                      |<-------------------------|                  |
|       |                      |                          |                  |
|       |  6. EAP-Request      |                          |                  |
|       |     (challenge)      |                          |                  |
|       |<---------------------|                          |                  |
|       |                      |                          |                  |
|       |  7. EAP-Response     |                          |                  |
|       |     (credentials)    |                          |                  |
|       |--------------------->|                          |                  |
|       |                      |                          |                  |
|       |                      |  8. RADIUS               |                  |
|       |                      |     Access-Request       |                  |
|       |                      |     (credentials)        |                  |
|       |                      |------------------------->|                  |
|       |                      |                          |                  |
|       |                      |  9. RADIUS               |                  |
|       |                      |     Access-Accept        |                  |
|       |                      |     + attributs VLAN     |                  |
|       |                      |<-------------------------|                  |
|       |                      |                          |                  |
|       |  10. EAP-Success     |                          |                  |
|       |<---------------------|                          |                  |
|       |                      |                          |                  |
|       |  PORT AUTORISE       |                          |                  |
|       |  (VLAN assigne)      |                          |                  |
|       |======================|                          |                  |
|       |                      |                          |                  |
+-----------------------------------------------------------------------------+

Etats du Port 802.1X :
+------------------+-----------------------------------------+
| Etat             | Description                              |
+------------------+-----------------------------------------+
| UNAUTHORIZED     | Port bloque, seul trafic EAPOL autorise |
| AUTHENTICATING   | Echange EAP en cours                    |
| AUTHORIZED       | Authentification reussie, trafic ouvert |
| FORCE-AUTHORIZED | Port toujours ouvert (pas de 802.1X)   |
| FORCE-UNAUTH     | Port toujours bloque                    |
+------------------+-----------------------------------------+
| GUEST VLAN       | Client sans supplicant 802.1X           |
| AUTH-FAIL VLAN   | Echec d'authentification                |
| CRITICAL VLAN    | Serveur RADIUS injoignable              |
+------------------+-----------------------------------------+

Legende :
===============================================================
EAPOL     : EAP over LAN (trame L2 entre supplicant et switch)
EAP       : Extensible Authentication Protocol (framework)
RADIUS    : Protocole AAA entre switch et serveur (UDP 1812/1813)
Methodes  : EAP-TLS (certificats), PEAP (password), EAP-FAST
===============================================================
```

---

## 4. Schema AAA (Authentication, Authorization, Accounting)

### Architecture AAA Complete

```
+---------------------------------------------------------------------+
|                         MODELE AAA                                  |
|                                                                     |
|  +--------------------------------------------------------------+  |
|  |                   AUTHENTICATION                             |  |
|  |                  "Qui es-tu ?"                               |  |
|  |                                                              |  |
|  |  Methodes :                                                  |  |
|  |  +----------+  +----------+  +----------+  +----------+   |  |
|  |  |  Local   |  |  RADIUS  |  |  TACACS+ |  |  LDAP/AD |   |  |
|  |  |  (DB     |  |  (UDP    |  |  (TCP    |  |  (Annuaire|   |  |
|  |  |  locale) |  |  1812)   |  |   49)    |  |   389)   |   |  |
|  |  +----------+  +----------+  +----------+  +----------+   |  |
|  +--------------------------------------------------------------+  |
|                            |                                        |
|                            v                                        |
|  +--------------------------------------------------------------+  |
|  |                   AUTHORIZATION                              |  |
|  |                "Qu'as-tu le droit de faire ?"                |  |
|  |                                                              |  |
|  |  +----------------------------------------------------+     |  |
|  |  | Niveau 0  : Commandes de base (logout, enable)     |     |  |
|  |  | Niveau 1  : Mode user EXEC (show basique)          |     |  |
|  |  | Niveau 15 : Mode privileged EXEC (tout)            |     |  |
|  |  | Custom    : Commandes specifiques par role          |     |  |
|  |  +----------------------------------------------------+     |  |
|  |                                                              |  |
|  |  Attributs retournes par le serveur :                       |  |
|  |  - Privilege level (0, 1, 15)                               |  |
|  |  - VLAN assigne                                             |  |
|  |  - ACL a appliquer                                          |  |
|  |  - Timeout session                                          |  |
|  +--------------------------------------------------------------+  |
|                            |                                        |
|                            v                                        |
|  +--------------------------------------------------------------+  |
|  |                    ACCOUNTING                                |  |
|  |                "Qu'as-tu fait ?"                             |  |
|  |                                                              |  |
|  |  +----------------------------------------------------+     |  |
|  |  | Start   : Debut de session enregistre              |     |  |
|  |  | Stop    : Fin de session enregistree               |     |  |
|  |  | Interim : Mise a jour periodique                   |     |  |
|  |  +----------------------------------------------------+     |  |
|  |                                                              |  |
|  |  Donnees enregistrees :                                     |  |
|  |  - Identite utilisateur                                     |  |
|  |  - Horodatage connexion/deconnexion                         |  |
|  |  - Commandes executees                                      |  |
|  |  - Volume de donnees transfere                              |  |
|  |  - Source IP / port d'acces                                 |  |
|  +--------------------------------------------------------------+  |
+---------------------------------------------------------------------+


Flux AAA Detaille :

+----------+        +--------------+        +--------------+
|  Admin   |        |   Router /   |        |   TACACS+    |
|  (SSH)   |        |   Switch     |        |   Server     |
+----+-----+        +------+-------+        +------+-------+
     |                     |                       |
     | 1. SSH connexion    |                       |
     |-------------------->|                       |
     |                     |                       |
     | 2. Username ?       |                       |
     |<--------------------|                       |
     |                     |                       |
     | 3. admin            |                       |
     |-------------------->|                       |
     |                     | 4. AUTHEN START       |
     |                     |  (user=admin)         |
     |                     |---------------------->|
     |                     |                       |
     |                     | 5. AUTHEN GETPASS      |
     |                     |<----------------------|
     |                     |                       |
     | 6. Password ?       |                       |
     |<--------------------|                       |
     |                     |                       |
     | 7. ********         |                       |
     |-------------------->|                       |
     |                     | 8. AUTHEN CONT        |
     |                     |  (password)           |
     |                     |---------------------->|
     |                     |                       |
     |                     | 9. AUTHEN PASS        |
     |                     |  (priv-lvl=15)        |
     |                     |<----------------------|
     |                     |                       |
     | 10. Router#         |                       |
     |<--------------------|                       |
     |                     | 11. ACCT START        |
     |                     |  (session begin)      |
     |                     |---------------------->|
     |                     |                       |

RADIUS vs TACACS+ :
+--------------+----------------+----------------+
| Critere      | RADIUS         | TACACS+        |
+--------------+----------------+----------------+
| Transport    | UDP 1812/1813  | TCP 49         |
| Chiffrement  | Password seul  | Paquet entier  |
| AAA          | AuthN + AuthZ  | Separe         |
|              | combines       | (granulaire)   |
| Usage        | Network access | Device admin   |
| Standard     | RFC 2865       | Cisco (ouvert) |
+--------------+----------------+----------------+

Legende :
===============================================================
Authentication : Verification de l'identite (login/password, certificat)
Authorization  : Attribution des droits (privilege level, VLAN, ACL)
Accounting     : Journalisation des actions (audit, conformite)
TACACS+ prefere pour l'administration des equipements (granularite)
RADIUS prefere pour l'acces reseau (802.1X, VPN)
===============================================================
```

---

## 5. Topologie VPN Site-to-Site (IPsec)

### Architecture VPN IPsec entre 2 Sites

```
+-----------------------------------------------------------------------------+
|                        VPN IPSEC SITE-TO-SITE                              |
|                                                                             |
|   SITE A (Siege)                                        SITE B (Agence)    |
|   192.168.10.0/24                                       192.168.20.0/24    |
|                                                                             |
|   +---------+                                           +---------+        |
|   |  PC-A1  |                                           |  PC-B1  |        |
|   | .10.10  |                                           | .20.10  |        |
|   +----+----+                                           +----+----+        |
|        |                                                     |             |
|   +----+----+                                           +----+----+        |
|   |  PC-A2  |                                           |  PC-B2  |        |
|   | .10.20  |                                           | .20.20  |        |
|   +----+----+                                           +----+----+        |
|        |                                                     |             |
|   +----+------+                                         +----+------+      |
|   | SW-A      |                                         | SW-B      |      |
|   | Switch L2 |                                         | Switch L2 |      |
|   +-----+-----+                                         +-----+-----+      |
|         |                                                     |            |
|   +-----+-----+                                         +-----+-----+      |
|   |  R-SITE-A |                                         |  R-SITE-B |      |
|   |           |                                         |           |      |
|   | Gi0/0:    |                                         | Gi0/0:    |      |
|   | .10.1/24  |                                         | .20.1/24  |      |
|   |           |                                         |           |      |
|   | Gi0/1:    |         INTERNET / WAN                  | Gi0/1:    |      |
|   | 203.0.    |    +---------------------+              | 198.51.   |      |
|   | 113.1/30  +----+                     +--------------+ 100.1/30  |      |
|   |           |    |    Reseau Public     |              |           |      |
|   +-----------+    |    (non securise)    |              +-----------+      |
|                    +---------------------+                                  |
|                                                                             |
|          +===========================================+                      |
|          |        TUNNEL IPSEC CHIFFRE              |                      |
|          |  203.0.113.1 <------------> 198.51.100.1  |                      |
|          |                                           |                      |
|          |  Phase 1 (IKE/ISAKMP) :                  |                      |
|          |    - Algorithme : AES-256                 |                      |
|          |    - Hash : SHA-256                       |                      |
|          |    - Auth : Pre-shared key                |                      |
|          |    - DH Group : 14                        |                      |
|          |    - Lifetime : 86400s (24h)              |                      |
|          |                                           |                      |
|          |  Phase 2 (IPsec SA) :                    |                      |
|          |    - Transform : ESP-AES-256 + SHA-256   |                      |
|          |    - Mode : Tunnel                        |                      |
|          |    - PFS : Group 14                       |                      |
|          |    - Lifetime : 3600s (1h)                |                      |
|          +===========================================+                      |
|                                                                             |
|  Trafic interessant (declenche le VPN) :                                   |
|  Source      : 192.168.10.0/24                                             |
|  Destination : 192.168.20.0/24                                             |
|                                                                             |
+-----------------------------------------------------------------------------+

Phases IPsec :
+-------------------------------------------------------------+
| Phase 1 (IKE SA / ISAKMP)                                  |
|   1. Negociation des parametres (encryption, hash, DH)     |
|   2. Echange Diffie-Hellman (cle secrete partagee)         |
|   3. Authentification mutuelle (PSK ou certificats)        |
|   --> Resultat : canal securise pour Phase 2               |
+-------------------------------------------------------------+
| Phase 2 (IPsec SA / Quick Mode)                            |
|   1. Negociation transform set (ESP/AH, chiffrement)      |
|   2. Creation des SA IPsec (une par direction)             |
|   3. Optionnel : PFS (nouveau DH)                          |
|   --> Resultat : tunnel chiffre operationnel               |
+-------------------------------------------------------------+

Legende :
===============================================================
IKE     : Internet Key Exchange (negociation des cles)
ISAKMP  : Internet Security Association Key Management Protocol
SA      : Security Association (accord de securite)
ESP     : Encapsulating Security Payload (chiffrement + auth)
AH      : Authentication Header (integrite, pas de chiffrement)
PSK     : Pre-Shared Key (cle partagee)
DH      : Diffie-Hellman (echange de cles)
PFS     : Perfect Forward Secrecy (nouvelles cles par session)
===============================================================
```

---

## 6. Schema GRE Tunnel over IPsec

### Architecture GRE over IPsec

```
+-----------------------------------------------------------------------------+
|                        GRE OVER IPSEC                                      |
|                                                                             |
|   SITE A                                                 SITE B            |
|                                                                             |
|   +-----------+                                   +-----------+            |
|   |  R-A      |                                   |  R-B      |            |
|   |           |                                   |           |            |
|   | Gi0/0:   |                                   | Gi0/0:   |            |
|   | 10.1.1.1 |                                   | 10.2.2.1 |            |
|   | (LAN)    |                                   | (LAN)    |            |
|   |           |                                   |           |            |
|   | Gi0/1:   |         INTERNET                  | Gi0/1:   |            |
|   | 1.1.1.1  +-----------------------------------+ 2.2.2.1  |            |
|   | (WAN)    |                                   | (WAN)    |            |
|   |           |                                   |           |            |
|   | Tunnel0: |   +=========================+     | Tunnel0: |            |
|   | 172.16.  |   |  GRE Tunnel (logique)   |     | 172.16.  |            |
|   | 0.1/30   +---+  src: 1.1.1.1           +-----+ 0.2/30   |            |
|   |           |   |  dst: 2.2.2.1           |     |           |            |
|   +-----------+   +=========================+     +-----------+            |
|                                                                             |
|                                                                             |
|   ENCAPSULATION DES PAQUETS :                                              |
|                                                                             |
|   Paquet original (IP interne) :                                           |
|   +------------------------------------------+                             |
|   | IP Header         | Data                 |                             |
|   | Src: 10.1.1.10    | (payload)            |                             |
|   | Dst: 10.2.2.10    |                      |                             |
|   +------------------------------------------+                             |
|                         |                                                   |
|                         v Encapsulation GRE                                |
|   +----------+------------------------------------------+                  |
|   | GRE Hdr  | IP Header         | Data                 |                  |
|   | Proto 47 | Src: 10.1.1.10    | (payload)            |                  |
|   |          | Dst: 10.2.2.10    |                      |                  |
|   +----------+------------------------------------------+                  |
|                         |                                                   |
|                         v Encapsulation IPsec (ESP)                        |
|   +----------+----------+------------------------------------------+-----+ |
|   | IP Hdr   | ESP Hdr  | GRE Hdr  | IP Header  | Data            | ESP | |
|   | Src:     | SPI      | Proto 47 | Src:10.1.  | (payload)       |Trail| |
|   | 1.1.1.1  | Seq      |          | Dst:10.2.  |                 |+Auth| |
|   | Dst:     |          |          |            |                 |     | |
|   | 2.2.2.1  |          |          |            |                 |     | |
|   | Proto:50 |          |    <---- CHIFFRE PAR ESP -------->     |     | |
|   +----------+----------+------------------------------------------+-----+ |
|                                                                             |
|   Avantages GRE over IPsec vs IPsec seul :                                |
|   +--------------------------------+------------------------------+       |
|   | GRE over IPsec                | IPsec seul                    |       |
|   +--------------------------------+------------------------------+       |
|   | Supporte multicast (OSPF,     | Unicast uniquement            |       |
|   | EIGRP, RIP)                   |                               |       |
|   | Supporte protocoles non-IP    | IP uniquement                 |       |
|   | Interface tunnel routable     | Crypto map sur interface      |       |
|   | Routage dynamique possible    | Routes statiques requises     |       |
|   | Overhead plus eleve (~60-70B) | Overhead plus faible (~50B)   |       |
|   +--------------------------------+------------------------------+       |
|                                                                             |
+-----------------------------------------------------------------------------+

Legende :
===============================================================
GRE  : Generic Routing Encapsulation (protocole IP 47)
ESP  : Encapsulating Security Payload (protocole IP 50)
SPI  : Security Parameter Index (identifie la SA)
Le tunnel GRE fournit l'encapsulation multiprotocole
IPsec fournit la confidentialite et l'integrite
MTU  : 1500 - 24 (GRE) - ~50 (IPsec) = ~1426 octets effectifs
===============================================================
```

---

## 7. Topologie WAN MPLS (PE, P, CE Routers)

### Architecture MPLS Detaillee

```
+-----------------------------------------------------------------------------+
|                         RESEAU WAN MPLS                                    |
|                                                                             |
|  CLIENT SITE A              MPLS PROVIDER                CLIENT SITE B     |
|                                                                             |
|  +-----------+      +--------------------------------+   +-----------+    |
|  |   LAN A   |      |                                |   |   LAN B   |    |
|  |10.1.0.0/16|      |     MPLS BACKBONE              |   |10.2.0.0/16|    |
|  |           |      |                                |   |           |    |
|  |  +-----+  |      |  +------+        +------+     |   |  +-----+  |    |
|  |  | SW  |  |      |  | PE-1 |        | PE-2 |     |   |  | SW  |  |    |
|  |  +--+--+  |      |  |      |        |      |     |   |  +--+--+  |    |
|  |     |     |      |  +--+---+        +---+--+     |   |     |     |    |
|  +-----+-----+      |     |                |        |   +-----+-----+    |
|        |            |     |                |        |         |          |
|  +-----+-----+      |  +--+---+        +---+--+    |   +-----+-----+    |
|  |   CE-A    |      |  | P-1  |========| P-2  |    |   |   CE-B    |    |
|  |  (Client  +------+  |(Core)|        |(Core)|    +---+  (Client  |    |
|  |  Edge)    |      |  +--+---+        +---+--+    |   |  Edge)    |    |
|  |           |      |     |                |        |   |           |    |
|  | BGP/OSPF |      |     |    +------+    |        |   | BGP/OSPF |    |
|  | vers PE   |      |     +----+ P-3  +----+        |   | vers PE   |    |
|  +-----------+      |          |(Core)|             |   +-----------+    |
|                     |          +------+             |                    |
|                     |                                |                    |
|  CLIENT SITE C      |     +------+                  |   CLIENT SITE D   |
|  +-----------+      |     | PE-3 |                  |   +-----------+    |
|  |   LAN C   |      |     +--+---+                  |   |   LAN D   |    |
|  |10.3.0.0/16|      |        |                      |   |10.4.0.0/16|    |
|  |           |      |     +--+---+                  |   |           |    |
|  |  +-----+  |      |     | P-4  |    +------+     |   |  +-----+  |    |
|  |  | SW  |  |      |     |(Core)+----+ PE-4 |     |   |  | SW  |  |    |
|  |  +--+--+  |      |     +------+    +--+---+     |   |  +--+--+  |    |
|  |     |     |      |                    |         |   |     |     |    |
|  +-----+-----+      |                    |         |   +-----+-----+    |
|        |            |                    |         |         |          |
|  +-----+-----+      |                    |         |   +-----+-----+    |
|  |   CE-C    +------+                    +---------+---+   CE-D    |    |
|  +-----------+      |                    |         |   +-----------+    |
|                     +--------------------------------+                    |
|                                                                             |
+-----------------------------------------------------------------------------+

Roles des Routeurs MPLS :
+------+--------------------+-------------------------------------+
| Role | Nom Complet        | Fonction                             |
+------+--------------------+-------------------------------------+
| CE   | Customer Edge      | Routeur du client, connecte au      |
|      |                    | reseau du fournisseur via PE.        |
|      |                    | Ne connait pas MPLS.                 |
+------+--------------------+-------------------------------------+
| PE   | Provider Edge      | Routeur du fournisseur a la         |
|      |                    | frontiere. Ajoute/retire les        |
|      |                    | labels MPLS. Maintient les VRF      |
|      |                    | (tables de routage par client).     |
+------+--------------------+-------------------------------------+
| P    | Provider (Core)    | Routeur coeur du fournisseur.       |
|      |                    | Commute uniquement sur les labels   |
|      |                    | MPLS (pas de routage IP client).    |
|      |                    | Haute performance, haute dispo.     |
+------+--------------------+-------------------------------------+

Encapsulation MPLS (Label Switching) :
+----------------------------------------------------------------+
|                                                                |
|  CE-A --> PE-1 : Paquet IP classique                          |
|  +----------+-----------------+                               |
|  | IP Hdr   | Data            |                               |
|  | Src:10.1 |                 |                               |
|  | Dst:10.2 |                 |                               |
|  +----------+-----------------+                               |
|                                                                |
|  PE-1 --> P-1 : Ajout label(s) MPLS (Push)                   |
|  +----------+----------+----------+-----------------+         |
|  | L2 Hdr   |MPLS Label| IP Hdr   | Data            |         |
|  |          | 24 (VPN) | Src:10.1 |                 |         |
|  |          | 18 (LSP) | Dst:10.2 |                 |         |
|  +----------+----------+----------+-----------------+         |
|                                                                |
|  P-1 --> P-2 : Swap label (Commutation)                      |
|  +----------+----------+----------+-----------------+         |
|  | L2 Hdr   |MPLS Label| IP Hdr   | Data            |         |
|  |          | 24 (VPN) | Src:10.1 |                 |         |
|  |          | 30 (LSP) | Dst:10.2 |                 |         |
|  +----------+----------+----------+-----------------+         |
|                                                                |
|  PE-2 --> CE-B : Retrait label(s) MPLS (Pop)                 |
|  +----------+-----------------+                               |
|  | IP Hdr   | Data            |                               |
|  | Src:10.1 |                 |                               |
|  | Dst:10.2 |                 |                               |
|  +----------+-----------------+                               |
|                                                                |
+----------------------------------------------------------------+

Legende :
===============================================================
MPLS  : MultiProtocol Label Switching
VRF   : Virtual Routing and Forwarding (isolation par client)
LSP   : Label Switched Path (chemin a travers le coeur MPLS)
LDP   : Label Distribution Protocol (distribution des labels)
Push  : Ajout d'un label (PE d'entree)
Swap  : Remplacement du label (routeurs P core)
Pop   : Retrait du label (PE de sortie)
=== Liens haute capacite entre routeurs P (backbone)
--- Liens CE-PE (acces client)
===============================================================
```

---

## 8. Schema SDN Architecture (Application/Control/Data Planes)

### Architecture SDN Detaillee

```
+-----------------------------------------------------------------------------+
|                     ARCHITECTURE SDN (Software-Defined Networking)          |
|                                                                             |
|  +-----------------------------------------------------------------------+ |
|  |                       APPLICATION PLANE                               | |
|  |                    (Applications Reseau)                              | |
|  |                                                                       | |
|  |  +----------+  +----------+  +----------+  +----------+            | |
|  |  | Network  |  | Security |  |   QoS    |  | Traffic  |            | |
|  |  | Monitor  |  | Policy   |  | Manager  |  |Engineer  |            | |
|  |  |          |  | Manager  |  |          |  |          |            | |
|  |  +----+-----+  +----+-----+  +----+-----+  +----+-----+            | |
|  |       |             |             |             |                   | |
|  |       +-------------+------+------+-------------+                   | |
|  |                            |                                        | |
|  |                    NORTHBOUND API (NBI)                             | |
|  |                    (REST API, Python, Java)                         | |
|  |                            |                                        | |
|  +----------------------------+----------------------------------------+ |
|                               |                                          |
|  +----------------------------+----------------------------------------+ |
|  |                            |                                        | |
|  |                    CONTROL PLANE                                    | |
|  |                 (SDN Controller)                                    | |
|  |                                                                     | |
|  |  +-------------------------------------------------------------+   | |
|  |  |                  SDN CONTROLLER                              |   | |
|  |  |          (Cisco DNA Center / OpenDaylight)                  |   | |
|  |  |                                                             |   | |
|  |  |  +-------------+ +--------------+ +-----------------+     |   | |
|  |  |  | Topology    | | Forwarding   | | Policy Engine   |     |   | |
|  |  |  | Discovery   | | Manager      | |                 |     |   | |
|  |  |  +-------------+ +--------------+ +-----------------+     |   | |
|  |  |                                                             |   | |
|  |  |  +-------------+ +--------------+ +-----------------+     |   | |
|  |  |  | Statistics  | | Path         | | Security        |     |   | |
|  |  |  | Collector   | | Computation  | | Module          |     |   | |
|  |  |  +-------------+ +--------------+ +-----------------+     |   | |
|  |  |                                                             |   | |
|  |  +-------------------------------------------------------------+   | |
|  |                            |                                        | |
|  |                    SOUTHBOUND API (SBI)                             | |
|  |             (OpenFlow, NETCONF, RESTCONF, SNMP)                    | |
|  |                            |                                        | |
|  +----------------------------+----------------------------------------+ |
|                               |                                          |
|  +----------------------------+----------------------------------------+ |
|  |                            |                                        | |
|  |                      DATA PLANE                                     | |
|  |              (Infrastructure Reseau)                                | |
|  |                                                                     | |
|  |     +----------+      +----------+      +----------+              | |
|  |     | Switch-1 |======| Switch-2 |======| Switch-3 |              | |
|  |     | (Forward |      | (Forward |      | (Forward |              | |
|  |     |  only)   |      |  only)   |      |  only)   |              | |
|  |     +----+-----+      +----+-----+      +----+-----+              | |
|  |          |                 |                  |                    | |
|  |     +----+-----+     +----+-----+       +----+-----+              | |
|  |     | Router-1 |=====| Router-2 |=======| Router-3 |              | |
|  |     | (Forward |     | (Forward |       | (Forward |              | |
|  |     |  only)   |     |  only)   |       |  only)   |              | |
|  |     +----------+     +----------+       +----------+              | |
|  |                                                                     | |
|  +---------------------------------------------------------------------+ |
|                                                                          |
+-----------------------------------------------------------------------------+

Comparaison SDN vs Reseau Traditionnel :
+--------------------+---------------------+---------------------+
| Aspect             | Traditionnel        | SDN                 |
+--------------------+---------------------+---------------------+
| Control Plane      | Distribue (chaque   | Centralise          |
|                    | equipement)         | (controleur)        |
+--------------------+---------------------+---------------------+
| Data Plane         | Couple au control   | Decouple, forward   |
|                    | plane               | uniquement          |
+--------------------+---------------------+---------------------+
| Configuration      | CLI par equipement  | Centralisee, API    |
+--------------------+---------------------+---------------------+
| Programmabilite    | Limitee (scripts)   | Native (API REST)   |
+--------------------+---------------------+---------------------+
| Agilite            | Lente (manuel)      | Rapide (automation) |
+--------------------+---------------------+---------------------+
| Vue globale        | Non (chaque device) | Oui (controleur)    |
+--------------------+---------------------+---------------------+

Legende :
===============================================================
Northbound API (NBI) : Interface entre applications et controleur
  - REST API (HTTP/HTTPS), Python SDK, Java SDK
  - Les applications envoient des intentions/politiques

Southbound API (SBI) : Interface entre controleur et equipements
  - OpenFlow   : Manipulation directe des tables de forwarding
  - NETCONF    : Configuration XML via SSH (RFC 6241)
  - RESTCONF   : Configuration JSON/XML via HTTP (RFC 8040)
  - SNMP       : Monitoring et configuration basique

Control Plane centralise : Decisions de routage/switching
Data Plane distribue     : Forwarding des paquets uniquement
===============================================================
```

---

## 9. Schema REST API Interaction avec Network Controller

### Communication REST API Detaillee

```
+-----------------------------------------------------------------------------+
|                   REST API - INTERACTION AVEC CONTROLEUR RESEAU            |
|                                                                             |
|   CLIENT (Script Python / Postman / curl)                                  |
|                                                                             |
|   +---------------------------------------------------------------------+  |
|   |                                                                     |  |
|   |  import requests                                                    |  |
|   |                                                                     |  |
|   |  # Authentification                                                 |  |
|   |  url = "https://controller.local/api/v1"                           |  |
|   |  token = get_auth_token(username, password)                        |  |
|   |                                                                     |  |
|   |  # Requete GET (lire)                                              |  |
|   |  headers = {"X-Auth-Token": token,                                 |  |
|   |             "Content-Type": "application/json"}                     |  |
|   |                                                                     |  |
|   +----------------------------+----------------------------------------+  |
|                                |                                           |
|           +--------------------+--------------------+                     |
|           |                    |                    |                     |
|           v                    v                    v                     |
|                                                                             |
|   +--------------+  +--------------+  +--------------+                   |
|   |    GET        |  |    POST       |  |   DELETE      |                   |
|   |  (Lire)      |  |  (Creer)     |  |  (Supprimer) |                   |
|   +------+-------+  +------+-------+  +------+-------+                   |
|          |                 |                  |                            |
|          v                 v                  v                            |
|                                                                             |
|   +---------------------------------------------------------------------+  |
|   |                 METHODES HTTP REST                                  |  |
|   |                                                                     |  |
|   |  +------+--------------------+--------------+------------------+   |  |
|   |  |Method| Action             | URI Exemple  | Code Reponse     |   |  |
|   |  +------+--------------------+--------------+------------------+   |  |
|   |  | GET  | Lire une ressource | /devices     | 200 OK           |   |  |
|   |  | POST | Creer une ressource| /vlans       | 201 Created      |   |  |
|   |  | PUT  | Remplacer entier   | /vlans/10    | 200 OK           |   |  |
|   |  |PATCH | Modifier partiel   | /vlans/10    | 200 OK           |   |  |
|   |  |DELETE| Supprimer          | /vlans/10    | 204 No Content   |   |  |
|   |  +------+--------------------+--------------+------------------+   |  |
|   |                                                                     |  |
|   +---------------------------------------------------------------------+  |
|                                |                                           |
|                                v                                           |
|   +---------------------------------------------------------------------+  |
|   |                    SDN CONTROLLER                                   |  |
|   |               (Cisco DNA Center / Meraki)                          |  |
|   |                                                                     |  |
|   |  HTTPS (port 443)                                                  |  |
|   |  Authentification : Token / Basic Auth / OAuth2                    |  |
|   |  Format donnees   : JSON (principalement)                          |  |
|   |                                                                     |  |
|   +---------------------------------------------------------------------+  |
|                                |                                           |
|                                v                                           |
|   +---------------------------------------------------------------------+  |
|   |                    EQUIPEMENTS RESEAU                               |  |
|   |                                                                     |  |
|   |  +----------+      +----------+      +----------+                 |  |
|   |  | Switch-1 |      | Router-1 |      | AP WiFi  |                 |  |
|   |  +----------+      +----------+      +----------+                 |  |
|   +---------------------------------------------------------------------+  |
|                                                                             |
|                                                                             |
|   EXEMPLE COMPLET : Recuperer la liste des equipements                     |
|                                                                             |
|   Requete :                                                                |
|   +-----------------------------------------------------------------+     |
|   | GET https://controller.local/dna/intent/api/v1/network-device  |     |
|   | Headers:                                                        |     |
|   |   X-Auth-Token: eyJhbGciOiJSUzI1NiIs...                       |     |
|   |   Content-Type: application/json                                |     |
|   |   Accept: application/json                                      |     |
|   +-----------------------------------------------------------------+     |
|                                |                                           |
|                                v                                           |
|   Reponse (200 OK) :                                                      |
|   +-----------------------------------------------------------------+     |
|   | {                                                               |     |
|   |   "response": [                                                 |     |
|   |     {                                                           |     |
|   |       "hostname": "SW-CORE-1",                                  |     |
|   |       "managementIpAddress": "10.1.1.1",                       |     |
|   |       "platformId": "C9300-48T",                               |     |
|   |       "softwareVersion": "17.6.1",                             |     |
|   |       "role": "DISTRIBUTION",                                   |     |
|   |       "reachabilityStatus": "Reachable",                       |     |
|   |       "upTime": "45 days, 12:30:00"                            |     |
|   |     },                                                          |     |
|   |     {                                                           |     |
|   |       "hostname": "SW-ACCESS-1",                                |     |
|   |       "managementIpAddress": "10.1.1.10",                      |     |
|   |       "platformId": "C9200-24P",                               |     |
|   |       "softwareVersion": "17.6.1",                             |     |
|   |       "role": "ACCESS",                                         |     |
|   |       "reachabilityStatus": "Reachable",                       |     |
|   |       "upTime": "30 days, 8:15:00"                             |     |
|   |     }                                                           |     |
|   |   ]                                                             |     |
|   | }                                                               |     |
|   +-----------------------------------------------------------------+     |
|                                                                             |
|   Codes de Reponse HTTP :                                                  |
|   +------+--------------------------------------------+                   |
|   | Code | Signification                               |                   |
|   +------+--------------------------------------------+                   |
|   | 200  | OK - Requete reussie                        |                   |
|   | 201  | Created - Ressource creee                   |                   |
|   | 204  | No Content - Suppression reussie            |                   |
|   | 400  | Bad Request - Requete malformee             |                   |
|   | 401  | Unauthorized - Authentification requise     |                   |
|   | 403  | Forbidden - Droits insuffisants             |                   |
|   | 404  | Not Found - Ressource inexistante           |                   |
|   | 500  | Internal Server Error - Erreur serveur      |                   |
|   +------+--------------------------------------------+                   |
|                                                                             |
+-----------------------------------------------------------------------------+

Legende :
===============================================================
REST    : Representational State Transfer
API     : Application Programming Interface
CRUD    : Create (POST), Read (GET), Update (PUT/PATCH),
          Delete (DELETE)
JSON    : JavaScript Object Notation (format de donnees)
Token   : Jeton d'authentification temporaire
URI     : Uniform Resource Identifier (chemin vers la ressource)
===============================================================
```

---

## Questions de Revision

### Securite Reseau
1. Quels sont les roles des zones DMZ, Trust et Untrust dans une architecture firewall ?
2. Comment DHCP Snooping protege-t-il contre les serveurs DHCP illegitimes ?
3. Quelle est la relation entre DHCP Snooping et DAI ?
4. Decrivez les 3 composants du modele 802.1X.

### AAA et VPN
5. Quelles sont les differences entre RADIUS et TACACS+ ?
6. Decrivez les deux phases de negociation IPsec.
7. Quel avantage GRE apporte-t-il par rapport a IPsec seul ?

### WAN et SDN
8. Quels sont les roles des routeurs CE, PE et P dans MPLS ?
9. Quelle est la difference entre Northbound API et Southbound API en SDN ?
10. Nommez les 4 methodes HTTP principales utilisees avec les API REST.

---

*Schemas crees pour la revision CCNA*
*Auteur : Roadmvn*