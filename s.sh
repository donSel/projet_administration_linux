#!/bin/bash

# --------------------------------[NOTES]--------------------------------[
#faire des fonctions
#demander les variables qui sont en dessous
# --------------------------------[NOTES]--------------------------------[

# Définition des variables
SERVER_IP=10.30.48.100
SERVER_USER="aaugus25"
SSH_KEY="/home/isen/.ssh/id_rsa"
FILE="accounts.csv"
subject="Votre compte a été créé"

# Démarrage de la tâche cron
service cron start

# --------------------------------[CREATION DES DOSSIER ET UTILISATEURS]--------------------------------[

# Création du fichier shared appartenant à root 
mkdir /home/shared

# Mise a jour des droits du fichier shared
chown root:root /home/shared
chmod 755 /home/shared

# Création du dossier "saves" sur la machine distante
ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" mkdir "/home/saves"
ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" chown "$SERVER_USER:$SERVER_USER" "/home/saves"
ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" chmod 777 "/home/saves"

# Demande des des informations pour l'envoi de mail
#echo "Veuillez saisir votre adresse de serveur smtp (pour Outlook : smtp.office365.com) :"
#read smtp_server
#echo "Veuillez saisir le port de votre serveur smtp (pour Outlook : 587) :"
#read smtp_port
#echo "Veuillez rentrer l'adresse email de l'expéditeur :"
#read from_email
#echo "Veuillez saisir le mot de passe de cette adresse e-mail :"
#read smtp_password

# Boucle de lecture sur le fichier account.csv (excepté la première)
tail -n +2 "$FILE" | while IFS=';' read -r name surname mail password; do

    # Suppression de l'espace dans le surname 
    #surname="${surname// /}"
    
    # Géneration du login
    #username="${name:0:1}${surname,,}"

    # Création du compte utilisateur avec mdp 
    #useradd -m -p "$(openssl passwd -1 "$password")" "$username"
    
    # Expiration du mot de passe
    #usermod -e 2000-01-01 "$username"
    
    # Création d'un dossier dans le dossier "shared"
    #mkdir "/home/shared/$username"
    #chown "$username" "/home/shared/$username"
    #chmod 755 "/home/shared/$username"
    
    # Création d'un lien symbolique vers eclipse dans le dossier home de l'utilisateur
    ln -s /usr/local/share/eclipse/eclipse "/home/$username/eclipse"

    # Création des dossier ".ssh" pour l'utilisateur    
    #mkdir "/home/$username/.ssh"
    #chmod 700 "/home/$username/.ssh"

    # Création d'une clé SSH pour l'utilisateur
    #ssh-keygen -t rsa -b 2048 -f "/home/$username/.ssh/id_rsa" -q -N ""
    #chown -R "$username:$username" "/home/$username/.ssh"

    # Ajout de la clé publique de l'utilisateur dans le fichier authorized_keys distant
    #ssh-copy-id -i "/home/$username/.ssh/id_rsa.pub" $SERVER_USER@$SERVER_IP
    
    # Création du dossier "a_sauver" dans le dossier home de l'utilisateur
    #mkdir -m 755 "/home/$username/a_sauver"
    #chown "$username" "/home/$username/a_sauver"
    
    # --------------------------------[ENVOI DE MAIL]--------------------------------
    
    smtp_server="smtp.office365.com"
    smtp_port="587"
    from_email="mickael.neroda@isen-ouest.yncrea.fr"
    smtp_password="TCr4BMLuXBEmU5DSYVvFaK7WYY5gHKYKkfCc55pw9FJtofhwtFktdY5QKBQCZyCcLZYasRozH5n"
    mail="mickael.neroda@gmail.com"
    
    # Création du corps du mail
    body="Bonjour $name $surname,
    
    Votre compte utilisateur a été créé avec succès !
    
    Votre login : $username\n
    Votre mot de passe de connexion : $password    

    /!\ Attention : ce mot de passe devra être changé lors de votre première connexion.
    
    Cordialement"
    
    # Envoi de l'e-mail via le serveur SMTP
    #ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" "mail --subject \"$subject\"  --exec \"set sendmail=smtp://${from_email/@/%40}:${smtp_password/@/%40}@$smtp_server:$smtp_port\" --append \"From:$from_email\" $mail <<< \"$body\" "
    
    # --------------------------------[SEAUVEGARDE SUR LE SERVEUR DISTANT]--------------------------------

    # Ajout de la tâche cron s'exécutant tout les jours de la semaine à 23h pour seauvegarder les fichier du dossier "a_sauver" de l'utilisateur sur le dossier "saves" du serveur distant
    crontab -l > newcron
    echo "0 23 * * 1-5 tar -czf /home/$username/save_$username.tgz /home/$username/a_sauver && sudo chmod a+x /home/$username/save_$username.tgz && scp -i $SSH_KEY /home/$username/save_$username.tgz $SERVER_USER@$SERVER_IP:/home/saves/" >> newcron
    crontab newcron
    rm newcron
    
    # --------------------------------[RETABLISSEMENT DE LA SEAUVEGARDE SUR LE SERVEUR DISTANT]--------------------------------< 
    
    # Création du script de récupération de la seauvegarde
    touch /home/retablir_sauvegarde.sh
    echo "#!/bin/sh" > /home/retablir_sauvegarde.sh
    
    # Récupération de l'utilisateur courant
    echo "username=$(whoami)" > /home/retablir_sauvegarde.sh
    
    # Récupération de la sauvegarde du répertoire "a_sauver" de l'utilisateur
    echo "scp -i $SSH_KEY $SERVER_USER@$SERVER_IP:/home/saves/save_$username.tgz /home/$username/save_$username.tgz" > /home/retablir_sauvegarde.sh
    
    # Suppression du contenu du répertoire "a_sauver" de l'utilisateur
    echo "rm -rf /home/$username/a_sauver/" > /home/retablir_sauvegarde.sh
    
    # Extraction de la sauvegarde dans le répertoire "a_sauver" de l'utilisateur
    echo "tar -xzf /home/$username/save_$username.tgz -C /home/$username/a_sauver" > /home/retablir_sauvegarde.sh
    
    # Suppression de la sauvegarde
    echo "rm /home/$username/save_$username.tgz" > /home/retablir_sauvegarde.sh
    
    # Modification des droits du script
    chown root:root /home/retablir_sauvegarde.sh
    chmod 755 /home/retablir_sauvegarde.sh
         
done 

# --------------------------------[PARE-FEU]--------------------------------[

# Blocage des connexions FTP
#iptables -A OUTPUT -p tcp --dport 21 -j DROP
#iptables -A INPUT -p tcp --dport 21 -j DROP

# Blocage des connexions UDP 
#iptables -A OUTPUT -p udp -j DROP
#iptables -A INPUT -p udp -j DROP

# --------------------------------[[INSTALLATION D'ECLIPSE]--------------------------------[

#apt update

# Installation de Java Development Kit
#apt install openjdk-11-jdk

# Instrallation de curl si nécessaire
#apt install -y curl

# Téléchargement d'Eclipse
#curl -L "https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2021-12/R/eclipse-java-2021-12-R-linux-gtk-x86_64.tar.gz&r=1" -o /tmp/eclipse.tar.gz

# Extraction de l'archive d'Eclipse
#tar -xzf /tmp/eclipse.tar.gz -C /usr/local/share
#chown -R root:root /usr/local/share/eclipse

# Création d'u lien symbolique vers l'exécutable d'Eclipse
#ln -s /usr/local/share/eclipse/eclipse /usr/local/bin/eclipse























































