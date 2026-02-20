#!/bin/bash

# =============================================================================
# Script : Configuration EtherChannel - Cisco CCNA
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations EtherChannel pour equipements Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-etherchannel.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration EtherChannel - CCNA${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $message"
}

# =============================================================================
# CONFIGURATIONS ETHERCHANNEL
# =============================================================================

generate_lacp_trunk_config() {
    local hostname="$1"
    local channel_group="$2"
    local start_port="$3"
    local end_port="$4"
    local mode="$5"
    local vlans="$6"
    local native_vlan="$7"

    cat << EOF
!
! Configuration EtherChannel LACP (Trunk) - $hostname
!
hostname $hostname
!
! Etape 1 : Configurer le channel-group sur les interfaces physiques
interface range gigabitethernet 0/$start_port-$end_port
 channel-group $channel_group mode $mode
 exit
!
! Etape 2 : Configurer le Port-Channel logique
interface port-channel $channel_group
 description "EtherChannel LACP - Po$channel_group"
 switchport mode trunk
 switchport trunk allowed vlan $vlans
 switchport trunk native vlan $native_vlan
 exit
!
! Verification :
! show etherchannel summary
! show etherchannel $channel_group detail
! show interfaces port-channel $channel_group
! show interfaces trunk
!
end
EOF
}

generate_pagp_trunk_config() {
    local hostname="$1"
    local channel_group="$2"
    local start_port="$3"
    local end_port="$4"
    local mode="$5"
    local vlans="$6"

    cat << EOF
!
! Configuration EtherChannel PAgP (Trunk) - $hostname
!
hostname $hostname
!
! Configuration PAgP sur les interfaces physiques
interface range gigabitethernet 0/$start_port-$end_port
 channel-group $channel_group mode $mode
 exit
!
! Configuration du Port-Channel
interface port-channel $channel_group
 description "EtherChannel PAgP - Po$channel_group"
 switchport mode trunk
 switchport trunk allowed vlan $vlans
 exit
!
! Verification :
! show etherchannel summary
! show etherchannel $channel_group detail
!
end
EOF
}

generate_l3_etherchannel_config() {
    local hostname="$1"
    local channel_group="$2"
    local start_port="$3"
    local end_port="$4"
    local ip_address="$5"
    local subnet_mask="$6"

    cat << EOF
!
! Configuration EtherChannel Layer 3 - $hostname
!
hostname $hostname
!
! Interfaces physiques en mode routed (no switchport)
interface range gigabitethernet 0/$start_port-$end_port
 no switchport
 channel-group $channel_group mode active
 exit
!
! Port-Channel Layer 3 avec adresse IP
interface port-channel $channel_group
 no switchport
 ip address $ip_address $subnet_mask
 exit
!
! Verification :
! show etherchannel summary
! show ip interface brief | include Port-channel
! show interfaces port-channel $channel_group
!
end
EOF
}

generate_full_topology_config() {
    cat << EOF
!
! Configuration EtherChannel Complete - Infrastructure 2 Switches
!
! ===============================================
! SWITCH A - Configuration
! ===============================================
!
hostname SW-A
!
! VLANs
vlan 10
 name Users
 exit
vlan 20
 name IT
 exit
vlan 30
 name Servers
 exit
vlan 99
 name Management
 exit
!
! EtherChannel LACP vers SW-B
interface range gigabitethernet 0/1-4
 channel-group 1 mode active
 exit
!
interface port-channel 1
 description "EtherChannel LACP vers SW-B"
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,99
 switchport trunk native vlan 99
 exit
!
! Ports Access
interface range fastethernet 0/1-8
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
interface range fastethernet 0/9-16
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
interface range fastethernet 0/17-24
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! Load Balancing
port-channel load-balance src-dst-ip
!
! ===============================================
! SWITCH B - Configuration
! ===============================================
!
hostname SW-B
!
! VLANs (identiques a SW-A)
vlan 10
 name Users
 exit
vlan 20
 name IT
 exit
vlan 30
 name Servers
 exit
vlan 99
 name Management
 exit
!
! EtherChannel LACP vers SW-A
interface range gigabitethernet 0/1-4
 channel-group 1 mode active
 exit
!
interface port-channel 1
 description "EtherChannel LACP vers SW-A"
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,99
 switchport trunk native vlan 99
 exit
!
! Ports Access (identique a SW-A)
interface range fastethernet 0/1-8
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
interface range fastethernet 0/9-16
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
interface range fastethernet 0/17-24
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! Load Balancing (meme methode des deux cotes)
port-channel load-balance src-dst-ip
!
! ===============================================
! VERIFICATION POST-CONFIGURATION
! ===============================================
!
! Sur les deux switches :
! show etherchannel summary
! show etherchannel 1 detail
! show interfaces port-channel 1
! show interfaces trunk
! show etherchannel load-balance
! show spanning-tree
!
end
EOF
}

generate_troubleshooting_commands() {
    cat << EOF
!
! Commandes de Troubleshooting EtherChannel
!
! === Verification Globale ===
show etherchannel summary
show etherchannel detail
show etherchannel port-channel
!
! === Verification d'un Channel Specifique ===
show etherchannel 1 summary
show etherchannel 1 detail
show etherchannel 1 port
!
! === Verification du Port-Channel ===
show interfaces port-channel 1
show interfaces port-channel 1 switchport
show interfaces port-channel 1 trunk
!
! === Verification des Ports Membres ===
show interfaces gi0/1 switchport
show interfaces gi0/2 switchport
show interfaces status
!
! === Load Balancing ===
show etherchannel load-balance
! Test de hash (quel lien pour un flux donne)
test etherchannel load-balance interface port-channel 1 mac AAAA.BBBB.CCCC DDDD.EEEE.FFFF
!
! === Compteurs et Statistiques ===
show interfaces port-channel 1 counters
show interfaces gi0/1 counters
show interfaces gi0/2 counters
!
! === Debug ===
debug etherchannel all
debug lacp all
debug pagp all
!
! Desactiver debug :
undebug all
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration EtherChannel ===${NC}"
    echo ""
    echo "1) Generer config LACP Trunk"
    echo "2) Generer config PAgP Trunk"
    echo "3) Generer config EtherChannel Layer 3"
    echo "4) Generer config complete (2 switches)"
    echo "5) Afficher commandes de troubleshooting"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-5] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration EtherChannel"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Hostname : " hostname
                read -p "Channel-group number : " cg
                read -p "Premier port (ex: 1) : " start
                read -p "Dernier port (ex: 4) : " end
                read -p "Mode (active/passive) : " mode
                read -p "VLANs autorises (ex: 10,20,30) : " vlans
                read -p "Native VLAN : " native
                echo ""
                generate_lacp_trunk_config "$hostname" "$cg" "$start" "$end" "$mode" "$vlans" "$native"
                ;;
            2)
                read -p "Hostname : " hostname
                read -p "Channel-group number : " cg
                read -p "Premier port (ex: 1) : " start
                read -p "Dernier port (ex: 2) : " end
                read -p "Mode (desirable/auto) : " mode
                read -p "VLANs autorises : " vlans
                echo ""
                generate_pagp_trunk_config "$hostname" "$cg" "$start" "$end" "$mode" "$vlans"
                ;;
            3)
                read -p "Hostname : " hostname
                read -p "Channel-group number : " cg
                read -p "Premier port (ex: 1) : " start
                read -p "Dernier port (ex: 2) : " end
                read -p "Adresse IP : " ip
                read -p "Masque : " mask
                echo ""
                generate_l3_etherchannel_config "$hostname" "$cg" "$start" "$end" "$ip" "$mask"
                ;;
            4)
                generate_full_topology_config
                ;;
            5)
                generate_troubleshooting_commands
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

# =============================================================================
# POINT D'ENTREE
# =============================================================================

main
