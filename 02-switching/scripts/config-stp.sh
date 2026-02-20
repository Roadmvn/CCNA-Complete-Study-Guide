#!/bin/bash

# =============================================================================
# Script : Configuration STP - Cisco CCNA
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations STP pour equipements Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-stp.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration STP - CCNA${NC}"
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
# CONFIGURATIONS STP PREDEFINIES
# =============================================================================

generate_root_bridge_config() {
    local hostname="$1"
    local vlans="$2"
    local priority="$3"

    cat << EOF
!
! Configuration Root Bridge STP - $hostname
!
hostname $hostname
!
! Activation Rapid PVST+ (recommande)
spanning-tree mode rapid-pvst
!
! Configuration Root Bridge
! Priority $priority pour VLANs $vlans
spanning-tree vlan $vlans priority $priority
!
! Timers STP (optionnel, valeurs par defaut recommandees)
! spanning-tree vlan $vlans hello-time 2
! spanning-tree vlan $vlans forward-time 15
! spanning-tree vlan $vlans max-age 20
!
! Verification :
! show spanning-tree
! show spanning-tree root
! show spanning-tree vlan $vlans
!
end
EOF
}

generate_secondary_root_config() {
    local hostname="$1"
    local vlans="$2"

    cat << EOF
!
! Configuration Root Bridge Secondaire - $hostname
!
hostname $hostname
!
spanning-tree mode rapid-pvst
!
! Root secondaire (priority 28672 par defaut)
spanning-tree vlan $vlans root secondary
!
! Verification :
! show spanning-tree
! show spanning-tree root
!
end
EOF
}

generate_portfast_bpduguard_config() {
    local start_port="$1"
    local end_port="$2"

    cat << EOF
!
! Configuration PortFast et BPDU Guard
! Ports access : Fa0/$start_port a Fa0/$end_port
!
! Methode 1 : Configuration par plage
interface range fastethernet 0/$start_port-$end_port
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! Methode 2 : Configuration globale (tous ports access)
! spanning-tree portfast default
! spanning-tree portfast bpduguard default
!
! Configuration Root Guard (sur ports vers switches en aval)
! interface gi0/1
!  spanning-tree guard root
!  exit
!
! Configuration Loop Guard (ports non-designated)
! interface gi0/2
!  spanning-tree guard loop
!  exit
!
! Verification :
! show spanning-tree interface fa0/$start_port detail
! show spanning-tree interface fa0/$start_port portfast
! show spanning-tree inconsistentports
!
end
EOF
}

generate_stp_optimization_config() {
    cat << EOF
!
! Configuration STP Optimisee - Infrastructure Complete
!
! ===============================================
! SW-CORE-1 : Root Bridge Principal
! ===============================================
!
hostname SW-CORE-1
!
spanning-tree mode rapid-pvst
!
! Root pour VLANs pairs
spanning-tree vlan 10,20,30 priority 4096
! Secondary pour VLANs impairs
spanning-tree vlan 11,21,31 priority 8192
!
! Ports vers switches access : Designated Ports
! Pas de configuration speciale necessaire
!
! ===============================================
! SW-CORE-2 : Root Bridge Secondaire
! ===============================================
!
hostname SW-CORE-2
!
spanning-tree mode rapid-pvst
!
! Root pour VLANs impairs
spanning-tree vlan 11,21,31 priority 4096
! Secondary pour VLANs pairs
spanning-tree vlan 10,20,30 priority 8192
!
! ===============================================
! SW-ACCESS : Switches Access
! ===============================================
!
hostname SW-ACCESS-X
!
spanning-tree mode rapid-pvst
!
! PortFast sur tous les ports access
spanning-tree portfast default
!
! BPDU Guard global sur ports PortFast
spanning-tree portfast bpduguard default
!
! Auto-recovery pour ports err-disabled
errdisable recovery cause bpduguard
errdisable recovery interval 300
!
! Ports access (exemple)
interface range fa0/1-24
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! Ports trunk vers distribution/core
interface range gi0/1-2
 spanning-tree guard root
 exit
!
! Verification complete :
! show spanning-tree
! show spanning-tree root
! show spanning-tree blockedports
! show spanning-tree inconsistentports
! show errdisable recovery
!
end
EOF
}

generate_stp_troubleshooting_commands() {
    cat << EOF
!
! Commandes de Troubleshooting STP
!
! === Verification Globale ===
show spanning-tree
show spanning-tree summary
show spanning-tree root
show spanning-tree bridge
!
! === Verification par VLAN ===
show spanning-tree vlan 10
show spanning-tree vlan 10 brief
show spanning-tree vlan 10 detail
!
! === Verification par Interface ===
show spanning-tree interface fa0/1
show spanning-tree interface fa0/1 detail
show spanning-tree interface fa0/1 portfast
!
! === Verification des Problemes ===
show spanning-tree blockedports
show spanning-tree inconsistentports
show spanning-tree pathcost method
!
! === Verification err-disabled ===
show interfaces status err-disabled
show errdisable recovery
!
! === Debug (attention en production) ===
debug spanning-tree events
debug spanning-tree bpdu
!
! Desactiver debug :
undebug all
!
! === Monitoring ===
show processes cpu | include spanning
show logging | include SPANTREE
show logging | include BPDU
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration STP ===${NC}"
    echo ""
    echo "1) Generer config Root Bridge Primary"
    echo "2) Generer config Root Bridge Secondary"
    echo "3) Generer config PortFast + BPDU Guard"
    echo "4) Generer config STP Optimisee (infrastructure complete)"
    echo "5) Afficher commandes de troubleshooting STP"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-5] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration STP"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Hostname du switch : " hostname
                read -p "VLANs (ex: 1-100 ou 10,20,30) : " vlans
                read -p "Priority (defaut 4096) : " priority
                priority=${priority:-4096}
                echo ""
                generate_root_bridge_config "$hostname" "$vlans" "$priority"
                ;;
            2)
                read -p "Hostname du switch : " hostname
                read -p "VLANs (ex: 1-100 ou 10,20,30) : " vlans
                echo ""
                generate_secondary_root_config "$hostname" "$vlans"
                ;;
            3)
                read -p "Premier port access (ex: 1) : " start_port
                read -p "Dernier port access (ex: 24) : " end_port
                echo ""
                generate_portfast_bpduguard_config "$start_port" "$end_port"
                ;;
            4)
                generate_stp_optimization_config
                ;;
            5)
                generate_stp_troubleshooting_commands
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
