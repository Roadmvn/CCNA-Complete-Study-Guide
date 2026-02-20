#!/bin/bash

# =============================================================================
# Script : Configuration Port-Security - Cisco CCNA
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations port-security pour equipements Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-port-security.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration Port-Security - CCNA${NC}"
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
# CONFIGURATIONS PORT-SECURITY
# =============================================================================

generate_basic_port_security() {
    local vlan="$1"
    local start_port="$2"
    local end_port="$3"
    local max_mac="$4"
    local violation_mode="$5"

    cat << EOF
!
! Configuration Port-Security de Base
! Ports Fa0/$start_port a Fa0/$end_port - VLAN $vlan
!
! Etape 1 : Configurer les ports en mode access
interface range fastethernet 0/$start_port-$end_port
 switchport mode access
 switchport access vlan $vlan
 exit
!
! Etape 2 : Activer port-security
interface range fastethernet 0/$start_port-$end_port
 switchport port-security
 switchport port-security maximum $max_mac
 switchport port-security violation $violation_mode
 exit
!
! Verification :
! show port-security
! show port-security interface fa0/$start_port
! show port-security address
!
end
EOF
}

generate_sticky_port_security() {
    local vlan="$1"
    local start_port="$2"
    local end_port="$3"
    local max_mac="$4"

    cat << EOF
!
! Configuration Port-Security avec Sticky MAC
! Les adresses MAC sont apprises dynamiquement et
! sauvegardees dans la running-config
!
interface range fastethernet 0/$start_port-$end_port
 switchport mode access
 switchport access vlan $vlan
 switchport port-security
 switchport port-security maximum $max_mac
 switchport port-security violation shutdown
 switchport port-security mac-address sticky
 exit
!
! Les MACs apprises apparaitront dans la config comme :
! switchport port-security mac-address sticky XXXX.XXXX.XXXX
!
! Pour persister les MACs apres reboot :
! copy running-config startup-config
!
! Verification :
! show port-security interface fa0/$start_port
! show port-security address
! show running-config interface fa0/$start_port
!
end
EOF
}

generate_static_mac_security() {
    local interface="$1"
    local vlan="$2"
    local mac_address="$3"

    cat << EOF
!
! Configuration Port-Security avec MAC Statique
! Port $interface - VLAN $vlan
!
interface $interface
 switchport mode access
 switchport access vlan $vlan
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 switchport port-security mac-address $mac_address
 exit
!
! Seule l'adresse MAC $mac_address est autorisee
! Toute autre adresse declenchera la violation
!
! Verification :
! show port-security interface $interface
! show port-security address
!
end
EOF
}

generate_complete_security_config() {
    cat << EOF
!
! Configuration Port-Security Complete - Switch Access
!
hostname SW-ACCESS
!
! ===============================================
! VLANs
! ===============================================
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
! ===============================================
! Ports Utilisateurs - VLAN 10 (Sticky, Shutdown)
! ===============================================
! Configuration securisee pour postes utilisateurs
! Maximum 2 MACs (PC + telephone IP)
!
interface range fastethernet 0/1-8
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation shutdown
 switchport port-security mac-address sticky
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! ===============================================
! Ports IT - VLAN 20 (Sticky, Restrict)
! ===============================================
! Mode restrict : drop + log mais port reste up
! Utile pour IT qui peut changer de poste
!
interface range fastethernet 0/9-16
 switchport mode access
 switchport access vlan 20
 switchport port-security
 switchport port-security maximum 3
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! ===============================================
! Ports Serveurs - VLAN 30 (Static, Shutdown)
! ===============================================
! MACs statiques pour les serveurs (plus securise)
!
interface fastethernet 0/17
 switchport mode access
 switchport access vlan 30
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 switchport port-security mac-address 0001.0001.0001
 description "Serveur Web"
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
interface fastethernet 0/18
 switchport mode access
 switchport access vlan 30
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 switchport port-security mac-address 0002.0002.0002
 description "Serveur DB"
 spanning-tree portfast
 spanning-tree bpduguard enable
 exit
!
! ===============================================
! Ports Inutilises - SECURISATION
! ===============================================
! Desactiver tous les ports non utilises
!
interface range fastethernet 0/19-24
 shutdown
 switchport mode access
 switchport access vlan 999
 exit
!
! VLAN 999 "Black Hole" pour ports non utilises
vlan 999
 name BlackHole
 exit
!
! ===============================================
! Trunk Ports (pas de port-security)
! ===============================================
interface range gigabitethernet 0/1-2
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,99
 switchport trunk native vlan 99
 switchport nonegotiate
 exit
!
! ===============================================
! Auto-Recovery pour ports err-disabled
! ===============================================
errdisable recovery cause psecure-violation
errdisable recovery cause bpduguard
errdisable recovery interval 300
!
! ===============================================
! VERIFICATION POST-CONFIGURATION
! ===============================================
!
! show port-security
! show port-security interface fa0/1
! show port-security address
! show interfaces status err-disabled
! show errdisable recovery
! show vlan brief
!
end
EOF
}

generate_recovery_commands() {
    cat << EOF
!
! Commandes de Recovery et Troubleshooting Port-Security
!
! === Verification de l'Etat ===
show port-security
show port-security interface fa0/1
show port-security address
!
! === Ports err-disabled ===
show interfaces status err-disabled
show errdisable recovery
!
! === Recovery Manuelle d'un Port ===
! (remplacer fa0/1 par le port concerne)
interface fa0/1
 shutdown
 no shutdown
 exit
!
! === Configurer Auto-Recovery ===
! Recuperation automatique apres 300 secondes
errdisable recovery cause psecure-violation
errdisable recovery interval 300
!
! === Supprimer une MAC Securisee ===
! (pour permettre un nouveau device)
clear port-security sticky interface fa0/1
! ou
no switchport port-security mac-address sticky XXXX.XXXX.XXXX
!
! === Reinitialiser les Compteurs ===
clear port-security all
!
! === Logs et Monitoring ===
show logging | include SEC_VIOLATION
show logging | include PSECURE
show logging | include err-disabled
!
! === Debug ===
debug port-security
undebug all
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration Port-Security ===${NC}"
    echo ""
    echo "1) Generer config port-security basique"
    echo "2) Generer config sticky MAC"
    echo "3) Generer config MAC statique (1 port)"
    echo "4) Generer config complete (switch access)"
    echo "5) Afficher commandes recovery/troubleshooting"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-5] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration port-security"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "VLAN : " vlan
                read -p "Premier port (ex: 1) : " start
                read -p "Dernier port (ex: 8) : " end
                read -p "Max MAC addresses : " max_mac
                read -p "Mode violation (shutdown/restrict/protect) : " mode
                echo ""
                generate_basic_port_security "$vlan" "$start" "$end" "$max_mac" "$mode"
                ;;
            2)
                read -p "VLAN : " vlan
                read -p "Premier port (ex: 1) : " start
                read -p "Dernier port (ex: 8) : " end
                read -p "Max MAC addresses : " max_mac
                echo ""
                generate_sticky_port_security "$vlan" "$start" "$end" "$max_mac"
                ;;
            3)
                read -p "Interface (ex: fa0/1) : " interface
                read -p "VLAN : " vlan
                read -p "Adresse MAC (ex: AAAA.BBBB.CCCC) : " mac
                echo ""
                generate_static_mac_security "$interface" "$vlan" "$mac"
                ;;
            4)
                generate_complete_security_config
                ;;
            5)
                generate_recovery_commands
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
