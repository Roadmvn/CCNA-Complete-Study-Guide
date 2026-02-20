# Module 3 : Routing - Protocoles et Configuration

## Vue d'Ensemble du Module

Ce module couvre le routage IP, pierre angulaire de toute infrastructure reseau. Vous maitriserez les routes statiques, le protocole OSPF, EIGRP et les bases de BGP, competences essentielles pour la certification CCNA.

## Objectifs d'Apprentissage *(Semaines 5-6)*

A la fin de ce module, vous serez capable de :

- **Configurer** des routes statiques, default routes et floating static routes
- **Deployer** OSPF single-area et multi-area
- **Comprendre** EIGRP, son algorithme DUAL et ses metriques
- **Expliquer** les bases de BGP et les concepts d'Autonomous Systems
- **Diagnostiquer** des problemes de routage avec les commandes show/debug

## Contenu du Module

### [Fiches de Revision](./fiches/)
- [Routage Statique](./fiches/routage-statique.md) - Routes statiques, default route, floating static
- [OSPF](./fiches/ospf.md) - Link-state, areas, DR/BDR, LSA, OSPFv3
- [Protocoles Avances](./fiches/protocoles-avances.md) - EIGRP, BGP, redistribution

### [Schemas et Topologies](./schemas/)
- [Topologies Routing](./schemas/topologies-routing.md) - Schemas ASCII detailles

### [Exercices Pratiques](./exercices/)
- [Labs Routing](./exercices/labs-routing.md) - Labs complets et questions de revision

### [Scripts de Configuration](./scripts/)
- [Routes Statiques](./scripts/config-static-routes.sh) - Configuration routes statiques
- [OSPF](./scripts/config-ospf.sh) - Configuration OSPF single et multi-area
- [EIGRP](./scripts/config-eigrp.sh) - Configuration EIGRP

## Checklist de Progression

### Semaine 5 : Routage Statique et OSPF Single-Area
- [ ] **Routes statiques** : next-hop, exit interface, default route
- [ ] **Floating static routes** : administrative distance, backup
- [ ] **Routes statiques IPv6** : configuration et verification
- [ ] **OSPF single-area** : configuration, neighbors, verification

### Semaine 6 : OSPF Multi-Area et Protocoles Avances
- [ ] **OSPF multi-area** : Area 0, ABR, ASBR, LSA types
- [ ] **DR/BDR** : election, fonctionnement sur segments multi-access
- [ ] **EIGRP** : DUAL, metriques, successor/feasible successor
- [ ] **BGP basics** : eBGP, iBGP, path attributes

## Technologies Couvertes

### Routage Statique
```
Decision de Routage :

Paquet arrive sur R1
        |
        v
+-------------------+
| Table de routage  |
| show ip route     |
+-------------------+
        |
        v
+-------------------+
| Longest Prefix    |
| Match             |
| /32 > /24 > /16  |
+-------------------+
        |
        v
+-------------------+     +-------------------+
| Route trouvee ?   |---->| Oui : Forward     |
+-------------------+     | via next-hop      |
        |                 +-------------------+
        v
+-------------------+
| Non : Default     |
| route ? Sinon     |
| DROP              |
+-------------------+
```

### OSPF (Open Shortest Path First)
```
Topologie OSPF Multi-Area :

                    +-------------+
                    |    ASBR     |
                    | (Redistrib) |
                    +------+------+
                           |
              +------------+------------+
              |                         |
       +------+------+          +------+------+
       |   Area 0    |          |   Area 0    |
       |  Backbone   |          |  Backbone   |
       |    ABR-1    |==========|    ABR-2    |
       +------+------+          +------+------+
              |                         |
       +------+------+          +------+------+
       |   Area 1    |          |   Area 2    |
       |  Internal   |          |  Internal   |
       |  Routers    |          |  Routers    |
       +-------------+          +-------------+
```

### EIGRP (Enhanced Interior Gateway Routing Protocol)
```
EIGRP DUAL Algorithm :

         Destination : 10.0.0.0/24
              |
    +---------+---------+
    |                   |
Successor          Feasible
(Best Path)        Successor
FD = 30720         (Backup)
                   RD < FD ?
                   20480 < 30720
                   Oui = FS valide
```

## Commandes Cisco Essentielles

### Routage Statique
```cisco
! Route statique via next-hop
ip route 192.168.2.0 255.255.255.0 10.0.0.2

! Route statique via exit interface
ip route 192.168.2.0 255.255.255.0 GigabitEthernet0/1

! Default route
ip route 0.0.0.0 0.0.0.0 10.0.0.1

! Verification
show ip route
show ip route static
```

### OSPF
```cisco
! Configuration OSPF
router ospf 1
 router-id 1.1.1.1
 network 192.168.1.0 0.0.0.255 area 0
 passive-interface GigabitEthernet0/0

! Verification
show ip ospf neighbor
show ip ospf interface brief
show ip ospf database
show ip route ospf
```

### EIGRP
```cisco
! Configuration EIGRP
router eigrp 100
 network 192.168.1.0 0.0.0.255
 no auto-summary
 passive-interface GigabitEthernet0/0

! Verification
show ip eigrp neighbors
show ip eigrp topology
show ip route eigrp
```

## Questions d'Auto-Evaluation

### Routage Statique
1. Difference entre route statique next-hop et exit interface ?
2. Qu'est-ce qu'une floating static route et quand l'utiliser ?
3. Quelle est l'administrative distance d'une route statique ?

### OSPF
1. Pourquoi Area 0 est-elle obligatoire en OSPF multi-area ?
2. Comment se deroule l'election DR/BDR ?
3. Quels sont les 7 etats de voisinage OSPF ?

### EIGRP / BGP
1. Difference entre Feasible Distance et Reported Distance ?
2. Qu'est-ce qu'un Autonomous System en BGP ?
3. Comparez les administrative distances de RIP, OSPF, EIGRP et BGP.

## Validation des Acquis

**Criteres de Reussite :**
- **Configuration** : Routes statiques et OSPF sans documentation
- **Diagnostic** : Identifier un probleme de routage en 5 minutes
- **Theorie** : Expliquer le processus OSPF neighbor adjacency
- **Analyse** : Lire et interpreter une table de routage complexe

## Prochaines Etapes

Une fois ce module maitrise :

1. **Auto-evaluation** avec les labs pratiques
2. **Validation** des competences sur Packet Tracer
3. **Transition** vers [Module 4 - Services](../04-services/README.md)

## Ressources Complementaires

- **RFC 2328** : OSPF Version 2
- **RFC 5340** : OSPF for IPv6 (OSPFv3)
- **RFC 7868** : EIGRP
- **RFC 4271** : BGP-4
- **Cisco Documentation** : IP Routing Configuration Guide

## Liens avec Autres Modules

- **Module 1 (Fondamentaux)** : Couche 3 OSI, adressage IP
- **Module 2 (Switching)** : Inter-VLAN routing, SVI
- **Module 4 (Services)** : NAT, ACLs sur interfaces routees
- **Module 5 (Securite)** : VPN, securisation du plan de controle

---

*Module cree pour la revision CCNA methodique*
*Auteur : Tudy Gbaguidi*
