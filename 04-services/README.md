# Module 4 : Services Reseau

## Vue d'Ensemble du Module

Ce module couvre les services reseau essentiels au fonctionnement d'une infrastructure d'entreprise. Vous maitriserez NAT/PAT, DHCP, les listes de controle d'acces (ACLs) et les protocoles de monitoring indispensables a la CCNA.

## Objectifs d'Apprentissage *(Semaines 7-8)*

A la fin de ce module, vous serez capable de :

- **Configurer** NAT statique, dynamique et PAT sur routeurs Cisco
- **Deployer** un serveur DHCP et configurer le relay agent
- **Implementer** des ACLs standard et etendues pour filtrer le trafic
- **Mettre en place** NTP, Syslog et SNMP pour le monitoring reseau
- **Depanner** les problemes lies aux services reseau

## Contenu du Module

### [Fiches de Revision](./fiches/)
- [NAT et PAT](./fiches/nat-pat.md) - Traduction d'adresses reseau
- [DHCP](./fiches/dhcp.md) - Attribution dynamique d'adresses
- [ACLs](./fiches/acls.md) - Listes de controle d'acces
- [Monitoring](./fiches/monitoring.md) - NTP, Syslog, SNMP, CDP/LLDP

### [Schemas et Topologies](./schemas/)
- [Schemas Services Reseau](./schemas/schemas-services.md) - Schemas ASCII detailles

### [Scripts de Configuration](./scripts/)
- [Configuration NAT](./scripts/config-nat.sh)
- [Configuration DHCP](./scripts/config-dhcp.sh)
- [Configuration ACLs](./scripts/config-acls.sh)
- [Configuration Monitoring](./scripts/config-monitoring.sh)

### [Exercices Pratiques](./exercices/)
- [Labs Services Reseau](./exercices/labs-services.md) - Labs et questions de revision

## Checklist de Progression

### Semaine 7 : NAT/PAT et DHCP
- [ ] **NAT statique** : Configuration mapping 1:1
- [ ] **NAT dynamique** : Configuration pool d'adresses
- [ ] **PAT/Overload** : Configuration many:1
- [ ] **DHCP** : Serveur, pool, exclusions
- [ ] **DHCP Relay** : ip helper-address
- [ ] **DHCPv6** : Stateful et Stateless

### Semaine 8 : ACLs et Monitoring
- [ ] **ACL Standard** : Filtrage par source
- [ ] **ACL Etendue** : Filtrage multi-criteres
- [ ] **Named ACLs** : ACLs nommees
- [ ] **NTP** : Synchronisation horaire
- [ ] **Syslog** : Journalisation centralisee
- [ ] **SNMP** : Supervision reseau
- [ ] **CDP/LLDP** : Decouverte de voisins

## Commandes Cisco Essentielles

```cisco
! NAT
show ip nat translations
show ip nat statistics
debug ip nat

! DHCP
show ip dhcp binding
show ip dhcp pool
show ip dhcp conflict

! ACLs
show access-lists
show ip interface (verifier ACL appliquee)

! Monitoring
show ntp status
show logging
show snmp
show cdp neighbors
show lldp neighbors
```

## Prochaines Etapes

Une fois ce module maitrise :

1. **Auto-evaluation** avec les labs pratiques
2. **Validation** des competences en environnement Packet Tracer
3. **Transition** vers [Module 5 - Securite et WAN](../05-securite-wan/README.md)

## Ressources Complementaires

- **RFC 3022** : Traditional IP Network Address Translator (NAT)
- **RFC 2131** : Dynamic Host Configuration Protocol (DHCP)
- **RFC 3164** : The BSD Syslog Protocol
- **Cisco Documentation** : IP Access Lists, NAT Configuration Guide

---

*Module cree pour une revision CCNA methodique*
*Auteur : Tudy Gbaguidi*
