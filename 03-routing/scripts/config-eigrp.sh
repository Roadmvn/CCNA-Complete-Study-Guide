#!/bin/bash

# =============================================================================
# Script : Configuration EIGRP - Cisco IOS
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations EIGRP pour routeurs Cisco
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-eigrp.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration EIGRP - CCNA${NC}"
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
# CONFIGURATIONS EIGRP
# =============================================================================

generate_eigrp_basic() {
    local hostname="$1"
    local as_number="$2"
    local router_id="$3"
    local lan_network="$4"
    local lan_wildcard="$5"
    local link_network="$6"
    local link_wildcard="$7"

    cat << EOF
!
! Configuration EIGRP Classique - $hostname
! AS Number : $as_number (doit etre identique sur tous les voisins)
!
hostname $hostname
!
router eigrp $as_number
 !
 ! Router-ID explicite (recommande)
 eigrp router-id $router_id
 !
 ! Annonce du reseau LAN
 network $lan_network $lan_wildcard
 !
 ! Annonce du lien inter-routeur
 network $link_network $link_wildcard
 !
 ! Desactive l'auto-summarisation (OBLIGATOIRE en mode classique)
 ! Sans ca, EIGRP resume les routes aux frontieres de classes
 no auto-summary
 !
 ! Passive-interface sur le LAN (pas de voisin EIGRP cote LAN)
 passive-interface GigabitEthernet0/0
 exit
!
! Verification :
! show ip eigrp neighbors
! show ip eigrp topology
! show ip route eigrp
! show ip protocols
!
end
EOF
}

generate_eigrp_named_mode() {
    local hostname="$1"
    local process_name="$2"
    local as_number="$3"
    local router_id="$4"

    cat << EOF
!
! Configuration EIGRP Named Mode - $hostname
! Le Named Mode est la methode moderne recommandee par Cisco
!
hostname $hostname
!
! Le Named Mode utilise une structure hierarchique :
!   router eigrp <NOM>
!     address-family ipv4 unicast autonomous-system <ASN>
!       af-interface <interface>
!       topology base
!
router eigrp $process_name
 !
 ! === Configuration IPv4 ===
 address-family ipv4 unicast autonomous-system $as_number
  !
  ! Router-ID
  eigrp router-id $router_id
  !
  ! Annonce des reseaux
  network 192.168.1.0 0.0.0.255
  network 10.0.0.0 0.0.0.3
  !
  ! Configuration par interface (passive, authentication, etc.)
  af-interface GigabitEthernet0/0
   passive-interface
   exit-af-interface
  !
  af-interface GigabitEthernet0/1
   ! Hello et Hold timers personnalises
   hello-interval 5
   hold-time 15
   exit-af-interface
  !
  ! Configuration de la topologie
  topology base
   ! Redistribution, filtrage, etc.
   exit-af-topology
  !
  exit-address-family
 !
 ! === Configuration IPv6 (optionnel) ===
 address-family ipv6 unicast autonomous-system $as_number
  !
  eigrp router-id $router_id
  !
  af-interface GigabitEthernet0/0
   passive-interface
   exit-af-interface
  !
  topology base
   exit-af-topology
  !
  exit-address-family
 exit
!
! Avantages du Named Mode :
! - Configuration IPv4 et IPv6 sous le meme processus
! - Configuration par interface integree (af-interface)
! - Support des wide metrics (metriques 64 bits)
! - Structure plus claire et organisee
!
! Verification :
! show eigrp address-family ipv4 neighbors
! show eigrp address-family ipv4 topology
! show eigrp address-family ipv4 interfaces
!
end
EOF
}

generate_eigrp_bandwidth_delay() {
    cat << EOF
!
! Manipulation Bandwidth et Delay pour EIGRP
! La metrique EIGRP utilise par defaut : Bandwidth + Delay
!
! =============================================================
! Formule de la metrique EIGRP (simplifiee, K1=1, K3=1)
! =============================================================
!
! Metric = 256 * ( (10^7 / BW_min_kbps) + (somme_delays / 10) )
!
! BW_min = bande passante minimale sur tout le chemin (en Kbps)
! Delays = somme des delais de chaque interface traversee (en microsecondes)
!
! =============================================================
! Verification des valeurs actuelles
! =============================================================
!
! show interfaces GigabitEthernet0/0
!   BW 1000000 Kbit/sec, DLY 10 usec
!
! show interfaces Serial0/0/0
!   BW 1544 Kbit/sec, DLY 20000 usec
!
! =============================================================
! Modification de la bandwidth (logique, pas physique)
! =============================================================
!
! La commande bandwidth ne change PAS la vitesse reelle du lien
! Elle modifie uniquement la valeur utilisee par EIGRP (et OSPF)
!
interface Serial0/0/0
 description Lien WAN - ajuster BW pour la metrique
 ! Par defaut : bandwidth 1544
 bandwidth 512
 ! EIGRP utilisera 512 Kbps pour calculer la metrique
 ! Resultat : metrique plus elevee = chemin moins prefere
 exit
!
! =============================================================
! Modification du delay
! =============================================================
!
interface GigabitEthernet0/1
 description Lien vers R2 - ajuster delay pour preferer ce chemin
 ! Par defaut : delay 10 (en dizaines de microsecondes)
 delay 1
 ! EIGRP utilisera un delay de 10 usec (1 * 10)
 ! Resultat : metrique plus basse = chemin prefere
 exit
!
interface Serial0/0/0
 description Lien de secours - augmenter delay
 delay 100000
 ! EIGRP utilisera un delay de 1,000,000 usec
 ! Resultat : chemin tres peu prefere
 exit
!
! =============================================================
! Exemple pratique : forcer le trafic via un lien specifique
! =============================================================
!
! Topologie : R1 -- (GigE) -- R2 -- (GigE) -- R3
!             R1 -- (Serial) ------- R3
!
! Pour preferer le chemin R1->R2->R3 au lieu de R1->R3 :
!
! Option 1 : Augmenter le delay sur le lien Serial
interface Serial0/0/0
 delay 65535
 exit
!
! Option 2 : Diminuer la bandwidth sur le lien Serial
interface Serial0/0/0
 bandwidth 64
 exit
!
! Verification :
! show ip eigrp topology
!   FD (Feasible Distance) = metrique du meilleur chemin
!   RD (Reported Distance) = metrique annoncee par le voisin
! show interfaces Serial0/0/0 | include BW|DLY
! show ip eigrp topology all-links
!   Affiche tous les chemins, y compris les Feasible Successors
!
end
EOF
}

generate_eigrp_summary_routes() {
    cat << EOF
!
! Routes de Summarisation EIGRP
! Reduire la taille de la table de routage en aggregeant les prefixes
!
! =============================================================
! Auto-Summary (desactive par defaut en IOS 15+)
! =============================================================
!
router eigrp 100
 ! TOUJOURS desactiver auto-summary en environnement moderne
 no auto-summary
 !
 ! auto-summary resume les routes aux frontieres de classes :
 ! 192.168.1.0/24 + 192.168.2.0/24 => 192.168.0.0/16 (Classe C resumerait mal)
 ! 10.1.0.0/24 + 10.2.0.0/24 => 10.0.0.0/8 (trop large !)
 exit
!
! =============================================================
! Summarisation manuelle (RECOMMANDE)
! =============================================================
!
! Topologie :
!   R1 annonce : 192.168.1.0/24, 192.168.2.0/24,
!                192.168.3.0/24, 192.168.4.0/24
!   On veut resumer en : 192.168.0.0/22 vers R2
!
! Calcul du resume :
!   192.168.1.0   = 192.168.00000001.0
!   192.168.2.0   = 192.168.00000010.0
!   192.168.3.0   = 192.168.00000011.0
!   192.168.4.0   = 192.168.00000100.0
!   Resume        = 192.168.00000000.0 = 192.168.0.0/22
!
! Mode classique : summarisation sur l'interface de sortie
interface GigabitEthernet0/1
 description Lien vers R2 - summarisation EIGRP
 ip summary-address eigrp 100 192.168.0.0 255.255.252.0
 ! Remplace les 4 routes /24 par une seule route /22 vers R2
 exit
!
! Mode Named : summarisation dans af-interface
router eigrp ENTERPRISE
 address-family ipv4 unicast autonomous-system 100
  af-interface GigabitEthernet0/1
   summary-address 192.168.0.0 255.255.252.0
   exit-af-interface
  exit-address-family
 exit
!
! =============================================================
! Effets de la summarisation
! =============================================================
!
! 1. R2 recoit une seule route 192.168.0.0/22 au lieu de 4 routes /24
! 2. R1 installe automatiquement une route Null0 pour le resume
!    (pour eviter les boucles de routage)
! 3. Si un des 4 reseaux tombe, R2 ne le sait pas (le resume reste)
!
! Route Null0 sur R1 :
!   D  192.168.0.0/22 is a summary, Null0
!
! Verification :
! show ip route eigrp            (sur R2 : voir la route resumee)
! show ip eigrp topology         (sur R1 : voir la route summary)
! show ip route 192.168.0.0      (detail de la route)
!
end
EOF
}

generate_eigrp_complete_config() {
    cat << EOF
!
! Configuration EIGRP Complete - Infrastructure 4 Routeurs
!
! Topologie :
!   R1 ---- (Gi) ---- R2 ---- (Gi) ---- R3
!   |                                      |
!   +---- (Serial) ---- R4 ---- (Gi) -----+
!
! =============================================================
! R1 : Routeur principal
! =============================================================
!
hostname R1
!
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
 exit
!
interface GigabitEthernet0/1
 ip address 10.0.12.1 255.255.255.252
 no shutdown
 exit
!
interface Serial0/0/0
 ip address 10.0.14.1 255.255.255.252
 bandwidth 1544
 no shutdown
 exit
!
router eigrp 100
 eigrp router-id 1.1.1.1
 network 192.168.1.0 0.0.0.255
 network 10.0.12.0 0.0.0.3
 network 10.0.14.0 0.0.0.3
 passive-interface GigabitEthernet0/0
 no auto-summary
 exit
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
interface GigabitEthernet0/1
 ip address 10.0.12.2 255.255.255.252
 no shutdown
 exit
!
interface GigabitEthernet0/2
 ip address 10.0.23.1 255.255.255.252
 no shutdown
 exit
!
router eigrp 100
 eigrp router-id 2.2.2.2
 network 192.168.2.0 0.0.0.255
 network 10.0.12.0 0.0.0.3
 network 10.0.23.0 0.0.0.3
 passive-interface GigabitEthernet0/0
 no auto-summary
 exit
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
interface GigabitEthernet0/1
 ip address 10.0.23.2 255.255.255.252
 no shutdown
 exit
!
interface GigabitEthernet0/2
 ip address 10.0.34.1 255.255.255.252
 no shutdown
 exit
!
router eigrp 100
 eigrp router-id 3.3.3.3
 network 192.168.3.0 0.0.0.255
 network 10.0.23.0 0.0.0.3
 network 10.0.34.0 0.0.0.3
 passive-interface GigabitEthernet0/0
 no auto-summary
 exit
!
! =============================================================
! R4 : Routeur de secours (lien Serial vers R1)
! =============================================================
!
hostname R4
!
interface GigabitEthernet0/0
 ip address 192.168.4.1 255.255.255.0
 no shutdown
 exit
!
interface Serial0/0/0
 ip address 10.0.14.2 255.255.255.252
 bandwidth 1544
 no shutdown
 exit
!
interface GigabitEthernet0/1
 ip address 10.0.34.2 255.255.255.252
 no shutdown
 exit
!
router eigrp 100
 eigrp router-id 4.4.4.4
 network 192.168.4.0 0.0.0.255
 network 10.0.14.0 0.0.0.3
 network 10.0.34.0 0.0.0.3
 passive-interface GigabitEthernet0/0
 no auto-summary
 exit
!
end
EOF
}

generate_eigrp_verification() {
    cat << EOF
!
! Commandes de Verification EIGRP - Reference Complete
!
! === Voisins EIGRP ===
show ip eigrp neighbors
! H = handle, Address = IP du voisin, Interface, Hold time
! SRTT = Smooth Round Trip Time, RTO = Retransmit Timeout
! Q Cnt = paquets en attente (doit etre 0 en regime normal)
! Seq Num = numero de sequence du dernier paquet recu
!
show ip eigrp neighbors detail
! Affiche les K-values, software version, etc.
!
! === Topologie EIGRP ===
show ip eigrp topology
! P = Passive (route stable), A = Active (en recalcul)
! FD = Feasible Distance (metrique locale vers la destination)
! Successors = nombre de meilleurs chemins
! via X.X.X.X (FD/RD) = voisin (metrique locale / metrique du voisin)
!
show ip eigrp topology all-links
! Affiche aussi les routes non-feasible (qui ne respectent pas
! la feasibility condition)
!
show ip eigrp topology 192.168.1.0/24
! Detail d'une route specifique
!
! === Routes EIGRP ===
show ip route eigrp
! D = route EIGRP interne
! D EX = route EIGRP externe (redistribuee)
! [90/X] = AD=90, metrique EIGRP
!
! === Interfaces EIGRP ===
show ip eigrp interfaces
! Peers, Xmit Queue, SRTT, Pacing Time
!
show ip eigrp interfaces detail
! Hello interval, Hold time, Split horizon, etc.
!
! === Protocoles actifs ===
show ip protocols
! AS number, K-values, networks, passive-interfaces
! Routing Information Sources (voisins)
!
! === Statistiques EIGRP ===
show ip eigrp traffic
! Nombre de paquets Hello, Update, Query, Reply, ACK
! envoyes et recus
!
! === Debug (attention en production) ===
debug eigrp packets hello
! Suivi des paquets Hello
!
debug eigrp fsm
! Suivi de la machine d'etat DUAL (Diffusing Update Algorithm)
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
    echo -e "${BLUE}=== Menu Configuration EIGRP ===${NC}"
    echo ""
    echo "1) EIGRP configuration de base (classique)"
    echo "2) EIGRP Named Mode"
    echo "3) Manipulation Bandwidth/Delay"
    echo "4) Routes de summarisation"
    echo "5) Configuration complete (4 routeurs)"
    echo "6) Commandes de verification"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-6] : " choice
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script de configuration EIGRP"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Hostname : " hostname
                read -p "AS Number (ex: 100) : " as_number
                read -p "Router-ID (ex: 1.1.1.1) : " router_id
                read -p "Reseau LAN (ex: 192.168.1.0) : " lan_net
                read -p "Wildcard LAN (ex: 0.0.0.255) : " lan_wc
                read -p "Reseau lien (ex: 10.0.0.0) : " link_net
                read -p "Wildcard lien (ex: 0.0.0.3) : " link_wc
                echo ""
                generate_eigrp_basic "$hostname" "$as_number" "$router_id" "$lan_net" "$lan_wc" "$link_net" "$link_wc"
                ;;
            2)
                read -p "Hostname : " hostname
                read -p "Nom du processus (ex: ENTERPRISE) : " process_name
                read -p "AS Number (ex: 100) : " as_number
                read -p "Router-ID (ex: 1.1.1.1) : " router_id
                echo ""
                generate_eigrp_named_mode "$hostname" "$process_name" "$as_number" "$router_id"
                ;;
            3)
                generate_eigrp_bandwidth_delay
                ;;
            4)
                generate_eigrp_summary_routes
                ;;
            5)
                generate_eigrp_complete_config
                ;;
            6)
                generate_eigrp_verification
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
