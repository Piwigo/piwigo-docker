#!/command/with-contenv ash

set -eu

TZVAL="${TZ}"
PHPV="${PHP_VERSION}"

## Set Timezone
# check the timezone in /usr/share/zoneinfo and fallback to UTC if it doesn't exist
if [ ! -e "/usr/share/zoneinfo/${TZVAL}" ]; then 
  echo "[timezone] '${TZVAL}' not found, fallback UTC" >&2
  TZVAL="UTC"
fi

# for nginx/cron/log etc..
ln -snf "/usr/share/zoneinfo/$TZVAL" /etc/localtime
echo "$TZVAL" > /etc/timezone
# for php-fpm
echo "date.timezone=${TZVAL}" > "/etc/php${PHPV}/conf.d/99-timezone.ini"

echo "[timezone] set to '${TZVAL}'" >&2


## Ensure directories are writable (see https://github.com/MariaDB/mariadb-docker/blob/master/docker-entrypoint.sh)
find "/var/www/html/piwigo/" \! -user nginx \( -exec chown nginx: '{}' + -o -true \)

SOURCE_VERSION=$(php$PHPV -r "include '/var/www/source/piwigo/include/constants.php'; echo PHPWG_VERSION;" 2> /dev/null)
if [ -f '/var/www/html/piwigo/include/constants.php' ]; then
    # Check if the version of piwigo in the volume folder is different from the source
    VOLUME_VERSION=$(php$PHPV -r "include '/var/www/html/piwigo/include/constants.php'; echo PHPWG_VERSION;" 2> /dev/null)
    # Compare version number using php https://www.php.net/manual/en/function.version-compare.php
    VERSION_COMPARE=$(php$PHPV -r "echo version_compare('$SOURCE_VERSION','$VOLUME_VERSION');")
    case $VERSION_COMPARE in
        -1) echo "Please update your container to the latest version by running docker compose pull";;
        0)  echo "Updating to piwigo version $SOURCE_VERSION"
            /bin/cp -arT /var/www/source/piwigo /var/www/html/piwigo/;;
        1) echo "Current piwigo version $VOLUME_VERSION";;
    esac
else
    echo "Installing piwigo $SOURCE_VERSION"
    /bin/cp -arT /var/www/source/piwigo /var/www/html/piwigo/
fi

## Load user scripts if it exist
if [ -e "/usr/local/bin/scripts/user.sh" ]; then
    echo "Loading user script"
    chmod +x "/usr/local/bin/scripts/user.sh"
    /bin/ash -c "/usr/local/bin/scripts/user.sh"
else
    echo "No user script found; you can optionally add one in ./piwigo-data/scripts/user.sh"
    echo "See documentation : https://github.com/Piwigo/piwigo-docker?tab=readme-ov-file#advanced-options"
fi