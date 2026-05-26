#!/bin/sh

set -eu

: "${PMA_HOST:?PMA_HOST Required}"
: "${PMA_PORT:?PMA_PORT Required}"

CONFIG_FILE=/etc/phpmyadmin/config.inc.php
PUBLIC_DIR=/var/www/phpmyadmin
BLOWFISH_SECRET=$(openssl rand -hex 32)

mkdir -p "$PUBLIC_DIR"
find "$PUBLIC_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cp -aL /usr/share/phpmyadmin/. "$PUBLIC_DIR/"

cat > "$CONFIG_FILE" <<EOF
<?php
\$i = 1;
\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';
\$cfg['PmaAbsoluteUri'] = 'https://' . \$_SERVER['HTTP_HOST'] . '/phpmyadmin/';
\$cfg['Servers'][\$i]['host'] = '${PMA_HOST}';
\$cfg['Servers'][\$i]['port'] = '${PMA_PORT}';
\$cfg['Servers'][\$i]['connect_type'] = 'tcp';
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['TempDir'] = '/tmp';
\$cfg['SendErrorReports'] = 'never';
EOF

CONF_FILE="/etc/php/8.2/fpm/pool.d/www.conf"
sed -i 's|^listen = .*|listen = 9000|' "$CONF_FILE"
sed -i 's|^;*listen.owner = .*|listen.owner = www-data|' "$CONF_FILE"
sed -i 's|^;*listen.group = .*|listen.group = www-data|' "$CONF_FILE"
sed -i 's|^;*listen.mode = .*|listen.mode = 0660|' "$CONF_FILE"

exec php-fpm8.2 -F
