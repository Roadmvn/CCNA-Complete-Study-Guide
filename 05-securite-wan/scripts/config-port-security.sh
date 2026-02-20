#!/bin/bash

# =============================================================================
# Script : Configuration Port-Security, DHCP Snooping, DAI, IP Source Guard
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations de securite Layer 2 pour switches Cisco
#            Port-Security, Storm Control, IP Source Guard
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-port-security.log"

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}    Configuration Port-Security & Securite L2 - CCNA${NC}"
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
# FONCTION 1 : Port-Security basique avec Sticky MAC
# =============================================================================

generate_port_security_basic() {
    local start_port="$1"
    local end_port="$2"
    local max_mac="$3"
    local violation="$4"
    local vlan="$5"

    cat << EOF
!
! ============================================================
! Configuration Port-Security Basique avec Sticky MAC
! Ports : Fa0/$start_port a Fa0/$end_port
! Max MAC : $max_mac | Violation : $violation | VLAN : $vlan
! ============================================================
!
! Prerequis :
! - Les ports doivent etre en mode access
! - Ne PAS activer port-security sur un port trunk
!
configure terminal
!
! --- Etape 1 : Configurer les ports en mode access ---
interface range fastEthernet 0/$start_port - $end_port
 switchport mode access
 switchport access vlan $vlan
 no shutdown
!
! --- Etape 2 : Activer port-security avec sticky MAC ---
! sticky = apprend dynamiquement les MAC et les sauvegarde
!          dans la running-config (persistant apres write memory)
!
interface range fastEthernet 0/$start_port - $end_port
 switchport port-security
 switchport port-security maximum $max_mac
 switchport port-security violation $violation
 switchport port-security mac-address sticky
!
! Modes de violation :
! - shutdown  : desactive le port (err-disabled) + log + compteur
!               -> Necessite "shutdown / no shutdown" pour reactiver
! - restrict  : drop le trafic non autorise + log + compteur
!               -> Le port reste actif pour les MAC autorisees
! - protect   : drop le trafic non autorise silencieusement
!               -> Pas de log, pas de compteur
!
! Recommandation :
! - Postes utilisateurs : restrict (evite les interruptions)
! - Serveurs/imprimantes : shutdown (securite maximale)
!
end
!
! --- Verification ---
show port-security
show port-security interface fastEthernet 0/$start_port
show port-security address
!
write memory
EOF
}

# =============================================================================
# FONCTION 2 : Port-Security avec MAC statique
# =============================================================================

generate_port_security_static() {
    local port="$1"
    local mac_address="$2"
    local vlan="$3"

    cat << EOF
!
! ============================================================
! Configuration Port-Security avec MAC Statique
! Port : Fa0/$port | MAC : $mac_address | VLAN : $vlan
! ============================================================
!
! Cas d'usage : serveur, imprimante, equipement reseau fixe
! La MAC est definie manuellement (pas de sticky)
!
configure terminal
!
interface fastEthernet 0/$port
 switchport mode access
 switchport access vlan $vlan
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 switchport port-security mac-address $mac_address
 no shutdown
!
! Note : la MAC statique est enregistree dans la running-config
! Elle ne changera pas meme si un autre equipement est branche
!
end
!
! --- Verification ---
show port-security interface fastEthernet 0/$port
show port-security address
show mac address-table interface fastEthernet 0/$port
!
write memory
EOF
}

# =============================================================================
# FONCTION 3 : Port-Security pour environnement VoIP (IP Phone + PC)
# =============================================================================

generate_port_security_voip() {
    local start_port="$1"
    local end_port="$2"
    local data_vlan="$3"
    local voice_vlan="$4"

    cat << EOF
!
! ============================================================
! Configuration Port-Security pour VoIP (IP Phone + PC)
! Ports : Fa0/$start_port a Fa0/$end_port
! VLAN Data : $data_vlan | VLAN Voice : $voice_vlan
! ============================================================
!
! Topologie typique :
!
!   [Switch]---Fa0/x---[IP Phone]---[PC]
!                        |    |
!                   Voice VLAN  Data VLAN
!                    ($voice_vlan)      ($data_vlan)
!
! Le telephone IP a sa propre MAC et le PC a la sienne
! -> Besoin de maximum 3 MAC (PC + Phone + CDP/LLDP)
!
configure terminal
!
! --- Configuration VLAN Voice ---
vlan $voice_vlan
 name VOICE
!
! --- Configuration des ports VoIP ---
interface range fastEthernet 0/$start_port - $end_port
 switchport mode access
 switchport access vlan $data_vlan
 switchport voice vlan $voice_vlan
 switchport port-security
 switchport port-security maximum 3
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 no shutdown
!
! Explication maximum 3 :
! - 1 MAC pour le PC (data VLAN)
! - 1 MAC pour le telephone IP (voice VLAN)
! - 1 MAC supplementaire pour CDP/LLDP du telephone
!
! Note : Certains modeles de telephones peuvent necessiter
! maximum 4 si ils utilisent des MAC differentes pour
! le trafic voix et la signalisation
!
end
!
! --- Verification ---
show port-security
show port-security interface fastEthernet 0/$start_port
show interfaces fastEthernet 0/$start_port switchport
!
! Verifier le VLAN voice
show interfaces fastEthernet 0/$start_port trunk
!
write memory
EOF
}

# =============================================================================
# FONCTION 4 : Err-disable recovery automatique
# =============================================================================

generate_errdisable_recovery() {
    local interval="$1"

    cat << EOF
!
! ============================================================
! Configuration Err-Disable Recovery Automatique
! Interval : $interval secondes
! ============================================================
!
! Quand un port passe en err-disabled (violation shutdown),
! il reste desactive jusqu'a intervention manuelle.
! L'auto-recovery permet de reactiver automatiquement le port
! apres un delai configurable.
!
configure terminal
!
! --- Activer la recovery pour les violations port-security ---
errdisable recovery cause psecure-violation
!
! --- Activer aussi pour BPDU Guard (bonne pratique) ---
errdisable recovery cause bpduguard
!
! --- Activer pour DHCP rate-limit ---
errdisable recovery cause dhcp-rate-limit
!
! --- Activer pour ARP inspection ---
errdisable recovery cause arp-inspection
!
! --- Definir l'intervalle de recovery ---
! Valeur en secondes (defaut 300 = 5 minutes)
errdisable recovery interval $interval
!
! Note :
! - Le timer commence quand le port passe en err-disabled
! - Le port sera automatiquement reactive apres $interval secondes
! - Si la cause persiste, le port repassera en err-disabled
! - En production, 300-600 secondes est un bon compromis
!
end
!
! --- Verification ---
show errdisable recovery
show interfaces status err-disabled
!
! --- Recovery manuelle d'un port err-disabled ---
! interface fastEthernet 0/X
!  shutdown
!  no shutdown
!
write memory
EOF
}

# =============================================================================
# FONCTION 5 : Storm Control
# =============================================================================

generate_storm_control() {
    local start_port="$1"
    local end_port="$2"
    local broadcast_level="$3"
    local multicast_level="$4"
    local unicast_level="$5"

    cat << EOF
!
! ============================================================
! Configuration Storm Control
! Ports : Fa0/$start_port a Fa0/$end_port
! Broadcast : ${broadcast_level}% | Multicast : ${multicast_level}%
! Unicast : ${unicast_level}%
! ============================================================
!
! Storm Control protege contre les tempetes de broadcast,
! multicast et unicast inconnu qui peuvent saturer le reseau.
!
! Principe : si le trafic depasse le seuil configure (en %
! de la bande passante), le switch prend une action :
! - drop le trafic excedentaire (par defaut)
! - shutdown le port
! - generer un trap SNMP
!
configure terminal
!
interface range fastEthernet 0/$start_port - $end_port
!
! --- Limiter le broadcast ---
! Typiquement 10-20% pour un reseau bureautique
 storm-control broadcast level $broadcast_level
!
! --- Limiter le multicast ---
 storm-control multicast level $multicast_level
!
! --- Limiter l'unicast inconnu (flooding) ---
 storm-control unicast level $unicast_level
!
! --- Action en cas de depassement ---
! Par defaut : drop le trafic excedentaire
! Option : shutdown le port
 storm-control action shutdown
!
! --- Activer le trap SNMP (optionnel) ---
 storm-control action trap
!
end
!
! Seuils recommandes :
! +-------------------+----------+----------+
! | Type trafic       | Bureau   | Serveur  |
! +-------------------+----------+----------+
! | Broadcast         | 10-20%   | 5-10%    |
! | Multicast         | 10-20%   | 10-15%   |
! | Unicast inconnu   | 10-20%   | 5-10%    |
! +-------------------+----------+----------+
!
! --- Verification ---
show storm-control
show storm-control broadcast
show storm-control multicast
show storm-control unicast
show interfaces fastEthernet 0/$start_port counters storm-control
!
write memory
EOF
}

# =============================================================================
# FONCTION 6 : IP Source Guard
# =============================================================================

generate_ip_source_guard() {
    local start_port="$1"
    local end_port="$2"

    cat << EOF
!
! ============================================================
! Configuration IP Source Guard
! Ports : Fa0/$start_port a Fa0/$end_port
! ============================================================
!
! IP Source Guard filtre le trafic IP sur les ports access
! en verifiant que l'adresse IP source correspond a l'entree
! dans la binding table DHCP Snooping.
!
! Prerequis OBLIGATOIRE :
! - DHCP Snooping doit etre active (voir config-dhcp-snooping.sh)
! - Les clients doivent avoir obtenu leur IP via DHCP
!
! Chaine de protection L2 complete :
!
!   DHCP Snooping -> Binding Table -> DAI (verifie ARP)
!                                  -> IP Source Guard (verifie IP)
!                                  -> Port-Security (verifie MAC)
!
configure terminal
!
! --- Activer IP Source Guard sur les ports access ---
interface range fastEthernet 0/$start_port - $end_port
!
! Mode 1 : Filtrer par IP seulement
! ip verify source
!
! Mode 2 : Filtrer par IP ET MAC (plus securise)
 ip verify source port-security
!
! Note : le mode "port-security" necessite que port-security
! soit aussi active sur ces ports
!
end
!
! --- Pour les hotes a IP statique ---
! Il faut creer une entree statique dans la binding table :
!
! ip source binding AAAA.BBBB.CCCC vlan 10 10.1.10.100 interface Fa0/5
!
! --- Verification ---
show ip verify source
show ip source binding
show ip dhcp snooping binding
!
write memory
EOF
}

# =============================================================================
# FONCTION 7 : Desactivation des ports non utilises
# =============================================================================

generate_unused_ports_shutdown() {
    local start_port="$1"
    local end_port="$2"
    local parking_vlan="$3"

    cat << EOF
!
! ============================================================
! Desactivation des ports non utilises (Best Practice)
! Ports : Fa0/$start_port a Fa0/$end_port
! VLAN Parking : $parking_vlan
! ============================================================
!
! Bonne pratique de securite :
! - Desactiver (shutdown) tous les ports non utilises
! - Les placer dans un VLAN "parking" isole
! - Aucun trafic ne peut transiter par ce VLAN
!
configure terminal
!
! --- Creer le VLAN parking ---
vlan $parking_vlan
 name PARKING_UNUSED
!
! --- Configurer les ports inutilises ---
interface range fastEthernet 0/$start_port - $end_port
 switchport mode access
 switchport access vlan $parking_vlan
 switchport nonegotiate
 spanning-tree portfast
 shutdown
!
! Commandes supplementaires (optionnel) :
! - switchport nonegotiate : desactive DTP (anti VLAN hopping)
! - spanning-tree portfast : evite le delai STP si le port
!   est reactive accidentellement
!
end
!
! --- Verification ---
show interfaces status | include disabled
show vlan id $parking_vlan
!
write memory
EOF
}

# =============================================================================
# FONCTION 8 : Configuration securite complete (all-in-one)
# =============================================================================

generate_complete_security_config() {
    cat << EOF
!
! ============================================================
! Configuration Securite L2 Complete - Switch Access
! ============================================================
!
! Ce template combine toutes les protections L2 recommandees
! pour un switch d'acces en environnement entreprise.
!
! Topologie de reference :
!
!   +-----------------------------------------------+
!   |           SW-ACCESS-01 (Catalyst 2960)        |
!   +-----------------------------------------------+
!   | Fa0/1-20  : Postes utilisateurs  (VLAN 10)   |
!   | Fa0/21-22 : Imprimantes          (VLAN 10)   |
!   | Fa0/23-24 : Telephones VoIP      (VLAN 10+50)|
!   | Gi0/1     : Trunk vers SW-DISTRIB (trusted)   |
!   | Gi0/2     : Trunk vers SW-DISTRIB (trusted)   |
!   | Fa0/25-48 : Non utilises          (VLAN 999) |
!   +-----------------------------------------------+
!
configure terminal
!
hostname SW-ACCESS-01
!
! ===========================================
! PARTIE 1 : VLANs
! ===========================================
!
vlan 10
 name DATA
vlan 50
 name VOICE
vlan 999
 name PARKING_UNUSED
!
! ===========================================
! PARTIE 2 : Trunks (vers distribution)
! ===========================================
!
interface range gigabitEthernet 0/1 - 2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,50,999
 switchport nonegotiate
 no shutdown
!
! ===========================================
! PARTIE 3 : Ports utilisateurs (Fa0/1-20)
! ===========================================
!
interface range fastEthernet 0/1 - 20
 description Postes utilisateurs
 switchport mode access
 switchport access vlan 10
 switchport nonegotiate
 spanning-tree portfast
 spanning-tree bpduguard enable
!
! Port-Security : sticky, max 2, restrict
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation restrict
 switchport port-security mac-address sticky
!
! Storm Control
 storm-control broadcast level 20
 storm-control multicast level 20
 storm-control unicast level 20
 storm-control action shutdown
!
! IP Source Guard
 ip verify source port-security
!
 no shutdown
!
! ===========================================
! PARTIE 4 : Imprimantes (Fa0/21-22)
! ===========================================
!
interface range fastEthernet 0/21 - 22
 description Imprimantes reseau
 switchport mode access
 switchport access vlan 10
 switchport nonegotiate
 spanning-tree portfast
 spanning-tree bpduguard enable
!
! Port-Security : max 1, shutdown (critique)
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 switchport port-security mac-address sticky
!
 no shutdown
!
! ===========================================
! PARTIE 5 : Telephones VoIP (Fa0/23-24)
! ===========================================
!
interface range fastEthernet 0/23 - 24
 description Postes VoIP (Phone + PC)
 switchport mode access
 switchport access vlan 10
 switchport voice vlan 50
 switchport nonegotiate
 spanning-tree portfast
 spanning-tree bpduguard enable
!
! Port-Security : max 3 (PC + Phone + CDP)
 switchport port-security
 switchport port-security maximum 3
 switchport port-security violation restrict
 switchport port-security mac-address sticky
!
 no shutdown
!
! ===========================================
! PARTIE 6 : Ports non utilises (Fa0/25-48)
! ===========================================
!
interface range fastEthernet 0/25 - 48
 description UNUSED - PARKING
 switchport mode access
 switchport access vlan 999
 switchport nonegotiate
 spanning-tree portfast
 shutdown
!
! ===========================================
! PARTIE 7 : Err-disable recovery
! ===========================================
!
errdisable recovery cause psecure-violation
errdisable recovery cause bpduguard
errdisable recovery cause dhcp-rate-limit
errdisable recovery cause arp-inspection
errdisable recovery interval 300
!
end
!
! --- Verification globale ---
show port-security
show port-security address
show storm-control
show ip verify source
show interfaces status
show interfaces status err-disabled
show errdisable recovery
show vlan brief
!
write memory
EOF
}

# =============================================================================
# FONCTION 9 : Commandes de verification et troubleshooting
# =============================================================================

generate_verification_commands() {
    cat << EOF
!
! ============================================================
! Commandes de Verification et Troubleshooting - Securite L2
! ============================================================
!
! === PORT-SECURITY ===
!
! Vue d'ensemble de tous les ports securises
show port-security
!
! Detail d'un port specifique
show port-security interface fastEthernet 0/1
! -> Affiche : status, violation count, max MAC, mode violation
!
! Table des MAC apprises (sticky et statiques)
show port-security address
!
! === STORM CONTROL ===
!
show storm-control
show storm-control broadcast
show storm-control multicast
show storm-control unicast
!
! === IP SOURCE GUARD ===
!
show ip verify source
show ip source binding
!
! === ERR-DISABLED ===
!
! Ports actuellement en err-disabled
show interfaces status err-disabled
!
! Configuration de recovery
show errdisable recovery
!
! === TROUBLESHOOTING ===
!
! Probleme : port en err-disabled
! Solution manuelle :
! interface fastEthernet 0/X
!  shutdown
!  no shutdown
!
! Probleme : PC ne peut pas se connecter (MAC non autorisee)
! Diagnostic :
show port-security interface fastEthernet 0/1
show mac address-table interface fastEthernet 0/1
!
! Probleme : trop de violations sur un port
! Verifier le nombre de MAC et ajuster si necessaire :
! interface fastEthernet 0/X
!  switchport port-security maximum 3
!
! Probleme : MAC sticky incorrecte
! Supprimer les MAC sticky et recommencer :
! clear port-security sticky interface fastEthernet 0/X
! ou supprimer manuellement :
! no switchport port-security mac-address sticky AAAA.BBBB.CCCC
!
! === COMPTEURS ET STATISTIQUES ===
!
show interfaces fastEthernet 0/1 counters
show interfaces counters errors
!
! Reset des compteurs de violation :
! clear port-security all
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration Port-Security & Securite L2 ===${NC}"
    echo ""
    echo -e " ${CYAN}1)${NC} Port-Security basique (sticky MAC)"
    echo -e " ${CYAN}2)${NC} Port-Security avec MAC statique"
    echo -e " ${CYAN}3)${NC} Port-Security pour VoIP (Phone + PC)"
    echo -e " ${CYAN}4)${NC} Err-disable recovery automatique"
    echo -e " ${CYAN}5)${NC} Storm Control"
    echo -e " ${CYAN}6)${NC} IP Source Guard"
    echo -e " ${CYAN}7)${NC} Desactivation ports non utilises"
    echo -e " ${CYAN}8)${NC} Configuration securite complete (all-in-one)"
    echo -e " ${CYAN}9)${NC} Commandes de verification / troubleshooting"
    echo -e " ${RED}0)${NC} Quitter"
    echo ""
    read -p "Votre choix [0-9] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration Port-Security"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Premier port (ex: 1) : " start_port
                read -p "Dernier port (ex: 24) : " end_port
                read -p "Max MAC par port (defaut 2) : " max_mac
                max_mac=${max_mac:-2}
                read -p "Mode violation [shutdown/restrict/protect] (defaut restrict) : " violation
                violation=${violation:-restrict}
                read -p "VLAN (defaut 10) : " vlan
                vlan=${vlan:-10}
                echo ""
                log_message "Generation config port-security basique Fa0/$start_port-$end_port"
                generate_port_security_basic "$start_port" "$end_port" "$max_mac" "$violation" "$vlan"
                ;;
            2)
                read -p "Numero du port (ex: 5) : " port
                read -p "Adresse MAC (format AAAA.BBBB.CCCC) : " mac_address
                read -p "VLAN (defaut 10) : " vlan
                vlan=${vlan:-10}
                echo ""
                log_message "Generation config port-security statique Fa0/$port MAC=$mac_address"
                generate_port_security_static "$port" "$mac_address" "$vlan"
                ;;
            3)
                read -p "Premier port VoIP (ex: 1) : " start_port
                read -p "Dernier port VoIP (ex: 24) : " end_port
                read -p "VLAN Data (defaut 10) : " data_vlan
                data_vlan=${data_vlan:-10}
                read -p "VLAN Voice (defaut 50) : " voice_vlan
                voice_vlan=${voice_vlan:-50}
                echo ""
                log_message "Generation config port-security VoIP Fa0/$start_port-$end_port"
                generate_port_security_voip "$start_port" "$end_port" "$data_vlan" "$voice_vlan"
                ;;
            4)
                read -p "Intervalle de recovery en secondes (defaut 300) : " interval
                interval=${interval:-300}
                echo ""
                log_message "Generation config err-disable recovery ($interval sec)"
                generate_errdisable_recovery "$interval"
                ;;
            5)
                read -p "Premier port (ex: 1) : " start_port
                read -p "Dernier port (ex: 24) : " end_port
                read -p "Seuil broadcast % (defaut 20) : " broadcast_level
                broadcast_level=${broadcast_level:-20}
                read -p "Seuil multicast % (defaut 20) : " multicast_level
                multicast_level=${multicast_level:-20}
                read -p "Seuil unicast % (defaut 20) : " unicast_level
                unicast_level=${unicast_level:-20}
                echo ""
                log_message "Generation config storm-control Fa0/$start_port-$end_port"
                generate_storm_control "$start_port" "$end_port" "$broadcast_level" "$multicast_level" "$unicast_level"
                ;;
            6)
                read -p "Premier port (ex: 1) : " start_port
                read -p "Dernier port (ex: 24) : " end_port
                echo ""
                log_message "Generation config IP Source Guard Fa0/$start_port-$end_port"
                generate_ip_source_guard "$start_port" "$end_port"
                ;;
            7)
                read -p "Premier port inutilise (ex: 25) : " start_port
                read -p "Dernier port inutilise (ex: 48) : " end_port
                read -p "VLAN parking (defaut 999) : " parking_vlan
                parking_vlan=${parking_vlan:-999}
                echo ""
                log_message "Generation config shutdown ports Fa0/$start_port-$end_port -> VLAN $parking_vlan"
                generate_unused_ports_shutdown "$start_port" "$end_port" "$parking_vlan"
                ;;
            8)
                log_message "Generation config securite complete (all-in-one)"
                generate_complete_security_config
                ;;
            9)
                generate_verification_commands
                ;;
            0)
                log_message "Arret du script"
                echo -e "${GREEN}Au revoir !${NC}"
                break
                ;;
            *)
                echo -e "${RED}Choix invalide. Veuillez entrer un nombre entre 0 et 9.${NC}"
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
