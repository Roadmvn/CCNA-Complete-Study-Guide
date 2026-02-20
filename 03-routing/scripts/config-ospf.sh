#!/bin/bash

# =============================================================================
# Script : Configuration OSPF - Cisco IOS
# Auteur : Tudy Gbaguidi
# Date   : 2024
# Objectif : Generer des configurations OSPF pour routeurs Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-ospf.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration OSPF - CCNA${NC}"
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
# CONFIGURATIONS OSPF
# =============================================================================

generate_ospf_single_area() {
    local hostname="$1"
    local router_id="$2"
    local lan_network="$3"
    local lan_wildcard="$4"
    local link_network="$5"
    local link_wildcard="$6"

    cat << EOF
!
! Configuration OSPF Single-Area - $hostname
! Tous les reseaux dans Area 0
!
hostname $hostname
!
router ospf 1
 router-id $router_id
 !
 ! Reference bandwidth a 10 Gbps pour differencier GigE et FastE
 auto-cost reference-bandwidth 10000
 !
 ! Annonce du reseau LAN dans Area 0
 network $lan_network $lan_wildcard area 0
 !
 ! Annonce du lien inter-routeur dans Area 0
 network $link_network $link_wildcard area 0
 !
 ! Passive-interface sur le LAN (pas de voisin OSPF cote LAN)
 ! Le reseau est quand meme annonce dans OSPF
 passive-interface GigabitEthernet0/0
 exit
!
! Verification :
! show ip ospf
! show ip ospf neighbor
! show ip ospf interface brief
! show ip route ospf
!
end
EOF
}

generate_ospf_multi_area() {
    cat << EOF
!
! Configuration OSPF Multi-Area
! ABR : routeur frontiere entre Area 0 et les autres areas
!
! =============================================================
! ABR-1 : Frontiere entre Area 0 et Area 1
! =============================================================
!
hostname ABR-1
!
router ospf 1
 router-id 2.2.2.2
 auto-cost reference-bandwidth 10000
 !
 ! Interface vers Area 1 (reseau interne)
 network 172.16.1.0 0.0.0.255 area 1
 !
 ! Interface vers Area 0 (backbone)
 network 10.0.0.0 0.0.0.3 area 0
 !
 ! L'ABR genere des LSA Type 3 (Summary) pour resumer
 ! les routes d'une area vers les autres areas
 !
 ! Optionnel : Summarisation inter-area
 ! Resume toutes les routes 172.16.x.x d'Area 1 en une seule route
 area 1 range 172.16.0.0 255.255.0.0
 exit
!
! =============================================================
! Routeur interne Area 1
! =============================================================
!
hostname R1-Internal
!
router ospf 1
 router-id 1.1.1.1
 auto-cost reference-bandwidth 10000
 network 172.16.1.0 0.0.0.255 area 1
 network 172.16.10.0 0.0.0.255 area 1
 passive-interface GigabitEthernet0/0
 exit
!
! =============================================================
! Routeur Backbone Area 0
! =============================================================
!
hostname R3-Backbone
!
router ospf 1
 router-id 3.3.3.3
 auto-cost reference-bandwidth 10000
 network 10.0.0.0 0.0.0.3 area 0
 network 10.0.1.0 0.0.0.3 area 0
 exit
!
! Verification ABR :
! show ip ospf                    (doit lister plusieurs areas)
! show ip ospf border-routers     (liste des ABR et ASBR connus)
! show ip ospf database           (LSA par area)
! show ip route ospf              (routes O et O IA)
!
end
EOF
}

generate_ospf_dr_bdr() {
    cat << EOF
!
! Configuration DR/BDR - Manipulation de la priorite OSPF
! Sur un segment multi-access (Ethernet), OSPF elit un DR et un BDR
!
! =============================================================
! Routeur qui doit etre DR (priorite la plus haute)
! =============================================================
!
hostname SW-CORE-DR
!
interface GigabitEthernet0/0
 description Segment multi-access - Force DR
 ip ospf priority 255
 ! Priorite max = 255, ce routeur sera prefere comme DR
 exit
!
! =============================================================
! Routeur qui doit etre BDR (priorite intermediaire)
! =============================================================
!
hostname SW-CORE-BDR
!
interface GigabitEthernet0/0
 description Segment multi-access - Force BDR
 ip ospf priority 100
 exit
!
! =============================================================
! Routeur qui ne doit JAMAIS devenir DR/BDR
! =============================================================
!
hostname SW-ACCESS
!
interface GigabitEthernet0/0
 description Segment multi-access - Jamais DR/BDR
 ip ospf priority 0
 ! Priorite 0 = ne participe pas a l'election DR/BDR
 exit
!
! =============================================================
! Forcer un type de reseau pour eviter l'election DR/BDR
! =============================================================
!
! Sur un lien point-a-point Ethernet (2 routeurs seulement)
interface GigabitEthernet0/1
 description Lien P2P Ethernet - pas besoin de DR/BDR
 ip ospf network point-to-point
 ! Pas d'election DR/BDR, adjacence FULL directe
 exit
!
! Regles de l'election DR/BDR :
! 1. Plus haute priorite OSPF (defaut=1, range 0-255)
! 2. En cas d'egalite : plus haut Router-ID
! 3. Election NON preemptive : un nouveau routeur avec priorite
!    plus haute ne delogera PAS le DR actuel
! 4. Pour forcer une nouvelle election : clear ip ospf process
!
! Verification :
! show ip ospf interface GigabitEthernet0/0
! show ip ospf neighbor
!
end
EOF
}

generate_ospf_passive_interfaces() {
    cat << EOF
!
! Configuration Passive Interfaces OSPF
! Empeche l'envoi de Hello sur les interfaces specifiees
! Le reseau est toujours annonce dans OSPF
!
! =============================================================
! Methode 1 : Passive-interface selective
! =============================================================
!
router ospf 1
 ! Desactiver OSPF Hello sur les interfaces LAN
 passive-interface GigabitEthernet0/0
 passive-interface GigabitEthernet0/1
 ! Les interfaces Gi0/2 et Se0/0/0 continuent d'envoyer des Hello
 exit
!
! =============================================================
! Methode 2 : Tout passif par defaut, puis exceptions
! Recommande quand il y a beaucoup d'interfaces LAN
! =============================================================
!
router ospf 1
 ! Toutes les interfaces deviennent passives par defaut
 passive-interface default
 !
 ! Reactiver OSPF Hello sur les interfaces vers les voisins OSPF
 no passive-interface GigabitEthernet0/2
 no passive-interface Serial0/0/0
 exit
!
! Quand utiliser passive-interface :
! - Interfaces connectees aux LANs utilisateurs
! - Interfaces Loopback
! - Interfaces vers des reseaux sans routeur OSPF
!
! Quand NE PAS utiliser passive-interface :
! - Interfaces connectees a d'autres routeurs OSPF
! - Liens inter-routeurs (Serial, tunnel, etc.)
!
! Verification :
! show ip ospf interface brief
! show ip protocols    (liste les passive interfaces)
!
end
EOF
}

generate_ospf_default_route() {
    cat << EOF
!
! Propagation de Default Route via OSPF
! Utilise quand un routeur a acces a Internet ou un reseau externe
!
! =============================================================
! ASBR : Routeur avec acces Internet qui annonce la default route
! =============================================================
!
hostname ASBR-Internet
!
! Route statique vers Internet (via le FAI)
ip route 0.0.0.0 0.0.0.0 203.0.113.1
!
router ospf 1
 router-id 10.10.10.10
 auto-cost reference-bandwidth 10000
 !
 ! Annonce la default route dans OSPF
 ! "always" = annonce meme si la route statique 0.0.0.0/0 n'existe pas
 default-information originate always
 !
 ! Sans "always" : annonce uniquement si une default route
 ! existe dans la table de routage
 ! default-information originate
 !
 network 10.0.0.0 0.0.0.3 area 0
 exit
!
! Sur les autres routeurs OSPF, la default route apparait comme :
! O*E2  0.0.0.0/0 [110/1] via 10.0.0.1, GigabitEthernet0/0
!
! O*E2 = route externe OSPF Type 2, default route
! [110/1] = AD=110, metrique=1
!
! Verification :
! show ip route ospf
! show ip ospf database external
!
end
EOF
}

generate_ospf_authentication() {
    cat << EOF
!
! Authentification OSPF
! Protege les echanges OSPF contre les routeurs non autorises
!
! =============================================================
! Methode 1 : Authentification simple (texte clair - PAS RECOMMANDE)
! =============================================================
!
interface GigabitEthernet0/0
 ip ospf authentication
 ip ospf authentication-key MonMotDePasse
 ! Le mot de passe circule en clair sur le reseau
 exit
!
! =============================================================
! Methode 2 : Authentification MD5 (RECOMMANDE)
! =============================================================
!
interface GigabitEthernet0/0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 MotDePasseSecure
 exit
!
! =============================================================
! Methode 3 : Authentification par area (globale)
! Tous les routeurs de l'area doivent avoir la meme config
! =============================================================
!
router ospf 1
 area 0 authentication message-digest
 exit
!
interface GigabitEthernet0/0
 ip ospf message-digest-key 1 md5 MotDePasseSecure
 exit
!
interface GigabitEthernet0/1
 ip ospf message-digest-key 1 md5 MotDePasseSecure
 exit
!
! Les deux routeurs d'un lien doivent avoir :
! - Le meme type d'authentification
! - Le meme key-id
! - Le meme mot de passe
!
! Verification :
! show ip ospf interface GigabitEthernet0/0
!   Message digest authentication enabled
!   Youngest key id is 1
! show ip ospf neighbor
!   Si l'adjacence est FULL, l'authentification fonctionne
!
end
EOF
}

generate_ospf_verification() {
    cat << EOF
!
! Commandes de Verification OSPF - Reference Complete
!
! === Informations generales du processus OSPF ===
show ip ospf
! Router-ID, reference bandwidth, nombre d'areas, timers SPF
!
! === Liste des voisins OSPF ===
show ip ospf neighbor
! Neighbor ID, Priority, State (FULL/2WAY), Dead Time, Interface
! Etat normal : FULL/DR, FULL/BDR, FULL/- (P2P), 2WAY/DROTHER
!
! === Detail des interfaces OSPF ===
show ip ospf interface brief
! PID, Area, IP, Cost, State, Nombre de voisins
!
show ip ospf interface GigabitEthernet0/0
! Detail complet : DR/BDR, timers, network type, cost, etc.
!
! === Table de routage OSPF ===
show ip route ospf
! O    = route intra-area (meme area)
! O IA = route inter-area (via ABR)
! O E1 = route externe type 1 (metrique interne + externe)
! O E2 = route externe type 2 (metrique externe seule)
!
! === Base de donnees OSPF (LSDB) ===
show ip ospf database
! Liste tous les LSA par type et par area
!
show ip ospf database router
! LSA Type 1 : generes par chaque routeur
!
show ip ospf database network
! LSA Type 2 : generes par le DR
!
show ip ospf database summary
! LSA Type 3 : generes par les ABR
!
show ip ospf database external
! LSA Type 5 : generes par les ASBR
!
! === Informations sur les ABR/ASBR ===
show ip ospf border-routers
!
! === Protocoles de routage actifs ===
show ip protocols
! Affiche process-id, router-id, networks, passive-interfaces
!
! === Debug (attention en production) ===
debug ip ospf adj
! Suivi de l'etablissement des adjacences
!
debug ip ospf hello
! Suivi des paquets Hello
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
    echo -e "${BLUE}=== Menu Configuration OSPF ===${NC}"
    echo ""
    echo "1) OSPF Single-Area (configuration de base)"
    echo "2) OSPF Multi-Area (avec ABR)"
    echo "3) Manipulation DR/BDR (priorite)"
    echo "4) Passive Interfaces"
    echo "5) Propagation Default Route (default-information originate)"
    echo "6) Authentification OSPF"
    echo "7) Commandes de verification"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-7] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration OSPF"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Hostname : " hostname
                read -p "Router-ID (ex: 1.1.1.1) : " router_id
                read -p "Reseau LAN (ex: 192.168.1.0) : " lan_net
                read -p "Wildcard LAN (ex: 0.0.0.255) : " lan_wc
                read -p "Reseau lien (ex: 10.0.0.0) : " link_net
                read -p "Wildcard lien (ex: 0.0.0.3) : " link_wc
                echo ""
                generate_ospf_single_area "$hostname" "$router_id" "$lan_net" "$lan_wc" "$link_net" "$link_wc"
                ;;
            2)
                generate_ospf_multi_area
                ;;
            3)
                generate_ospf_dr_bdr
                ;;
            4)
                generate_ospf_passive_interfaces
                ;;
            5)
                generate_ospf_default_route
                ;;
            6)
                generate_ospf_authentication
                ;;
            7)
                generate_ospf_verification
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
