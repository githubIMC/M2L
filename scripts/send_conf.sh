#!/bin/bash

# Tableau associatif : Nom => "IP fichier_config"
declare -A equipements=(
  ["SW1-M2L"]="172.16.99.2 sw1m2l-confg"
  ["LIG-SW3"]="172.16.99.20 lig-sw3-confg"
  ["LIG-SW2"]="172.16.99.19 lig-sw2-confg"
  ["LIG-SW1"]="172.16.99.18 lig-sw1-confg"
  ["RLIGUES"]="172.16.99.17 rligues-confg"
  ["HSRP2"]="10.0.0.4 hsrp-sec-confg"
  ["HSRP1"]="10.0.0.5 hsrp-pri-confg"
  ["RM2L"]="172.16.99.1 rm2l-confg"
)

# Tableau définissant l'ordre souhaité
ordre=( "LIG-SW3" "LIG-SW2" "LIG-SW1" "RLIGUES" "HSRP2" "HSRP1" "RM2L" "SW1-M2L")

# Mot de passe SSH pour tous les équipements
PASSWORD="admin"

# Fonction pour attendre qu'un équipement réponde au ping
wait_for_ping() {
    local IP="$1"
    local TIMEOUT=300  # Temps d'attente maximum en secondes (5 min)
    local INTERVAL=10  # Intervalle entre chaque tentative en secondes
    local ELAPSED=0

    echo "Attente de la disponibilité de l'équipement $IP..."
    while ! ping -c 1 -W 2 "$IP" &> /dev/null; do
        echo "Équipement $IP non joignable, nouvelle tentative dans $INTERVAL secondes..."
        sleep "$INTERVAL"
        ELAPSED=$((ELAPSED + INTERVAL))
        
        if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
            echo "Temps d'attente dépassé pour $IP. Passage au suivant."
            return 1
        fi
    done
    echo "Équipement $IP est maintenant joignable."
    return 0
}


# Boucle sur chaque équipement (ordre non garanti)
for equipement in "${ordre[@]}"; do

  echo "$equipement => ${equipements[$equipement]}"

  # Extraire l'IP et le nom du fichier de configuration
  IP=$(echo ${equipements[$equipement]} | awk '{print $1}')
  CONFIG_FILE=$(echo ${equipements[$equipement]} | awk '{print $2}')
  
  echo "#############################################################"
  echo "🚀 Connexion à $equipement ($IP) avec le fichier $CONFIG_FILE"
  echo "#############################################################"

  wait_for_ping "$IP" || continue  # Attendre que l'équipement réponde au ping avant SSH

  # Lancer le script Expect pour chaque équipement
  expect <<EOF
    spawn ssh admin@$IP
    expect {
      "Password:" { send "$PASSWORD\r" }
      "password:" { send "$PASSWORD\r" }
      timeout { puts "⚠️ Timeout lors de la connexion à $equipement ($IP)"; exit 1 }
    }

    expect "#"
    send "copy tftp: startup-config\r"
    expect "Address or name of remote host" { send "172.16.2.50\r" }
    expect "Source filename" { send "$CONFIG_FILE\r" }
    expect "Destination filename" { send "\r" }

    # Vérification de la fin du transfert TFTP
    expect {
      "bytes copied*" { puts "✅ Fichier TFTP transféré avec succès." }
      "#" { puts "✅ Fichier TFTP transféré avec succès." }
    }

    # Suppression de la base VLAN
    send "dir flash:\r"
    expect {
      "vlan.dat" {
        puts "📌 vlan.dat trouvé, suppression en cours..."
        send "delete flash:vlan.dat\r"
        send "\r"  
        send "\r"  
      }
      "#" { puts "✅ Aucun fichier vlan.dat trouvé, suppression non nécessaire." }
    }

    send "reload\r"
    send "\r"
    send "\r"
    

    # Pause pour attendre le redémarrage
    puts "⏳ Attente de 60 secondes pour le redémarrage..."
    sleep 60

    puts "✅ Commandes exécutées avec succès pour $equipement ($IP)."
    expect eof
EOF

  echo "✅ $equipement ($IP) : Configuration transférée et redémarrage terminé."
done

echo "🎉 Toutes les configurations ont été mises à jour et les équipements ont redémarré."
