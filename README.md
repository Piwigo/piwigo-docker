# Piwigo docker

An alpine based container to easily deploy piwigo !

## Usage

You can follow the [install guide](https://piwigo.org/guides/install/docker) and the [update guide](https://piwigo.org/guides/update/docker) to get your container setup and up to date. 

Sample `.env` file :

```
piwigo_port=8080
db_user_password=<DatabasePassword>
timezone=<Timezone>
PIWIGO_UID=1000
PIWIGO_GID=1000
```

Users comming from LinuxServer can follow this guide : https://github.com/Piwigo/piwigo-docker/wiki/Migration-Guide-from-the-LinuxServer

If you want to have write permision in your piwigo folder see this page of the wiki : https://github.com/Piwigo/piwigo-docker/wiki/Copying-files-directly-to-piwigo-docker

## Advanced options

If you prefer using a `mysql` container instead of `mariadb` edit `compose.yaml` and replace mariadb by mysql (be aware it is case sensitive).

If you want to use an existing MySQL/MariaDB database you already setup, use `compose-nodb.yaml` and rename it `compose.yaml`.
You can either create `.env` without `piwigo_port=`.

Create a script at `./piwigo-data/scripts/user.sh` to run commands before nginx and php start.  
eg: to install extra dependencies like pandoc `apk add --no-cache pandoc`, available packages are listed at [alpine pkg index](https://pkgs.alpinelinux.org/packages).  
**Note that the script is run as root**.

## Container Architeture

Two containers :
- Alpine with nginx and php-fpm
- MariaDB

PHP modules are installed with alpine natives packages, php-fpm is running with the same user as nginx.

Container network trafic is internal in the `piwigo-network` bridge.

All persistent data is stored in `./piwigo-data/` :

- `piwigo` piwigo files, when a new version is released, new files will be copied over
- `mysql` database files from the mariaDB/mysql
- `scripts` allow user to sideload dependencies and other files outside of piwigo

