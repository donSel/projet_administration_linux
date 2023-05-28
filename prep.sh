#!/bin/bash

# --------------------- / SUPPRESSION DES UTILISATEURS ET DOSSIERS CREES SUR LA MACHINE LOCALE \ ---------------------

# MAJ dorits
chmod +x prep.sh
chmod +x script.sh

# Exclure l'utilisateur "isen"
excluded_user="isen"

# Parcourir tous les utilisateurs du répertoire /home
for user in /home/*; do
  # Extraire le nom d'utilisateur à partir du chemin
  username=$(basename "$user")

  # Vérifier si l'utilisateur est différent de celui à exclure
  if [ "$username" != "$excluded_user" ]; then
    # Supprimer l'utilisateur et son dossier personnel
    sudo deluser --remove-home "$username"
  fi
done

sudo rm -r /home/shared

# --------------------- / SUPPRESSION DES UTILISATEURS ET DOSSIERS CREES SUR LE SERVEUR DISTANT \ ---------------------
