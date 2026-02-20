#!/bin/bash

# =============================================================================
# Script : Configuration DHCP Snooping + Dynamic ARP Inspection (DAI)
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations DHCP Snooping et DAI pour switches Cisco
#            Protection contre rogue DHCP, ARP spoofing, DHCP starvation
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-dhcp-snooping.log"

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}    Configuration DHCP Snooping & DAI - CCNA${NC}"
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
# FONCTION 1 : DHCP Snooping global
# =============================================================================

generate_dhcp_snooping_global() {
    local vlans="$1"
    local trusted_port1="$2"
    local trusted_port2="$3"
    local rate_limit="$4"
    local access_start="$5"
    local access_end="$6"

    cat << EOF
!
! ============================================================
! Configuration DHCP Snooping Globale
! VLANs : $vlans
! Ports Trusted : $trusted_port1, $trusted_port2
! Rate Limit : $rate_limit paquets/seconde
! ============================================================
!
! DHCP Snooping intercepte les messages DHCP sur le switch.
! Il distingue les ports TRUSTED (vers serveur DHCP legitime)
! des ports UNTRUSTED (vers les clients).
!
! Flux DHCP avec snooping :
!
!   [Client PC]                [Rogue DHCP]
!       |                           |
!   Fa0/1 (untrusted)         Fa0/10 (untrusted)
!       |                           |
!   +---+---------------------------+---+
!   |           SWITCH (Snooping ON)    |
!   +---+-------------------------------+
!       |
!   Gi0/1 (trusted)
!       |
!   [Serveur DHCP Legitime]
!
! -> Les DHCP Offer/Ack venant de Fa0/10 seront BLOQUES
! -> Seuls les DHCP Offer/Ack de Gi0/1 seront AUTORISES
!
configure terminal
!
! --- Etape 1 : Activation globale de DHCP Snooping ---
ip dhcp snooping
!
! --- Etape 2 : Activer sur les VLANs concernes ---
ip dhcp snooping vlan $vlans
!
! Desactiver l'insertion de l'option 82 (si pas de DHCP relay)
! L'option 82 ajoute des informations de relais DHCP.
! Si le serveur DHCP n'attend pas cette option, cela peut
! causer des echecs DHCP.
no ip dhcp snooping information option
!
! --- Etape 3 : Configurer les ports TRUSTED ---
! Ports vers serveur DHCP et/ou routeur avec ip helper-address
!
interface $trusted_port1
 ip dhcp snooping trust
 description Vers serveur DHCP / routeur
!
interface $trusted_port2
 ip dhcp snooping trust
 description Vers distribution / routeur backup
!
! --- Etape 4 : Rate limiting sur les ports access ---
! Limite le nombre de requetes DHCP par seconde
! Protege contre les attaques DHCP starvation (DoS)
!
interface range fastEthernet 0/$access_start - $access_end
 ip dhcp snooping limit rate $rate_limit
!
! Recommandations rate limit :
! +-------------------+------------------+
! | Type de port      | Rate recommande  |
! +-------------------+------------------+
! | Poste utilisateur | 5-10 pps         |
! | Telephone VoIP    | 10-15 pps        |
! | Port serveur      | illimite (trust) |
! +-------------------+------------------+
!
! Si le rate limit est depasse, le port passe en err-disabled.
! Activer la recovery automatique :
errdisable recovery cause dhcp-rate-limit
errdisable recovery interval 300
!
end
!
! --- Verification ---
show ip dhcp snooping
show ip dhcp snooping binding
show ip dhcp snooping statistics
!
write memory
EOF
}

# =============================================================================
# FONCTION 2 : DHCP Snooping - Binding Table details
# =============================================================================

generate_dhcp_snooping_binding_info() {
    cat << EOF
!
! ============================================================
! DHCP Snooping Binding Table - Explications
! ============================================================
!
! La binding table est le coeur de DHCP Snooping.
! Elle enregistre automatiquement les associations :
!   MAC <-> IP <-> VLAN <-> Port <-> Lease Time
!
! Cette table est utilisee par :
! - Dynamic ARP Inspection (DAI)  -> valide les paquets ARP
! - IP Source Guard               -> valide les paquets IP
!
! Exemple de binding table :
!
! MacAddress         IpAddress      Lease(sec)  Type          VLAN  Interface
! --------           ----------     ----------  ----------    ----  ---------
! 00:1A:2B:3C:4D:01  10.1.10.10    86400       dhcp-snooping 10    Fa0/1
! 00:1A:2B:3C:4D:02  10.1.10.11    86400       dhcp-snooping 10    Fa0/2
! 00:1A:2B:3C:4D:03  10.1.20.10    86400       dhcp-snooping 20    Fa0/3
! AA:BB:CC:DD:EE:01  10.1.10.100   infinite    static        10    Fa0/5
!
! --- Commandes de verification ---
show ip dhcp snooping binding
!
! --- Ajouter une entree statique (hote IP fixe) ---
! ip source binding AAAA.BBBB.CCCC vlan 10 10.1.10.100 interface Fa0/5
!
! --- Supprimer une entree ---
! no ip source binding AAAA.BBBB.CCCC vlan 10 10.1.10.100 interface Fa0/5
!
! --- Sauvegarder la binding table (persistance au reboot) ---
! ip dhcp snooping database flash:dhcp-snooping.db
! ip dhcp snooping database timeout 60
!
! Note : par defaut, la binding table est perdue au reboot.
! Il est FORTEMENT recommande de sauvegarder la database
! sur flash ou sur un serveur TFTP/FTP.
!
! Persistance sur flash :
configure terminal
ip dhcp snooping database flash:dhcp-snooping-db
ip dhcp snooping database write-delay 60
end
!
write memory
EOF
}

# =============================================================================
# FONCTION 3 : Dynamic ARP Inspection (DAI)
# =============================================================================

generate_dai_config() {
    local vlans="$1"
    local trusted_port1="$2"
    local trusted_port2="$3"

    cat << EOF
!
! ============================================================
! Configuration Dynamic ARP Inspection (DAI)
! VLANs : $vlans
! Ports Trusted : $trusted_port1, $trusted_port2
! ============================================================
!
! PREREQUIS : DHCP Snooping DOIT etre active avant DAI
! DAI utilise la binding table de DHCP Snooping pour valider
! les paquets ARP.
!
! Attaque ARP Spoofing (sans DAI) :
!
!   [Victime]          [Attaquant]           [Passerelle]
!   10.1.10.10         10.1.10.99            10.1.10.1
!   MAC-V              MAC-A                 MAC-GW
!       |                   |                     |
!       |   ARP Reply :     |                     |
!       |<--"10.1.10.1 est  |                     |
!       |    a MAC-A"       |                     |
!       |                   |                     |
!       +------Trafic------>+------Trafic-------->+
!                    (Man-in-the-Middle)
!
! Avec DAI active :
! Le switch verifie que le couple IP/MAC dans l'ARP Reply
! correspond a une entree de la binding table DHCP Snooping.
! -> L'ARP Reply falsifie de l'attaquant est BLOQUE.
!
configure terminal
!
! --- Activer DAI sur les VLANs ---
ip arp inspection vlan $vlans
!
! --- Configurer les ports TRUSTED pour DAI ---
! Memes ports que pour DHCP Snooping (vers routeur/serveur DHCP)
!
interface $trusted_port1
 ip arp inspection trust
!
interface $trusted_port2
 ip arp inspection trust
!
! --- Validation supplementaire (optionnel mais recommande) ---
! Verifie la coherence des en-tetes Ethernet et ARP :
! - src-mac : MAC source Ethernet = MAC source ARP
! - dst-mac : MAC destination Ethernet = MAC destination ARP
! - ip : pas d'adresses IP invalides (0.0.0.0, 255.255.255.255)
ip arp inspection validate src-mac dst-mac ip
!
! --- Rate limiting DAI (anti-DoS) ---
! Par defaut : 15 pps sur les ports untrusted
! Si le rate est depasse, le port passe en err-disabled
!
! Augmenter la limite si necessaire :
! interface fastEthernet 0/1
!  ip arp inspection limit rate 30
!
! Recovery automatique
errdisable recovery cause arp-inspection
errdisable recovery interval 300
!
! --- Logging DAI ---
! Par defaut, DAI log les paquets refuses (denied)
! Optionnel : logger aussi les paquets autorises
ip arp inspection log-buffer entries 1024
ip arp inspection log-buffer logs 10 interval 1
!
end
!
! --- Verification ---
show ip arp inspection
show ip arp inspection vlan $vlans
show ip arp inspection statistics
show ip arp inspection interfaces
show ip arp inspection log
!
write memory
EOF
}

# =============================================================================
# FONCTION 4 : DAI avec ARP ACL pour hotes statiques
# =============================================================================

generate_dai_static_hosts() {
    local vlan="$1"
    local acl_name="$2"

    cat << EOF
!
! ============================================================
! Configuration DAI pour Hotes a IP Statique
! VLAN : $vlan | ACL : $acl_name
! ============================================================
!
! Les hotes avec IP statique ne passent PAS par DHCP,
! donc ils n'ont PAS d'entree dans la binding table.
! Sans ARP ACL, DAI bloquera leurs paquets ARP !
!
! Solution : creer une ARP ACL manuelle pour ces hotes.
!
! Exemple : serveurs avec IP fixe
!
!   Serveur Web  : 10.1.10.100 / MAC AA:BB:CC:DD:EE:01
!   Serveur Mail : 10.1.10.101 / MAC AA:BB:CC:DD:EE:02
!   Imprimante   : 10.1.10.102 / MAC AA:BB:CC:DD:EE:03
!
configure terminal
!
! --- Creer l'ARP ACL ---
arp access-list $acl_name
 permit ip host 10.1.10.100 mac host AABB.CCDD.EE01
 permit ip host 10.1.10.101 mac host AABB.CCDD.EE02
 permit ip host 10.1.10.102 mac host AABB.CCDD.EE03
!
! --- Appliquer l'ARP ACL sur le VLAN ---
! "static" signifie : verifier d'abord l'ACL, puis la binding table
ip arp inspection filter $acl_name vlan $vlan static
!
! Note sur le mot-cle "static" :
! - Avec "static" : verifie ACL d'abord, puis binding table si pas de match
! - Sans "static" : verifie SEULEMENT l'ACL (ignore la binding table)
! -> Utiliser "static" pour un VLAN mixte (DHCP + IP fixes)
!
end
!
! --- Verification ---
show arp access-list $acl_name
show ip arp inspection vlan $vlan
!
! Pour ajouter un nouvel hote statique :
! configure terminal
! arp access-list $acl_name
!  permit ip host <IP> mac host <MAC>
! end
!
write memory
EOF
}

# =============================================================================
# FONCTION 5 : Configuration complete DHCP Snooping + DAI
# =============================================================================

generate_complete_snooping_dai() {
    cat << EOF
!
! ============================================================
! Configuration Complete DHCP Snooping + DAI
! Switch Access - Environnement Entreprise
! ============================================================
!
! Topologie :
!
!   [Serveur DHCP]     [Routeur/L3 Switch]
!   10.1.10.254            (DHCP Relay)
!       |                       |
!   Gi0/1 (trusted)        Gi0/2 (trusted)
!       |                       |
!   +---+-----------------------+---+
!   |      SW-ACCESS-01             |
!   |      DHCP Snooping : ON      |
!   |      DAI : ON                 |
!   +---+---+---+---+---+---+------+
!       |   |   |   |   |   |
!    Fa0/1....................Fa0/24
!    (untrusted - clients DHCP)
!
configure terminal
!
! ===========================================
! ETAPE 1 : DHCP Snooping
! ===========================================
!
! Activation globale
ip dhcp snooping
!
! VLANs concernes
ip dhcp snooping vlan 10,20,30
!
! Desactiver option 82 si pas de relay
no ip dhcp snooping information option
!
! Persistance binding table
ip dhcp snooping database flash:dhcp-snooping-db
ip dhcp snooping database write-delay 60
!
! Ports trusted (serveur DHCP + routeur)
interface gigabitEthernet 0/1
 description Vers Serveur DHCP
 ip dhcp snooping trust
!
interface gigabitEthernet 0/2
 description Vers Routeur / Distribution
 ip dhcp snooping trust
!
! Rate limiting sur ports access
interface range fastEthernet 0/1 - 24
 ip dhcp snooping limit rate 10
!
! ===========================================
! ETAPE 2 : Dynamic ARP Inspection (DAI)
! ===========================================
!
! Activer DAI sur les VLANs
ip arp inspection vlan 10,20,30
!
! Ports trusted pour DAI
interface gigabitEthernet 0/1
 ip arp inspection trust
!
interface gigabitEthernet 0/2
 ip arp inspection trust
!
! Validation supplementaire
ip arp inspection validate src-mac dst-mac ip
!
! Logging
ip arp inspection log-buffer entries 1024
ip arp inspection log-buffer logs 10 interval 1
!
! ===========================================
! ETAPE 3 : ARP ACL pour hotes statiques
! ===========================================
!
! Serveurs avec IP fixe sur VLAN 10
arp access-list STATIC-SERVERS
 permit ip host 10.1.10.100 mac host AABB.CCDD.EE01
 permit ip host 10.1.10.101 mac host AABB.CCDD.EE02
!
ip arp inspection filter STATIC-SERVERS vlan 10 static
!
! ===========================================
! ETAPE 4 : Err-disable recovery
! ===========================================
!
errdisable recovery cause dhcp-rate-limit
errdisable recovery cause arp-inspection
errdisable recovery interval 300
!
end
!
! ===========================================
! VERIFICATION COMPLETE
! ===========================================
!
! --- DHCP Snooping ---
show ip dhcp snooping
show ip dhcp snooping binding
show ip dhcp snooping statistics
show ip dhcp snooping database
!
! --- DAI ---
show ip arp inspection
show ip arp inspection vlan 10,20,30
show ip arp inspection statistics
show ip arp inspection interfaces
show ip arp inspection log
!
! --- ARP ACL ---
show arp access-list
!
! --- Err-disabled ---
show interfaces status err-disabled
show errdisable recovery
!
write memory
EOF
}

# =============================================================================
# FONCTION 6 : Commandes de verification et troubleshooting
# =============================================================================

generate_verification_commands() {
    cat << EOF
!
! ============================================================
! Commandes de Verification et Troubleshooting
! DHCP Snooping & DAI
! ============================================================
!
! === DHCP SNOOPING ===
!
! Status global DHCP Snooping
show ip dhcp snooping
! -> Verifie : snooping actif, VLANs, option 82
!
! Binding table (associations MAC/IP/VLAN/Port)
show ip dhcp snooping binding
! -> Verifie : entrees apprises par DHCP
!
! Statistiques (paquets recus, filtres, rejetes)
show ip dhcp snooping statistics
! -> Chercher : compteurs de paquets droppes
!
! Base de donnees (persistance)
show ip dhcp snooping database
! -> Verifie : sauvegarde sur flash/TFTP
!
! === DAI ===
!
! Status global DAI
show ip arp inspection
! -> Verifie : DAI actif sur quels VLANs
!
! Status par VLAN
show ip arp inspection vlan 10
! -> Verifie : nombre de paquets valides/invalides
!
! Statistiques detaillees
show ip arp inspection statistics
! -> Chercher : Forwarded, Dropped, DHCP Denied, ACL Denied
!
! Status par interface (trusted/untrusted, rate)
show ip arp inspection interfaces
!
! Logs DAI
show ip arp inspection log
! -> Voir les paquets ARP rejetes
!
! === TROUBLESHOOTING ===
!
! Probleme : Client n'obtient pas d'adresse DHCP
! 1. Verifier que le port vers le serveur DHCP est trusted :
show ip dhcp snooping
! 2. Verifier les statistiques pour des drops :
show ip dhcp snooping statistics
! 3. Verifier que l'option 82 ne pose pas probleme :
!    -> "no ip dhcp snooping information option" si necessaire
!
! Probleme : Hote ne peut plus communiquer apres activation DAI
! 1. Verifier la binding table :
show ip dhcp snooping binding
! 2. Si IP statique, creer une ARP ACL
! 3. Verifier les stats DAI pour des drops :
show ip arp inspection statistics
!
! Probleme : Port en err-disabled (rate limit depasse)
! 1. Verifier :
show interfaces status err-disabled
! 2. Recovery manuelle :
!    interface Fa0/X
!     shutdown
!     no shutdown
! 3. Ou augmenter le rate limit :
!    interface Fa0/X
!     ip dhcp snooping limit rate 15
!
! Probleme : Binding table perdue apres reboot
! Solution : sauvegarder sur flash
!    ip dhcp snooping database flash:dhcp-snooping-db
!
! === DEBUG (attention en production) ===
!
! debug ip dhcp snooping event
! debug ip dhcp snooping packet
! debug arp inspection
! undebug all
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration DHCP Snooping & DAI ===${NC}"
    echo ""
    echo -e " ${CYAN}1)${NC} DHCP Snooping global (trusted/untrusted/rate limit)"
    echo -e " ${CYAN}2)${NC} DHCP Snooping binding table (explications)"
    echo -e " ${CYAN}3)${NC} Dynamic ARP Inspection (DAI)"
    echo -e " ${CYAN}4)${NC} DAI avec ARP ACL (hotes IP statiques)"
    echo -e " ${CYAN}5)${NC} Configuration complete Snooping + DAI (all-in-one)"
    echo -e " ${CYAN}6)${NC} Commandes de verification / troubleshooting"
    echo -e " ${RED}0)${NC} Quitter"
    echo ""
    read -p "Votre choix [0-6] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration DHCP Snooping & DAI"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "VLANs (ex: 10,20,30) : " vlans
                read -p "Port trusted 1 (ex: gigabitEthernet 0/1) : " trusted_port1
                read -p "Port trusted 2 (ex: gigabitEthernet 0/2) : " trusted_port2
                read -p "Rate limit pps (defaut 10) : " rate_limit
                rate_limit=${rate_limit:-10}
                read -p "Premier port access (ex: 1) : " access_start
                read -p "Dernier port access (ex: 24) : " access_end
                echo ""
                log_message "Generation config DHCP Snooping VLANs=$vlans"
                generate_dhcp_snooping_global "$vlans" "$trusted_port1" "$trusted_port2" "$rate_limit" "$access_start" "$access_end"
                ;;
            2)
                log_message "Affichage infos binding table DHCP Snooping"
                generate_dhcp_snooping_binding_info
                ;;
            3)
                read -p "VLANs (ex: 10,20,30) : " vlans
                read -p "Port trusted 1 (ex: gigabitEthernet 0/1) : " trusted_port1
                read -p "Port trusted 2 (ex: gigabitEthernet 0/2) : " trusted_port2
                echo ""
                log_message "Generation config DAI VLANs=$vlans"
                generate_dai_config "$vlans" "$trusted_port1" "$trusted_port2"
                ;;
            4)
                read -p "VLAN pour les hotes statiques (ex: 10) : " vlan
                read -p "Nom de l'ARP ACL (defaut STATIC-HOSTS) : " acl_name
                acl_name=${acl_name:-STATIC-HOSTS}
                echo ""
                log_message "Generation config DAI ARP ACL=$acl_name VLAN=$vlan"
                generate_dai_static_hosts "$vlan" "$acl_name"
                ;;
            5)
                log_message "Generation config complete DHCP Snooping + DAI"
                generate_complete_snooping_dai
                ;;
            6)
                generate_verification_commands
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
