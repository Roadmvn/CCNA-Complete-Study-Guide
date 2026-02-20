#!/bin/bash

# =============================================================================
# Script : Configuration VPN - GRE, IPsec, GRE over IPsec
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations VPN site-to-site pour routeurs Cisco
#            Tunnel GRE, IPsec avec crypto map, GRE over IPsec
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-vpn-basic.log"

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}    Configuration VPN (GRE / IPsec / GRE over IPsec) - CCNA${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo ""
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $message"
}

# =============================================================================
# FONCTION 1 : Tunnel GRE simple
# =============================================================================

generate_gre_tunnel_simple() {
    cat << EOF
!
! ============================================================
! Configuration Tunnel GRE Simple - Deux Sites
! ============================================================
!
! Topologie :
!
!   LAN-A (10.1.1.0/24)                   LAN-B (10.2.2.0/24)
!       |                                       |
!   [R1-SIEGE]--------- Internet ----------[R2-BRANCH]
!   Gi0/0: 10.1.1.1                       Gi0/0: 10.2.2.1
!   Gi0/1: 203.0.113.1                    Gi0/1: 198.51.100.1
!   Tunnel0: 172.16.1.1/30                Tunnel0: 172.16.1.2/30
!
!   Encapsulation GRE :
!
!   +--------------------------------------------------+
!   | IP Externe      | En-tete GRE | IP Interne | Data|
!   | Src: 203.0.113.1| Protocol 47 | Src: 10.1.1.x   |
!   | Dst: 198.51.100.1|            | Dst: 10.2.2.x   |
!   +--------------------------------------------------+
!   |<--- 20 octets-->|<- 4 oct. ->|
!   Overhead GRE = 24 octets -> MTU = 1500 - 24 = 1476
!
! GRE (Generic Routing Encapsulation) :
! - Protocole IP numero 47
! - Peut encapsuler n'importe quel protocole (IP, IPv6, IPX, multicast)
! - PAS de chiffrement (trafic en clair)
! - Utilite : transporter du multicast ou des protocoles de routage
!   a travers Internet (ce qu'IPsec seul ne peut pas faire)
!
! ==========================
! ROUTEUR R1 (Siege)
! ==========================
!
configure terminal
!
hostname R1-SIEGE
!
! Interface LAN
interface gigabitEthernet 0/0
 description LAN Site A - Siege
 ip address 10.1.1.1 255.255.255.0
 no shutdown
!
! Interface WAN (vers Internet / ISP)
interface gigabitEthernet 0/1
 description WAN vers Internet
 ip address 203.0.113.1 255.255.255.0
 no shutdown
!
! Configuration du tunnel GRE
interface tunnel 0
 description GRE Tunnel vers Site B (R2-BRANCH)
 ip address 172.16.1.1 255.255.255.252
 tunnel source gigabitEthernet 0/1
 tunnel destination 198.51.100.1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 keepalive 10 3
 no shutdown
!
! keepalive 10 3 = envoie un keepalive toutes les 10 sec
!                  si 3 echecs consecutifs -> tunnel down
! ip mtu 1476 = MTU ajuste pour l'overhead GRE (24 octets)
! ip tcp adjust-mss 1436 = MSS TCP = MTU - 40 (IP+TCP headers)
!
! Route vers le LAN distant via le tunnel
ip route 10.2.2.0 255.255.255.0 172.16.1.2
!
! Route par defaut vers Internet
ip route 0.0.0.0 0.0.0.0 203.0.113.254
!
end
write memory
!
! ==========================
! ROUTEUR R2 (Succursale)
! ==========================
!
configure terminal
!
hostname R2-BRANCH
!
! Interface LAN
interface gigabitEthernet 0/0
 description LAN Site B - Succursale
 ip address 10.2.2.1 255.255.255.0
 no shutdown
!
! Interface WAN
interface gigabitEthernet 0/1
 description WAN vers Internet
 ip address 198.51.100.1 255.255.255.0
 no shutdown
!
! Configuration du tunnel GRE
interface tunnel 0
 description GRE Tunnel vers Site A (R1-SIEGE)
 ip address 172.16.1.2 255.255.255.252
 tunnel source gigabitEthernet 0/1
 tunnel destination 203.0.113.1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 keepalive 10 3
 no shutdown
!
! Route vers le LAN distant via le tunnel
ip route 10.1.1.0 255.255.255.0 172.16.1.1
!
! Route par defaut vers Internet
ip route 0.0.0.0 0.0.0.0 198.51.100.254
!
end
write memory
!
! ==========================
! VERIFICATION
! ==========================
!
! Sur R1 :
show interface tunnel 0
! -> Line protocol should be up/up
!
show ip route | include 10.2.2.0
! -> 10.2.2.0/24 via 172.16.1.2
!
ping 172.16.1.2 source 172.16.1.1
! -> Test connectivite tunnel
!
ping 10.2.2.1 source 10.1.1.1
! -> Test connectivite LAN-to-LAN
!
show interfaces tunnel 0 | include tunnel
! -> Tunnel source/destination
!
show interfaces tunnel 0 | include MTU
! -> Verifier MTU = 1476
!
EOF
}

# =============================================================================
# FONCTION 2 : Tunnel GRE personnalisable
# =============================================================================

generate_gre_tunnel_custom() {
    local hostname_r1="$1"
    local hostname_r2="$2"
    local wan_r1="$3"
    local wan_r2="$4"
    local lan_r1_net="$5"
    local lan_r1_mask="$6"
    local lan_r2_net="$7"
    local lan_r2_mask="$8"
    local tunnel_r1="$9"
    local tunnel_r2="${10}"
    local tunnel_mask="${11}"

    cat << EOF
!
! ============================================================
! Configuration Tunnel GRE Personnalise
! $hostname_r1 <-----> $hostname_r2
! ============================================================
!
! ==========================
! ROUTEUR $hostname_r1
! ==========================
!
configure terminal
hostname $hostname_r1
!
interface tunnel 0
 description GRE Tunnel vers $hostname_r2
 ip address $tunnel_r1 $tunnel_mask
 tunnel source $wan_r1
 tunnel destination $wan_r2
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 keepalive 10 3
 no shutdown
!
! Route vers le LAN distant
ip route $lan_r2_net $lan_r2_mask $tunnel_r2
!
end
write memory
!
! ==========================
! ROUTEUR $hostname_r2
! ==========================
!
configure terminal
hostname $hostname_r2
!
interface tunnel 0
 description GRE Tunnel vers $hostname_r1
 ip address $tunnel_r2 $tunnel_mask
 tunnel source $wan_r2
 tunnel destination $wan_r1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 keepalive 10 3
 no shutdown
!
! Route vers le LAN distant
ip route $lan_r1_net $lan_r1_mask $tunnel_r1
!
end
write memory
!
! ==========================
! VERIFICATION
! ==========================
show interface tunnel 0
show ip route
ping $tunnel_r2 source $tunnel_r1
!
EOF
}

# =============================================================================
# FONCTION 3 : VPN IPsec Site-to-Site (crypto map)
# =============================================================================

generate_ipsec_site_to_site() {
    cat << EOF
!
! ============================================================
! Configuration VPN IPsec Site-to-Site avec Crypto Map
! ============================================================
!
! Topologie :
!
!   LAN-A (10.1.1.0/24)                   LAN-B (10.2.2.0/24)
!       |                                       |
!   [R1-SIEGE]===== Tunnel IPsec =====[R2-BRANCH]
!   Gi0/1: 203.0.113.1                Gi0/1: 198.51.100.1
!
! IPsec fonctionne en 2 phases :
!
!   Phase 1 (IKE / ISAKMP) :
!   - Negociation de la politique de securite
!   - Authentification des peers (Pre-Shared Key ou certificats)
!   - Echange de cles Diffie-Hellman
!   - Resultat : ISAKMP SA (Security Association) = tunnel de controle
!
!   Phase 2 (IPsec SA) :
!   - Negociation du transform set (algorithmes de chiffrement)
!   - Creation des SA IPsec (tunnel de donnees)
!   - Application aux trafics via crypto map
!   - Resultat : trafic chiffre entre les deux sites
!
!   Chronologie :
!   +-----------+     Phase 1 (ISAKMP)     +-----------+
!   |    R1     |<========================>|    R2     |
!   |           |  Auth + DH Key Exchange  |           |
!   |           |     Phase 2 (IPsec)      |           |
!   |           |<========================>|           |
!   |           | Transform Set + Crypto   |           |
!   |           |     Trafic chiffre       |           |
!   |           |<=======================>|           |
!   |           |   ESP (protocol 50)      |           |
!   +-----------+                          +-----------+
!
! ==========================
! ROUTEUR R1 (Siege)
! ==========================
!
configure terminal
hostname R1-SIEGE
!
! --- Phase 1 : ISAKMP Policy ---
! Definit comment les peers s'authentifient et echangent les cles
!
crypto isakmp policy 10
 authentication pre-share
 encryption aes 256
 hash sha256
 group 14
 lifetime 86400
!
! Parametres Phase 1 :
! - authentication pre-share : utilise une cle partagee (PSK)
! - encryption aes 256 : chiffrement AES 256 bits
! - hash sha256 : integrite SHA-256
! - group 14 : Diffie-Hellman groupe 14 (2048 bits)
! - lifetime 86400 : duree de vie du SA = 24h
!
! Pre-Shared Key pour le peer distant
crypto isakmp key SUPER_SECRET_KEY_2024 address 198.51.100.1
!
! --- Phase 2 : Transform Set ---
! Definit comment le trafic sera chiffre
!
crypto ipsec transform-set IPSEC-TS esp-aes 256 esp-sha256-hmac
 mode tunnel
!
! Parametres Phase 2 :
! - esp-aes 256 : chiffrement ESP avec AES 256
! - esp-sha256-hmac : integrite ESP avec SHA-256
! - mode tunnel : encapsule tout le paquet IP original
!   (mode transport = chiffre seulement le payload)
!
! --- ACL pour le trafic interessant ---
! Definit quel trafic doit etre chiffre par le VPN
!
ip access-list extended VPN-TRAFFIC
 permit ip 10.1.1.0 0.0.0.255 10.2.2.0 0.0.0.255
!
! --- Crypto Map ---
! Associe le peer, le transform set et l'ACL
!
crypto map VPN-MAP 10 ipsec-isakmp
 set peer 198.51.100.1
 set transform-set IPSEC-TS
 match address VPN-TRAFFIC
 set security-association lifetime seconds 3600
!
! lifetime seconds 3600 = renouveler le SA toutes les heures
!
! --- Appliquer la crypto map sur l'interface WAN ---
interface gigabitEthernet 0/1
 crypto map VPN-MAP
!
! Route pour le trafic VPN (si pas de route par defaut)
ip route 10.2.2.0 255.255.255.0 203.0.113.254
!
end
write memory
!
! ==========================
! ROUTEUR R2 (Succursale)
! ==========================
!
configure terminal
hostname R2-BRANCH
!
! --- Phase 1 : ISAKMP Policy ---
crypto isakmp policy 10
 authentication pre-share
 encryption aes 256
 hash sha256
 group 14
 lifetime 86400
!
! Pre-Shared Key (DOIT etre identique sur les deux routeurs)
crypto isakmp key SUPER_SECRET_KEY_2024 address 203.0.113.1
!
! --- Phase 2 : Transform Set ---
crypto ipsec transform-set IPSEC-TS esp-aes 256 esp-sha256-hmac
 mode tunnel
!
! --- ACL pour le trafic interessant (inverse de R1) ---
ip access-list extended VPN-TRAFFIC
 permit ip 10.2.2.0 0.0.0.255 10.1.1.0 0.0.0.255
!
! --- Crypto Map ---
crypto map VPN-MAP 10 ipsec-isakmp
 set peer 203.0.113.1
 set transform-set IPSEC-TS
 match address VPN-TRAFFIC
 set security-association lifetime seconds 3600
!
! --- Appliquer sur l'interface WAN ---
interface gigabitEthernet 0/1
 crypto map VPN-MAP
!
ip route 10.1.1.0 255.255.255.0 198.51.100.254
!
end
write memory
!
! ==========================
! VERIFICATION IPsec
! ==========================
!
! Verifier Phase 1 (ISAKMP SA)
show crypto isakmp sa
! -> Etat QM_IDLE = Phase 1 OK
!
! Verifier Phase 2 (IPsec SA)
show crypto ipsec sa
! -> Affiche : packets encaps/decaps, transform set, lifetime
!
! Verifier la politique ISAKMP
show crypto isakmp policy
!
! Verifier la crypto map
show crypto map
!
! Test : envoyer du trafic entre les LANs
ping 10.2.2.1 source 10.1.1.1
!
! Verifier les compteurs apres le ping
show crypto ipsec sa | include pkts
! -> "pkts encaps" et "pkts decaps" doivent augmenter
!
EOF
}

# =============================================================================
# FONCTION 4 : GRE over IPsec (tunnel protection)
# =============================================================================

generate_gre_over_ipsec() {
    cat << EOF
!
! ============================================================
! Configuration GRE over IPsec (Tunnel Protection)
! ============================================================
!
! Pourquoi GRE over IPsec ?
!
! GRE seul :
! + Transporte multicast, protocoles de routage (OSPF, EIGRP)
! + Simple a configurer
! - PAS de chiffrement (trafic en clair !)
!
! IPsec seul :
! + Chiffrement fort (confidentialite, integrite, authenticite)
! - Ne transporte PAS le multicast
! - Ne supporte PAS les protocoles de routage dynamique
!
! GRE over IPsec = le meilleur des deux mondes :
! + Chiffrement IPsec
! + Transport multicast et routage dynamique
!
! Encapsulation GRE over IPsec :
!
!   +---------------------------------------------------------+
!   | IP Ext.  | ESP Header | GRE Hdr | IP Int.  | Data | ESP|
!   | 20 oct.  | 8-22 oct.  | 4 oct.  | 20 oct.  |      |Trl|
!   +---------------------------------------------------------+
!   |<------------- Chiffre par IPsec ----------------------->|
!
!   Overhead total : ~62 octets -> MTU = 1500 - 62 = ~1438
!
! Topologie :
!
!   LAN-A (10.1.1.0/24)                   LAN-B (10.2.2.0/24)
!       |                                       |
!   [R1-SIEGE]===== GRE + IPsec =====[R2-BRANCH]
!   Gi0/1: 203.0.113.1                Gi0/1: 198.51.100.1
!   Tunnel0: 172.16.1.1/30            Tunnel0: 172.16.1.2/30
!
! ==========================
! ROUTEUR R1 (Siege)
! ==========================
!
configure terminal
hostname R1-SIEGE
!
! --- Phase 1 : ISAKMP ---
crypto isakmp policy 10
 authentication pre-share
 encryption aes 256
 hash sha256
 group 14
 lifetime 86400
!
crypto isakmp key GRE_IPSEC_KEY_2024 address 198.51.100.1
!
! --- Phase 2 : Transform Set ---
! Mode TRANSPORT (pas tunnel) car GRE fournit deja l'encapsulation
crypto ipsec transform-set GRE-IPSEC-TS esp-aes 256 esp-sha256-hmac
 mode transport
!
! Note importante : mode TRANSPORT vs TUNNEL
! - Transport : chiffre seulement le payload du paquet GRE
!   -> Plus efficace (moins d'overhead)
! - Tunnel : ajoute un en-tete IP supplementaire
!   -> Plus d'overhead mais isole completement les en-tetes
!
! --- IPsec Profile (alternative a crypto map pour tunnels) ---
crypto ipsec profile GRE-IPSEC-PROFILE
 set transform-set GRE-IPSEC-TS
 set security-association lifetime seconds 3600
!
! --- Interface Tunnel GRE avec protection IPsec ---
interface tunnel 0
 description GRE over IPsec vers R2-BRANCH
 ip address 172.16.1.1 255.255.255.252
 tunnel source gigabitEthernet 0/1
 tunnel destination 198.51.100.1
 tunnel mode gre ip
 tunnel protection ipsec profile GRE-IPSEC-PROFILE
 ip mtu 1400
 ip tcp adjust-mss 1360
 keepalive 10 3
 no shutdown
!
! "tunnel protection ipsec profile" :
! -> Chiffre automatiquement tout le trafic GRE avec IPsec
! -> Pas besoin de crypto map ni d'ACL pour le trafic interessant
!
! MTU reduit a 1400 pour tenir compte de l'overhead GRE + IPsec
! MSS = 1400 - 40 = 1360
!
! Route vers le LAN distant
ip route 10.2.2.0 255.255.255.0 172.16.1.2
!
! Route par defaut
ip route 0.0.0.0 0.0.0.0 203.0.113.254
!
end
write memory
!
! ==========================
! ROUTEUR R2 (Succursale)
! ==========================
!
configure terminal
hostname R2-BRANCH
!
! --- Phase 1 ---
crypto isakmp policy 10
 authentication pre-share
 encryption aes 256
 hash sha256
 group 14
 lifetime 86400
!
crypto isakmp key GRE_IPSEC_KEY_2024 address 203.0.113.1
!
! --- Phase 2 ---
crypto ipsec transform-set GRE-IPSEC-TS esp-aes 256 esp-sha256-hmac
 mode transport
!
! --- IPsec Profile ---
crypto ipsec profile GRE-IPSEC-PROFILE
 set transform-set GRE-IPSEC-TS
 set security-association lifetime seconds 3600
!
! --- Tunnel GRE avec protection IPsec ---
interface tunnel 0
 description GRE over IPsec vers R1-SIEGE
 ip address 172.16.1.2 255.255.255.252
 tunnel source gigabitEthernet 0/1
 tunnel destination 203.0.113.1
 tunnel mode gre ip
 tunnel protection ipsec profile GRE-IPSEC-PROFILE
 ip mtu 1400
 ip tcp adjust-mss 1360
 keepalive 10 3
 no shutdown
!
ip route 10.1.1.0 255.255.255.0 172.16.1.1
ip route 0.0.0.0 0.0.0.0 198.51.100.254
!
end
write memory
!
! ==========================
! VERIFICATION GRE over IPsec
! ==========================
!
! Tunnel GRE
show interface tunnel 0
! -> up/up
!
! IPsec SA (doit montrer le tunnel comme protege)
show crypto ipsec sa
! -> Chercher "local ident" et "remote ident"
! -> Verifier pkts encaps/decaps
!
! ISAKMP SA
show crypto isakmp sa
! -> QM_IDLE = Phase 1 OK
!
! Test connectivite
ping 172.16.1.2 source 172.16.1.1
ping 10.2.2.1 source 10.1.1.1
!
! Verifier que le trafic est bien chiffre
show crypto ipsec sa | include pkts
! -> Les compteurs doivent augmenter apres chaque ping
!
! Avantage GRE over IPsec :
! On peut maintenant faire tourner OSPF sur le tunnel !
! router ospf 1
!  network 172.16.1.0 0.0.0.3 area 0
!  network 10.1.1.0 0.0.0.255 area 0
!
EOF
}

# =============================================================================
# FONCTION 5 : Commandes de verification VPN
# =============================================================================

generate_vpn_verification() {
    cat << EOF
!
! ============================================================
! Commandes de Verification et Troubleshooting VPN
! ============================================================
!
! === TUNNEL GRE ===
!
! Etat du tunnel
show interface tunnel 0
! -> Chercher : "line protocol is up"
! -> Si down : verifier la connectivite WAN et les IP source/dest
!
! Details du tunnel
show interfaces tunnel 0 | include tunnel
! -> Source, destination, mode
!
! MTU du tunnel
show interface tunnel 0 | include MTU
! -> Verifier que MTU = 1476 (GRE) ou 1400 (GRE+IPsec)
!
! Table de routage
show ip route
! -> Verifier les routes via le tunnel
!
! === IPSEC ===
!
! Phase 1 - ISAKMP SA
show crypto isakmp sa
! -> Etats possibles :
!    QM_IDLE    = Phase 1 etablie, tout OK
!    MM_NO_STATE = Echec de negociation Phase 1
!    MM_KEY_EXCH = Echange de cles en cours
!    MM_SA_SETUP = Negociation en cours
!
! Phase 1 - Politique
show crypto isakmp policy
! -> Verifier que les parametres correspondent entre les peers
!
! Phase 2 - IPsec SA
show crypto ipsec sa
! -> Informations cles :
!    - local/remote ident : trafic protege
!    - pkts encaps : paquets chiffres envoyes
!    - pkts decaps : paquets dechiffres recus
!    - current peer : adresse du peer IPsec
!    - transform : algorithmes utilises
!
! Crypto Map
show crypto map
!
! Transform Set
show crypto ipsec transform-set
!
! === TROUBLESHOOTING ===
!
! Probleme : Phase 1 ne s'etablit pas
! 1. Verifier la connectivite WAN entre les peers :
!    ping <peer_ip> source <wan_ip>
! 2. Verifier que les policies ISAKMP sont identiques :
!    show crypto isakmp policy
! 3. Verifier que la PSK est identique :
!    show running-config | include isakmp key
! 4. Verifier le NAT-Traversal si NAT entre les peers :
!    show crypto isakmp sa detail
!
! Probleme : Phase 2 ne s'etablit pas
! 1. Verifier que les transform sets correspondent :
!    show crypto ipsec transform-set
! 2. Verifier que les ACL "trafic interessant" sont miroir :
!    show access-list VPN-TRAFFIC
! 3. Verifier la crypto map :
!    show crypto map
!
! Probleme : Tunnel up mais pas de trafic
! 1. Verifier les routes :
!    show ip route
! 2. Verifier que le trafic match l'ACL VPN :
!    show access-list VPN-TRAFFIC
! 3. Verifier les compteurs IPsec :
!    show crypto ipsec sa | include pkts
!    -> Si pkts encaps = 0 : le trafic ne match pas l'ACL
!    -> Si pkts decaps = 0 : le peer ne repond pas
!
! Probleme : Fragmentation / Paquets perdus
! 1. Verifier le MTU :
!    show interface tunnel 0 | include MTU
! 2. Tester avec differentes tailles de ping :
!    ping 10.2.2.1 source 10.1.1.1 size 1400 df-bit
!    -> Si echec : reduire le MTU du tunnel
!
! === DEBUG (attention en production !) ===
!
! debug crypto isakmp
! debug crypto ipsec
! debug tunnel
! undebug all
!
! === RESET DES SA (si besoin de renegocier) ===
!
! clear crypto isakmp
! clear crypto sa
!
! Note : cela coupe temporairement le VPN
! Les SA seront renegociees automatiquement
!
EOF
}

# =============================================================================
# FONCTION 6 : Tableau recapitulatif des protocoles VPN
# =============================================================================

generate_vpn_summary() {
    cat << EOF
!
! ============================================================
! Recapitulatif des Technologies VPN - CCNA
! ============================================================
!
! +------------------+--------+---------+---------------+
! | Technologie      | Chiffr.| Multicast| Protocole IP |
! +------------------+--------+---------+---------------+
! | GRE              | Non    | Oui     | 47            |
! | IPsec (tunnel)   | Oui    | Non     | 50 (ESP)      |
! | IPsec (transport)| Oui    | Non     | 50 (ESP)      |
! | GRE over IPsec   | Oui    | Oui     | 47 + 50       |
! +------------------+--------+---------+---------------+
!
! +------------------+-----------+----------+-----------+
! | Technologie      | Overhead  | MTU      | MSS TCP   |
! +------------------+-----------+----------+-----------+
! | GRE              | 24 oct.   | 1476     | 1436      |
! | IPsec (tunnel)   | ~50-57 oct| ~1443-50 | ~1403-10  |
! | IPsec (transport)| ~30-37 oct| ~1463-70 | ~1423-30  |
! | GRE + IPsec      | ~62-74 oct| ~1400    | ~1360     |
! +------------------+-----------+----------+-----------+
!
! Algorithmes ISAKMP (Phase 1) recommandes :
! +------------------+-------------------+----------------+
! | Parametre        | Recommande (2024) | A eviter       |
! +------------------+-------------------+----------------+
! | Chiffrement      | AES 256           | DES, 3DES      |
! | Hash             | SHA-256, SHA-384  | MD5, SHA-1     |
! | Groupe DH        | 14 (2048), 19, 20 | 1, 2, 5       |
! | Authentification | Pre-share / Certs | -              |
! | Lifetime         | 86400 (24h)       | > 86400        |
! +------------------+-------------------+----------------+
!
! Algorithmes IPsec (Phase 2) recommandes :
! +------------------+-------------------+----------------+
! | Parametre        | Recommande (2024) | A eviter       |
! +------------------+-------------------+----------------+
! | ESP chiffrement  | esp-aes 256       | esp-des        |
! | ESP integrite    | esp-sha256-hmac   | esp-md5-hmac   |
! | Mode             | tunnel ou transp. | -              |
! | PFS (optionnel)  | group 14          | group 1, 2     |
! | Lifetime         | 3600 (1h)         | > 28800        |
! +------------------+-------------------+----------------+
!
! Ports et protocoles a autoriser dans les ACL/firewall :
! +------------------+-------------------------+
! | Protocole        | Port / Numero           |
! +------------------+-------------------------+
! | IKE (Phase 1)    | UDP 500                 |
! | NAT-Traversal    | UDP 4500                |
! | ESP              | IP Protocol 50          |
! | AH               | IP Protocol 51          |
! | GRE              | IP Protocol 47          |
! +------------------+-------------------------+
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration VPN (GRE / IPsec) ===${NC}"
    echo ""
    echo -e " ${CYAN}1)${NC} Tunnel GRE simple (deux sites)"
    echo -e " ${CYAN}2)${NC} Tunnel GRE personnalise"
    echo -e " ${CYAN}3)${NC} VPN IPsec site-to-site (crypto map)"
    echo -e " ${CYAN}4)${NC} GRE over IPsec (tunnel protection)"
    echo -e " ${CYAN}5)${NC} Commandes de verification / troubleshooting VPN"
    echo -e " ${CYAN}6)${NC} Tableau recapitulatif des protocoles VPN"
    echo -e " ${RED}0)${NC} Quitter"
    echo ""
    read -p "Votre choix [0-6] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration VPN"

    while true; do
        show_menu

        case $choice in
            1)
                log_message "Generation config GRE tunnel simple"
                generate_gre_tunnel_simple
                ;;
            2)
                echo -e "${YELLOW}Configuration du tunnel GRE personnalise${NC}"
                echo ""
                read -p "Hostname routeur 1 : " hostname_r1
                read -p "Hostname routeur 2 : " hostname_r2
                read -p "IP WAN routeur 1 : " wan_r1
                read -p "IP WAN routeur 2 : " wan_r2
                read -p "Reseau LAN routeur 1 (ex: 10.1.1.0) : " lan_r1_net
                read -p "Masque LAN routeur 1 (ex: 255.255.255.0) : " lan_r1_mask
                read -p "Reseau LAN routeur 2 (ex: 10.2.2.0) : " lan_r2_net
                read -p "Masque LAN routeur 2 (ex: 255.255.255.0) : " lan_r2_mask
                read -p "IP tunnel routeur 1 (ex: 172.16.1.1) : " tunnel_r1
                read -p "IP tunnel routeur 2 (ex: 172.16.1.2) : " tunnel_r2
                read -p "Masque tunnel (defaut 255.255.255.252) : " tunnel_mask
                tunnel_mask=${tunnel_mask:-255.255.255.252}
                echo ""
                log_message "Generation config GRE personnalise $hostname_r1 <-> $hostname_r2"
                generate_gre_tunnel_custom "$hostname_r1" "$hostname_r2" "$wan_r1" "$wan_r2" \
                    "$lan_r1_net" "$lan_r1_mask" "$lan_r2_net" "$lan_r2_mask" \
                    "$tunnel_r1" "$tunnel_r2" "$tunnel_mask"
                ;;
            3)
                log_message "Generation config IPsec site-to-site"
                generate_ipsec_site_to_site
                ;;
            4)
                log_message "Generation config GRE over IPsec"
                generate_gre_over_ipsec
                ;;
            5)
                generate_vpn_verification
                ;;
            6)
                generate_vpn_summary
                ;;
            0)
                log_message "Arret du script"
                echo -e "${GREEN}Au revoir !${NC}"
                break
                ;;
            *)
                echo -e "${RED}Choix invalide. Veuillez entrer un nombre entre 0 et 6.${NC}"
                ;;
        esac

        echo ""
        read -p "Appuyez sur Entree pour continuer..."
    done
}

# =============================================================================
# POINT D'ENTREE
# =============================================================================

main
