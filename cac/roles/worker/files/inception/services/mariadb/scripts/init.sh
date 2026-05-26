#!/bin/sh

set -eu

if [ -z "$(ls -A /var/lib/mysql)" ]; then

	: "${DB_NAME:?DB_NAME Required}"
	: "${USER_NAME:?USER_NAME Required}"

	if [ ! -f /run/secrets/user_pass ] || [ ! -f /run/secrets/root_pass ]; then
		echo "[ERROR] Required secrets not found!"
		exit 1
	fi
	USER_PASS=$(cat /run/secrets/user_pass)
	ROOT_PASS=$(cat /run/secrets/root_pass)

	install -d -o mysql -g mysql /run/mysqld /var/lib/mysql

	if [ ! -d /var/lib/mysql/mysql ]; then
		mysql_install_db --user=mysql --datadir=/var/lib/mysql
	fi

	mysqld_safe --skip-networking --skip-grant-tables --datadir=/var/lib/mysql &
	mysql_pid=$!

	until mysqladmin ping -u root --silent; do
		sleep 1
	done

	mysql -u root <<-EOSQL
		FLUSH PRIVILEGES;
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
	EOSQL

	mysql -uroot -p"${ROOT_PASS}" <<-EOSQL
		CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
		CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASS}';

		CREATE USER IF NOT EXISTS '${USER_NAME}'@'%' IDENTIFIED BY '${USER_PASS}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${USER_NAME}'@'%';

		CREATE USER '${USER_NAME}'@'localhost' IDENTIFIED BY '${USER_PASS}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${USER_NAME}'@'localhost';
		FLUSH PRIVILEGES;
	EOSQL

	mysqladmin -uroot -p"$ROOT_PASS" shutdown
	wait $mysql_pid
fi

sed -i 's/^#*\s*bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

exec mysqld_safe --datadir=/var/lib/mysql