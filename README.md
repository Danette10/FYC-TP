# TP – Mise en place d’une architecture Web avec bascule automatique sous Debian

---

## Contexte

Dans un environnement professionnel, un site web doit rester accessible même lorsqu’un serveur rencontre un problème (panne, service arrêté, erreur de configuration, etc.).

Pour répondre à ce besoin, on met en place une **architecture à haute disponibilité**, c’est-à-dire une infrastructure capable de continuer à fournir un service même si un serveur tombe en panne.

Dans ce TP, vous allez mettre en place **deux serveurs web** fonctionnant ensemble :
- un serveur principal
- un serveur de secours

Si le serveur principal ne fonctionne plus correctement, le serveur de secours prendra automatiquement le relais, sans interruption visible pour l’utilisateur.

---

## Objectifs pédagogiques

À l’issue de ce TP, vous serez capable de :

- Comprendre le principe de **continuité de service**
- Mettre en place **deux serveurs web redondants**
- Configurer une **adresse IP virtuelle** utilisée par les clients
- Détecter automatiquement une panne de service web
- Mettre en œuvre une **bascule automatique** vers un serveur de secours
- Vérifier le bon fonctionnement du système côté utilisateur

---

## Travail demandé

Vous devez mettre en place une infrastructure composée de **deux machines Debian** hébergeant un serveur web **Nginx**.

L’utilisateur accède au site web **uniquement via une adresse IP virtuelle (VIP)**.  
Cette adresse IP doit automatiquement être déplacée vers le serveur disponible en cas de panne du serveur principal.

---

## Contraintes à respecter

- Les deux serveurs doivent héberger le **même site web**
- L’utilisateur ne doit jamais accéder directement aux adresses IP des serveurs
- La bascule doit être **automatique**, sans intervention manuelle
- La détection de panne doit vérifier :
  - que le serveur est accessible
  - et que le **service web fonctionne réellement**
- Le site doit rester accessible pendant toute la durée des tests

---

## Architecture cible à réaliser

- **Deux machines virtuelles Debian**
  - Serveur principal (MASTER)
  - Serveur de secours (BACKUP)
- **Une adresse IP virtuelle (VIP)** partagée entre les deux serveurs
- **Serveur web** : Nginx
- **Mécanisme de bascule automatique** : Keepalived
- **Hyperviseur** : VMware

---

## Mise à disposition des machines virtuelles

Les machines virtuelles sont fournies sous forme de fichiers **OVA**.

Vous devez :
- télécharger les deux fichiers
- importer les machines virtuelles dans VMware
- vérifier leur bon fonctionnement

Lien de téléchargement : [https://github.com/Danette10/FYC-TP/releases](https://github.com/Danette10/FYC-TP/releases)

---

## Configuration réseau requise (IMPORTANT)

Chaque machine virtuelle doit disposer de **deux interfaces réseau**.

### Interface 1 – Réseau de haute disponibilité
- Mode : **Host-Only**
- Sous-réseau : `192.168.116.0/24`
- Utilisée pour :
  - la communication entre les serveurs
  - l’adresse IP virtuelle (VIP)

### Interface 2 – Accès Internet
- Mode : **NAT**
- Utilisée uniquement pour :
  - l’installation des paquets
  - les mises à jour du système

---

## Travail à réaliser

Vous devez :

1. Configurer le réseau des deux machines virtuelles
2. Installer et configurer un serveur web Nginx sur chaque serveur
3. Mettre en place un mécanisme de bascule automatique avec :
   - une adresse IP virtuelle
   - une détection de panne du service web
4. Vérifier que l’adresse IP virtuelle est déplacée automatiquement vers le serveur disponible
5. Tester le fonctionnement du système en simulant différentes pannes

---

## Tests à effectuer

Vous devrez prouver le bon fonctionnement de votre infrastructure en réalisant notamment :

- un accès normal au site web via l’adresse IP virtuelle
- une simulation de panne du serveur principal
- une vérification que le site reste accessible
- une identification du serveur actuellement actif

---

## Conclusion

Ce TP doit démontrer votre capacité à mettre en place une **architecture robuste** permettant d’assurer la continuité d’un service web en cas de panne.


