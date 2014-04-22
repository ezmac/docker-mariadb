# MariaDB (https://mariadb.org/)

FROM jayofdoom/docker-ubuntu-14.04
# taken from MAINTAINER Ryan Seto <ryanseto@yak.net>

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list

# Ensure UTF-8
RUN apt-get update
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Install MariaDB from repository.
RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install python-software-properties &&\
    apt-get update && \
    apt-get install -y mariadb-server curl  bc rsync wget openjdk-7-jre-headless openjdk-7-jre ruby rpm golang

# Install other tools.
RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y pwgen inotify-tools

# Decouple our data from our container.
VOLUME ["/data"]

# Install etcdctl
RUN cd /tmp && wget -d https://github.com/coreos/etcd/releases/download/v0.3.0/etcd-v0.3.0-linux-amd64.tar.gz && \
  tar -xf etcd-v0.3.0-linux-amd64.tar.gz  && cp etcd-v0.3.0-linux-amd64/etcdctl /usr/bin/etcdctl &&\
  rm -rf etcd-v0*

# Configure the database to use our data dir.
RUN sed -i -e 's/^datadir\s*=.*/datadir = \/data/' /etc/mysql/my.cnf

# Configure MariaDB to listen on any address.
RUN sed -i -e 's/^bind-address/#bind-address/' /etc/mysql/my.cnf

# Install Tungsten replicator
RUN cd /tmp && wget -d https://s3.amazonaws.com/files.continuent.com/builds/nightly/tungsten-2.0-snapshots/tungsten-replicator-2.1.0-346.tar.gz&&\
    tar -xf tungsten-replicator-2.1.0-346.tar.gz && mv tungsten-replicator-2.1.0-346 tungsten

EXPOSE 3306
ADD scripts /scripts
RUN chmod +x /scripts/start.sh
RUN touch /firstrun

#CMD ["/scripts/start.sh"]
CMD []
ENTRYPOINT ["/bin/bash"]
