# Module 5 : Securite, WAN et Automation

## Vue d'Ensemble du Module

Ce module couvre les trois derniers grands domaines du CCNA 200-301 : la securite des reseaux, les technologies WAN/VPN et l'automation reseau (SDN, REST APIs, configuration management). Ces sujets representent environ 25% de l'examen.

## Objectifs d'Apprentissage *(Semaines 9-10)*

A la fin de ce module, vous serez capable de :

- **Configurer** port-security, DHCP snooping et DAI sur un switch Cisco
- **Expliquer** le fonctionnement de 802.1X et AAA (RADIUS/TACACS+)
- **Deployer** un tunnel GRE et comprendre les bases IPsec
- **Comparer** les technologies WAN : MPLS, Metro Ethernet, broadband
- **Decrire** l'architecture SDN et le role des controleurs (DNA Center)
- **Utiliser** les concepts REST API : methodes HTTP, JSON, XML
- **Identifier** les outils de configuration management (Ansible, Puppet, Chef)

## Contenu du Module

### [Fiches de Revision](./fiches/)
- [Securite Reseau](./fiches/securite-reseau.md) -- Port-security, DHCP snooping, DAI, 802.1X, AAA, wireless
- [VPN et WAN](./fiches/vpn-wan.md) -- MPLS, GRE, IPsec, PPPoE, QoS
- [Automation et SDN](./fiches/automation.md) -- SDN, REST APIs, JSON/XML, Ansible, DNA Center

### [Schemas et Topologies](./schemas/)
- [Topologies Securite et WAN](./schemas/topologies-securite.md) -- Schemas ASCII detailles

### [Scripts de Configuration](./scripts/)
- [Port-Security](./scripts/config-port-security.sh)
- [DHCP Snooping](./scripts/config-dhcp-snooping.sh)
- [VPN Basic (GRE)](./scripts/config-vpn-basic.sh)

### [Exercices Pratiques](./exercices/)
- [Labs Securite et QCM Final](./exercices/labs-securite.md)

## Checklist de Progression

### Semaine 9 : Securite et WAN
- [ ] **Port-Security** : modes violation, sticky MAC, configuration
- [ ] **DHCP Snooping** : trusted/untrusted, binding table
- [ ] **DAI** : Dynamic ARP Inspection, integration avec DHCP snooping
- [ ] **802.1X** : supplicant, authenticator, authentication server
- [ ] **AAA** : Authentication, Authorization, Accounting (RADIUS vs TACACS+)
- [ ] **Wireless** : WPA2-Personal vs Enterprise, WPA3
- [ ] **WAN** : MPLS, Metro Ethernet, DSL, Cable, Fiber
- [ ] **VPN** : site-to-site vs remote access, GRE, IPsec basics

### Semaine 10 : Automation et Revision
- [ ] **SDN** : control/data/management planes separation
- [ ] **Controllers** : DNA Center, APIC-EM
- [ ] **REST APIs** : GET, POST, PUT, DELETE, codes HTTP
- [ ] **Formats** : JSON vs XML (syntaxe, parsing)
- [ ] **Config Management** : Ansible, Puppet, Chef (differences)
- [ ] **Intent-Based Networking** : concepts et implementation
- [ ] **QCM Final** : revision multi-modules 01-05

## Commandes Essentielles de ce Module

```cisco
! Port-Security
switchport port-security
switchport port-security maximum 2
switchport port-security violation shutdown
switchport port-security mac-address sticky
show port-security interface fa0/1

! DHCP Snooping
ip dhcp snooping
ip dhcp snooping vlan 10
interface gi0/1
  ip dhcp snooping trust
show ip dhcp snooping binding

! Verification securite
show ip arp inspection
show dot1x all
show aaa sessions
```

## Questions d'Auto-Evaluation

### Niveau Comprehension
1. Quels sont les trois modes de violation port-security ?
2. Comment DHCP snooping protege contre les serveurs DHCP malveillants ?
3. Quelle est la difference entre un VPN site-to-site et remote access ?

### Niveau Application
1. Configurez port-security avec sticky MAC et mode restrict
2. Mettez en place DHCP snooping sur le VLAN 10
3. Decrivez le flux IKE Phase 1 puis Phase 2

### Niveau Analyse
1. Comparez RADIUS et TACACS+ : avantages/inconvenients
2. Expliquez pourquoi SDN separe le control plane du data plane
3. Concevez une architecture securisee avec DMZ, IDS/IPS et firewall

## Validation des Acquis

**Criteres de Reussite :**
- Configurer port-security et DHCP snooping sans documentation
- Expliquer le flux 802.1X complet (supplicant -> authenticator -> RADIUS)
- Configurer un tunnel GRE entre deux routeurs
- Decrire l'architecture SDN et les avantages de l'automation
- Reussir le QCM final avec 80% minimum

## Prochaines Etapes

Une fois ce module maitrise :

1. **Revision finale** de tous les modules (01 a 05)
2. **Examen blanc** complet type CCNA 200-301
3. **Passage de l'examen** Cisco CCNA

## Ressources Complementaires

- **Cisco Press** : CCNA 200-301 Official Cert Guide, Volume 2
- **Cisco Documentation** : Security Configuration Guide, IOS XE
- **RFC 3748** : Extensible Authentication Protocol (EAP)
- **RFC 2784** : Generic Routing Encapsulation (GRE)
- **Cisco DevNet** : REST API et Automation Learning Labs

---

*Module cree pour une revision CCNA methodique*
*Auteur : Roadmvn*
