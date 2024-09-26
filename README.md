# Documentation du fichier `docker-compose.yml`

Ce fichier `docker-compose.yml` définit plusieurs services pour déployer une infrastructure de site web basée sur WordPress, avec un proxy Traefik, une base de données MySQL et un serveur FTP. Chaque service est décrit ci-dessous avec son rôle, ses paramètres, et ses dépendances.

## Structure des services

### 1. **Traefik**
Traefik est un reverse proxy et un load balancer pour les services déployés via Docker. Il s'occupe de la gestion du routage du trafic HTTP/HTTPS vers les différents conteneurs.

#### Configuration :
- **Nom du conteneur** : `traefik`
- **Image** : `traefik:v2.5`
- **Commandes** :
  - `--api.insecure=true` : Active l'interface API de Traefik en mode non sécurisé (uniquement à des fins de développement, à ne pas utiliser en production).
  - `--providers.docker=true` : Active la découverte automatique des conteneurs Docker.
  - `--entrypoints.web.address=:80` : Définition de l'entrée pour le trafic HTTP sur le port 80.
  - `--entrypoints.websecure.address=:443` : Définition de l'entrée pour le trafic HTTPS sur le port 443.
  - `--certificatesresolvers.myresolver.acme.tlschallenge=true` : Utilisation du défi TLS pour la génération des certificats Let's Encrypt.
  - `--certificatesresolvers.myresolver.acme.email=monitoring@verywell.digital` : Adresse e-mail pour l'inscription à Let's Encrypt.
  - `--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json` : Emplacement de stockage des certificats Let's Encrypt.
  
#### Ports exposés :
- **Port 80** : HTTP
- **Port 443** : HTTPS

#### Volumes :
- `/var/run/docker.sock:/var/run/docker.sock:ro` : Liaison au socket Docker pour permettre à Traefik de gérer automatiquement les conteneurs.
- `traefik-certificates:/letsencrypt` : Stockage persistant des certificats Let's Encrypt.

---

### 2. **WordPress**
Ce service déploie une instance de WordPress pour gérer le contenu de votre site web.

#### Configuration :
- **Nom du conteneur** : `wordpress`
- **Image** : `wordpress:latest`
- **Labels Traefik** :
  - `traefik.enable=true` : Active la gestion de ce service par Traefik.
  - `traefik.http.routers.wordpress.rule=Host(`${WORDPRESS_DOMAIN}`)` : Règle de routage basée sur le nom d'hôte (ici `docker.verywell.dev`).
  - `traefik.http.routers.wordpress.entrypoints=websecure` : Utilisation de l'entrée sécurisée (HTTPS).
  - `traefik.http.routers.wordpress.tls=true` : Active TLS pour ce routeur.
  - `traefik.http.routers.wordpress.tls.certresolver=myresolver` : Utilisation du résolveur de certificats Let's Encrypt défini dans Traefik.

#### Variables d'environnement :
- `WORDPRESS_DB_HOST=db` : Hôte de la base de données (ici, le service `db`).
- `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_NAME` : Variables d'environnement pour se connecter à la base de données (les valeurs sont récupérées à partir de variables système).

#### Volumes :
- `wordpress_data:/var/www/html` : Stockage persistant des données WordPress (fichiers du site web).

#### Dépendances :
- **dépend de** : `db` (la base de données doit être active pour démarrer WordPress).

---

### 3. **Base de données (MySQL)**
Ce service déploie une base de données MySQL pour stocker les données de WordPress.

#### Configuration :
- **Nom du conteneur** : `db`
- **Image** : `mysql:latest`

#### Variables d'environnement :
- `MYSQL_DATABASE` : Nom de la base de données à créer.
- `MYSQL_USER` : Utilisateur MySQL à créer.
- `MYSQL_PASSWORD` : Mot de passe pour l'utilisateur MySQL.
- `MYSQL_ROOT_PASSWORD` : Mot de passe pour l'utilisateur root de MySQL.

#### Ports exposés :
- **Port 3306** : Port MySQL pour les connexions à la base de données.

#### Volumes :
- `db_data:/var/lib/mysql` : Stockage persistant des données de la base de données.

---

### 4. **FTP**
Ce service déploie un serveur FTP basé sur l'image `garethflowers/ftp-server`, permettant l'accès FTP aux fichiers WordPress.

#### Configuration :
- **Nom du conteneur** : `ftp`
- **Image** : `garethflowers/ftp-server`

#### Variables d'environnement :
- `FTP_USER` et `FTP_PASS` : Utilisateur et mot de passe pour la connexion au serveur FTP (récupérés à partir des variables d'environnement système).

#### Ports exposés :
- **Ports 20-21** : Ports standard pour les connexions FTP.
- **Ports 40000-40009** : Ports supplémentaires pour les connexions passives FTP.

#### Volumes :
- `wordpress_data:/home/user` : Le répertoire WordPress est accessible via FTP.

---

## Volumes persistants

Trois volumes sont définis pour le stockage persistant des données entre les redémarrages des conteneurs :
- `wordpress_data` : Stocke les fichiers du site WordPress.
- `db_data` : Stocke les données de la base de données MySQL.
- `traefik-certificates` : Stocke les certificats SSL/TLS générés par Let's Encrypt.

---

## Conclusion

Ce fichier `docker-compose.yml` permet de déployer un site WordPress complet avec une configuration HTTPS automatisée via Traefik, une base de données MySQL et un accès FTP pour gérer les fichiers du site. Assurez-vous d'avoir défini correctement les variables d'environnement (comme les utilisateurs, mots de passe et noms de base de données) avant de démarrer les services.









# Documentation Technique : `deploy.yml`

## Objectif
Le fichier `deploy.yml` est un workflow GitHub Actions qui automatise le déploiement d'un projet sur un serveur distant chaque fois qu'une modification est poussée sur la branche principale (`main`). Il s'exécute sur un serveur Ubuntu, copie le code vers le serveur cible, vérifie l'installation de Docker et Docker Compose, configure un fichier `.env` avec des secrets, puis lance ou redémarre les services Docker sur le serveur.

---

## Détails du Fichier `deploy.yml`

### Nom du Workflow
```yaml
name: Deploy to Server
```
- **Description**: Le workflow est nommé "Deploy to Server", ce qui signifie que chaque exécution de ce fichier déclenche un déploiement vers un serveur distant.

### Déclencheur (Trigger)
```yaml
on:
  push:
    branches:
      - main
```
- **Description**: Le workflow s'exécute à chaque fois qu'un commit est poussé sur la branche `main` du dépôt.

### Jobs : `deploy`

Chaque job dans GitHub Actions est une série de commandes ou d'étapes exécutées sur une machine virtuelle.

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
```
- **Description**: Le job s'exécute sur un environnement Ubuntu à jour.

---

## Étapes du Job

### 1. **Checkout du code**
```yaml
- name: Checkout code
  uses: actions/checkout@v2
```
- **Description**: Cette étape utilise l'action `checkout@v2` pour cloner le dépôt GitHub dans l'environnement Ubuntu. Cela permet de disposer du code source pour le reste du workflow.

### 2. **Copie du dépôt vers le serveur**
```yaml
- name: Copy repository to server
  uses: appleboy/scp-action@master
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    source: "."
    target: "~/repo"
```
- **Description**: Cette étape utilise l'action `scp-action` pour copier l'intégralité du dépôt (répertoire source `"."`) vers un répertoire cible (`~/repo`) sur le serveur distant via le protocole SCP.
- **Secrets utilisés** :
  - `SSH_HOST`: L'adresse du serveur.
  - `SSH_USER`: Le nom d'utilisateur SSH pour se connecter au serveur.
  - `SSH_PRIVATE_KEY`: La clé privée SSH utilisée pour l'authentification.

### 3. **Vérification et installation de Docker et Docker Compose**
```yaml
- name: Check and install Docker and Docker Compose if needed
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    script: |
      if ! docker-compose --version > /dev/null 2>&1; then
        echo "docker-compose not found, installing Docker and Docker Compose..."
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install docker.io -y
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
      else
        echo "docker-compose is already installed."
```
- **Description**: Cette étape vérifie si Docker Compose est installé sur le serveur distant. Si ce n'est pas le cas :
  - Elle met à jour le système avec `apt update` et `apt upgrade`.
  - Elle installe Docker avec `apt install docker.io`.
  - Elle télécharge et installe Docker Compose via `curl`, puis le rend exécutable.
- Si Docker Compose est déjà installé, un message confirme sa présence.

### 4. **Création du fichier `.env` sur le serveur**
```yaml
- name: Create .env file on the server
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    script: |
      cd ~/repo
      echo "Creating .env file..."
      cat > .env <<EOF
      WORDPRESS_DB_USER=${{ secrets.WORDPRESS_DB_USER }}
      WORDPRESS_DB_PASSWORD=${{ secrets.WORDPRESS_DB_PASSWORD }}
      WORDPRESS_DB_NAME=${{ secrets.WORDPRESS_DB_NAME }}
      MYSQL_PASSWORD=${{ secrets.MYSQL_PASSWORD }}
      MYSQL_ROOT_PASSWORD=${{ secrets.MYSQL_ROOT_PASSWORD }}
      FTP_PASS=${{ secrets.FTP_PASS }}
      FTP_USER=${{ secrets.FTP_USER }}
      WORDPRESS_DOMAIN=${{ secrets.WORDPRESS_DOMAIN }}
      EOF
```
- **Description**: Cette étape crée un fichier `.env` dans le répertoire du dépôt (`~/repo`) sur le serveur distant. Ce fichier contient des variables d'environnement cruciales pour la configuration de l'application, comme les identifiants de base de données et les mots de passe FTP, qui sont stockés en tant que secrets dans le dépôt GitHub.
- **Secrets utilisés** :
  - `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_NAME`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `FTP_PASS`, `FTP_USER`, `WORDPRESS_DOMAIN`.

### 5. **Exécution des commandes Docker via SSH**
```yaml
- name: Execute commands over SSH
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.SSH_HOST }}
    username: ${{ secrets.SSH_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    script: |
      cd ~/repo
      sudo docker-compose down
      sudo docker-compose up -d --build
      sudo docker-compose down
      sudo docker-compose up -d
```
- **Description**: Cette étape se connecte au serveur distant via SSH et exécute les commandes Docker suivantes dans le répertoire `~/repo` :
  1. `docker-compose down`: Arrête tous les conteneurs Docker s'ils sont en cours d'exécution.
  2. `docker-compose up -d --build`: Relance les conteneurs en mode détaché (`-d`), tout en reconstruisant les images Docker si nécessaire.
  3. Une nouvelle commande `docker-compose down` est exécutée pour s'assurer que tout est bien arrêté.
  4. Finalement, `docker-compose up -d` est exécuté pour démarrer les services en mode détaché sans reconstruction.

---

## Conclusion

Ce fichier `deploy.yml` fournit une solution complète et automatisée pour :
- **Cloner** le dépôt,
- **Transférer** le code sur un serveur distant,
- **Vérifier** et installer les outils nécessaires (Docker, Docker Compose),
- **Configurer** l'environnement via un fichier `.env`,
- **Gérer** les conteneurs Docker pour démarrer l'application en toute sécurité.

Grâce à l'utilisation de secrets GitHub, toutes les informations sensibles sont protégées et le processus de déploiement est sécurisé.
