# Automation et SDN - Software-Defined Networking, REST APIs, Configuration Management

## Vue d'Ensemble

L'automation reseau est un domaine majeur du CCNA 200-301 (environ 10% de l'examen). Il couvre le SDN (Software-Defined Networking), les REST APIs, les formats de donnees (JSON, XML) et les outils de configuration management (Ansible, Puppet, Chef). L'objectif est de comprendre comment les reseaux modernes sont geres par logiciel plutot que manuellement.

---

## 1. SDN (Software-Defined Networking)

### Principe

SDN separe le plan de controle (intelligence, decisions de routage) du plan de donnees (acheminement des paquets). Un controleur central prend les decisions et les programme sur les equipements reseau.

### Les 3 Plans du Reseau

```
ARCHITECTURE RESEAU TRADITIONNELLE vs SDN
===========================================

TRADITIONNEL :                        SDN :
Chaque equipement decide seul         Un controleur central decide

+----------+  +----------+           +---------------------+
| Routeur  |  | Routeur  |           |    CONTROLEUR SDN   |
|          |  |          |           |  (Control Plane)    |
| Control  |  | Control  |           |  - Topologie        |
| Plane    |  | Plane    |           |  - Routing          |
|----------|  |----------|           |  - Policies         |
| Data     |  | Data     |           +----------+----------+
| Plane    |  | Plane    |                      |
+----------+  +----------+              API (Southbound)
                                               |
Probleme : chaque routeur         +----+-------+--------+----+
fait ses propres calculs          |    |                |    |
= configuration manuelle         v    v                v    v
  sur chaque equipement      +------+ +------+    +------+ +------+
                              |Switch| |Switch|    |Router| |Router|
                              | Data | | Data |    | Data | | Data |
                              |Plane | |Plane |    |Plane | |Plane |
                              +------+ +------+    +------+ +------+
```

### Schema : Architecture SDN Detaillee

```
ARCHITECTURE SDN - 3 COUCHES
==============================

+--------------------------------------------------------------------+
|                    APPLICATION LAYER                                |
|                  (Northbound Interface)                             |
|                                                                    |
|  +----------+  +----------+  +----------+  +----------+           |
|  | Network  |  | Security |  | Load     |  | Network  |           |
|  | Monitor  |  | App      |  | Balancer |  | Automation|          |
|  +----------+  +----------+  +----------+  +----------+           |
|                                                                    |
|  Communication : REST API (HTTP/HTTPS)                             |
|                  JSON / XML                                        |
+--------------------------------------------------------------------+
         |              |              |              |
         v              v              v              v
     Northbound API (NB-API) : REST, gRPC, NETCONF
         |              |              |              |
+--------------------------------------------------------------------+
|                    CONTROL LAYER                                   |
|                  (SDN Controller)                                  |
|                                                                    |
|  +--------------------------------------------------------------+ |
|  |                SDN CONTROLLER                                 | |
|  |                                                              | |
|  |  +------------------+  +------------------+                  | |
|  |  | Topology Manager |  | Path Computation |                  | |
|  |  | (vue du reseau)  |  | (calcul routes)  |                  | |
|  |  +------------------+  +------------------+                  | |
|  |                                                              | |
|  |  +------------------+  +------------------+                  | |
|  |  | Policy Engine    |  | Statistics       |                  | |
|  |  | (regles/ACLs)    |  | (monitoring)     |                  | |
|  |  +------------------+  +------------------+                  | |
|  +--------------------------------------------------------------+ |
|                                                                    |
|  Exemples : Cisco DNA Center, APIC-EM, OpenDaylight, ONOS        |
+--------------------------------------------------------------------+
         |              |              |              |
         v              v              v              v
     Southbound API (SB-API) : OpenFlow, NETCONF, RESTCONF, CLI
         |              |              |              |
+--------------------------------------------------------------------+
|                 INFRASTRUCTURE LAYER                               |
|                   (Data Plane)                                     |
|                                                                    |
|  +----------+  +----------+  +----------+  +----------+           |
|  | Switch   |  | Switch   |  | Router   |  | Router   |           |
|  | (Data    |  | (Data    |  | (Data    |  | (Data    |           |
|  |  Plane)  |  |  Plane)  |  |  Plane)  |  |  Plane)  |           |
|  +----------+  +----------+  +----------+  +----------+           |
|                                                                    |
|  Equipements physiques ou virtuels qui transmettent les paquets   |
+--------------------------------------------------------------------+

INTERFACES :
+-------------------+-----------------------------------------------+
| Interface         | Role                                          |
+-------------------+-----------------------------------------------+
| Northbound (NB)   | Communication controleur <-> applications     |
|                   | Protocoles : REST API, gRPC                   |
+-------------------+-----------------------------------------------+
| Southbound (SB)   | Communication controleur <-> equipements      |
|                   | Protocoles : OpenFlow, NETCONF, RESTCONF,     |
|                   |              SNMP, SSH/CLI                     |
+-------------------+-----------------------------------------------+
| Eastbound/        | Communication entre controleurs SDN           |
| Westbound         | (haute disponibilite, federation)             |
+-------------------+-----------------------------------------------+
```

### Les 3 Plans Expliques

```
+-----------------+----------------------------------------------------+
| Plan            | Fonction                       | Exemples          |
+-----------------+----------------------------------------------------+
| Management      | Configuration, monitoring,     | SSH, SNMP,        |
| Plane           | acces administrateur           | Syslog, NTP,      |
|                 |                                | NETCONF, REST API |
+-----------------+----------------------------------------------------+
| Control Plane   | Decisions de routage,          | OSPF, EIGRP,      |
|                 | apprentissage topologie,       | BGP, STP, ARP,    |
|                 | mise a jour tables             | table MAC, FIB    |
+-----------------+----------------------------------------------------+
| Data Plane      | Acheminement effectif          | Forwarding IP,    |
| (Forwarding)    | des paquets selon les          | Switching L2,     |
|                 | tables precalculees            | NAT, ACL apply,   |
|                 |                                | QoS marking       |
+-----------------+----------------------------------------------------+
```

---

## 2. Cisco DNA Center et APIC-EM

### Cisco DNA Center

```
CISCO DNA CENTER - CONTROLEUR SDN ENTERPRISE
==============================================

+--------------------------------------------------------------------+
|                    DNA CENTER                                      |
|                                                                    |
|  +--------------------------------------------------------------+ |
|  |  FONCTIONNALITES PRINCIPALES                                 | |
|  |                                                              | |
|  |  1. DESIGN                                                   | |
|  |     - Conception topologie reseau                            | |
|  |     - Templates de configuration                            | |
|  |     - Hierarchie : Site > Building > Floor                  | |
|  |                                                              | |
|  |  2. POLICY (Intent-Based)                                    | |
|  |     - Definir des intentions business                        | |
|  |     - Traduites automatiquement en config technique          | |
|  |     - Exemple : "Le VLAN Guest ne doit pas acceder           | |
|  |       aux serveurs internes"                                | |
|  |                                                              | |
|  |  3. PROVISION                                                | |
|  |     - Deploiement automatique des configurations             | |
|  |     - Plug-and-play (zero-touch provisioning)               | |
|  |     - Image management (OS upgrades)                        | |
|  |                                                              | |
|  |  4. ASSURANCE                                                | |
|  |     - Monitoring temps reel                                  | |
|  |     - Analyse proactive des problemes                       | |
|  |     - Machine learning pour la detection d'anomalies        | |
|  +--------------------------------------------------------------+ |
|                                                                    |
|  API : REST API (HTTPS)                                           |
|  Interface : GUI web + API programmatique                         |
|  Protocoles SB : NETCONF, RESTCONF, CLI (SSH)                    |
+--------------------------------------------------------------------+

APIC-EM (predecesseur de DNA Center) :
- Plateforme SDN plus ancienne de Cisco
- Remplacee par DNA Center
- Fonctions similaires mais moins avancees
- A connaitre pour l'examen CCNA (reference historique)
```

### Intent-Based Networking (IBN)

```
INTENT-BASED NETWORKING
========================

1. INTENTION BUSINESS :
   "Les employes du marketing doivent pouvoir acceder
    a l'application CRM mais pas aux serveurs finance"
          |
          v
2. TRADUCTION :
   DNA Center traduit en politiques techniques :
   - VLAN Marketing : 10.1.20.0/24
   - ACL : permit tcp 10.1.20.0/24 host 10.1.50.10 eq 443
   - ACL : deny ip 10.1.20.0/24 10.1.30.0/24
          |
          v
3. DEPLOIEMENT AUTOMATIQUE :
   Configuration poussee sur tous les switches et routeurs
   concernes via NETCONF/CLI
          |
          v
4. VERIFICATION CONTINUE :
   DNA Center verifie en permanence que la politique
   est respectee (assurance)
          |
          v
5. REMEDIATION :
   Si une deviation est detectee, alerte ou correction
   automatique
```

---

## 3. REST APIs

### Principe

REST (REpresentational State Transfer) est un style d'architecture pour les APIs web. Il utilise les methodes HTTP standard pour interagir avec des ressources identifiees par des URLs. C'est l'interface principale entre les applications et les controleurs SDN.

### Schema : REST API Flow

```
REST API - FLUX DE COMMUNICATION
==================================

+-------------------+                     +-------------------+
|   CLIENT          |                     |   SERVEUR         |
|   (Application,   |                     |   (DNA Center,    |
|    Script Python,  |                     |    Controleur)    |
|    Postman)        |                     |                   |
+--------+----------+                     +--------+----------+
         |                                         |
         |  1. REQUEST (Requete HTTP)              |
         |  +-----------------------------------+  |
         |  | Method: GET                       |  |
         |  | URL: https://dnac.local/api/v1/   |  |
         |  |      network-device               |  |
         |  | Headers:                          |  |
         |  |   Content-Type: application/json  |  |
         |  |   X-Auth-Token: abc123xyz         |  |
         |  | Body: (vide pour GET)             |  |
         |  +-----------------------------------+  |
         |---------------------------------------->|
         |                                         |
         |                                         | 2. Traitement
         |                                         |    de la requete
         |                                         |
         |  3. RESPONSE (Reponse HTTP)             |
         |  +-----------------------------------+  |
         |  | Status: 200 OK                    |  |
         |  | Headers:                          |  |
         |  |   Content-Type: application/json  |  |
         |  | Body:                             |  |
         |  | {                                 |  |
         |  |   "response": [                   |  |
         |  |     {                             |  |
         |  |       "hostname": "SW1",          |  |
         |  |       "managementIpAddress":       |  |
         |  |         "10.1.1.1",               |  |
         |  |       "platformId": "C9300-48T"   |  |
         |  |     }                             |  |
         |  |   ]                               |  |
         |  | }                                 |  |
         |  +-----------------------------------+  |
         |<----------------------------------------|
         |                                         |
+--------+----------+                     +--------+----------+
|   CLIENT          |                     |   SERVEUR         |
+-------------------+                     +-------------------+
```

### Methodes HTTP (CRUD)

```
METHODES HTTP REST
===================

+--------+----------+--------------------------------------------------+
| Method | CRUD     | Description                    | Exemple         |
+--------+----------+--------------------------------------------------+
| GET    | Read     | Recuperer une ressource        | Lister les      |
|        |          | Pas de body dans la requete    | equipements     |
|        |          | Idempotent (meme resultat)     |                 |
+--------+----------+--------------------------------------------------+
| POST   | Create   | Creer une nouvelle ressource   | Ajouter un VLAN |
|        |          | Body contient les donnees      |                 |
|        |          | Non idempotent                 |                 |
+--------+----------+--------------------------------------------------+
| PUT    | Update   | Remplacer une ressource        | Modifier config |
|        |          | (remplacement complet)         | d'une interface |
|        |          | Body contient la ressource     |                 |
|        |          | Idempotent                     |                 |
+--------+----------+--------------------------------------------------+
| PATCH  | Update   | Modifier partiellement         | Changer juste   |
|        |          | une ressource                  | la description  |
|        |          | Body contient les champs       | d'un port       |
|        |          | a modifier                     |                 |
+--------+----------+--------------------------------------------------+
| DELETE | Delete   | Supprimer une ressource        | Supprimer un    |
|        |          | Idempotent                     | VLAN            |
+--------+----------+--------------------------------------------------+

CRUD = Create, Read, Update, Delete
Idempotent = appeler N fois donne le meme resultat qu'une seule fois
```

### Codes de Reponse HTTP

```
+-------+---------------------+------------------------------------------+
| Code  | Status              | Signification                            |
+-------+---------------------+------------------------------------------+
| 200   | OK                  | Requete reussie                          |
| 201   | Created             | Ressource creee avec succes              |
| 204   | No Content          | Succes, pas de contenu a retourner       |
| 400   | Bad Request         | Requete malformee (erreur client)        |
| 401   | Unauthorized        | Authentification requise                 |
| 403   | Forbidden           | Droits insuffisants                      |
| 404   | Not Found           | Ressource inexistante                    |
| 500   | Internal Server Err | Erreur cote serveur                      |
+-------+---------------------+------------------------------------------+

Regles a retenir :
- 2xx = Succes
- 4xx = Erreur client (verifier la requete)
- 5xx = Erreur serveur (pas de notre faute)
```

---

## 4. Formats de Donnees : JSON vs XML

### JSON (JavaScript Object Notation)

```
JSON - FORMAT LEGER ET LISIBLE
================================

Syntaxe de base :
{
  "hostname": "Switch-01",
  "managementIp": "10.1.1.1",
  "platform": "Cisco Catalyst 9300",
  "interfaces": [
    {
      "name": "GigabitEthernet0/1",
      "status": "up",
      "vlan": 10,
      "speed": 1000,
      "duplex": "full",
      "ipAddress": null
    },
    {
      "name": "GigabitEthernet0/2",
      "status": "down",
      "vlan": 20,
      "speed": 100,
      "duplex": "auto",
      "ipAddress": null
    }
  ],
  "serialNumber": "FCW2145L0AB",
  "softwareVersion": "17.6.3",
  "uptime": 864000,
  "isReachable": true
}

Types de donnees JSON :
+----------------+-------------------------+
| Type           | Exemple                 |
+----------------+-------------------------+
| String         | "hostname": "SW1"       |
| Number         | "vlan": 10              |
| Boolean        | "isReachable": true     |
| Null           | "ipAddress": null       |
| Object (dict)  | { "key": "value" }     |
| Array (liste)  | [ "item1", "item2" ]   |
+----------------+-------------------------+
```

### XML (eXtensible Markup Language)

```
XML - FORMAT STRUCTURE A BALISES
==================================

<?xml version="1.0" encoding="UTF-8"?>
<device>
  <hostname>Switch-01</hostname>
  <managementIp>10.1.1.1</managementIp>
  <platform>Cisco Catalyst 9300</platform>
  <interfaces>
    <interface>
      <name>GigabitEthernet0/1</name>
      <status>up</status>
      <vlan>10</vlan>
      <speed>1000</speed>
      <duplex>full</duplex>
    </interface>
    <interface>
      <name>GigabitEthernet0/2</name>
      <status>down</status>
      <vlan>20</vlan>
      <speed>100</speed>
      <duplex>auto</duplex>
    </interface>
  </interfaces>
  <serialNumber>FCW2145L0AB</serialNumber>
  <softwareVersion>17.6.3</softwareVersion>
  <uptime>864000</uptime>
  <isReachable>true</isReachable>
</device>
```

### Comparaison JSON vs XML

```
+-------------------------+-------------------+-------------------+
| Critere                 | JSON              | XML               |
+-------------------------+-------------------+-------------------+
| Lisibilite humaine      | Tres bonne        | Bonne             |
| Taille (verbosity)      | Compact           | Verbose           |
| Types de donnees natifs | Oui (string, int, | Non (tout est     |
|                         | bool, null, array) | texte)            |
| Parsing                 | Rapide            | Plus lent         |
| Commentaires            | Non supporte      | Supporte          |
| Validation schema       | JSON Schema       | XSD, DTD          |
| Usage REST API          | Standard (prefere)| Supporte          |
| Usage NETCONF           | Non               | Standard          |
| Usage RESTCONF          | Oui               | Oui               |
+-------------------------+-------------------+-------------------+

Tendance actuelle : JSON est prefere pour les REST APIs
                    XML reste utilise pour NETCONF
```

---

## 5. Configuration Management Tools

### Principe

Les outils de configuration management automatisent le deploiement et la gestion des configurations reseau sur de nombreux equipements simultanement, de facon reproductible et tracable.

### Comparaison : Ansible vs Puppet vs Chef

```
OUTILS DE CONFIGURATION MANAGEMENT
=====================================

+------------------------+---------------+---------------+---------------+
| Critere                | Ansible       | Puppet        | Chef          |
+------------------------+---------------+---------------+---------------+
| Architecture           | Agentless     | Agent-based   | Agent-based   |
|                        | (push via SSH)| (agent sur    | (agent sur    |
|                        |               | chaque noeud) | chaque noeud) |
+------------------------+---------------+---------------+---------------+
| Langage config         | YAML          | Puppet DSL    | Ruby          |
|                        | (Playbooks)   | (Manifests)   | (Recipes/     |
|                        |               |               |  Cookbooks)   |
+------------------------+---------------+---------------+---------------+
| Mode                   | Push          | Pull          | Pull          |
|                        | (on envoie)   | (agent tire)  | (agent tire)  |
+------------------------+---------------+---------------+---------------+
| Courbe apprentissage   | Faible        | Moyenne       | Elevee        |
+------------------------+---------------+---------------+---------------+
| Communication          | SSH / NETCONF | HTTPS (8140)  | HTTPS (443)   |
+------------------------+---------------+---------------+---------------+
| Idempotent             | Oui           | Oui           | Oui           |
+------------------------+---------------+---------------+---------------+
| Cisco support          | Tres bon      | Bon           | Moyen         |
|                        | (modules IOS) |               |               |
+------------------------+---------------+---------------+---------------+

Resume CCNA :
- Ansible = le plus simple, agentless, ideal pour le reseau
- Puppet  = tres utilise en datacenter, agent requis
- Chef    = puissant mais complexe, plus pour les developpeurs
```

### Schema : Architecture Ansible (Agentless)

```
ANSIBLE - ARCHITECTURE PUSH (AGENTLESS)
=========================================

+--------------------------------------------------------------------+
|  ANSIBLE CONTROL NODE (serveur de gestion)                         |
|                                                                    |
|  +-------------------+  +-------------------+                      |
|  | Inventory         |  | Playbook          |                      |
|  | (hosts.yaml)      |  | (deploy.yaml)     |                      |
|  |                   |  |                   |                      |
|  | [switches]        |  | - name: Config    |                      |
|  | sw1 10.1.1.1      |  |   hosts: switches |                      |
|  | sw2 10.1.1.2      |  |   tasks:          |                      |
|  | sw3 10.1.1.3      |  |     - ios_config: |                      |
|  |                   |  |       lines:      |                      |
|  | [routers]         |  |         - vlan 10 |                      |
|  | r1  10.2.1.1      |  |         - name HR |                      |
|  +-------------------+  +-------------------+                      |
|                                                                    |
+----+-----------------------+-----------------------+---------------+
     |                       |                       |
     | SSH                   | SSH                   | SSH
     | (pas d'agent)         | (pas d'agent)         | (pas d'agent)
     v                       v                       v
+----------+           +----------+           +----------+
| SW1      |           | SW2      |           | SW3      |
| 10.1.1.1 |           | 10.1.1.2 |           | 10.1.1.3 |
+----------+           +----------+           +----------+

Avantage : aucun logiciel a installer sur les equipements reseau
           SSH suffit (deja actif sur les routeurs/switches Cisco)
```

### Exemple Playbook Ansible pour Cisco IOS

```yaml
# Exemple de playbook Ansible pour configurer des VLANs
# Fichier : configure-vlans.yaml

---
- name: Configurer les VLANs sur les switches
  hosts: switches
  gather_facts: no
  connection: network_cli

  vars:
    vlans:
      - id: 10
        name: UTILISATEURS
      - id: 20
        name: SERVEURS
      - id: 30
        name: VOIP

  tasks:
    - name: Creer les VLANs
      cisco.ios.ios_vlans:
        config:
          - vlan_id: "{{ item.id }}"
            name: "{{ item.name }}"
            state: active
      loop: "{{ vlans }}"

    - name: Sauvegarder la configuration
      cisco.ios.ios_config:
        save_when: modified
```

---

## 6. Protocoles de Gestion Reseau

### NETCONF, RESTCONF, SNMP

```
PROTOCOLES DE GESTION
======================

+------------------+---------------------------------------------------+
| Protocole        | Description                                       |
+------------------+---------------------------------------------------+
| SNMP             | Simple Network Management Protocol                |
| (ancien)         | - UDP 161/162                                     |
|                  | - MIB (Management Information Base)               |
|                  | - GET/SET/TRAP                                    |
|                  | - Versions : v1 (insecure), v2c, v3 (securise)   |
|                  | - Monitoring principalement                       |
+------------------+---------------------------------------------------+
| NETCONF          | Network Configuration Protocol                    |
| (moderne)        | - TCP 830 (SSH)                                   |
|                  | - Format : XML (YANG data models)                 |
|                  | - Operations : get-config, edit-config, commit    |
|                  | - Transactionnel (rollback possible)              |
|                  | - Configuration ET monitoring                     |
+------------------+---------------------------------------------------+
| RESTCONF         | REST-based NETCONF                                |
| (moderne)        | - HTTPS 443                                       |
|                  | - Format : JSON ou XML                            |
|                  | - Methodes HTTP : GET, POST, PUT, PATCH, DELETE   |
|                  | - Plus simple que NETCONF                         |
|                  | - Memes YANG data models                          |
+------------------+---------------------------------------------------+

YANG = Yet Another Next Generation
       Langage de modelisation des donnees reseau
       Definit la structure des configurations
```

---

## 7. Resume : Automation Reseau

```
ECOSYSTEME AUTOMATION RESEAU - VUE COMPLETE
=============================================

+--------------------------------------------------------------------+
|                                                                    |
|  COUCHE APPLICATION / ORCHESTRATION                               |
|  +--------------------------------------------------------------+ |
|  | Ansible | Puppet | Chef | Terraform | Python scripts         | |
|  +--------------------------------------------------------------+ |
|                          |                                         |
|                    REST API / NETCONF / RESTCONF                   |
|                          |                                         |
|  COUCHE CONTROLEUR                                                |
|  +--------------------------------------------------------------+ |
|  | Cisco DNA Center | Meraki Dashboard | vManage (SD-WAN)       | |
|  | OpenDaylight     | ONOS             | NSO                    | |
|  +--------------------------------------------------------------+ |
|                          |                                         |
|                    NETCONF / RESTCONF / CLI (SSH) / SNMP           |
|                          |                                         |
|  COUCHE INFRASTRUCTURE                                            |
|  +--------------------------------------------------------------+ |
|  | Routeurs | Switches | Firewalls | APs WiFi | WLC            | |
|  | (IOS-XE) | (NX-OS)  | (ASA)     | (CAPWAP) |                | |
|  +--------------------------------------------------------------+ |
|                                                                    |
+--------------------------------------------------------------------+

AVANTAGES DE L'AUTOMATION :
+--------------------------------------------------------------------+
| Avantage             | Explication                                 |
+--------------------------------------------------------------------+
| Coherence            | Meme config appliquee partout, sans erreur  |
|                      | humaine (copier-coller)                     |
| Rapidite             | 100 switches configures en minutes au lieu  |
|                      | d'heures/jours                              |
| Reproductibilite     | Meme playbook = meme resultat a chaque fois |
| Audit / Compliance   | Historique des changements (git), rollback   |
| Scalabilite          | Ajouter un site = relancer le playbook      |
| Reduction erreurs    | Plus de typos, oublis de "no shutdown", etc |
+--------------------------------------------------------------------+
```

---

## Questions de Revision

### Niveau Fondamental
1. Quels sont les 3 plans d'un reseau (management, control, data) et leur role ?
2. Quelle est la difference entre Northbound API et Southbound API ?
3. Nommez les 4 methodes HTTP principales et leur operation CRUD.

### Niveau Intermediaire
1. Comparez JSON et XML : avantages et usages respectifs.
2. Pourquoi Ansible est-il dit "agentless" et quel est l'avantage pour le reseau ?
3. Expliquez le concept d'Intent-Based Networking avec un exemple concret.

### Niveau Avance
1. Decrivez le flux complet d'une requete REST API pour creer un VLAN via DNA Center : methode HTTP, URL, headers, body, code de reponse attendu.
2. Comparez SNMP, NETCONF et RESTCONF en termes de protocole de transport, format de donnees et cas d'usage.
3. Concevez un workflow d'automation pour deployer une politique de securite (port-security + DHCP snooping) sur 200 switches en utilisant Ansible.

---

*Fiche creee pour la revision CCNA*
*Auteur : Tudy Gbaguidi*
