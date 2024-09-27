#!/bin/bash

until wp db check --path="/var/www/html" --allow-root; do
  echo "Waiting for database to be ready..."
  sleep 5
done

wp plugin install jetpack --activate --path="/var/www/html" --allow-root
wp plugin install woocommerce --activate --path="/var/www/html" --allow-root
wp plugin install wordfence --activate --path="/var/www/html" --allow-root
