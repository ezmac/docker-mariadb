#!/bin/bash
# configure mysql
echo "**** Configuring mysql and tungsten ****"
sed -ri "s/#log_bin.*/log_bin=$(hostname)-bin/" /etc/mysql/my.cnf

#configure tungsten
cd /tmp/tungsten/
hostname=$(hostname)
# Get the current list of tungsten clients
peers=$(etcdctl -C=http://etcd.local:4001 ls /tungsten/peers)
echo "Found $peers"
#should enter as one peer per line.
sed '4,9d' -i cookbook/COMMON_NODES.sh
i=2
echo "export NODE1=$(hostname)">>cookbook/COMMON_NODES.sh
#peers is a dir of dirs. Dir names are hostname, has keys of ip, port, etc.
for peer in $peers; do
  peer_hostname=$(echo ${peer}|sed "s/\/tungsten\/peers\///")
  echo "adding $peer_hostname"
  peer_ip=$(etcdctl -C=http://etcd.local:4001 get /tungsten/peers/${peer}/ip)
  peer_ip=$(etcdctl -C=http://etcd.local:4001 get /tungsten/peers/${peer}/ip)

  echo "export NODE${i}=${peer_hostname}">>cookbook/COMMON_NODES.sh
  i=$(($i+1))
done
next_server_id=$(etcdctl -C=http://etcd.local:4001 get /tungsten/next_id)
etcdctl -C=http://etcd.local:4001 set /tungsten/next_id $((next_server_id+1))

sed -ri "s/#server-id.*/server-id=$next_server_id/" /etc/mysql/my.cnf
export VERBOSE=1

ip=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')

etcdctl -C=http://etcd.local:4001 mkdir /tungsten/peers/$(hostname)
etcdctl -C=http://etcd.local:4001 set /tungsten/peers/$(hostname)/ip $ip
sed -r "s/MY_CNF=.*/MY_CNF=\/etc\/mysql\/my.cnf/" -i cookbook/USER_VALUES.sh
sed -r "s/TUNGSTEN_BASE=.*/TUNGSTEN_BASE=\/usr\/bin\/tungsten\/cookbook/" -i cookbook/USER_VALUES.sh
tungsten_name=$(etcdctl -C=http://etcd.local:4001 get /tungsten/username)
tungsten_pass=$(etcdctl -C=http://etcd.local:4001 get /tungsten/password)
echo "tungsten_name= $tungsten_name"
echo "tungsten_pass= $tungsten_pass"
sed -r "s/DATABASE_USER=.*/DATABASE_USER=${tungsten_name}/" -i cookbook/USER_VALUES.sh
sed -r "s/DATABASE_PASSWORD=.*/DATABASE_PASSWORD=${tungsten_pass}/" -i cookbook/USER_VALUES.sh
