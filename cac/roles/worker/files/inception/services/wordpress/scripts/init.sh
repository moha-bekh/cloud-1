#!/bin/sh

set -eu

if [ ! -f /run/secrets/user_pass ]; then
  echo "[ERROR] Required secrets not found!"
  exit 1
fi
USER_PASS=$(cat /run/secrets/user_pass)

: "${DB_NAME:?DB_NAME Required}"
: "${USER_NAME:?USER_NAME Required}"
: "${DB_HOST:?DB_HOST Required}"
: "${WP_ROOT:?WP_ROOT Required}"
: "${WP_URL:?WP_URL Required}"
: "${WP_TITLE:?WP_TITLE Required}"
: "${WP_EMAIL:?WP_EMAIL Required}"
: "${WP_THEME:?WP_THEME Required}"
: "${WP_LOCALE:?LOCALE Required}"
: "${IP_ADDR:?IP_ADDR Required}"

export WP_CLI_SERVER_URL="${WP_URL}"

if [ ! -f /usr/local/bin/wp ]; then
  mkdir -p /usr/local/bin
  curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x /usr/local/bin/wp
fi

if [ ! -f $WP_ROOT/index.php ]; then
  curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C $WP_ROOT --strip-components=1
  rm -f /tmp/wordpress.tar.gz
fi

if [ ! -f "${WP_ROOT}/wp-config.php" ]; then
  wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$USER_NAME" \
    --dbpass="$USER_PASS" \
    --dbhost="$DB_HOST" \
    --locale="$WP_LOCALE" \
    --skip-check \
    --allow-root \
    --path="${WP_ROOT}"
fi

until wp db check --path="${WP_ROOT}" --allow-root >/dev/null 2>&1; do
  sleep 2
done

if ! wp core is-installed --path="${WP_ROOT}" --allow-root; then
  wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$USER_NAME" \
    --admin_password="$USER_PASS" \
    --admin_email="$WP_EMAIL" \
    --skip-email \
    --allow-root \
    --path="${WP_ROOT}"
  wp theme install $WP_THEME --activate --allow-root

fi

wp option update home "https://${IP_ADDR}" --allow-root --path="${WP_ROOT}"
wp option update siteurl "https://${IP_ADDR}" --allow-root --path="${WP_ROOT}"

chown -R www-data:www-data "${WP_ROOT}"
chmod -R 775 $WP_ROOT

CONF_FILE="/etc/php/8.2/fpm/pool.d/www.conf"
sed -i 's|^listen = .*|listen = 9000|' ${CONF_FILE}
sed -i 's|^;*listen.owner = .*|listen.owner = www-data|' ${CONF_FILE}
sed -i 's|^;*listen.group = .*|listen.group = www-data|' ${CONF_FILE}
sed -i 's|^;*listen.mode = .*|listen.mode = 0660|' ${CONF_FILE}

exec php-fpm8.2 -F
