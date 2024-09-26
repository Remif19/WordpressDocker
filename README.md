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
  - `traefik.http.routers.wordpress.rule=Host(docker.verywell.dev)` : Règle de routage basée sur le nom d'hôte (ici `docker.verywell.dev`).
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