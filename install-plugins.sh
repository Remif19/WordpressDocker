#!/bin/bash

set -e

# Exécute le script d'entrée par défaut de WordPress
docker-entrypoint.sh apache2-foreground &

# Attendre que WordPress soit prêt
until $(curl --output /dev/null --silent --head --fail http://falcatiremi.com:80); do
    printf '.'
    sleep 5
done

# Installer et activer les plugins
echo "Installation des plugins..."

# Liste des plugins à installer
plugins=(
    "akismet"
    "wordfence"
    "yoast-seo"
)

for plugin in "${plugins[@]}"; do
    echo "Installation et activation de $plugin..."
    wp plugin install "$plugin" --activate --allow-root
done

# Mettre à jour la base de données si nécessaire
wp core update-db --allow-root

# Attendre que le conteneur soit terminé
wait