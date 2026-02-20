#!/bin/bash

# =============================================================================
# Script : Configuration NAT/PAT - Cisco CCNA
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations NAT/PAT pour routeurs Cisco
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-nat.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration NAT/PAT - CCNA${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $1"
}

# =============================================================================
# GENERATEURS DE CONFIGURATION NAT
# =============================================================================

generate_static_nat() {
    local inside_intf="$1"
    local inside_ip="$2"
    local inside_mask="$3"
    local outside_intf="$4"
    local outside_ip="$5"
    local outside_mask="$6"
    local private_ip="$7"
    local public_ip="$8"

    cat << EOF
!
! =============================================
! Configuration NAT Statique
! =============================================
!
! Configuration des interfaces
interface $inside_intf
 ip address $inside_ip $inside_mask
 ip nat inside
 no shutdown
 exit
!
interface $outside_intf
 ip address $outside_ip $outside_mask
 ip nat outside
 no shutdown
 exit
!
! Mapping NAT statique (1:1)
ip nat inside source static $private_ip $public_ip
!
! Verification :
! show ip nat translations
! show ip nat statistics
!
end
EOF
}

generate_dynamic_nat() {
    local inside_intf="$1"
    local inside_ip="$2"
    local inside_mask="$3"
    local outside_intf="$4"
    local outside_ip="$5"
    local outside_mask="$6"
    local pool_start="$7"
    local pool_end="$8"
    local pool_mask="$9"
    local acl_network="${10}"
    local acl_wildcard="${11}"

    cat << EOF
!
! =============================================
! Configuration NAT Dynamique (Pool)
! =============================================
!
! Configuration des interfaces
interface $inside_intf
 ip address $inside_ip $inside_mask
 ip nat inside
 no shutdown
 exit
!
interface $outside_intf
 ip address $outside_ip $outside_mask
 ip nat outside
 no shutdown
 exit
!
! Definition du pool d'adresses publiques
ip nat pool NAT-POOL $pool_start $pool_end netmask $pool_mask
!
! ACL identifiant le trafic a traduire
access-list 1 permit $acl_network $acl_wildcard
!
! Association ACL <-> Pool
ip nat inside source list 1 pool NAT-POOL
!
! Verification :
! show ip nat translations
! show ip nat statistics
! show access-lists 1
!
end
EOF
}

generate_pat() {
    local inside_intf="$1"
    local inside_ip="$2"
    local inside_mask="$3"
    local outside_intf="$4"
    local outside_ip="$5"
    local outside_mask="$6"
    local acl_network="$7"
    local acl_wildcard="$8"
    local default_gw="$9"

    cat << EOF
!
! =============================================
! Configuration PAT (NAT Overload)
! =============================================
!
! Configuration des interfaces
interface $inside_intf
 ip address $inside_ip $inside_mask
 ip nat inside
 no shutdown
 exit
!
interface $outside_intf
 ip address $outside_ip $outside_mask
 ip nat outside
 no shutdown
 exit
!
! Route par defaut vers ISP
ip route 0.0.0.0 0.0.0.0 $default_gw
!
! ACL identifiant le trafic interne
access-list 1 permit $acl_network $acl_wildcard
!
! PAT avec adresse de l'interface de sortie (overload)
ip nat inside source list 1 interface $outside_intf overload
!
! Verification :
! show ip nat translations
! show ip nat statistics
! debug ip nat (attention en production)
!
end
EOF
}

generate_lab_nat_complete() {
    cat << EOF
!
! =============================================
! Lab Complet : NAT Statique + PAT
! =============================================
!
! Topologie :
!   LAN (10.1.1.0/24) --- R1 --- ISP (203.0.113.0/30)
!   Serveur Web : 10.1.1.100 -> 203.0.113.10 (statique)
!   Tous les PC : PAT via interface outside
!
hostname R1
!
interface GigabitEthernet 0/0
 description LAN Interface
 ip address 10.1.1.1 255.255.255.0
 ip nat inside
 no shutdown
 exit
!
interface GigabitEthernet 0/1
 description WAN Interface vers ISP
 ip address 203.0.113.2 255.255.255.252
 ip nat outside
 no shutdown
 exit
!
! Route par defaut
ip route 0.0.0.0 0.0.0.0 203.0.113.1
!
! NAT Statique pour le serveur web
ip nat inside source static 10.1.1.100 203.0.113.10
!
! PAT pour tout le LAN
access-list 1 permit 10.1.1.0 0.0.0.255
ip nat inside source list 1 interface GigabitEthernet 0/1 overload
!
! Securite de base
enable secret class
service password-encryption
no ip domain-lookup
banner motd # Acces Autorise Uniquement #
!
line console 0
 password cisco
 login
 exit
line vty 0 4
 password cisco
 login
 transport input ssh
 exit
!
end
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration NAT/PAT ===${NC}"
    echo ""
    echo "1) Generer config NAT Statique"
    echo "2) Generer config NAT Dynamique (Pool)"
    echo "3) Generer config PAT (Overload)"
    echo "4) Generer Lab Complet (NAT + PAT)"
    echo "5) Afficher aide-memoire NAT"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-5] : " choice
    echo ""
}

show_nat_cheatsheet() {
    echo -e "${BLUE}=== Aide-Memoire NAT/PAT ===${NC}"
    echo ""
    echo "NAT Statique : ip nat inside source static [privee] [publique]"
    echo "NAT Dynamique: ip nat inside source list [ACL] pool [POOL-NAME]"
    echo "PAT          : ip nat inside source list [ACL] interface [intf] overload"
    echo ""
    echo "Interfaces   : ip nat inside / ip nat outside"
    echo "Verification : show ip nat translations"
    echo "               show ip nat statistics"
    echo "Effacer      : clear ip nat translation *"
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script NAT/PAT"

    while true; do
        show_menu

        case $choice in
            1)
                local config_file="$SCRIPT_DIR/nat-static-config.txt"
                generate_static_nat "GigabitEthernet0/0" "10.1.1.1" "255.255.255.0" \
                    "GigabitEthernet0/1" "203.0.113.2" "255.255.255.252" \
                    "10.1.1.100" "203.0.113.10" > "$config_file"
                log_message "Config NAT Statique generee : $config_file"
                ;;
            2)
                local config_file="$SCRIPT_DIR/nat-dynamic-config.txt"
                generate_dynamic_nat "GigabitEthernet0/0" "10.1.1.1" "255.255.255.0" \
                    "GigabitEthernet0/1" "203.0.113.2" "255.255.255.252" \
                    "203.0.113.10" "203.0.113.14" "255.255.255.240" \
                    "10.1.1.0" "0.0.0.255" > "$config_file"
                log_message "Config NAT Dynamique generee : $config_file"
                ;;
            3)
                local config_file="$SCRIPT_DIR/pat-config.txt"
                generate_pat "GigabitEthernet0/0" "10.1.1.1" "255.255.255.0" \
                    "GigabitEthernet0/1" "203.0.113.2" "255.255.255.252" \
                    "10.1.1.0" "0.0.0.255" "203.0.113.1" > "$config_file"
                log_message "Config PAT generee : $config_file"
                ;;
            4)
                local config_file="$SCRIPT_DIR/lab-nat-complete.txt"
                generate_lab_nat_complete > "$config_file"
                log_message "Lab NAT complet genere : $config_file"
                ;;
            5)
                show_nat_cheatsheet
                ;;
            0)
                log_message "Arret du script"
                echo -e "${GREEN}Au revoir !${NC}"
                break
                ;;
            *)
                echo -e "${RED}Choix invalide.${NC}"
                ;;
        esac

        echo ""
        read -p "Appuyez sur Entree pour continuer..."
    done
}

main
