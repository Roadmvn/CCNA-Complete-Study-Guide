! ============================================================
! Script Cisco IOS : Configuration Port-Security
! Objectif : Securiser les ports d'acces contre le MAC flooding
!            et les connexions non autorisees
! Auteur : Roadmvn
! ============================================================

! Prerequis : les ports doivent etre en mode access
! Ne PAS activer port-security sur un port trunk

! ============================================================
! ETAPE 1 : Configurer les ports en mode access
! ============================================================
configure terminal

interface range fastEthernet 0/1 - 24
 switchport mode access
 switchport access vlan 10
 no shutdown

! ============================================================
! ETAPE 2 : Activer port-security avec sticky MAC
! ============================================================

! Configuration recommandee pour un environnement bureautique
interface range fastEthernet 0/1 - 24
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation restrict
 switchport port-security mac-address sticky

! Explication des parametres :
! - maximum 2 : autorise 2 MAC par port (PC + telephone IP)
! - violation restrict : drop le trafic non autorise + log
!   (sans desactiver le port)
! - sticky : apprend dynamiquement les MAC et les sauvegarde
!   dans la running-config

! ============================================================
! ETAPE 3 : Ports critiques (serveurs) en mode shutdown
! ============================================================

! Pour les ports serveurs, utiliser le mode shutdown
! car une violation indique une tentative suspecte
interface range fastEthernet 0/45 - 48
 switchport mode access
 switchport access vlan 30
 switchport port-security
 switchport port-security maximum 1
 switchport port-security violation shutdown
 switchport port-security mac-address sticky

! ============================================================
! ETAPE 4 : Auto-recovery pour les ports en err-disabled
! ============================================================

! Reactiver automatiquement les ports apres 300 secondes
errdisable recovery cause psecure-violation
errdisable recovery interval 300

! ============================================================
! ETAPE 5 : Desactiver les ports non utilises
! ============================================================

! Bonne pratique : shutdown les ports inutilises
! et les mettre dans un VLAN "parking"
vlan 999
 name PARKING_UNUSED

interface range fastEthernet 0/25 - 44
 switchport mode access
 switchport access vlan 999
 shutdown

end

! ============================================================
! VERIFICATION
! ============================================================

show port-security
show port-security interface fastEthernet 0/1
show port-security address
show errdisable recovery

! ============================================================
! SAUVEGARDER LA CONFIGURATION
! ============================================================

write memory
