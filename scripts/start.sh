#!/bin/bash
# Starts up MariaDB within the container.

# Stop on error
#set -e

mkdir -p /run/mysqld/
DATA_DIR=/data
MYSQL_LOG=$DATA_DIR/mysql.log

cd /tmp/tungsten/
# Get the current list of tungsten clients
peers=$(etcdctl -C=http://etcd.local:4001 ls /tungsten/peers)
echo "Found $peers"
#should enter as one peer per line.
sed '4,9d' -i cookbook/COMMON_NODES.sh
i=1
for peer in $peers; do
  peer_ip=$(etcdctl -C=http://etcd.local:4001 ls /tungsten/peers/$peer)
  echo "export NODE${i}=${peer}">>cookbook/COMMON_NODES.sh
done

export VERBOSE=1

ip=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')

echo "export NODE0=${ip}:3306">>cookbook/COMMON_NODES.sh
etcdctl -C=http://etcd.local:4001 set /tungsten/peers/${ip} ${ip}
sed -r "s/MY_CNF=.*/MY_CNF=\/etc\/mysql\/my.cnf/" -i cookbook/USER_VALUES.sh
sed -r "s/TUNGSTEN_BASE=.*/TUNGSTEN_BASE=\/usr\/bin\/tungsten\/cookbook/" -i cookbook/USER_VALUES.sh
tungsten_name=$(etcdctl -C=http://etcd.local:4001 get /tungsten/username)
tungsten_pass=$(etcdctl -C=http://etcd.local:4001 get /tungsten/password)
echo "tungsten_name= $tungsten_name"
echo "tungsten_pass= $tungsten_pass"
sed -r "s/DATABASE_USER=.*/DATABASE_USER=${tungsten_name}/" -i cookbook/USER_VALUES.sh
sed -r "s/DATABASE_PASSWORD=.*/DATABASE_PASSWORD=${tungsten_pass}/" -i cookbook/USER_VALUES.sh


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
