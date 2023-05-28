#!/bin/bash

# Définition des variables
SERVER_IP=10.30.48.100
SERVER_USER="aaugus25"
FILE="accounts.csv"

# --------------------------------[CREATION DES DOSSIER ET UTILISATEURS]--------------------------------[

# Création du fichier shared appartenant à root 
mkdir /home/shared

# Mise a jour des droits du fichier shared
chown root:root /home/shared
chmod 755 /home/shared

# Création du dossier "saves" sur la machine distante
ssh -n -i /home/isen/.ssh/id_rsa "$SERVER_USER@$SERVER_IP" mkdir "/home/saves"
ssh -n -i /home/isen/.ssh/id_rsa "$SERVER_USER@$SERVER_IP" chown "$SERVER_USER:$SERVER_USER" "/home/saves"
ssh -n -i /home/isen/.ssh/id_rsa "$SERVER_USER@$SERVER_IP" chmod 777 "/home/saves"

# Demande des des informations pour l'envoi de mail
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
    
    # Expiration du mot de passe
    usermod -e 2000-01-01 "$username"
    
    # Création d'un dossier dans le dossier "shared"
    mkdir "/home/shared/$username"
    chown "$username" "/home/shared/$username"
    chmod 755 "/home/shared/$username"
    
    # Création d'un lien symbolique vers eclipse dans le dossier home de l'utilisateur
    ln -s /usr/local/share/eclipse/eclipse "/home/$username/eclipse"

    # Création des dossier ".ssh" pour l'utilisateur    
    mkdir "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"

    # Création d'une clé SSH pour l'utilisateur
    ssh-keygen -t rsa -b 2048 -f "/home/$username/.ssh/id_rsa" -q -N ""
    chown -R "$username:$username" "/home/$username/.ssh"

    # Ajout de la clé publique de l'utilisateur dans le fichier authorized_keys distant
    ssh-copy-id -i "/home/$username/.ssh/id_rsa.pub" $SERVER_USER@$SERVER_IP
    
    # Création du dossier "a_sauver" dans le dossier home de l'utilisateur
    mkdir -m 755 "/home/$username/a_sauver"
    chown "$username" "/home/$username/a_sauver"
    
    # --------------------------------[ENVOI DE MAIL]--------------------------------
    
    # Création du corps du mail
    body="Bonjour $name $surname,
    
    Votre compte utilisateur a été créé avec succès !
    
    Votre login : $username\n
    Votre mot de passe de connexion : $password    

    /!\ Attention : ce mot de passe devra être changé lors de votre première connexion.
    
    Cordialement"
    
    # Envoi de l'e-mail via le serveur SMTP
    subject="Votre compte a été créé"
    ssh -n -i /home/isen/.ssh/id_rsa "$SERVER_USER@$SERVER_IP" "mail --subject \"$subject\"  --exec \"set sendmail=smtp://${from_email/@/%40}:${smtp_password/@/%40}@$smtp_server:$smtp_port\" --append \"From:$from_email\" $mail <<< \"$body\" "
    
done 

# --------------------------------[[INSTALLATION D'ECLIPSE]--------------------------------[

apt update

# Installation de Java Development Kit
apt install openjdk-11-jdk

# Instrallation de curl si nécessaire
apt install -y curl

# Téléchargement d'Eclipse
curl -L "https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2021-12/R/eclipse-java-2021-12-R-linux-gtk-x86_64.tar.gz&r=1" -o /tmp/eclipse.tar.gz

# Extraction de l'archive d'Eclipse
tar -xzf /tmp/eclipse.tar.gz -C /usr/local/share
chown -R root:root /usr/local/share/eclipse

# Création d'u lien symbolique vers l'exécutable d'Eclipse
ln -s /usr/local/share/eclipse/eclipse /usr/local/bin/eclipse


# --------------------------------[PARE-FEU]--------------------------------[

#Installation du pare-feu
apt install ufw -y

# Activation du pare-feu
ufw enable

# BLoquage des connexion FTP
ufw deny ftp 

# Bloquage des connexions UDP
ufw deny proto udp from any to any

# Redémarage du pare-feu
ufw reload




















































