#!/bin/bash

# Tableau associatif : Nom => "IP fichier_config"
declare -A equipements=(
  ["LIG-SW3"]="172.16.99.20 lig-sw3-confg"
  ["LIG-SW2"]="172.16.99.19 lig-sw2-confg"
  ["LIG-SW1"]="172.16.99.18 lig-sw1-confg"
  ["RLIGUES"]="172.16.99.17 rligues-confg"
  ["HSRP2"]="10.0.0.4 hsrp-sec-confg"
  ["HSRP1"]="10.0.0.5 hsrp-pri-confg"
  ["RM2L"]="172.16.99.1 rm2l-confg"
  ["SW1-M2L"]="172.16.99.2 sw1m2l-confg"
)

# Mot de passe SSH pour tous les équipements
PASSWORD="admin"

# Boucle sur chaque équipement (ordre non garanti)
for equipement in "${!equipements[@]}"; do
  IP=$(echo ${equipements[$equipement]} | awk '{print $1}')
  CONFIG_FILE=$(echo ${equipements[$equipement]} | awk '{print $2}')

  echo "🚀 Connexion à $equipement ($IP) avec le fichier $CONFIG_FILE"

  # Lancer le script Expect pour chaque équipement
  expect <<EOF
    set timeout 60
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
    sleep 80

    puts "✅ Commandes exécutées avec succès pour $equipement ($IP)."
    expect eof
EOF

  echo "✅ $equipement ($IP) : Configuration transférée et redémarrage terminé."
done

echo "🎉 Toutes les configurations ont été mises à jour et les équipements ont redémarré."
