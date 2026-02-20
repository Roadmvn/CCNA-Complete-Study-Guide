#!/bin/bash

# =============================================================================
# Script : Configuration Routes Statiques - Cisco IOS
# Auteur : Tudy Gbaguidi
# Date   : 2024
# Objectif : Generer des configurations de routes statiques pour routeurs Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-static-routes.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration Routes Statiques - CCNA${NC}"
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
# CONFIGURATIONS DE ROUTES STATIQUES
# =============================================================================

generate_static_next_hop() {
    local hostname="$1"
    local dest_network="$2"
    local dest_mask="$3"
    local next_hop="$4"

    cat << EOF
!
! Route statique next-hop - $hostname
! Le routeur envoie le paquet vers l'adresse IP du prochain saut
!
hostname $hostname
!
! Route statique : reseau destination via adresse du prochain routeur
ip route $dest_network $dest_mask $next_hop
!
! Avantage : fonctionne sur tous les types de liens (Ethernet, Serial)
! Inconvenient : necessite une resolution ARP sur les liens multi-access
!
! Verification :
! show ip route static
! show ip route $dest_network
!
end
EOF
}

generate_static_exit_interface() {
    local hostname="$1"
    local dest_network="$2"
    local dest_mask="$3"
    local exit_if="$4"

    cat << EOF
!
! Route statique exit-interface - $hostname
! Le routeur envoie le paquet via l'interface de sortie specifiee
!
hostname $hostname
!
! Route statique : reseau destination via interface de sortie
ip route $dest_network $dest_mask $exit_if
!
! Recommande uniquement sur les liens point-a-point (Serial)
! Sur Ethernet, provoque des requetes ARP pour chaque destination
!
! Verification :
! show ip route static
! show ip route $dest_network
!
end
EOF
}

generate_default_route() {
    local hostname="$1"
    local next_hop="$2"

    cat << EOF
!
! Default Route (route par defaut) - $hostname
! Utilise quand aucune route plus specifique n'existe
!
hostname $hostname
!
! Default route : tout le trafic inconnu va vers $next_hop
ip route 0.0.0.0 0.0.0.0 $next_hop
!
! 0.0.0.0 0.0.0.0 = correspond a TOUTES les destinations
! Apparait comme S* dans la table de routage
!
! Verification :
! show ip route
! show ip route 0.0.0.0
!
end
EOF
}

generate_floating_static() {
    local hostname="$1"
    local dest_network="$2"
    local dest_mask="$3"
    local primary_nh="$4"
    local backup_nh="$5"
    local backup_ad="$6"

    cat << EOF
!
! Floating Static Route - $hostname
! Route de secours avec administrative distance elevee
!
hostname $hostname
!
! Route principale (AD par defaut = 1)
ip route $dest_network $dest_mask $primary_nh
!
! Route de secours (AD = $backup_ad, superieure aux routes OSPF=110, EIGRP=90)
! N'apparait dans la table que si la route principale disparait
ip route $dest_network $dest_mask $backup_nh $backup_ad
!
! Fonctionnement :
! - En temps normal : trafic passe par $primary_nh (AD=1)
! - Si le lien principal tombe : route vers $backup_nh (AD=$backup_ad) prend le relais
! - Quand le lien principal revient : retour automatique vers $primary_nh
!
! Verification :
! show ip route static
! show ip route $dest_network
!
end
EOF
}

generate_ipv6_static_routes() {
    cat << EOF
!
! Routes Statiques IPv6
! Syntaxe similaire a IPv4 mais avec les adresses IPv6
!
! Activer le routage IPv6
ipv6 unicast-routing
!
! Route statique IPv6 next-hop (link-local)
! Le next-hop link-local necessite l'interface de sortie
ipv6 route 2001:DB8:2::/64 GigabitEthernet0/1 FE80::2
!
! Route statique IPv6 next-hop (global unicast)
ipv6 route 2001:DB8:3::/64 2001:DB8:12::2
!
! Route statique IPv6 exit-interface (point-a-point uniquement)
ipv6 route 2001:DB8:4::/64 Serial0/0/0
!
! Default route IPv6
ipv6 route ::/0 2001:DB8:12::2
!
! Floating static route IPv6 (AD=250)
ipv6 route 2001:DB8:2::/64 2001:DB8:13::2 250
!
! Verification :
! show ipv6 route static
! show ipv6 route
! ping ipv6 2001:DB8:2::1
!
end
EOF
}

generate_complete_static_config() {
    cat << EOF
!
! Configuration Complete - Routes Statiques
! Topologie : R1 -- R2 -- R3 avec liens de secours
!
! =============================================================
! R1 : Routeur de bordure avec default route
! =============================================================
!
hostname R1
!
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
 exit
!
interface Serial0/0/0
 description Lien principal vers R2
 ip address 10.0.12.1 255.255.255.252
 no shutdown
 exit
!
interface Serial0/0/1
 description Lien de secours vers R2
 ip address 10.0.99.1 255.255.255.252
 no shutdown
 exit
!
! Routes statiques next-hop vers les reseaux distants
ip route 192.168.2.0 255.255.255.0 10.0.12.2
ip route 192.168.3.0 255.255.255.0 10.0.12.2
ip route 10.0.23.0 255.255.255.252 10.0.12.2
!
! Floating static routes via le lien de secours (AD=250)
ip route 192.168.2.0 255.255.255.0 10.0.99.2 250
ip route 192.168.3.0 255.255.255.0 10.0.99.2 250
!
! Default route vers le FAI
ip route 0.0.0.0 0.0.0.0 10.0.12.2
!
! =============================================================
! R2 : Routeur central
! =============================================================
!
hostname R2
!
interface GigabitEthernet0/0
 ip address 192.168.2.1 255.255.255.0
 no shutdown
 exit
!
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
 exit
!
interface Serial0/0/1
 ip address 10.0.23.1 255.255.255.252
 no shutdown
 exit
!
! Routes vers les reseaux distants
ip route 192.168.1.0 255.255.255.0 10.0.12.1
ip route 192.168.3.0 255.255.255.0 10.0.23.2
!
! =============================================================
! R3 : Routeur distant
! =============================================================
!
hostname R3
!
interface GigabitEthernet0/0
 ip address 192.168.3.1 255.255.255.0
 no shutdown
 exit
!
interface Serial0/0/0
 ip address 10.0.23.2 255.255.255.252
 no shutdown
 exit
!
! Default route vers R2 (tout le trafic passe par R2)
ip route 0.0.0.0 0.0.0.0 10.0.23.1
!
end
EOF
}

generate_verification_commands() {
    cat << EOF
!
! Commandes de Verification - Routes Statiques
!
! === Table de routage complete ===
show ip route
!
! === Routes statiques uniquement ===
show ip route static
!
! === Detail d'une route specifique ===
show ip route 192.168.2.0
!
! === Verifier la configuration courante ===
show running-config | include ip route
!
! === Test de connectivite ===
ping 192.168.2.1
ping 192.168.3.1
!
! === Trace du chemin ===
traceroute 192.168.3.1
!
! === Routes IPv6 ===
show ipv6 route
show ipv6 route static
!
! === Debug (attention en production) ===
debug ip routing
! Affiche les changements dans la table de routage en temps reel
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
    echo -e "${BLUE}=== Menu Configuration Routes Statiques ===${NC}"
    echo ""
    echo "1) Route statique next-hop"
    echo "2) Route statique exit-interface"
    echo "3) Default route"
    echo "4) Floating static route"
    echo "5) Routes statiques IPv6"
    echo "6) Configuration complete (3 routeurs)"
    echo "7) Commandes de verification"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-7] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration routes statiques"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Hostname : " hostname
                read -p "Reseau destination (ex: 192.168.2.0) : " dest_net
                read -p "Masque (ex: 255.255.255.0) : " dest_mask
                read -p "Next-hop IP (ex: 10.0.0.2) : " next_hop
                echo ""
                generate_static_next_hop "$hostname" "$dest_net" "$dest_mask" "$next_hop"
                ;;
            2)
                read -p "Hostname : " hostname
                read -p "Reseau destination (ex: 192.168.2.0) : " dest_net
                read -p "Masque (ex: 255.255.255.0) : " dest_mask
                read -p "Interface de sortie (ex: Serial0/0/0) : " exit_if
                echo ""
                generate_static_exit_interface "$hostname" "$dest_net" "$dest_mask" "$exit_if"
                ;;
            3)
                read -p "Hostname : " hostname
                read -p "Next-hop IP pour la default route : " next_hop
                echo ""
                generate_default_route "$hostname" "$next_hop"
                ;;
            4)
                read -p "Hostname : " hostname
                read -p "Reseau destination : " dest_net
                read -p "Masque : " dest_mask
                read -p "Next-hop principal : " primary_nh
                read -p "Next-hop de secours : " backup_nh
                read -p "AD de la route de secours (defaut 250) : " backup_ad
                backup_ad=${backup_ad:-250}
                echo ""
                generate_floating_static "$hostname" "$dest_net" "$dest_mask" "$primary_nh" "$backup_nh" "$backup_ad"
                ;;
            5)
                generate_ipv6_static_routes
                ;;
            6)
                generate_complete_static_config
                ;;
            7)
                generate_verification_commands
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
