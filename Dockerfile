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
    apt-get -y install python-software-properties && \
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && \
    add-apt-repository 'deb http://mirror.jmu.edu/pub/mariadb/repo/5.5/ubuntu trusty main' && \
    apt-get update && \
    apt-get install -y mariadb-server curl which bc rsync wget java-1.7.0-openjdk ruby rpm go

# Install other tools.
RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y pwgen inotify-tools

# Decouple our data from our container.
VOLUME ["/data"]

RUN go install github.com/coreos/etcdctl
# Configure the database to use our data dir.
RUN sed -i -e 's/^datadir\s*=.*/datadir = \/data/' /etc/mysql/my.cnf

# Configure MariaDB to listen on any address.
RUN sed -i -e 's/^bind-address/#bind-address/' /etc/mysql/my.cnf

EXPOSE 3306
ADD scripts /scripts
RUN chmod +x /scripts/start.sh
RUN touch /firstrun

ENTRYPOINT ["/scripts/start.sh"]
