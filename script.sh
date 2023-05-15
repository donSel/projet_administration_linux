#!/bin/bash

# Chemin vers le fichier accounts.csv
FILE="accounts.csv"

# Boucle sur chaque ligne du fichier
while IFS=';' read -r name surname mail password; do
    let name = $name
    let surname = $surname
    let mail = $mail
    let password = $password
done < "$FILE"









































