# Schemas Services Reseau - Representations ASCII Detaillees

## Vue d'Ensemble

Cette page regroupe tous les schemas ASCII detailles des services reseau couverts dans le module 4. Chaque schema est concu pour etre pedagogique et utilisable comme reference rapide.

---

## 1. NAT Inside/Outside - Flux de Paquets Complet

### Scenario : PC Interne Accede a un Serveur Web sur Internet

```
RESEAU INTERNE (INSIDE)              NAT ROUTER               INTERNET (OUTSIDE)

 PC-A                                                          Serveur Web
 IP: 10.1.1.10                                                 IP: 93.184.216.34
 MAC: AA:AA                                                    MAC: CC:CC

      +--------------+          +--------------+          +--------------+
      |              |          |              |          |              |
      |   10.1.1.10  |          | Gi0/0  Gi0/1|          | 93.184.216.34|
      |              |--------->|(inside)(out) |--------->|              |
      |              |          |              |          |              |
      +--------------+          +--------------+          +--------------+

=== ETAPE 1 : Paquet Original (PC-A vers Routeur) ===

+---------------------------------------------------------+
| Trame Ethernet                                          |
| Src MAC: AA:AA    Dst MAC: [MAC Gi0/0 routeur]         |
+---------------------------------------------------------+
| Paquet IP                                               |
| Src IP: 10.1.1.10         Dst IP: 93.184.216.34        |
+---------------------------------------------------------+
| Segment TCP                                             |
| Src Port: 49152            Dst Port: 80                 |
+---------------------------------------------------------+

=== ETAPE 2 : Routeur Effectue la Traduction NAT ===

Table NAT :
+-------------------------+-------------------------+
| Inside Local            | Inside Global           |
| 10.1.1.10:49152         | 203.0.113.1:49152       |
+-------------------------+-------------------------+

=== ETAPE 3 : Paquet Traduit (Routeur vers Internet) ===

+---------------------------------------------------------+
| Trame Ethernet                                          |
| Src MAC: [MAC Gi0/1]  Dst MAC: [MAC next-hop ISP]     |
+---------------------------------------------------------+
| Paquet IP                                               |
| Src IP: 203.0.113.1       Dst IP: 93.184.216.34        |  <- IP source TRADUITE
+---------------------------------------------------------+
| Segment TCP                                             |
| Src Port: 49152            Dst Port: 80                 |
+---------------------------------------------------------+

=== ETAPE 4 : Reponse du Serveur Web ===

+---------------------------------------------------------+
| Src IP: 93.184.216.34     Dst IP: 203.0.113.1          |
| Src Port: 80               Dst Port: 49152              |
+---------------------------------------------------------+

=== ETAPE 5 : Routeur Effectue la Traduction Inverse ===

+---------------------------------------------------------+
| Src IP: 93.184.216.34     Dst IP: 10.1.1.10            |  <- IP dest RETRADUITE
| Src Port: 80               Dst Port: 49152              |
+---------------------------------------------------------+
```

---

## 2. DHCP DORA - Processus en 4 Etapes

```
    CLIENT DHCP                                        SERVEUR DHCP
    (0.0.0.0)                                          (10.1.1.1)
    MAC: AA:BB:CC:11:22:33
         |                                                  |
         |                                                  |
    =====+==================================================+=====
    ETAPE 1 : DISCOVER                                      |
         |                                                  |
         |  +----------------------------------------+      |
         |  | DHCP DISCOVER                          |      |
         |  | Src IP  : 0.0.0.0                      |      |
         |  | Dst IP  : 255.255.255.255 (BROADCAST)  |      |
         |  | Src MAC : AA:BB:CC:11:22:33            |      |
         |  | Dst MAC : FF:FF:FF:FF:FF:FF            |      |
         |  | UDP Src : 68 (client)                  |      |
         |  | UDP Dst : 67 (serveur)                 |      |
         |  | Transaction ID (XID) : 0x3A4B5C6D      |      |
         |  +----------------------------------------+      |
         |------------------- BROADCAST ------------------->|
         |                                                  |
    =====+==================================================+=====
    ETAPE 2 : OFFER                                         |
         |                                                  |
         |      +----------------------------------------+  |
         |      | DHCP OFFER                             |  |
         |      | Src IP  : 10.1.1.1                     |  |
         |      | Dst IP  : 255.255.255.255 ou unicast   |  |
         |      | Your IP : 10.1.1.50 (IP proposee)      |  |
         |      | Subnet  : 255.255.255.0                |  |
         |      | Router  : 10.1.1.1                     |  |
         |      | DNS     : 8.8.8.8                      |  |
         |      | Lease   : 86400 sec (24h)              |  |
         |      | Server ID : 10.1.1.1                   |  |
         |      | XID     : 0x3A4B5C6D                   |  |
         |      +----------------------------------------+  |
         |<---------------- UNICAST/BROADCAST --------------|
         |                                                  |
    =====+==================================================+=====
    ETAPE 3 : REQUEST                                       |
         |                                                  |
         |  +----------------------------------------+      |
         |  | DHCP REQUEST                           |      |
         |  | Src IP  : 0.0.0.0                      |      |
         |  | Dst IP  : 255.255.255.255 (BROADCAST)  |      |
         |  | Requested IP : 10.1.1.50               |      |
         |  | Server ID    : 10.1.1.1                |      |
         |  | XID     : 0x3A4B5C6D                   |      |
         |  +----------------------------------------+      |
         |------------------- BROADCAST ------------------->|
         |  (Broadcast pour informer les AUTRES serveurs    |
         |   DHCP que leur offre n'a pas ete retenue)       |
         |                                                  |
    =====+==================================================+=====
    ETAPE 4 : ACKNOWLEDGE                                   |
         |                                                  |
         |      +----------------------------------------+  |
         |      | DHCP ACKNOWLEDGE                       |  |
         |      | Src IP  : 10.1.1.1                     |  |
         |      | Dst IP  : 255.255.255.255 ou unicast   |  |
         |      | Your IP : 10.1.1.50 (confirme)         |  |
         |      | Subnet  : 255.255.255.0                |  |
         |      | Router  : 10.1.1.1                     |  |
         |      | DNS     : 8.8.8.8                      |  |
         |      | Lease   : 86400 sec (confirme)         |  |
         |      +----------------------------------------+  |
         |<---------------- UNICAST/BROADCAST --------------|
         |                                                  |
    (10.1.1.50)                                             |
    Client configure !                                      |
```

---

## 3. ACL Placement sur Topologie Multi-Routeurs

```
                         TOPOLOGIE RESEAU

  VLAN 10 - Users         VLAN 20 - Admins         VLAN 30 - Serveurs
  10.1.10.0/24            10.1.20.0/24             10.1.30.0/24
       |                       |                        |
  +---------+            +---------+             +---------+
  | PC-User |            | PC-Admin|             | Serveur  |
  |10.1.10.50|           |10.1.20.50|            | Web      |
  +---------+            +---------+             |10.1.30.100|
       |                       |                 +---------+
       |                       |                      |
  +----+------------------------+--+             +----+----+
  |            R1                   |-------------|   R2    |
  |  Gi0/0         Gi0/1           |  Gi0/2      |         |
  | (10.1.10.1)   (10.1.20.1)     |  Link P2P   | Gi0/0   |
  +---------------------------------+ 10.1.100.0 |(10.1.30.1)|
                                      /30        +---------+


POLITIQUE DE SECURITE :
1. Les Users peuvent acceder au Web (HTTP/HTTPS) uniquement
2. Les Admins ont un acces complet
3. Personne ne peut faire Telnet vers les serveurs

PLACEMENT DES ACLs :

ACL ETENDUE "WEB-ONLY" sur R1, Gi0/0 IN (pres de la source Users) :
+--------------------------------------------------------------------+
| 10 permit tcp 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255 eq 80     |
| 20 permit tcp 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255 eq 443    |
| 30 permit udp 10.1.10.0 0.0.0.255 any eq 53                     |
| 40 permit icmp 10.1.10.0 0.0.0.255 any                          |
| 50 deny ip 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255             |
| 60 permit ip any any                                              |
| (deny implicite)                                                  |
+--------------------------------------------------------------------+

ACL ETENDUE "NO-TELNET" sur R2, Gi0/0 OUT (pres de la destination) :
+--------------------------------------------------------------------+
| 10 deny tcp any 10.1.30.0 0.0.0.255 eq 23                       |
| 20 permit ip any any                                              |
| (deny implicite)                                                  |
+--------------------------------------------------------------------+

Aucune ACL sur Gi0/1 (Admins) -> acces complet autorise
```

---

## 4. Architecture SNMP (Manager, Agent, MIB)

```
+-------------------------------------------------------------------------+
|                          RESEAU D'ENTREPRISE                            |
|                                                                         |
|   +------------------------------+                                     |
|   |  NMS (Network Management     |                                     |
|   |  Station)                    |                                     |
|   |  IP: 10.1.1.200             |                                     |
|   |                              |                                     |
|   |  Fonctions :                 |                                     |
|   |  - Polling (GET/GET-NEXT)    |                                     |
|   |  - Configuration (SET)       |                                     |
|   |  - Reception alertes (TRAP)  |                                     |
|   |  - Graphiques, dashboards    |                                     |
|   +----------+-------------------+                                     |
|              |                                                          |
|              |  UDP 161 (polling)                                       |
|              |  UDP 162 (traps)                                         |
|              |                                                          |
|    +---------+----------+------------------+                           |
|    |         |          |                  |                            |
|    v         v          v                  v                            |
| +------+ +------+ +------+ +------+                                  |
| |Router| |Switch| |Firewall| |Server|                                  |
| |      | |      | |      | |      |                                    |
| |Agent | |Agent | |Agent | |Agent |   Chaque agent contient           |
| |SNMP  | |SNMP  | |SNMP  | |SNMP  |   une MIB locale                 |
| |      | |      | |      | |      |                                    |
| | MIB  | | MIB  | | MIB  | | MIB  |                                   |
| +------+ +------+ +------+ +------+                                   |
|                                                                         |
| Flux de communication :                                                |
|                                                                         |
| NMS --GET--> Agent    "Quelle est ta charge CPU ?"                     |
| NMS <-RESP-- Agent    "CPU = 45%"                                      |
|                                                                         |
| NMS --SET--> Agent    "Change le hostname en R1-PROD"                  |
| NMS <-RESP-- Agent    "OK, hostname change"                            |
|                                                                         |
| NMS <-TRAP-- Agent    "ALERTE : Interface Gi0/1 DOWN !"               |
|                                                                         |
+-------------------------------------------------------------------------+

ARBRE MIB (extrait) :
+----------------------------------------------------------+
| .1 (iso)                                                 |
|  +-- .3 (org)                                            |
|       +-- .6 (dod)                                       |
|            +-- .1 (internet)                             |
|                 +-- .2 (mgmt)                            |
|                 |    +-- .1 (mib-2)                      |
|                 |         +-- .1 (system)                |
|                 |         |    +-- .1 sysDescr           |
|                 |         |    +-- .3 sysUpTime          |
|                 |         |    +-- .5 sysName            |
|                 |         |    +-- .6 sysLocation        |
|                 |         +-- .2 (interfaces)            |
|                 |         |    +-- .2 (ifTable)          |
|                 |         |         +-- ifDescr          |
|                 |         |         +-- ifSpeed          |
|                 |         |         +-- ifInOctets       |
|                 |         |         +-- ifOutOctets      |
|                 |         +-- .4 (ip)                    |
|                 |              +-- ipForwarding          |
|                 +-- .4 (private)                         |
|                      +-- .1 (enterprises)               |
|                           +-- .9 (cisco)                |
+----------------------------------------------------------+
```

---

## 5. Hierarchie NTP (Stratum 0 a 3)

```
                    STRATUM 0
              Sources de reference
         (Horloge atomique, GPS, CDMA)
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
    +----------++----------++----------+
    | Horloge  ||   GPS    ||  CDMA    |      Precision : microsecondes
    | Atomique || Receiver || Receiver |      Non accessible directement
    +----------++----------++----------+      sur le reseau
          |           |           |
          |    Connexion directe  |
          |    (serie, USB, PPS)  |
          v           v           v
                    STRATUM 1
          +----------------------+
          |  Serveurs NTP        |
          |  Primaires           |            Precision : millisecondes
          |                      |            Exemples :
          |  time.google.com     |            - pool.ntp.org
          |  time.cloudflare.com |            - time.nist.gov
          +----------------------+
            |         |         |
            |   Internet / WAN  |
            v         v         v
                    STRATUM 2
     +------------------------------+
     |  Serveurs NTP Entreprise     |
     |  (Data Center interne)       |         Precision : ~10 ms
     |                              |         Exemples :
     |  ntp-srv1.entreprise.local   |         - Serveurs NTP internes
     |  ntp-srv2.entreprise.local   |         - Routeurs principaux
     +------------------------------+
            |              |
            |   LAN / WAN  |
            v              v
                    STRATUM 3
  +--------------------------------------+
  |  Equipements Reseau                  |
  |                                      |    Precision : ~100 ms
  |  +--------+ +--------+ +--------+  |    Exemples :
  |  |Routeur | |Switch  | |Firewall|  |    - Routeurs de site
  |  | Site A | | Core   | | Edge   |  |    - Switches core
  |  +--------+ +--------+ +--------+  |    - Firewalls
  +--------------------------------------+
            |              |
            v              v
                    STRATUM 4
  +--------------------------------------+
  |  Clients Finaux                      |
  |                                      |    Exemples :
  |  PC, Telephones IP, Imprimantes     |    - Postes de travail
  |  Serveurs d'application             |    - Telephones VoIP
  +--------------------------------------+
```

---

## 6. Flux Syslog (Equipement vers Serveur)

```
+----------------------------------------------------------------------+
|                    FLUX SYSLOG COMPLET                                |
|                                                                      |
|  EVENEMENT SUR LE ROUTEUR :                                         |
|  Interface GigabitEthernet 0/1 passe DOWN                           |
|                                                                      |
|  +----------------------------------------------+                   |
|  |  ROUTEUR R1                                   |                   |
|  |                                               |                   |
|  |  1. Detection de l'evenement                  |                   |
|  |     -> Interface Gi0/1 link down             |                   |
|  |                                               |                   |
|  |  2. Generation du message Syslog              |                   |
|  |     Severity: 3 (Error)                       |                   |
|  |     Facility: LINK                            |                   |
|  |     Message:                                  |                   |
|  |     %LINK-3-UPDOWN: Interface Gi0/1,         |                   |
|  |     changed state to down                     |                   |
|  |                                               |                   |
|  |  3. Envoi vers destinations configurees :     |                   |
|  |     a) Console (si level >= warnings)         |                   |
|  |     b) Buffer local (logging buffered)        |                   |
|  |     c) Serveur Syslog distant (logging host)  |                   |
|  |     d) Terminal VTY (logging monitor)         |                   |
|  +------------------+---------------------------+                   |
|                     |                                                |
|                     | UDP port 514                                   |
|                     | (pas de retransmission,                        |
|                     |  pas d'accusé de reception)                    |
|                     v                                                |
|  +----------------------------------------------+                   |
|  |  SERVEUR SYSLOG (10.1.1.200)                 |                   |
|  |                                               |                   |
|  |  4. Reception et classification               |                   |
|  |     -> Trie par severity, facility, source   |                   |
|  |                                               |                   |
|  |  5. Stockage                                  |                   |
|  |     -> Fichiers logs (/var/log/network/)      |                   |
|  |     -> Base de donnees (pour recherche)       |                   |
|  |                                               |                   |
|  |  6. Analyse et alertes                        |                   |
|  |     -> Severity 0-3 : alerte email/SMS        |                   |
|  |     -> Severity 4-5 : dashboard warning       |                   |
|  |     -> Severity 6-7 : archivage simple        |                   |
|  +----------------------------------------------+                   |
|                                                                      |
|  DESTINATIONS SYSLOG :                                              |
|  +------------+------------------------------------------+          |
|  | Destination| Commande Cisco                           |          |
|  +------------+------------------------------------------+          |
|  | Console    | logging console [level]                  |          |
|  | VTY/Monitor| logging monitor [level]                  |          |
|  | Buffer     | logging buffered [size] [level]          |          |
|  | Serveur    | logging host [IP] + logging trap [level] |          |
|  +------------+------------------------------------------+          |
+----------------------------------------------------------------------+
```

---

## 7. Comparaison ACL Standard vs Etendue

```
+----------------------------------------------------------------------+
|                    ACL STANDARD vs ETENDUE                           |
+----------------------------------------------------------------------+
|                                                                      |
|  ACL STANDARD (1-99, 1300-1999)                                     |
|  +--------------------------------------------------+               |
|  |  Critere : IP SOURCE uniquement                  |               |
|  |                                                   |               |
|  |  access-list 10 permit 10.1.1.0 0.0.0.255        |               |
|  |                        +-----------------+        |               |
|  |                         Source seulement          |               |
|  |                                                   |               |
|  |  Placement : PRES DE LA DESTINATION              |               |
|  |                                                   |               |
|  |  PC-A --- R1 --- R2 --- R3 --- Serveur          |               |
|  |                               ^                   |               |
|  |                               |                   |               |
|  |                          ACL ICI                  |               |
|  |                    (pres destination)              |               |
|  +--------------------------------------------------+               |
|                                                                      |
|  ACL ETENDUE (100-199, 2000-2699)                                   |
|  +--------------------------------------------------+               |
|  |  Criteres : Protocole + Source + Destination     |               |
|  |            + Ports                               |               |
|  |                                                   |               |
|  |  access-list 100 permit tcp                      |               |
|  |    10.1.1.0 0.0.0.255                            |               |
|  |    +---- Source ----+                             |               |
|  |    host 10.1.4.100 eq 80                         |               |
|  |    +-- Destination -+ +Port+                     |               |
|  |                                                   |               |
|  |  Placement : PRES DE LA SOURCE                   |               |
|  |                                                   |               |
|  |  PC-A --- R1 --- R2 --- R3 --- Serveur          |               |
|  |           ^                                       |               |
|  |           |                                       |               |
|  |      ACL ICI                                     |               |
|  |  (pres source)                                   |               |
|  +--------------------------------------------------+               |
|                                                                      |
|  RESUME :                                                           |
|  +----------+-----------+--------------+----------------+          |
|  | Type     | Numeros   | Filtrage     | Placement      |          |
|  +----------+-----------+--------------+----------------+          |
|  | Standard | 1-99      | Source seule | Pres dest.     |          |
|  |          | 1300-1999 |              |                |          |
|  +----------+-----------+--------------+----------------+          |
|  | Etendue  | 100-199   | Src + Dst +  | Pres source   |          |
|  |          | 2000-2699 | Proto + Port |                |          |
|  +----------+-----------+--------------+----------------+          |
+----------------------------------------------------------------------+
```

---

*Schemas crees pour la revision CCNA*
*Auteur : Roadmvn*
