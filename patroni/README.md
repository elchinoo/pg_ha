# Patroni: A Template for PostgreSQL HA with ZooKeeper, etcd or Consul

According to its [Github repo[1]](https://github.com/zalando/patroni) Patroni is a template for you to create your own customized, high-availability solution using Python and - for maximum accessibility - a distributed configuration store like ZooKeeper, etcd, Consul or Kubernetes. Database engineers, DBAs, DevOps engineers, and SREs who are looking to quickly deploy HA PostgreSQL in the datacenter-or anywhere else-will hopefully find it useful.

Here we'll use Ubuntu 22 and the PostgreSQL 15 provided by Percona for simplicity. We can find the full documentation in their [website here[2]](https://docs.percona.com/postgresql/15/index.html) including instructions to install in other Linux distros like RedHat.

We start downloading and installing the Percona's repo:

```bash
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
```

We can use the utility to configure the repo to the version we want to use, Postgres 15 in our case:

```bash
percona-release enable-only ppg-15
apt-get update
apt-get upgrade -y
```

We now install the needed packages:

```bash
# We start with Postgres server
apt install -y percona-ppg-server-15

# Some python and auxiliary packages to help with Patroni and ETCD
apt install -y python3-pip python3-dev binutils

# We install the ETCD
apt install -y percona-patroni etcd-server etcd-client 
```

I'll stop and disable all services for now as I don't want SystemD messing up while configuring the instance:

```bash
systemctl stop {etcd,patroni,postgresql}
systemctl disable {etcd,patroni,postgresql}
```

I like to centralize all configuration files in the same folder to make my life easier when changing them, and will do it here:

```bash
#####
# I will create the following tree on my root directory to store our setup:
#   /pg_ha
#       |- config
#           |- etcd.conf
#           |- patroni.yaml
#           |- pgbackrest.conf
#           |- pgbouncer.ini
#           |- bouncer_users.txt
#           |- pgpass
#       |- data
#           |- etcd
#           |- postgres
#               |- main
#####
sudo mkdir -p /pg_ha/{config,data/{etcd,postgres/main}}
```

Okay, time to start configuring the services. Let's start with ETCD, and the first thing I'll do is to change the SystemD unit file to point to 

```bash
# We copy the unit file to the personalized unit files folder, this way we don't risk to have our changes overwritten when updating our services
sudo cp /usr/lib/systemd/system/etcd.service /etc/systemd/system/

# Then we change the owner of the service. We'll run everything here as Postgres user
sudo sed -i 's/^User=etcd/User=postgres/g' /etc/systemd/system/etcd.service

# We change the path to the environment file, which is in practice our ETCD configuration file
sudo sed -i 's|^EnvironmentFile=-/etc/default/%p|EnvironmentFile=-/pg_ha/config/%p.conf|g' /etc/systemd/system/etcd.service

# We reload the SystemD configuration
sudo systemctl daemon-reload
```

Time to create our ETCD config file and start the first node:

```bash
export NODE_NAME='node-1'
export NODE_IP='10.0.0.1'
export ETCD_TOKEN='PostgreSQL_HA_Cluster_1'
export ETCD_DATA_DIR='/pg_ha/data/etcd'

echo "
ETCD_NAME=${NODE_NAME}
ETCD_INITIAL_CLUSTER="${NODE_NAME}=http://${NODE_IP}:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="${ETCD_TOKEN}"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${NODE_IP}:2380"
ETCD_DATA_DIR="${ETCD_DATA_DIR}"
ETCD_LISTEN_PEER_URLS="http://${NODE_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="http://${NODE_IP}:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://${NODE_IP}:2379"
" | sudo tee -a /pg_ha/config/etcd.conf

# We make sure Postgres owns the pg_ha folder
sudo chown -R postgres:postgres /pg_ha

# Enable and start the service
sudo systemctl enable --now etcd

# Then we check if running
systemctl status etcd

# We should see something like
# node1:~$ systemctl status etcd
# ● etcd.service - etcd - highly-available key value store
#      Loaded: loaded (/etc/systemd/system/etcd.service; enabled; vendor preset: enabled)
#      Active: active (running) since Thu 2023-03-16 02:33:17 UTC; 36s ago
#        Docs: https://etcd.io/docs
#              man:etcd
#    Main PID: 1029674 (etcd)
#       Tasks: 8 (limit: 4689)
#      Memory: 118.8M
#         CPU: 3.481s
#      CGroup: /system.slice/etcd.service
#              └─1029674 /usr/bin/etcd
# 
```


```bash

```


```bash

```

[1] https://github.com/zalando/patroni
[2] https://docs.percona.com/postgresql/15/index.html