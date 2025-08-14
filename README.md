# Piwigo docker (Beta) :

An alpine based container to easily deploy piwigo !

Check the [podman README](./podman-quadlet/README.md) if you would rather use podman.

## Usage

### Starting the container

Create a folder named `Piwigo` and copy `compose.yaml` from this repository, then create a `.env` file


```
Piwigo
├── .env
└── compose.yaml
```

Edit the `.env` and add a password after `db_user_password=` (you can generate a strong password [**here**](https://bitwarden.com/password-generator/)). Change the exposed port if you need to.

```conf
db_user_password=
piwigo_port=8080
```

Start the container with `docker compose up -d`

### Configuring your reverse proxy

Setup your reverse proxy to have a domain/subdomain or subpath point to the container. The following examples are for nginx :

```conf
server {
	listen 80;
	server_name my_domain.tld;
	location / {
		proxy_pass http://127.0.0.1:8080/;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
}
```

If you intend to host piwigo on a subpath (ex: `my_domain.tld/gallery`) add `proxy_set_header X-Forwarded-Prefix /my_subpath` at the end of the location section;

```conf
	listen 80;
	server_name my_domain.tld;
	location /gallery/ {
		proxy_pass http://127.0.0.1:8080/;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
		proxy_set_header X-Forwarded-Prefix /gallery;
    }
```

### Installing piwigo 

Fill out the database form using the following values :
```
Database configuration:
	Host:			piwigo-db:3306
	User:			piwigodb_user
	Password:		#Password in .env
	Database name:		piwigodb
```

Create an admin account and your piwigo is installed !

### Making backups

Go to the folder where your `compose.yaml` is, stop the container using `docker compose down` and use rsync to backup `./piwigo-data/`

```sh
# --delete-before will remove your older backup !
rsync -r --delete-before ./piwigo-data/ ./piwigo-data.bck/ 
```

### Updating the container

**Making a backup is always advised before updating**  

Go to the folder where your `compose.yaml` is and stop the container. Then pull the new version of the container with `docker compose pull` and restart it with `docker compose up -d`

Updating piwigo via the web interface does not replace container updates !

## Advanced options

If you prefer using a `mysql` container instead of `mariadb` edit `compose.yaml` and replace mariadb by mysql (be aware it is case sensitive).

If you want to use an existing MySQL/MariaDB database you already setup, use `compose-nodb.yaml` and rename it `compose.yaml`.
You can either create `.env` with `piwigo_port=` or manually edit the compose file to change the exposed port.

Create a script at `./piwigo-data/scripts/user.sh` to run commands before nginx and php start.  
eg: to install extra dependencies like pandoc `apk add --no-cache pandoc`, available packages are listed at [alpine pkg index](https://pkgs.alpinelinux.org/packages).  
**Note that the script is run as root**.

## Container Architeture

Two containers :
- Alpine nginx with php-fpm
- MariaDB

PHP modules are installed with alpine natives packages, php-fpm is running with the same user as nginx.

Container network trafic is internal in the `piwigo-network` bridge.

All persistent data is stored in `./piwigo-data/` :

- `piwigo` piwigo files, when a new version is released, new files will be copied over
- `mysql` database files from the mariaDB/mysql
- `scripts` allow user to sideload dependencies and other files outside of piwigo
