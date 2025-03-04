#!/bin/bash

# Définition d'un tableau associatif (Nom de l'équipement -> Adresse IP)
declare -A equipements=(
  ["SW-M2L"]="172.16.99.2"
  ["RM2L-A"]="172.16.99.1"
  ["R-Ligues"]="172.16.99.17"
  ["SW1-LIG"]="172.16.99.18"
  ["SW2-LIG"]="172.16.99.19"
  ["SW3-LIG"]="172.16.99.20"
  ["RM2L-B"]="172.16.99.25"
  ["SW-WIFI"]="172.16.99.26"
  ["PA-WIFI"]="172.16.99.27"
  ["HSRP-1"]="10.0.0.5"
  ["HSRP-2"]="10.0.0.4"
)

# Boucle pour tester la connectivité de chaque équipement
for equipement in "${!equipements[@]}"; do
    ip=${equipements[$equipement]}
    if ! ping -c 3 "$ip" > /dev/null; then
        echo -e "\e[31m$equipement ($ip) ne répond pas\e[0m"
    else
        echo "$equipement ($ip) répond "
    fi
done
