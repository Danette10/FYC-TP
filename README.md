# TP — Infrastructure Web Hautement Disponible & PRA sécurisé

## Contexte pédagogique

Une entreprise souhaite héberger un service web critique devant rester disponible même en cas de panne (serveur, service, incident de sécurité).
L’objectif est de concevoir une infrastructure réaliste, intégrant à la fois :
- haute disponibilité (HA)
- journalisation des incidents
- synchronisation sécurisée des données
- protection contre la propagation d’un ransomware
- plan de reprise d’activité (PRA)

## Objectif du TP

À l’issue de ce TP, l’étudiant devra être capable de :
- Mettre en place une architecture web redondante
- Garantir la continuité de service via une IP virtuelle
- Analyser une panne à partir de logs
- Comprendre la différence entre réplication et sauvegarde
- Mettre en œuvre une synchronisation sécurisée
- Empêcher la propagation d’un ransomware
- Restaurer un service à partir de snapshots

---

## Architecture cible

### Infrastructures

- 2 machines virtuelles Debian :
  - **MASTER** : serveur principal
  - **BACKUP** : serveur de secours
- 1 IP virtuelle (VIP)
- Serveur web : **Nginx**
- Haute disponibilité : **Keepalived (VRRP)**

### Réseau

- **NAT** : accès Internet (APT)
- **Host-Only** : réseau interne HA (VIP)

---

## Ressources fournies

- 2 fichiers OVA :
  - ``MASTER.ova``
  - ``BACKUP.ova``
- 1 script d’automatisation :
  - ``setup-ha-web.sh``
- 1 repo GitHub contenant :
  - le script
  - la documentation

Lien : [https://github.com/Danette10/FYC-TP/releases](https://github.com/Danette10/FYC-TP/releases)

---

## Prérequis

- VMware Workstation ou VMware Player
- Connexion Internet (pour l’installation des paquets)
- Connaissances de base Linux (shell, édition de fichiers)

---

## Partie 1 — Mise en place de la haute disponibilité

### Travail demandé

- Importer les deux machines virtuelles fournies :
  - une machine jouant le rôle de **serveur principal (MASTER)** ;
  - une machine jouant le rôle de **serveur de secours (BACKUP)**.

- Configurer les cartes réseau sur chaque machine virtuelle :
  - **Carte réseau 1** en mode **NAT** afin de permettre l’accès à Internet ;
  - **Carte réseau 2** en mode **Host-Only**, sur le réseau `192.168.116.0/24`, dédié aux communications internes.

- Installer un **serveur web** sur les deux machines virtuelles.

- Configurer le service web de manière à ce que :
  - le site soit fonctionnel sur chaque serveur ;
  - le contenu du site soit identique sur les deux machines.

- Mettre en place un **mécanisme de haute disponibilité** permettant :
  - l’utilisation d’une **adresse IP virtuelle (VIP)** comme point d’accès unique ;
  - la bascule automatique du service vers le serveur de secours en cas de panne.

- Configurer un **mécanisme de surveillance du service web** afin que :
  - l’arrêt du service soit détecté automatiquement ;
  - la bascule soit déclenchée sans intervention humaine.

- Tester la **haute disponibilité** en simulant :
  - l’arrêt du service web sur le serveur principal ;
  - l’arrêt complet du serveur principal.
 
## Partie 2 — Journalisation et traçabilité des incidents

### Travail demandé

- Mettre en place un **système de journalisation** permettant de tracer :
  - les pannes du service web ;
  - les bascules entre le serveur principal et le serveur de secours ;
  - le retour à un fonctionnement normal.

- Vérifier que les événements liés à la haute disponibilité sont **enregistrés dans des journaux exploitables**.

- Identifier et consulter les journaux permettant d’analyser :
  - l’arrêt d’un service ;
  - un changement d’état du mécanisme de haute disponibilité.

- Provoquer volontairement une panne et :
  - identifier l’événement correspondant dans les logs ;
  - relever la date, l’heure et la nature de l’incident.

- Expliquer l’intérêt de la journalisation dans le cadre d’un **Plan de Reprise d’Activité (PRA)**.

## Partie 3 — Synchronisation des données du service web

### Travail demandé

- Mettre en place un **mécanisme de synchronisation** des fichiers du site web entre les deux serveurs.

- S’assurer que :
  - le contenu du site reste identique sur les deux machines ;
  - la synchronisation est automatisée ;
  - aucune action manuelle n’est nécessaire en fonctionnement normal.

- Analyser les limites d’une synchronisation classique dans un contexte d’incident de sécurité.
- Justifier l’architecture de synchronisation retenue.

## Partie 4 — Protection contre la propagation d’un ransomware

### Travail demandé

- Identifier les risques liés à la propagation d’un ransomware dans une infrastructure redondante.

- Mettre en œuvre une **synchronisation sécurisée** permettant :
  - d’éviter la diffusion d’une compromission vers le serveur de secours ;
  - de conserver des versions antérieures des données ;
  - de bloquer une synchronisation en cas de comportement suspect.

- Vérifier que les données précédentes restent accessibles après une tentative de compromission.

- Justifier les choix techniques effectués au regard des objectifs de sécurité.

## Partie 5 — Plan de Reprise d’Activité (PRA) et restauration

### Travail demandé

- Simuler un incident de sécurité impactant les données du service web.

- Vérifier que :
  - l’incident est détecté ;
  - les données saines antérieures sont toujours disponibles.

- Mettre en œuvre une **procédure de restauration** permettant de :
  - rétablir un service web fonctionnel ;
  - restaurer une version saine des données.

- Tester l’accessibilité du site après restauration.

- Analyser le temps de reprise et l’efficacité de la solution mise en place.

## Conclusion

Ce TP permet aux étudiants de mettre en œuvre une **infrastructure réaliste**, inspirée de celles utilisées en entreprise, intégrant à la fois des notions de **haute disponibilité**, de **sécurité** et de **plan de reprise d’activité (PRA)**.
Au-delà de la simple mise en place technique, les étudiants apprennent à :
- concevoir une architecture résiliente capable de faire face à des pannes matérielles ou logicielles ;
- comprendre le rôle et les limites des mécanismes de haute disponibilité ;
- analyser un incident à partir de journaux de sécurité exploitables ;
- distinguer clairement une **réplication** d’une **sauvegarde sécurisée** ;
- intégrer la problématique des ransomwares dans la conception d’une infrastructure ;
- mettre en œuvre une procédure de restauration fiable après incident.

Ce TP développe également une approche **réflexive et critique**, essentielle en environnement professionnel, où la continuité de service, la traçabilité et la capacité de reprise sont des enjeux majeurs.

À l’issue de ce travail, les étudiants disposent d’une vision globale des problématiques liées à la disponibilité et à la sécurité des systèmes, ainsi que des compétences pratiques directement transposables en entreprise.
