# Patroni: Initial Setup

For this tutorial I'll create a 3 nodes cluster with below details:
 - node-1 
    - IP: 10.0.100.1
 - node-2 
    - IP: 10.0.100.2
 - node-3 
    - IP: 10.0.100.3

We need to execute the instructions here in all 3 nodes, changing the values when needed.

We start configuring the hostnames and the host file:

```bash
# Run below command for each node changing the node name
sudo hostnamectl set-hostname node-1

# We add the IPs to the /etc/hosts file
echo "
# Cluster nodes
10.0.100.1      node-1
10.0.100.1      node-2
10.0.100.3      node-3
" | sudo tee -a /etc/hosts

# Check with hostnamectl
hostnamectl

# We should see something like:
# node-1:~$ hostnamectl
#  Static hostname: node-1
#        Icon name: computer-vm
#          Chassis: vm
#       Machine ID: 5afb793f085945ec9e61ae1c7a2cc3fe
#          Boot ID: 22ee7e8590d87a308ce2c1fe32b954bc
#   Virtualization: xen
# Operating System: Ubuntu 22.04.2 LTS              
#           Kernel: Linux 5.15.0-1028-aws
#     Architecture: x86-64
#  Hardware Vendor: Xen
#   Hardware Model: HVM domU
```

Next we download and install the Percona's repo:

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

# We install the other packages like patroni, etcd, etc
apt install -y \
   percona-patroni \
   etcd etcd-server etcd-client \
   percona-pgbackrest 
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
#           |- patroni.conf
#           |- pgbackrest.conf
#           |- pgbouncer.conf
#           |- bouncer_users.conf
#           |- pgpool.conf
#           |- haproxy.conf
#           |- pgpass
#       |- data
#           |- etcd
#           |- postgres
#               |- main
#####
sudo mkdir -p /pg_ha/{config,data/{etcd,postgres/main}}
```

[<<- Back to Patroni index](/patroni)