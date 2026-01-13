# TP – Haute Disponibilité d’un serveur Web sous Debian

## Objectif du TP

L’objectif de ce TP est de mettre en place une **infrastructure haute disponibilité (HA)** composée de **deux serveurs Debian** hébergeant un serveur web **Nginx**, avec une **bascule automatique** en cas de panne du serveur principal ou du service web.

L’utilisateur accède au service via une **IP virtuelle (VIP)** qui est automatiquement déplacée vers le serveur de secours en cas de défaillance.

---

## Architecture mise en place

- 2 machines virtuelles Debian :
  - **MASTER** : serveur principal
  - **BACKUP** : serveur de secours
- 1 IP virtuelle (VIP)
- Serveur web : **Nginx**
- Mécanisme de bascule : **Keepalived (VRRP)**
- Hyperviseur : **VMware**
- Réseau :
  - **Host-Only** : haute disponibilité (VIP)
  - **NAT** : accès Internet (APT)

---

## Récupération des machines virtuelles

Les machines virtuelles sont fournies sous forme de fichiers **OVA**.

Télécharger les fichiers depuis la page **Releases** du dépôt GitHub :
- `MASTER.ova`
- `BACKUP.ova`

Lien : [https://github.com/Danette10/FYC-TP/releases](https://github.com/Danette10/FYC-TP/releases)


---

## Prérequis

- VMware Workstation ou VMware Player
- Un PC hôte
- Connexion Internet (pour l’installation des paquets)

---

## Import des machines virtuelles

Pour chaque fichier `.ova` :
1. Ouvrir VMware
2. **File → Open**
3. Sélectionner le fichier `.ova`
4. Nommer les machines respectivement **MASTER** et **BACKUP** pour plus de lisiblité
5. Importer la machine

Importer **les deux VM** :
- MASTER
- BACKUP

---

## Configuration réseau VMware (IMPORTANT)

Chaque VM doit avoir **2 cartes réseau** :

### Carte réseau 1
- **Host-Only (VMnet2)**
- Sous-réseau : `192.168.116.0/24`
- Sert à la haute disponibilité (VIP)

### Carte réseau 2
- **NAT**
- Sert uniquement à l’accès Internet (APT)

---

## Script d’installation et de configuration

Un script unique permet :
- de configurer le réseau Host-Only
- d’installer Nginx et Keepalived
- de configurer l’IP virtuelle
- de mettre en place la bascule automatique
- de vérifier l’état du service web

Le script s’appelle : ``setup-ha-web.sh``

---

## Étapes à effectuer sur CHAQUE VM

### Accéder à la vm via ssh sur votre pc hote pour plus de confort

### Passer en root
```bash
su -
Entrer le mot de passe root
```

### Créer le script
```bash
nano setup-ha-web.sh
```
- Coller le contenu du script fourni dans le dépôt GitHub
- Sauvegarder avec CTRL + O, puis Entrée
- Quitter avec CTRL + X

### Rendre le script exécutable
```bash
chmod +x setup-ha-web.sh
```

## Exécution du script

### Sur la VM MASTER

```bash
./setup-ha-web.sh --role master --ho-ip 192.168.116.10 --vip 192.168.116.100
```

### Sur la VM BACKUP

```bash
./setup-ha-web.sh --role backup --ho-ip 192.168.116.11 --vip 192.168.116.100
```

## Tests de fonctionnement

### Accès au site web

Depuis le PC hôte, ouvrir un navigateur ou un terminal :
```bash
curl -I http://192.168.116.100
```
Le site doit répondre correctement.

Un en-tête HTTP permet d’identifier le serveur actif :
```css
X-Served-By: master
```

## Test de bascule (failover)

### Sur la VM MASTER

```bash
systemctl stop nginx
```
Attendre quelques secondes, puis relancer la commande depuis le PC hôte :
```bash
curl -I http://192.168.116.100
```
Résultat attendu :
```css
X-Served-By: backup
```
- Le site reste accessible
- La bascule est automatique
- Le serveur BACKUP a pris le relais

## Résultat attendu

- Le site est toujours accessible via la VIP
- La bascule se fait :
  - si le service Nginx tombe
  - si le serveur MASTER s’arrête
- Le contenu du site est **identique**
- La haute disponibilité est effective et vérifiable

## Conclusion

Ce TP met en œuvre une architecture réaliste de haute disponibilité basée sur :
- la redondance de serveurs
- une IP virtuelle
- une détection automatique des pannes
Il illustre les principes fondamentaux utilisés en entreprise pour garantir la continuité de service.
