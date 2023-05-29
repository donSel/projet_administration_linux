#!/bin/bash

# --------------------------------[FONCTIONS]--------------------------------[

# Fonction de déploiement du pare-feu
firewall_setup() {
    # Installation d'ufw
    apt install ufw -y
    
    # Activation de ufw
    ufw enable
    
    # Bloquage des connexions de type FTP
    ufw deny ftp 
    
    # Bloquage des connexions de type UDP
    ufw deny proto udp from any to any
    
    # Redemarrage du pare-feu
    ufw reload
}

# Fonction installant Eclipse sans apt
eclipse_install() {
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
}

# --------------------------------[END_FONNCTIONS]--------------------------------[

# Demande des des informations pour l'envoi de mail
echo "Veuillez saisir votre adresse de serveur smtp (pour Outlook : smtp.office365.com) :"
read smtp_server
echo "Veuillez saisir le port de votre serveur smtp (pour Outlook : 587) :"
read smtp_port
echo "Veuillez rentrer l'adresse email de l'expéditeur :"
read from_email
echo "Veuillez saisir le mot de passe de cette adresse e-mail :"
read smtp_password

# Demande des informations relatives au serveur
echo "Veuillez saisir l'adresse IP du serveur :"
read SERVER_IP
echo "Veuillez saisir votre nom d'utilisateur :"
read SERVER_USER
echo "Veuillez rentrer le chemin vers votre clé SSH :"
read SSH_KEY
echo "Veuillez saisir le chemin vers le fichier csv contenant les informations des comptes :"
read FILE

# Démarrage de la tâche cron
service cron start

# Création du fichier shared appartenant à root 
mkdir /home/shared

# Mise a jour des droits du fichier shared
chown root:root /home/shared
chmod 755 /home/shared

# Création du dossier "saves" sur la machine distante
ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" mkdir "/home/saves"
ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" chown "$SERVER_USER:$SERVER_USER" "/home/saves"
ssh -n -i $SSH_KEY "$SERVER_USER@$SERVER_IP" chmod 777 "/home/saves"

firewall_setup

eclipse_install

# --------------------------------------- configuration et installantion de Nextcloud ---------------------------------------

# Variables d'identifiant et mdp de l'administrateur pour la connexion au serveur Nextcloud
admin_login="nextcloud-admin"
admin_passwd="N3x+ClOuD"

# Installation de snapd
ssh -i $SSH_KEY $SERVER_USER@$SERVER_IP "apt install snapd -y"
ssh -i $SSH_KEY $SERVER_USER@$SERVER_IP "snap install core"

# Installation de Nextcloud
ssh -i $SSH_KEY $SERVER_USER@$SERVER_IP "snap install nextcloud"

# Lancement de Nextcloud 
ssh -i $SSH_KEY $SERVER_USER@$SERVER_IP "/snap/bin/nextcloud.manual-install $admin_login $admin_passwd"

# Création de l'exécutable pour lancer le tunnel sur le serveur Nextcloud
touch /home/tunnel_nextcloud
chmod 755 /home/tunnel_nextcloud
echo "#!/bin/bash" >> /home/tunnel_nextcloud
echo "ssh -L 4242:$SERVER_IP:80 $SERVER_USER@$SERVER_IP" >> /home/tunnel_nextcloud

# Boucle de lecture sur le fichier account.csv (excepté la première)
tail -n +2 "$FILE" | while IFS=';' read -r name surname mail password; do

    # Suppression de l'espace dans le surname 
    surname="${surname// /}"
    
    # Géneration du login
    username="${name:0:1}${surname,,}"
    
    # --------------------------------------- création de compte d'utilisateur avec ses dossier, ses droits et sa configuration ssh ---------------------------------------

    # Création du compte utilisateur avec mdp 
    useradd -m -p "$(openssl passwd -1 "$password")" "$username"
    
    # Expiration du mot de passe
    usermod -e 2000-01-01 "$username"
    
    # Création d'un dossier dans le dossier "shared"
    mkdir "/home/shared/$username"
    chown "$username" "/home/shared/$username"
    chmod 755 "/home/shared/$username"

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
    
    # Création d'un lien symbolique vers eclipse dans le dossier home de l'utilisateur
    ln -s /usr/local/share/eclipse/eclipse "/home/$username/eclipse"
    
    # Création d'un compte Nextcloud pour chaque utilisateur
    export OC_PASS=$password
    /snap/bin/nextcloud.occ user:add --password-from-env --display-name="$name $surname" $login 
    
    # --------------------------------------- Envoi de mails d'instruction aux utilisateurs ---------------------------------------
    
    subject="Votre compte a été créé"
    
    # Création du corps du mail
    body="Bonjour $name $surname,
    
    Votre compte utilisateur a été créé avec succès !
    
    Votre login : $username\n
    Votre mot de passe de connexion : $password    

    /!\ Attention : ce mot de passe devra être changé lors de votre première connexion.
    
    Cordialement"
    
    # Envoi de l'e-mail via le serveur SMTP
    ssh -n -i "$SSH_KEY" "$SERVER_USER@$SERVER_IP" "mail --subject \"$subject\"  --exec \"set sendmail=smtp://${from_email/@/%40}:${smtp_password/@/%40}@$smtp_server:$smtp_port\" --append \"From:$from_email\" $mail <<< \"$body\" "
             
    # --------------------------------------- ajout de la tâche cron s'exécutant tout les jours de la semaine à 23h pour seauvegarder ---------------------------------------
    # --------------------------------------- les fichiers du dossier "a_sauver" de l'utilisateur sur le dossier "saves" du serveur distant ---------------------------------------
    
    crontab -l > newcron
    echo "0 23 * * 1-5 tar -czvf /home/$username/save_$username.tgz /home/$username/a_sauver && sudo chmod a+x /home/$username/save_$username.tgz && scp -i $SSH_KEY /home/$username/save_$username.tgz $SERVER_USER@$SERVER_IP:/home/saves/ && rm /home/$username/save_$username.tgz" >> newcron
    crontab newcron
    rm newcron
    
done 

# --------------------------------------- création du script de récupération de la seauvegarde "recuperation_seauvegarde.sh" ---------------------------------------

# Création du fichier retablir seauvegarde
touch /home/retablir_sauvegarde.sh
echo "#!/bin/sh" >> /home/retablir_sauvegarde.sh

# Modification des droits du script
chown root:root /home/retablir_sauvegarde.sh
chmod 755 /home/retablir_sauvegarde.sh

# Récupération du nom d'utilisateur à qui l'on veut récuperer les fichiers du dossier "a_sauver" distant
echo "echo \"Veuillez saisir le login de l'utilisateur à qui vous voulez rétablir le dossier "a_sauver" :\"" >> /home/retablir_sauvegarde.sh
echo "read username" >> /home/retablir_sauvegarde.sh

# Récupération de la sauvegarde du répertoire "a_sauver" de l'utilisateur
echo "scp -i $SSH_KEY $SERVER_USER@$SERVER_IP:/home/saves/save_\$username.tgz /home/\$username/save_\$username.tgz" >> /home/retablir_sauvegarde.sh

# Suppression du contenu du répertoire "a_sauver" de l'utilisateur
echo "rm -rf /home/\$username/a_sauver/" >> /home/retablir_sauvegarde.sh

# Extraction de la sauvegarde dans le répertoire "a_sauver" de l'utilisateur
echo "tar -xzvf /home/\$username/save_\$username.tgz -C /home/\$username" >> /home/retablir_sauvegarde.sh

# Suppression de l'archive
echo "rm /home/\$username/save_\$username.tgz" >> /home/retablir_sauvegarde.sh

# Recréation du dossier a_sauver
echo "mkdir a_sauver" >> /home/retablir_sauvegarde.sh

# Déplacement des données extraites dans le nouveau dossier
echo "mv /home/\$username/home/\$username/a_sauver /home/\$username/a_sauver" >> /home/retablir_sauvegarde.sh

# Suppression de l'ancien dossier home extrait
echo "rm -r -d /home/\$username/home/" >> /home/retablir_sauvegarde.sh



























































