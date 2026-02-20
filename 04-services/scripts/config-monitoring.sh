#!/bin/bash

# =============================================================================
# Script : Configuration Monitoring (NTP + Syslog + SNMP + CDP/LLDP) - Cisco CCNA
# Auteur : Roadmvn
# Date   : 2024
# Objectif : Generer des configurations de monitoring pour equipements Cisco
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/config-monitoring.log"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Configuration Monitoring - CCNA${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo -e "${GREEN}[INFO]${NC} $1"
}

# =============================================================================
# GENERATEURS DE CONFIGURATION NTP
# =============================================================================

generate_ntp_server() {
    local hostname="$1"
    local stratum="$2"
    local timezone="$3"
    local tz_offset="$4"

    cat << EOF
!
! =============================================
! Configuration NTP Master (Serveur)
! Equipement : $hostname
! =============================================
!
hostname $hostname
!
! Fuseau horaire
clock timezone $timezone $tz_offset
!
! Ce routeur est source NTP (stratum $stratum)
ntp master $stratum
!
! Authentification NTP (optionnel, recommande en production)
ntp authenticate
ntp authentication-key 1 md5 NtpSecretKey123
ntp trusted-key 1
!
! Restreindre l'acces NTP (securite)
! access-list 20 permit 10.0.0.0 0.255.255.255
! ntp access-group peer 20
!
! Verification :
! show ntp status
! show ntp associations
! show clock
! show clock detail
!
end
EOF
}

generate_ntp_client() {
    local hostname="$1"
    local ntp_server="$2"
    local timezone="$3"
    local tz_offset="$4"

    cat << EOF
!
! =============================================
! Configuration NTP Client
! Equipement : $hostname
! =============================================
!
hostname $hostname
!
! Fuseau horaire
clock timezone $timezone $tz_offset
!
! Serveur NTP a utiliser pour la synchronisation
ntp server $ntp_server
!
! Serveur NTP de secours (optionnel)
! ntp server [IP_BACKUP] prefer
!
! Authentification NTP (doit correspondre au serveur)
! ntp authenticate
! ntp authentication-key 1 md5 NtpSecretKey123
! ntp trusted-key 1
! ntp server $ntp_server key 1
!
! Source des paquets NTP (interface de management)
! ntp source Loopback0
!
! Verification :
! show ntp status
! show ntp associations
! show clock
!
end
EOF
}

# =============================================================================
# GENERATEURS DE CONFIGURATION SYSLOG
# =============================================================================

generate_syslog() {
    local hostname="$1"
    local syslog_server="$2"
    local trap_level="$3"
    local source_intf="$4"

    cat << EOF
!
! =============================================
! Configuration Syslog
! Equipement : $hostname
! =============================================
!
hostname $hostname
!
! Activer les timestamps detailles dans les logs
service timestamps log datetime msec localtime show-timezone
service timestamps debug datetime msec localtime show-timezone
!
! Numerotation des messages (facilite le suivi)
service sequence-numbers
!
! Envoi des logs vers le serveur Syslog distant
logging host $syslog_server
!
! Niveau de severite envoye au serveur
! 0=emergencies, 1=alerts, 2=critical, 3=errors,
! 4=warnings, 5=notifications, 6=informational, 7=debugging
logging trap $trap_level
!
! Interface source des paquets Syslog
logging source-interface $source_intf
!
! Taille du buffer local (en octets)
logging buffered 32768 informational
!
! Niveau affiche sur la console (limiter pour les performances)
logging console warnings
!
! Niveau affiche sur les sessions VTY
logging monitor informational
!
! Facilite (categorie) par defaut : local7
! logging facility local7
!
! Verification :
! show logging
! show logging history
! show logging | include %LINK
! terminal monitor (activer logs sur session VTY)
!
end
EOF
}

# =============================================================================
# GENERATEURS DE CONFIGURATION SNMP
# =============================================================================

generate_snmp_v2c() {
    local hostname="$1"
    local ro_community="$2"
    local rw_community="$3"
    local nms_server="$4"
    local contact="$5"
    local location="$6"

    cat << EOF
!
! =============================================
! Configuration SNMP v2c
! Equipement : $hostname
! =============================================
!
hostname $hostname
!
! ACL pour restreindre l'acces SNMP au NMS uniquement
access-list 30 permit host $nms_server
access-list 30 deny any log
!
! Community strings (lecture seule et lecture-ecriture)
snmp-server community $ro_community ro 30
snmp-server community $rw_community rw 30
!
! Informations de contact et localisation
snmp-server contact $contact
snmp-server location $location
!
! Envoi de traps vers le NMS
snmp-server host $nms_server version 2c $ro_community
!
! Traps a activer
snmp-server enable traps snmp linkdown linkup coldstart warmstart
snmp-server enable traps config
snmp-server enable traps envmon
snmp-server enable traps syslog
!
! Verification :
! show snmp
! show snmp community
! show snmp host
! show snmp contact
! show snmp location
!
end
EOF
}

generate_snmp_v3() {
    local hostname="$1"
    local group_name="$2"
    local username="$3"
    local auth_pass="$4"
    local priv_pass="$5"
    local nms_server="$6"

    cat << EOF
!
! =============================================
! Configuration SNMP v3 (Securise)
! Equipement : $hostname
! =============================================
!
hostname $hostname
!
! Niveaux de securite SNMP v3 :
!   noAuthNoPriv  : Pas d'authentification, pas de chiffrement
!   authNoPriv    : Authentification (MD5/SHA), pas de chiffrement
!   authPriv      : Authentification ET chiffrement (DES/AES)
!
! Creation du groupe SNMP v3 avec securite maximale (authPriv)
snmp-server group $group_name v3 priv
!
! Creation de l'utilisateur avec authentification SHA et chiffrement AES-128
snmp-server user $username $group_name v3 auth sha $auth_pass priv aes 128 $priv_pass
!
! Envoi de traps/informs via SNMPv3
snmp-server host $nms_server version 3 priv $username
!
! Traps a activer
snmp-server enable traps snmp linkdown linkup
snmp-server enable traps config
snmp-server enable traps syslog
!
! Informations de contact
snmp-server contact admin@entreprise.local
snmp-server location "Salle Serveur Principal"
!
! Desactiver les anciennes community strings si presentes
! no snmp-server community public
! no snmp-server community private
!
! Verification :
! show snmp group
! show snmp user
! show snmp host
! show snmp engineID
!
end
EOF
}

# =============================================================================
# GENERATEURS DE CONFIGURATION CDP / LLDP
# =============================================================================

generate_cdp_lldp() {
    local hostname="$1"
    local outside_intf="$2"

    cat << EOF
!
! =============================================
! Configuration CDP et LLDP
! Equipement : $hostname
! =============================================
!
hostname $hostname
!
! --- CDP (Cisco Discovery Protocol) ---
! Protocole proprietaire Cisco, actif par defaut
!
! Activer CDP globalement
cdp run
!
! Modifier le timer CDP (defaut : 60s)
cdp timer 30
!
! Modifier le holdtime CDP (defaut : 180s)
cdp holdtime 120
!
! Desactiver CDP sur les interfaces orientees Internet (securite)
interface $outside_intf
 no cdp enable
 exit
!
! --- LLDP (Link Layer Discovery Protocol) ---
! Standard IEEE 802.1AB, compatible multi-vendeurs
!
! Activer LLDP globalement
lldp run
!
! Modifier les timers LLDP
lldp timer 30
lldp holdtime 120
lldp reinit 2
!
! Desactiver LLDP sur interfaces orientees Internet (securite)
interface $outside_intf
 no lldp transmit
 no lldp receive
 exit
!
! Verification CDP :
! show cdp
! show cdp neighbors
! show cdp neighbors detail
! show cdp interface
! show cdp entry *
!
! Verification LLDP :
! show lldp
! show lldp neighbors
! show lldp neighbors detail
! show lldp interface
!
end
EOF
}

# =============================================================================
# CONFIGURATION MONITORING COMPLETE
# =============================================================================

generate_monitoring_complete() {
    cat << EOF
!
! =============================================
! Configuration Monitoring Complete
! Infrastructure de Supervision
! =============================================
!
! Topologie :
!   [SRV-MONITOR] 172.16.100.10 (NTP + Syslog + NMS)
!        |
!   172.16.100.1/24
!   [R-CORE] Fa0/0
!   Fa0/1: 172.16.10.1/24  |  Fa0/2: 172.16.20.1/24
!        |                        |
!   [SW-DIST-1]              [SW-DIST-2]
!   172.16.10.2              172.16.20.2
!
! =============================================
! R-CORE : Configuration Complete
! =============================================
!
hostname R-CORE
!
! --- NTP ---
clock timezone CET 1 0
ntp server 172.16.100.10
!
! --- Syslog ---
service timestamps log datetime msec localtime show-timezone
service timestamps debug datetime msec localtime show-timezone
service sequence-numbers
logging host 172.16.100.10
logging trap informational
logging source-interface Loopback0
logging buffered 32768 informational
logging console warnings
!
! --- SNMP v2c (compatibilite) ---
access-list 30 permit host 172.16.100.10
snmp-server community MONITOR-RO ro 30
snmp-server community MONITOR-RW rw 30
snmp-server host 172.16.100.10 version 2c MONITOR-RO
snmp-server enable traps snmp linkdown linkup
snmp-server enable traps config
snmp-server enable traps syslog
snmp-server contact admin@entreprise.local
snmp-server location "Site Principal - Core"
!
! --- SNMP v3 (recommande en production) ---
snmp-server group MONITOR-GRP v3 priv
snmp-server user admin-snmp MONITOR-GRP v3 auth sha AuthP@ss123 priv aes 128 PrivP@ss456
snmp-server host 172.16.100.10 version 3 priv admin-snmp
!
! --- CDP / LLDP ---
cdp run
lldp run
!
! Desactiver sur interface WAN (securite)
interface Serial 0/0
 no cdp enable
 no lldp transmit
 no lldp receive
 exit
!
! =============================================
! SW-DIST-1 : Configuration Monitoring
! =============================================
!
hostname SW-DIST-1
!
! --- NTP (pointe vers R-CORE) ---
clock timezone CET 1 0
ntp server 172.16.10.1
!
! --- Syslog ---
service timestamps log datetime msec localtime show-timezone
service sequence-numbers
logging host 172.16.100.10
logging trap informational
logging buffered 16384 informational
logging console warnings
!
! --- SNMP v2c ---
access-list 30 permit host 172.16.100.10
snmp-server community MONITOR-RO ro 30
snmp-server host 172.16.100.10 version 2c MONITOR-RO
snmp-server enable traps snmp linkdown linkup
snmp-server enable traps config
snmp-server contact admin@entreprise.local
snmp-server location "Site Principal - Distribution 1"
!
! --- CDP / LLDP ---
cdp run
lldp run
!
! =============================================
! SW-DIST-2 : Configuration Monitoring
! =============================================
!
hostname SW-DIST-2
!
clock timezone CET 1 0
ntp server 172.16.20.1
!
service timestamps log datetime msec localtime show-timezone
service sequence-numbers
logging host 172.16.100.10
logging trap informational
logging buffered 16384 informational
logging console warnings
!
access-list 30 permit host 172.16.100.10
snmp-server community MONITOR-RO ro 30
snmp-server host 172.16.100.10 version 2c MONITOR-RO
snmp-server enable traps snmp linkdown linkup
snmp-server enable traps config
snmp-server contact admin@entreprise.local
snmp-server location "Site Principal - Distribution 2"
!
cdp run
lldp run
!
end
EOF
}

# =============================================================================
# COMMANDES DE TROUBLESHOOTING MONITORING
# =============================================================================

generate_monitoring_troubleshooting() {
    cat << EOF
!
! =============================================
! Commandes de Verification Monitoring
! =============================================
!
! === NTP ===
show ntp status
show ntp associations
show ntp associations detail
show clock
show clock detail
!
! Debug NTP (utiliser avec precaution)
! debug ntp events
! debug ntp packets
!
! === Syslog ===
show logging
show logging history
show logging | include %LINK
show logging | include %SYS
!
! Activer les logs sur une session VTY
terminal monitor
! Desactiver
terminal no monitor
!
! === SNMP ===
show snmp
show snmp community
show snmp group
show snmp user
show snmp host
show snmp engineID
show snmp contact
show snmp location
!
! Debug SNMP (utiliser avec precaution)
! debug snmp packets
!
! === CDP ===
show cdp
show cdp neighbors
show cdp neighbors detail
show cdp interface
show cdp entry *
show cdp traffic
!
! === LLDP ===
show lldp
show lldp neighbors
show lldp neighbors detail
show lldp interface
show lldp traffic
!
! === Verification generale ===
show processes cpu | include NTP
show processes cpu | include SNMP
show processes cpu | include Syslog
!
EOF
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo -e "${BLUE}=== Menu Configuration Monitoring ===${NC}"
    echo ""
    echo "1) Generer config NTP Serveur (Master)"
    echo "2) Generer config NTP Client"
    echo "3) Generer config Syslog"
    echo "4) Generer config SNMP v2c"
    echo "5) Generer config SNMP v3 (securise)"
    echo "6) Generer config CDP / LLDP"
    echo "7) Generer config Monitoring Complete (infrastructure)"
    echo "8) Afficher commandes de verification Monitoring"
    echo "9) Afficher aide-memoire Monitoring"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix [0-9] : " choice
    echo ""
}

show_monitoring_cheatsheet() {
    echo -e "${BLUE}=== Aide-Memoire Monitoring ===${NC}"
    echo ""
    echo "NTP :"
    echo "  ntp server [IP]          : Definir le serveur NTP"
    echo "  ntp master [stratum]     : Devenir source NTP"
    echo "  clock timezone [TZ] [+/-]: Fuseau horaire"
    echo ""
    echo "SYSLOG (niveaux de severite) :"
    echo "  0=emergencies  1=alerts       2=critical  3=errors"
    echo "  4=warnings     5=notifications 6=informational 7=debugging"
    echo "  logging host [IP]        : Serveur Syslog distant"
    echo "  logging trap [niveau]    : Niveau envoye au serveur"
    echo ""
    echo "SNMP :"
    echo "  v2c : snmp-server community [STRING] {ro|rw}"
    echo "  v3  : snmp-server group [GRP] v3 priv"
    echo "        snmp-server user [USR] [GRP] v3 auth sha [PASS] priv aes 128 [PASS]"
    echo ""
    echo "CDP / LLDP :"
    echo "  cdp run / no cdp run     : Activer/desactiver CDP"
    echo "  lldp run / no lldp run   : Activer/desactiver LLDP"
    echo "  no cdp enable            : Desactiver CDP sur une interface"
    echo ""
}

main() {
    print_header
    log_message "Demarrage du script Monitoring"

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Hostname : " hostname
                read -p "Stratum (defaut 3) : " stratum
                stratum=${stratum:-3}
                read -p "Timezone (defaut CET) : " timezone
                timezone=${timezone:-CET}
                read -p "Offset UTC (defaut 1) : " tz_offset
                tz_offset=${tz_offset:-1}
                echo ""
                generate_ntp_server "$hostname" "$stratum" "$timezone" "$tz_offset"
                ;;
            2)
                read -p "Hostname : " hostname
                read -p "IP serveur NTP : " ntp_server
                read -p "Timezone (defaut CET) : " timezone
                timezone=${timezone:-CET}
                read -p "Offset UTC (defaut 1) : " tz_offset
                tz_offset=${tz_offset:-1}
                echo ""
                generate_ntp_client "$hostname" "$ntp_server" "$timezone" "$tz_offset"
                ;;
            3)
                read -p "Hostname : " hostname
                read -p "IP serveur Syslog : " syslog_server
                read -p "Niveau (defaut informational) : " trap_level
                trap_level=${trap_level:-informational}
                read -p "Interface source (defaut Loopback0) : " source_intf
                source_intf=${source_intf:-Loopback0}
                echo ""
                generate_syslog "$hostname" "$syslog_server" "$trap_level" "$source_intf"
                ;;
            4)
                read -p "Hostname : " hostname
                read -p "Community RO (defaut MONITOR-RO) : " ro_community
                ro_community=${ro_community:-MONITOR-RO}
                read -p "Community RW (defaut MONITOR-RW) : " rw_community
                rw_community=${rw_community:-MONITOR-RW}
                read -p "IP du NMS : " nms_server
                read -p "Contact (defaut admin@entreprise.local) : " contact
                contact=${contact:-admin@entreprise.local}
                read -p "Location : " location
                location=${location:-"Salle Serveur"}
                echo ""
                generate_snmp_v2c "$hostname" "$ro_community" "$rw_community" "$nms_server" "$contact" "$location"
                ;;
            5)
                read -p "Hostname : " hostname
                read -p "Nom du groupe (defaut MONITOR-GRP) : " group_name
                group_name=${group_name:-MONITOR-GRP}
                read -p "Nom utilisateur (defaut admin-snmp) : " username
                username=${username:-admin-snmp}
                read -p "Mot de passe auth : " auth_pass
                read -p "Mot de passe priv : " priv_pass
                read -p "IP du NMS : " nms_server
                echo ""
                generate_snmp_v3 "$hostname" "$group_name" "$username" "$auth_pass" "$priv_pass" "$nms_server"
                ;;
            6)
                read -p "Hostname : " hostname
                read -p "Interface outside (ex: GigabitEthernet0/1) : " outside_intf
                echo ""
                generate_cdp_lldp "$hostname" "$outside_intf"
                ;;
            7)
                generate_monitoring_complete
                ;;
            8)
                generate_monitoring_troubleshooting
                ;;
            9)
                show_monitoring_cheatsheet
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
