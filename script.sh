#!/bin/bash

# --------------------- / INSTALLATION DE BASE \ ---------------------

# Création du fichier shared appartenant à root 
mkdir /home/shared

# Chemin vers le fichier accounts.csv
FILE="accounts.csv"

# Boucle de lecture sur le fichier account.csv (excepté la première)
tail -n +2 "$FILE" | while IFS=';' read -r name surname mail password; do

    # Suppression de l'espace dans le surname 
    surname="${surname// /}"
    # Géneration du login
    username="${name:0:1}${surname,,}"

    # Création du compte utilisateur avec mdp 
    useradd -m -p "$(openssl passwd -1 "$password")" "$username"
    #sudo useradd -m -d "/home/$username" -s "/bin/bash" "$username"
    #sudo passwd -e "$login"
    
    # Expiration du mot de passe
    usermod -e 2000-01-01 "$username"
    ##echo -e "$password\n$password" | sudo passwd --expire "$username"

    # Création du dossier "a_sauver" dans le dossier home de l'utilisateur
    mkdir -m 755 "/home/$username/a_sauver"
    chown "$username" "/home/$username/a_sauver"

    # Création d'un dossier dans le dossier "shared"
    mkdir "/home/shared/$username"
    chown "$username" "/home/shared/$username"
    chmod 755 "/home/shared/$username"
    
done 

# Mise a jour des droits du fichier shared
chown root:root /home/shared
chmod 755 /home/shared

















































