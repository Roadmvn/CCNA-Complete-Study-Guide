! ============================================================
! Script Cisco IOS : Configuration DHCP Snooping + DAI
! Objectif : Proteger contre les serveurs DHCP malveillants
!            et les attaques ARP spoofing
! Auteur : Tudy Gbaguidi
! ============================================================

! Prerequis :
! - VLANs deja configures
! - Ports access et trunk configures
! - Connaitre le port connecte au serveur DHCP legitime

! ============================================================
! ETAPE 1 : Activer DHCP Snooping
! ============================================================
configure terminal

! Activation globale
ip dhcp snooping

! Activer sur les VLANs concernes
ip dhcp snooping vlan 10
ip dhcp snooping vlan 20
ip dhcp snooping vlan 30

! ============================================================
! ETAPE 2 : Configurer les ports TRUSTED
! ============================================================

! Port vers le serveur DHCP (ou le routeur avec DHCP relay)
interface gigabitEthernet 0/1
 ip dhcp snooping trust

! Port trunk vers le routeur/distribution (si DHCP relay)
interface gigabitEthernet 0/2
 ip dhcp snooping trust

! Tous les autres ports restent UNTRUSTED par defaut
! = les ports access vers les PCs utilisateurs

! ============================================================
! ETAPE 3 : Limiter le debit DHCP (anti-DoS)
! ============================================================

! Limiter les requetes DHCP a 5 paquets/seconde sur les ports access
! Cela empeche un attaquant de saturer le serveur DHCP
interface range fastEthernet 0/1 - 24
 ip dhcp snooping limit rate 5

! ============================================================
! ETAPE 4 : Activer Dynamic ARP Inspection (DAI)
! ============================================================

! DAI utilise la binding table de DHCP snooping pour valider les ARP
ip arp inspection vlan 10
ip arp inspection vlan 20
ip arp inspection vlan 30

! Les ports trusted pour DAI (vers routeur et serveur DHCP)
interface gigabitEthernet 0/1
 ip arp inspection trust

interface gigabitEthernet 0/2
 ip arp inspection trust

! ============================================================
! ETAPE 5 : Gestion des hotes a IP statique
! ============================================================

! Les hotes avec IP statique ne sont pas dans la binding table DHCP.
! Il faut creer une ARP ACL pour les autoriser.

arp access-list STATIC-HOSTS
 permit ip host 10.1.10.100 mac host AA:BB:CC:DD:EE:01
 permit ip host 10.1.10.101 mac host AA:BB:CC:DD:EE:02
 permit ip host 10.1.10.102 mac host AA:BB:CC:DD:EE:03

! Appliquer l'ARP ACL sur les VLANs concernes
ip arp inspection filter STATIC-HOSTS vlan 10

! ============================================================
! ETAPE 6 : Validation supplementaire DAI (optionnel)
! ============================================================

! Verifier aussi la coherence IP et MAC dans les en-tetes
ip arp inspection validate src-mac dst-mac ip

end

! ============================================================
! VERIFICATION
! ============================================================

! Verifier DHCP snooping
show ip dhcp snooping
show ip dhcp snooping binding
show ip dhcp snooping statistics

! Verifier DAI
show ip arp inspection
show ip arp inspection vlan 10
show ip arp inspection statistics

! ============================================================
! SAUVEGARDER LA CONFIGURATION
! ============================================================

write memory
