#!/bin/bash

# =============================================================================
# Script : Configuration DHCP - Cisco CCNA
# Auteur : Tudy Gbaguidi
# Date   : 2024
# Objectif : Generer des configurations DHCP pour routeurs Cisco
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-dhcp.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration DHCP - CCNA${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $1"
}

# =============================================================================
# GENERATEURS DE CONFIGURATION DHCP
# =============================================================================

generate_dhcp_basic() {
    local pool_name="$1"
    local network="$2"
    local mask="$3"
    local gateway="$4"
    local dns1="$5"
    local dns2="$6"
    local domain="$7"
    local excluded_start="$8"
    local excluded_end="$9"

    cat << EOF
!
! =============================================
! Configuration DHCP Serveur - Pool Basique
! =============================================
!
! Exclure les adresses reservees (routeur, serveurs, etc.)
ip dhcp excluded-address $excluded_start $excluded_end
!
! Creation du pool DHCP
ip dhcp pool $pool_name
 network $network $mask
 default-router $gateway
 dns-server $dns1 $dns2
 domain-name $domain
 lease 1 0 0
 exit
!
! Verification :
! show ip dhcp binding
! show ip dhcp pool
! show ip dhcp server statistics
! show ip dhcp conflict
!
end
EOF
}

generate_dhcp_multi_vlan() {
    cat << EOF
!
! =============================================
! Configuration DHCP Multi-VLAN
! =============================================
!
! Exclusions pour chaque VLAN
ip dhcp excluded-address 192.168.10.1 192.168.10.10
ip dhcp excluded-address 192.168.20.1 192.168.20.10
ip dhcp excluded-address 192.168.30.1 192.168.30.10
!
! Pool VLAN 10 - Utilisateurs
ip dhcp pool VLAN10-USERS
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 dns-server 8.8.8.8 8.8.4.4
 domain-name entreprise.local
 lease 8 0 0
 exit
!
! Pool VLAN 20 - Serveurs (bail long)
ip dhcp pool VLAN20-SERVERS
 network 192.168.20.0 255.255.255.0
 default-router 192.168.20.1
 dns-server 8.8.8.8 8.8.4.4
 domain-name entreprise.local
 lease 30 0 0
 exit
!
! Pool VLAN 30 - Invites (bail court)
ip dhcp pool VLAN30-GUESTS
 network 192.168.30.0 255.255.255.0
 default-router 192.168.30.1
 dns-server 8.8.8.8
 domain-name guest.local
 lease 0 4 0
 exit
!
! Configuration des interfaces (router-on-a-stick ou L3)
interface GigabitEthernet 0/0.10
 encapsulation dot1q 10
 ip address 192.168.10.1 255.255.255.0
 exit
!
interface GigabitEthernet 0/0.20
 encapsulation dot1q 20
 ip address 192.168.20.1 255.255.255.0
 exit
!
interface GigabitEthernet 0/0.30
 encapsulation dot1q 30
 ip address 192.168.30.1 255.255.255.0
 exit
!
end
EOF
}

generate_dhcp_relay() {
    local client_intf="$1"
    local client_ip="$2"
    local client_mask="$3"
    local server_ip="$4"

    cat << EOF
!
! =============================================
! Configuration DHCP Relay Agent
! =============================================
!
! Le relay agent est configure sur l'interface COTE CLIENT
! (l'interface ou arrivent les broadcasts DHCP)
!
interface $client_intf
 ip address $client_ip $client_mask
 ip helper-address $server_ip
 no shutdown
 exit
!
! Si plusieurs serveurs DHCP (redondance) :
! interface $client_intf
!  ip helper-address $server_ip
!  ip helper-address [IP_SERVEUR_BACKUP]
!  exit
!
! IMPORTANT :
! - ip helper-address relaye les broadcasts UDP
! - A configurer sur CHAQUE interface cote client
! - PAS sur l'interface cote serveur DHCP
!
! Verification :
! show running-config interface $client_intf
! show ip dhcp binding (sur le serveur DHCP)
! debug ip dhcp server events
!
end
EOF
}

generate_dhcpv6_stateless() {
    cat << EOF
!
! =============================================
! Configuration DHCPv6 Stateless (SLAAC + DHCPv6)
! =============================================
!
! Le client genere son adresse via SLAAC
! DHCPv6 fournit uniquement DNS et domain-name
!
ipv6 unicast-routing
!
ipv6 dhcp pool DHCPv6-STATELESS
 dns-server 2001:4860:4860::8888
 dns-server 2001:4860:4860::8844
 domain-name entreprise.local
 exit
!
interface GigabitEthernet 0/0
 ipv6 address 2001:db8:1::1/64
 ipv6 dhcp server DHCPv6-STATELESS
 ipv6 nd other-config-flag
 no shutdown
 exit
!
! Verification :
! show ipv6 dhcp pool
! show ipv6 interface GigabitEthernet 0/0
!
end
EOF
}

generate_dhcpv6_stateful() {
    cat << EOF
!
! =============================================
! Configuration DHCPv6 Stateful
! =============================================
!
! Le serveur DHCPv6 attribue l'adresse IPv6 ET les options
!
ipv6 unicast-routing
!
ipv6 dhcp pool DHCPv6-STATEFUL
 address prefix 2001:db8:1::/64
 dns-server 2001:4860:4860::8888
 domain-name entreprise.local
 exit
!
interface GigabitEthernet 0/0
 ipv6 address 2001:db8:1::1/64
 ipv6 dhcp server DHCPv6-STATEFUL
 ipv6 nd managed-config-flag
 no shutdown
 exit
!
! Verification :
! show ipv6 dhcp pool
! show ipv6 dhcp binding
!
end
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration DHCP ===${NC}"
    echo ""
    echo "1) Generer config DHCP basique (1 pool)"
    echo "2) Generer config DHCP multi-VLAN"
    echo "3) Generer config DHCP Relay Agent"
    echo "4) Generer config DHCPv6 Stateless"
    echo "5) Generer config DHCPv6 Stateful"
    echo "6) Afficher aide-memoire DHCP"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-6] : " choice
    echo ""
}

show_dhcp_cheatsheet() {
    echo -e "${BLUE}=== Aide-Memoire DHCP ===${NC}"
    echo ""
    echo "Processus : DORA (Discover, Offer, Request, Acknowledge)"
    echo ""
    echo "Commandes cles :"
    echo "  ip dhcp excluded-address [start] [end]"
    echo "  ip dhcp pool [NOM]"
    echo "  network [IP] [MASQUE]"
    echo "  default-router [IP]"
    echo "  dns-server [IP1] [IP2]"
    echo "  lease [jours] [heures] [minutes]"
    echo ""
    echo "Relay : ip helper-address [IP_SERVEUR_DHCP]"
    echo "        (sur l'interface COTE CLIENT)"
    echo ""
    echo "Verification :"
    echo "  show ip dhcp binding"
    echo "  show ip dhcp pool"
    echo "  show ip dhcp server statistics"
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script DHCP"

    while true; do
        show_menu

        case $choice in
            1)
                local config_file="$SCRIPT_DIR/dhcp-basic-config.txt"
                generate_dhcp_basic "LAN-POOL" "10.1.1.0" "255.255.255.0" \
                    "10.1.1.1" "8.8.8.8" "8.8.4.4" "entreprise.local" \
                    "10.1.1.1" "10.1.1.10" > "$config_file"
                log_message "Config DHCP basique generee : $config_file"
                ;;
            2)
                local config_file="$SCRIPT_DIR/dhcp-multivlan-config.txt"
                generate_dhcp_multi_vlan > "$config_file"
                log_message "Config DHCP multi-VLAN generee : $config_file"
                ;;
            3)
                local config_file="$SCRIPT_DIR/dhcp-relay-config.txt"
                generate_dhcp_relay "GigabitEthernet0/0" "10.1.10.1" \
                    "255.255.255.0" "10.1.20.100" > "$config_file"
                log_message "Config DHCP Relay generee : $config_file"
                ;;
            4)
                local config_file="$SCRIPT_DIR/dhcpv6-stateless-config.txt"
                generate_dhcpv6_stateless > "$config_file"
                log_message "Config DHCPv6 Stateless generee : $config_file"
                ;;
            5)
                local config_file="$SCRIPT_DIR/dhcpv6-stateful-config.txt"
                generate_dhcpv6_stateful > "$config_file"
                log_message "Config DHCPv6 Stateful generee : $config_file"
                ;;
            6)
                show_dhcp_cheatsheet
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
