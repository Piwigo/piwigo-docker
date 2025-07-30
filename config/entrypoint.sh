#!/bin/sh

# Ensure directories are writable (see https://github.com/MariaDB/mariadb-docker/blob/master/docker-entrypoint.sh)
find "/var/www/html/piwigo/" \! -user nginx \( -exec chown nginx: '{}' + -o -true \)

# Check if the version of piwigo in the volume folder is different from the source
SOURCE_VERSION=$(php -r "include '/var/www/source/piwigo/include/constants.php'; echo PHPWG_VERSION;" 2> /dev/null)
VOLUME_VERSION=$(php -r "include '/var/www/html/piwigo/include/constants.php'; echo PHPWG_VERSION;" 2> /dev/null)
if ! [ "$SOURCE_VERSION" = "$VOLUME_VERSION" ]; then
    echo "Installing piwigo version $SOURCE_VERSION"
    /bin/cp -arT /var/www/source/piwigo /var/www/html/piwigo/
else
    echo "Current piwigo version $VOLUME_VERSION"
fi

# Load user scripts if it exist
if [ -e "/usr/local/bin/scripts/user.sh" ]; then
    echo "Loading user script"
    chmod +x "/usr/local/bin/scripts/user.sh"
    /bin/ash -c "/usr/local/bin/scripts/user.sh"
else
    echo "No user script found; you can optionally add one in ./piwigo-data/scripts/user.sh"
fi

# Log that the script has finished
echo "Starting supervisord"
/usr/bin/supervisord -c /etc/supervisord.conf