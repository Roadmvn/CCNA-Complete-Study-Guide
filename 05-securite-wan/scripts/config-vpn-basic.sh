! ============================================================
! Script Cisco IOS : Configuration Tunnel GRE
! Objectif : Creer un tunnel GRE entre deux sites distants
!            a travers Internet
! Auteur : Roadmvn
! ============================================================

! Topologie :
!
! LAN-A (10.1.1.0/24)               LAN-B (10.2.2.0/24)
!     |                                   |
!  [R1] --- Internet --- [R2]
!  WAN: 203.0.113.1          WAN: 198.51.100.1
!  Tunnel0: 172.16.1.1       Tunnel0: 172.16.1.2

! ============================================================
! CONFIGURATION ROUTEUR R1 (Site A - Siege)
! ============================================================
! Executer ces commandes sur le routeur R1

configure terminal

hostname R1

! Interface LAN
interface gigabitEthernet 0/0
 description LAN Site A
 ip address 10.1.1.1 255.255.255.0
 no shutdown

! Interface WAN (vers Internet)
interface gigabitEthernet 0/1
 description WAN vers Internet
 ip address 203.0.113.1 255.255.255.0
 no shutdown

! Configuration du tunnel GRE
interface tunnel 0
 description GRE Tunnel vers Site B
 ip address 172.16.1.1 255.255.255.252
 tunnel source gigabitEthernet 0/1
 tunnel destination 198.51.100.1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 no shutdown

! Route vers le LAN distant via le tunnel
ip route 10.2.2.0 255.255.255.0 172.16.1.2

! Route par defaut vers Internet (si necessaire)
ip route 0.0.0.0 0.0.0.0 203.0.113.254

end
write memory

! ============================================================
! CONFIGURATION ROUTEUR R2 (Site B - Succursale)
! ============================================================
! Executer ces commandes sur le routeur R2

configure terminal

hostname R2

! Interface LAN
interface gigabitEthernet 0/0
 description LAN Site B
 ip address 10.2.2.1 255.255.255.0
 no shutdown

! Interface WAN (vers Internet)
interface gigabitEthernet 0/1
 description WAN vers Internet
 ip address 198.51.100.1 255.255.255.0
 no shutdown

! Configuration du tunnel GRE
interface tunnel 0
 description GRE Tunnel vers Site A
 ip address 172.16.1.2 255.255.255.252
 tunnel source gigabitEthernet 0/1
 tunnel destination 203.0.113.1
 tunnel mode gre ip
 ip mtu 1476
 ip tcp adjust-mss 1436
 no shutdown

! Route vers le LAN distant via le tunnel
ip route 10.1.1.0 255.255.255.0 172.16.1.1

! Route par defaut vers Internet (si necessaire)
ip route 0.0.0.0 0.0.0.0 198.51.100.254

end
write memory

! ============================================================
! VERIFICATION (sur les deux routeurs)
! ============================================================

! Verifier l'etat du tunnel
show interface tunnel 0
! -> Line protocol is up

! Verifier la table de routage
show ip route
! -> 10.2.2.0/24 via 172.16.1.2 (sur R1)
! -> 10.1.1.0/24 via 172.16.1.1 (sur R2)

! Test de connectivite tunnel
ping 172.16.1.2 source 172.16.1.1
! -> Doit reussir

! Test de connectivite LAN-to-LAN
ping 10.2.2.1 source 10.1.1.1
! -> Doit reussir

! Verifier les details du tunnel
show interfaces tunnel 0 | include tunnel
! -> Tunnel source 203.0.113.1 (GigabitEthernet0/1)
! -> Tunnel destination 198.51.100.1

! ============================================================
! TROUBLESHOOTING
! ============================================================

! Si le tunnel est down :
! 1. Verifier que les interfaces WAN sont up
show ip interface brief

! 2. Verifier la connectivite WAN entre les deux routeurs
ping 198.51.100.1 source 203.0.113.1

! 3. Verifier la configuration du tunnel
show running-config interface tunnel 0

! 4. Si problemes de fragmentation (paquets perdus de grande taille) :
!    Verifier le MTU et le MSS
show interface tunnel 0 | include MTU

! Notes :
! - GRE overhead = 24 octets (20 IP + 4 GRE)
! - MTU tunnel = 1500 - 24 = 1476
! - MSS TCP = 1476 - 40 (IP+TCP) = 1436
! - Si GRE + IPsec : overhead supplementaire d'environ 50 octets
