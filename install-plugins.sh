#!/bin/sh

while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    echo "Waiting for database to be ready..."
    sleep 5
done

wp plugin install jetpack --activate
wp plugin install akismet --activate