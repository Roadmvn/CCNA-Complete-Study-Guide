#!/bin/bash

# =============================================================================
# Script : Configuration ACLs - Cisco CCNA
# Auteur : Tudy Gbaguidi
# Date   : 2024
# Objectif : Generer des configurations ACLs pour routeurs Cisco
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-acls.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration ACLs - CCNA${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $1"
}

# =============================================================================
# GENERATEURS DE CONFIGURATION ACLs
# =============================================================================

generate_acl_standard() {
    cat << EOF
!
! =============================================
! ACL Standard Numerotee
! =============================================
! Placement : PRES DE LA DESTINATION
!
! Scenario : Autoriser uniquement 10.1.1.0/24 a acceder au serveur
!
access-list 10 permit 10.1.1.0 0.0.0.255
access-list 10 deny any log
!
! Appliquer sur l'interface pres de la destination (OUT)
interface GigabitEthernet 0/2
 ip access-group 10 out
 exit
!
! --- ACL Standard Nommee (recommandee) ---
!
ip access-list standard ALLOW-MGMT
 permit 10.1.1.0 0.0.0.255
 permit 10.1.2.0 0.0.0.255
 deny any log
 exit
!
interface GigabitEthernet 0/2
 ip access-group ALLOW-MGMT out
 exit
!
! Verification :
! show access-lists
! show ip interface GigabitEthernet 0/2
!
end
EOF
}

generate_acl_extended() {
    cat << EOF
!
! =============================================
! ACL Etendue Nommee
! =============================================
! Placement : PRES DE LA SOURCE
!
! Scenario : Filtrage Web pour les utilisateurs (VLAN 10)
! - Autoriser HTTP (80) et HTTPS (443)
! - Autoriser DNS (53)
! - Autoriser ICMP (ping)
! - Bloquer tout autre acces vers les serveurs (VLAN 30)
! - Autoriser le reste
!
ip access-list extended USERS-WEB-FILTER
 remark --- Autorise navigation web ---
 permit tcp 10.1.10.0 0.0.0.255 any eq 80
 permit tcp 10.1.10.0 0.0.0.255 any eq 443
 remark --- Autorise DNS ---
 permit udp 10.1.10.0 0.0.0.255 any eq 53
 permit tcp 10.1.10.0 0.0.0.255 any eq 53
 remark --- Autorise ICMP ---
 permit icmp 10.1.10.0 0.0.0.255 any
 remark --- Bloque acces aux serveurs ---
 deny ip 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255 log
 remark --- Autorise tout le reste ---
 permit ip any any
 exit
!
! Appliquer sur l'interface Users (IN = trafic entrant des users)
interface GigabitEthernet 0/0
 ip access-group USERS-WEB-FILTER in
 exit
!
! Verification :
! show access-lists USERS-WEB-FILTER
! show ip interface GigabitEthernet 0/0
!
end
EOF
}

generate_acl_admin_access() {
    cat << EOF
!
! =============================================
! ACL pour Securiser l'Acces VTY (SSH/Telnet)
! =============================================
!
! Autoriser uniquement le reseau admin a se connecter en SSH
!
ip access-list standard VTY-ACCESS
 permit 10.1.20.0 0.0.0.255
 deny any log
 exit
!
line vty 0 4
 access-class VTY-ACCESS in
 transport input ssh
 login local
 exit
!
line vty 5 15
 access-class VTY-ACCESS in
 transport input ssh
 login local
 exit
!
! Creation utilisateur local pour SSH
username admin privilege 15 secret AdminP@ss123
!
! Configuration SSH
ip domain-name entreprise.local
crypto key generate rsa modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
!
end
EOF
}

generate_acl_security_complete() {
    cat << EOF
!
! =============================================
! Politique de Securite Complete par ACLs
! =============================================
!
! Topologie :
!   VLAN 10 (Users)     : 10.1.10.0/24 - Gi0/0
!   VLAN 20 (Admins)    : 10.1.20.0/24 - Gi0/1
!   VLAN 30 (Serveurs)  : 10.1.30.0/24 - Gi0/2
!   VLAN 40 (DMZ)       : 10.1.40.0/24 - Gi0/3
!
! Politique :
!   1. Users   -> Web + DNS uniquement vers Serveurs/DMZ
!   2. Admins  -> Acces complet partout
!   3. Serveurs-> Reponses uniquement (pas d'initiation vers Users)
!   4. DMZ     -> Acces Internet, pas vers LAN interne
!   5. Telnet interdit partout
!
! --- ACL Users (Gi0/0 IN) ---
ip access-list extended VLAN10-USERS
 remark --- Web et DNS uniquement ---
 permit tcp 10.1.10.0 0.0.0.255 any eq 80
 permit tcp 10.1.10.0 0.0.0.255 any eq 443
 permit udp 10.1.10.0 0.0.0.255 any eq 53
 permit tcp 10.1.10.0 0.0.0.255 any eq 53
 permit icmp 10.1.10.0 0.0.0.255 any
 deny ip 10.1.10.0 0.0.0.255 10.1.30.0 0.0.0.255 log
 deny ip 10.1.10.0 0.0.0.255 10.1.40.0 0.0.0.255 log
 permit ip any any
 exit
!
interface GigabitEthernet 0/0
 ip access-group VLAN10-USERS in
 exit
!
! --- ACL DMZ (Gi0/3 IN) ---
ip access-list extended VLAN40-DMZ
 remark --- DMZ ne peut pas initier vers LAN ---
 deny ip 10.1.40.0 0.0.0.255 10.1.10.0 0.0.0.255 log
 deny ip 10.1.40.0 0.0.0.255 10.1.20.0 0.0.0.255 log
 deny ip 10.1.40.0 0.0.0.255 10.1.30.0 0.0.0.255 log
 permit ip any any
 exit
!
interface GigabitEthernet 0/3
 ip access-group VLAN40-DMZ in
 exit
!
! --- ACL Anti-Telnet (Gi0/2 OUT) ---
ip access-list extended NO-TELNET
 deny tcp any any eq 23 log
 permit ip any any
 exit
!
interface GigabitEthernet 0/2
 ip access-group NO-TELNET out
 exit
!
! --- ACL VTY (acces SSH admins uniquement) ---
ip access-list standard VTY-ADMIN
 permit 10.1.20.0 0.0.0.255
 deny any log
 exit
!
line vty 0 15
 access-class VTY-ADMIN in
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
    echo -e "${BLUE}=== Menu Configuration ACLs ===${NC}"
    echo ""
    echo "1) Generer ACL Standard (numerotee + nommee)"
    echo "2) Generer ACL Etendue (filtrage web)"
    echo "3) Generer ACL Securite VTY (SSH)"
    echo "4) Generer Politique Securite Complete"
    echo "5) Afficher aide-memoire ACLs"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-5] : " choice
    echo ""
}

show_acl_cheatsheet() {
    echo -e "${BLUE}=== Aide-Memoire ACLs ===${NC}"
    echo ""
    echo "TYPES :"
    echo "  Standard  : 1-99, 1300-1999  | Source seulement | Pres destination"
    echo "  Etendue   : 100-199, 2000-2699 | Src+Dst+Port   | Pres source"
    echo ""
    echo "SYNTAXE :"
    echo "  Standard : access-list [N] {permit|deny} [source] [wildcard]"
    echo "  Etendue  : access-list [N] {permit|deny} [proto] [src] [wc] [dst] [wc] [op] [port]"
    echo ""
    echo "APPLICATION :"
    echo "  Interface : ip access-group [N/NOM] {in|out}"
    echo "  VTY      : access-class [N/NOM] in"
    echo ""
    echo "WILDCARD = 255.255.255.255 - Masque"
    echo "  host X.X.X.X = 0.0.0.0 (1 hote)"
    echo "  any = 0.0.0.0 255.255.255.255 (tout)"
    echo ""
    echo "VERIFICATION :"
    echo "  show access-lists"
    echo "  show ip interface [intf]"
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script ACLs"

    while true; do
        show_menu

        case $choice in
            1)
                local config_file="$SCRIPT_DIR/acl-standard-config.txt"
                generate_acl_standard > "$config_file"
                log_message "Config ACL Standard generee : $config_file"
                ;;
            2)
                local config_file="$SCRIPT_DIR/acl-extended-config.txt"
                generate_acl_extended > "$config_file"
                log_message "Config ACL Etendue generee : $config_file"
                ;;
            3)
                local config_file="$SCRIPT_DIR/acl-vty-config.txt"
                generate_acl_admin_access > "$config_file"
                log_message "Config ACL VTY generee : $config_file"
                ;;
            4)
                local config_file="$SCRIPT_DIR/acl-security-complete.txt"
                generate_acl_security_complete > "$config_file"
                log_message "Config Securite Complete generee : $config_file"
                ;;
            5)
                show_acl_cheatsheet
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
