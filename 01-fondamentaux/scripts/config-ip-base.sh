#!/bin/bash

# =============================================================================
# Script : Configuration IP de Base - Cisco CCNA
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Automatiser les configurations IP de base sur équipements Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-ip-base.log"

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration IP de Base - CCNA${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $message"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $message"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] WARNING: $message" >> "$LOG_FILE"
    echo -e "${YELLOW}[WARNING]${NC} $message"
}

# =============================================================================
# FONCTIONS DE VALIDATION
# =============================================================================

validate_ip() {
    local ip="$1"
    local pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ $ip =~ $pattern ]]; then
        # Vérifier chaque octet (0-255)
        IFS='.' read -ra OCTETS <<< "$ip"
        for octet in "${OCTETS[@]}"; do
            if [[ $octet -lt 0 || $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

validate_cidr() {
    local cidr="$1"
    if [[ $cidr =~ ^[0-9]+$ ]] && [[ $cidr -ge 8 && $cidr -le 30 ]]; then
        return 0
    else
        return 1
    fi
}

validate_interface() {
    local interface="$1"
    local pattern="^(fastethernet|gigabitethernet|fa|gi|ethernet|eth)[0-9]+/[0-9]+$"
    
    if [[ $interface =~ $pattern ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# GÉNÉRATEURS DE CONFIGURATION
# =============================================================================

generate_router_config() {
    local hostname="$1"
    local interface="$2"
    local ip_address="$3"
    local subnet_mask="$4"
    local description="$5"
    
    cat << EOF
!
! Configuration de base - Router $hostname
! Généré automatiquement le $(date)
!
hostname $hostname
!
! Configuration interface $interface
interface $interface
 description $description
 ip address $ip_address $subnet_mask
 no shutdown
 exit
!
! Configuration de base sécurité
enable secret cisco123
line console 0
 password console123
 login
 exit
line vty 0 4
 password vty123
 login
 exit
!
! Configuration services
service password-encryption
no ip domain-lookup
ip domain-name ccna.lab
!
! Sauvegarde configuration
copy running-config startup-config
!
end
EOF
}

generate_switch_config() {
    local hostname="$1"
    local management_ip="$2"
    local subnet_mask="$3"
    local default_gateway="$4"
    
    cat << EOF
!
! Configuration de base - Switch $hostname  
! Généré automatiquement le $(date)
!
hostname $hostname
!
! Configuration VLAN de management
interface vlan 1
 description Management VLAN
 ip address $management_ip $subnet_mask
 no shutdown
 exit
!
! Configuration passerelle par défaut
ip default-gateway $default_gateway
!
! Configuration de base sécurité
enable secret cisco123
line console 0
 password console123
 login
 exit
line vty 0 15
 password vty123
 login
 exit
!
! Configuration services
service password-encryption
no ip domain-lookup
ip domain-name ccna.lab
!
! Sauvegarde configuration
copy running-config startup-config
!
end
EOF
}

generate_multi_interface_config() {
    local hostname="$1"
    shift
    local interfaces=("$@")
    
    cat << EOF
!
! Configuration multi-interfaces - $hostname
! Généré automatiquement le $(date)
!
hostname $hostname
!
EOF

    # Traitement de chaque interface
    local i=0
    while [[ $i -lt ${#interfaces[@]} ]]; do
        local interface="${interfaces[$i]}"
        local ip="${interfaces[$((i+1))]}"
        local mask="${interfaces[$((i+2))]}"
        local desc="${interfaces[$((i+3))]}"
        
        cat << EOF
! Interface $interface
interface $interface
 description $desc
 ip address $ip $mask
 no shutdown
 exit
!
EOF
        i=$((i+4))
    done
    
    cat << EOF
! Configuration de base
enable secret cisco123
service password-encryption
no ip domain-lookup
!
end
EOF
}

# =============================================================================
# FONCTIONS INTERACTIVES
# =============================================================================

interactive_router_config() {
    print_header
    log_message "Début configuration interactive - Router"
    
    # Collecte des informations
    read -p "Nom du routeur : " hostname
    read -p "Interface (ex: fa0/0, gi0/1) : " interface
    read -p "Adresse IP : " ip_address
    read -p "Masque de sous-réseau (ex: 255.255.255.0) : " subnet_mask
    read -p "Description de l'interface : " description
    
    # Validation
    if ! validate_interface "$interface"; then
        log_error "Format d'interface invalide : $interface"
        return 1
    fi
    
    if ! validate_ip "$ip_address"; then
        log_error "Adresse IP invalide : $ip_address"
        return 1
    fi
    
    if ! validate_ip "$subnet_mask"; then
        log_error "Masque de sous-réseau invalide : $subnet_mask"
        return 1
    fi
    
    # Génération et sauvegarde
    local config_file="$SCRIPT_DIR/${hostname}_router_config.txt"
    generate_router_config "$hostname" "$interface" "$ip_address" "$subnet_mask" "$description" > "$config_file"
    
    log_message "Configuration générée : $config_file"
    echo ""
    echo -e "${GREEN}Configuration générée avec succès !${NC}"
    echo -e "${BLUE}Fichier :${NC} $config_file"
    echo ""
    echo -e "${YELLOW}Pour appliquer cette configuration :${NC}"
    echo "1. Connectez-vous au routeur"
    echo "2. Entrez en mode configuration : enable -> configure terminal"
    echo "3. Copiez-collez le contenu du fichier"
    echo ""
}

interactive_switch_config() {
    print_header
    log_message "Début configuration interactive - Switch"
    
    # Collecte des informations
    read -p "Nom du switch : " hostname
    read -p "IP de management : " management_ip
    read -p "Masque de sous-réseau : " subnet_mask
    read -p "Passerelle par défaut : " default_gateway
    
    # Validation
    if ! validate_ip "$management_ip"; then
        log_error "IP de management invalide : $management_ip"
        return 1
    fi
    
    if ! validate_ip "$subnet_mask"; then
        log_error "Masque invalide : $subnet_mask"
        return 1
    fi
    
    if ! validate_ip "$default_gateway"; then
        log_error "Passerelle invalide : $default_gateway"
        return 1
    fi
    
    # Génération et sauvegarde
    local config_file="$SCRIPT_DIR/${hostname}_switch_config.txt"
    generate_switch_config "$hostname" "$management_ip" "$subnet_mask" "$default_gateway" > "$config_file"
    
    log_message "Configuration Switch générée : $config_file"
    echo ""
    echo -e "${GREEN}Configuration générée avec succès !${NC}"
    echo -e "${BLUE}Fichier :${NC} $config_file"
    echo ""
}

# =============================================================================
# CONFIGURATIONS PRÉ-DÉFINIES
# =============================================================================

create_lab_topology() {
    print_header
    log_message "Création topologie de labo standard"
    
    local lab_dir="$SCRIPT_DIR/lab_configs"
    mkdir -p "$lab_dir"
    
    # Router R1
    generate_router_config "R1" "fa0/0" "192.168.1.1" "255.255.255.0" "LAN Interface" > "$lab_dir/R1_config.txt"
    
    # Router R2  
    generate_router_config "R2" "fa0/0" "192.168.2.1" "255.255.255.0" "LAN Interface" > "$lab_dir/R2_config.txt"
    
    # Switch SW1
    generate_switch_config "SW1" "192.168.1.10" "255.255.255.0" "192.168.1.1" > "$lab_dir/SW1_config.txt"
    
    # Switch SW2
    generate_switch_config "SW2" "192.168.2.10" "255.255.255.0" "192.168.2.1" > "$lab_dir/SW2_config.txt"
    
    # Fichier de topologie
    cat << EOF > "$lab_dir/topology.txt"
# Topologie de Labo CCNA - Configuration IP de Base
# Généré le $(date)

Équipements configurés :
========================

Router R1 :
- Interface Fa0/0 : 192.168.1.1/24
- Connecté au Switch SW1

Router R2 :
- Interface Fa0/0 : 192.168.2.1/24  
- Connecté au Switch SW2

Switch SW1 :
- IP Management : 192.168.1.10/24
- Passerelle : 192.168.1.1

Switch SW2 :
- IP Management : 192.168.2.10/24
- Passerelle : 192.168.2.1

Tests de connectivité :
======================
1. Depuis R1 : ping 192.168.1.10 (SW1)
2. Depuis R2 : ping 192.168.2.10 (SW2)
3. Configuration routing pour communication inter-réseau

Fichiers générés :
==================
- R1_config.txt : Configuration du Router R1
- R2_config.txt : Configuration du Router R2  
- SW1_config.txt : Configuration du Switch SW1
- SW2_config.txt : Configuration du Switch SW2
EOF
    
    log_message "Topologie de labo créée dans : $lab_dir"
    echo ""
    echo -e "${GREEN}Topologie de labo créée avec succès !${NC}"
    echo -e "${BLUE}Répertoire :${NC} $lab_dir"
    echo ""
    echo "Fichiers générés :"
    ls -la "$lab_dir"
    echo ""
}

# =============================================================================
# OUTILS DE DIAGNOSTIC
# =============================================================================

ip_calculator() {
    print_header
    log_message "Calculateur IP interactif"
    
    read -p "Adresse IP/CIDR (ex: 192.168.1.100/24) : " ip_cidr
    
    # Parsing IP/CIDR
    if [[ $ip_cidr =~ ^([0-9.]+)/([0-9]+)$ ]]; then
        local ip="${BASH_REMATCH[1]}"
        local cidr="${BASH_REMATCH[2]}"
        
        if ! validate_ip "$ip"; then
            log_error "IP invalide : $ip"
            return 1
        fi
        
        if ! validate_cidr "$cidr"; then
            log_error "CIDR invalide : $cidr"
            return 1
        fi
        
        # Calculs
        local host_bits=$((32 - cidr))
        local num_hosts=$((2**host_bits - 2))
        local subnet_size=$((2**host_bits))
        
        # Conversion CIDR vers masque décimal
        local mask_decimal=""
        local temp_cidr=$cidr
        for i in {1..4}; do
            if [[ $temp_cidr -ge 8 ]]; then
                mask_decimal+="255"
                temp_cidr=$((temp_cidr - 8))
            elif [[ $temp_cidr -gt 0 ]]; then
                local octet=$((256 - 2**(8-temp_cidr)))
                mask_decimal+="$octet"
                temp_cidr=0
            else
                mask_decimal+="0"
            fi
            [[ $i -lt 4 ]] && mask_decimal+="."
        done
        
        # Calcul adresse réseau (approximation simple)
        IFS='.' read -ra IP_OCTETS <<< "$ip"
        local network="${IP_OCTETS[0]}.${IP_OCTETS[1]}.${IP_OCTETS[2]}.0"
        
        echo ""
        echo -e "${GREEN}=== Résultats du Calcul IP ===${NC}"
        echo -e "${BLUE}IP saisie :${NC} $ip"
        echo -e "${BLUE}CIDR :${NC} /$cidr"
        echo -e "${BLUE}Masque décimal :${NC} $mask_decimal"
        echo -e "${BLUE}Réseau (approx) :${NC} $network/$cidr"
        echo -e "${BLUE}Nombre d'hôtes :${NC} $num_hosts"
        echo -e "${BLUE}Taille sous-réseau :${NC} $subnet_size"
        echo ""
        
    else
        log_error "Format invalide. Utilisez IP/CIDR (ex: 192.168.1.1/24)"
        return 1
    fi
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration IP de Base ===${NC}"
    echo ""
    echo "1) Configuration Router (interactif)"
    echo "2) Configuration Switch (interactif)"  
    echo "3) Créer topologie de labo standard"
    echo "4) Calculateur IP/sous-réseaux"
    echo "5) Afficher log des opérations"
    echo "6) Nettoyer fichiers générés"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-6] : " choice
    echo ""
}

clean_generated_files() {
    local count=0
    
    # Supprimer les fichiers de configuration
    for file in "$SCRIPT_DIR"/*_config.txt; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            ((count++))
            log_message "Supprimé : $(basename "$file")"
        fi
    done
    
    # Supprimer le répertoire lab si vide
    if [[ -d "$SCRIPT_DIR/lab_configs" ]]; then
        rm -rf "$SCRIPT_DIR/lab_configs"
        log_message "Supprimé : répertoire lab_configs"
        ((count++))
    fi
    
    if [[ $count -gt 0 ]]; then
        echo -e "${GREEN}$count fichier(s) supprimé(s)${NC}"
    else
        echo -e "${YELLOW}Aucun fichier à supprimer${NC}"
    fi
}

show_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${BLUE}=== Dernières opérations ===${NC}"
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}Aucun log disponible${NC}"
    fi
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

main() {
    # Initialisation
    print_header
    log_message "Démarrage du script de configuration IP"
    
    while true; do
        show_menu
        
        case $choice in
            1)
                interactive_router_config
                ;;
            2)
                interactive_switch_config
                ;;
            3)
                create_lab_topology
                ;;
            4)
                ip_calculator
                ;;
            5)
                show_logs
                ;;
            6)
                clean_generated_files
                ;;
            0)
                log_message "Arrêt du script"
                echo -e "${GREEN}Au revoir !${NC}"
                break
                ;;
            *)
                log_warning "Choix invalide : $choice"
                echo -e "${RED}Choix invalide. Essayez à nouveau.${NC}"
                ;;
        esac
        
        # Pause entre les opérations
        echo ""
        read -p "Appuyez sur Entrée pour continuer..."
    done
}

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================

# Vérification des dépendances
if ! command -v bash >/dev/null 2>&1; then
    echo "ERREUR : Bash n'est pas disponible"
    exit 1
fi

# Vérification des permissions d'écriture
if [[ ! -w "$SCRIPT_DIR" ]]; then
    echo "ERREUR : Pas de permission d'écriture dans $SCRIPT_DIR"
    exit 1
fi

# Exécution du programme principal
main

# Fin du script