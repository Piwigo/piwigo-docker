# Piwigo podman (Quadlet)

## Requirements

- systemd
- podman

## Usage

Create `/etc/containers/systemd/piwigo/` and copy each quadlet units files in it.

```
/etc/containers/systemd/piwigo/
    ├── piwigo-db.container
    ├── piwigo.container
    └── piwigo.network
```

Reload systemd units and start the service :

```sh
sudo systemctl daemon-reload
sudo systemctl start piwigo.service
``` 

### Changing the exposed port :

Edit `piwigo.container` :

```diff
- PublishPort=8080:80
+ PublishPort=12345:80
```

### Changing bind-mounts

Bind mounts are links between the host filesystem and the containers.  
Systemd placeholder are valid in quadlets, `%h` is match the container user home (`/root/`) see [the documentation](#documentation)

Edit `piwigo.container` :

```diff
- Volume=./piwigo-data/piwigo:/var/www/html/piwigo:z
- Volume=./piwigo-data/scripts:/usr/local/bin/scripts:z
+ Volume=%h/PiwigoPod/piwigo:/var/www/html/piwigo:z
+ Volume=%h/PiwigoPod/scripts:/usr/local/bin/scripts:z
```

And edit `piwigo-db.container` :

```diff
- Volume=./piwigo-data/mysql:/var/lib/mysql:z
+ Volume=%h/PiwigoPod/mysql:/var/lib/mysql:z
```

### Updating 

Stop and restart your containers, podman should pull an updated image automatically.

```sh
sudo systemctl stop piwigo.service piwigo-db.service
sudo systemctl daemon-reload
sudo systemctl start piwigo.service
```

### Diagnosing errors 

Access the systemd journal `journalctl --user -eu piwigo.service`, most common errors are permision issues.  
Ensure that your volume is in a valid location and has read and write permisions.

### Documentation 

- [Quadlet unit documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [Volume documentation](https://docs.podman.io/en/v4.4/markdown/options/volume.html)
- [System unit placeholder table](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Specifiers)