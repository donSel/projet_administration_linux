# projet_administration_linux

Ce projet à pour objectif de déployer des comptes pour un ensembles d'utilisateurs (dont les informations sont contenues dans le fichier ```account.csv```)
grâce à un unique script bash.

La création de compte comprend :
- Création d’un compte sur une machine locale, avec un home, un login déterminé, un mot de passe déterminé et à changer, envoi de mail de connexion avec explications 
(serveur smtp).
- Configuration de la connexion ssh sur le serveur distant pour chaqun des utilisateurs.
- Système de sauvegarde automatique d’un dossier, zippé, envoi au serveur, capacité à récupérer le fichier zippé et à le rétablir.
- Installation d'Eclipse sans utiliser apt
- Configuration d'un pare-feu
- Installation d'un système client-serveur Nextcloud
- Monitoring


# Utilisation 

- Le script ```script.sh``` sera lancé depuis une machine locale qui est connectée à la machine SSH (10.38.40.100) en tant que root :
```sudo ./script.sh```
- Le script ```prep.sh``` permet simplement de supprimer les utilisateurs et dossiers créés par le script ```script.sh``` sur la machine locale excepté l'utilisateur "isen"

