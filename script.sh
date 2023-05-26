#!/bin/bash

# --------------------------------[[CREATION DES DOSSIER ET UTILISATEURS]--------------------------------[

# Création du fichier shared appartenant à root 
mkdir /home/shared

# Chemin vers le fichier accounts.csv
FILE="accounts.csv"

# Demande des détails du serveur SMTP
echo "Veuillez saisir votre adresse de serveur smtp (pour Outlook : smtp.office365.com) :"
read smtp_server

echo "Veuillez saisir le port de votre serveur smtp (pour Outlook : 587) :"
read smtp_port

echo "Veuillez rentrer l'adresse email de l'expéditeur :"
read from_email

echo "Veuillez saisir le mot de passe de cette adresse e-mail :"
read smtp_password

    
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
    
    # --------------------------------[ENVOI DE MAIL]--------------------------------
    
    # Spécifiez les détails de l'e-mail
    body="Bonjour $name $surname,\n\nVotre compte utilisateur a été créé avec succès.\nVotre login : $username\nVotre mot de passe de connexion est : $password\n\n/!\ Attention ce mot de passe devra être changé lors de votre première connexion\n\n'Cordialement,\n\nL'équipe de support"
          
    # Envoi de l'e-mail via le serveur SMTP
     
    subject="Votre compte a été créé"
    #mail --subject "Votre compte a été créé" --exec "set sendmail=smtp://${from_email/@/%40}:${smtp_password/@/%40}@$smtp_server:$smtp_port" --append "From:$from_email" $mail <<< "$body"
    ssh -n aaugus25@10.30.48.100 "mail --subject \"Votre compte a été créé\" --exec \"set sendmail=smtp://${from_email/@/%40}:${smtp_password/@/%40}@$smtp_server:$smtp_port\" --append \"From:$from_email\" $mail <<< \"$body\" "

done 

# Mise a jour des droits du fichier shared
chown root:root /home/shared
chmod 755 /home/shared

















































