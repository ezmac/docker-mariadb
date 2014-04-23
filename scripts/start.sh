#!/bin/bash
# Starts up MariaDB within the container.

# Stop on error
#set -e
#alias etcdctl=etcdctl -C=http://etcd.local:4001
mkdir -p /run/mysqld/
DATA_DIR=/data
MYSQL_LOG=$DATA_DIR/mysql.log

source /scripts/tungsten_init.sh

if [[ -e /firstrun ]]; then
  echo "this was the first run"
  source /scripts/first_run.sh
else
  echo "normal run"
  source /scripts/normal_run.sh
fi

wait_for_mysql_and_run_post_start_action() {
  # Wait for mysql to finish starting up first.
  while [[ ! -e /run/mysqld/mysqld.sock ]] ; do
      inotifywait -q -e create /run/mysqld/ >> /dev/null
  done

  post_start_action
}

pre_start_action

wait_for_mysql_and_run_post_start_action &

# Start MariaDB
echo "Starting MariaDB..."
exec /usr/bin/mysqld_safe --skip-syslog --log-error=$MYSQL_LOG
