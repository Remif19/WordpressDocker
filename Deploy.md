# Documentation de Déploiement de l'Application en Docker

Cette documentation explique comment déployer votre application en utilisant Docker sur un serveur Lightsail.

## Étape 1 : Créer un Répertoire Git

1. Créez un dépôt Git avec le nom de votre site, par exemple `docker.verywell.dev`.

## Étape 2 : Créer un Serveur sur Lightsail

1. **Créer un serveur** :
   - Choisissez une instance avec un minimum de 2 Go de RAM.
   - Configurez la clé SSH et l'adresse IP statique.

2. **Configurer les ports à ouvrir** :
   - Ouvrez les ports suivants :
     - 20
     - 22
     - 443
     - 3306
     - 4000 à 65535

## Étape 3 : Ajouter les Fichiers de Production

1. Ajoutez les deux fichiers de production suivants à votre dépôt :
   - `docker-compose.yml`
   - `deploy.yml`

*Remarque : Ne précisez pas le code dans cette documentation.*

## Étape 4 : Ajouter les Secrets dans GitHub

1. Allez dans les paramètres de votre dépôt GitHub.
2. Ajoutez les secrets nécessaires dans le fichier `deploy.yml` avec les variables d'environnement suivantes :

   ```bash
   WORDPRESS_DB_USER=user
   WORDPRESS_DB_PASSWORD=password
   WORDPRESS_DB_NAME=wordpress_db
   MYSQL_PASSWORD=password
   MYSQL_ROOT_PASSWORD=root_password
   FTP_PASS=123
   FTP_USER=user
   ```

## Étape 5 : Lancer le Workflow

1. Lancez le workflow de déploiement à partir de votre dépôt.

## Conclusion

Votre application devrait maintenant être déployée avec succès sur Docker. Assurez-vous de vérifier que tous les services fonctionnent correctement.
