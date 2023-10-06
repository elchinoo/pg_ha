# Patroni: Configuring ETCD

Okay, time to start configuring the ETCD service. When creating the ETCD cluster some of the commands and configuration change from the first node in the cluster to the other nodes. Pay attention to this because many errors are caused because the user runs the same set of commands or use the same configuration in all nodes.

## Execute on all nodes

The first thing we'll do is to personalise the SystemD unit file to reflect our configuration and folder changes:

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

## Configuring node-1

Time to create our ETCD config file and start the first node:

```bash
# We'll export some variables to make it easier to create our config file
# We start with the node name
export NODE_NAME=`hostname -f`

# The local IP
export NODE_IP=`hostname -i | awk '{print $1}'`
# We can alternativelly find the IP with something like:
# export NODE_IP=`ip -f inet addr show eth0 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`

# Initial cluster token for the etcd cluster during bootstrap
export ETCD_TOKEN='PostgreSQL_HA_Cluster_1'

# The etcd data directory
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

# We should see something like:
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

## Configuring the remaining nodes

We will also create the same variables on the other nodes to help us during the configuration time:

```bash
# We'll export some variables to make it easier to create our config file
# We start with the node name
export NODE_NAME=`hostname -f`

# The local IP
export NODE_IP=`hostname -i | awk '{print $1}'`
# We can alternativelly find the IP with something like:
# export NODE_IP=`ip -f inet addr show eth0 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`

# Initial cluster token for the etcd cluster during bootstrap
export ETCD_TOKEN='PostgreSQL_HA_Cluster_1'

# The etcd data directory
export ETCD_DATA_DIR='/pg_ha/data/etcd'

```

Now we need to let the node-1 knows we are adding a new member to the cluster. We go back to the `node-1` server and execute below command:

```bash

# etcdctl member add <NODE_NAME> http://<NODE_IP>:2380
etcdctl member add node-2 http://10.0.100.2:2380

# We should see something like:
# Added member named node-2 with ID e9778bdd4c014314 to cluster
# 
# ETCD_NAME="node-2"
# ETCD_INITIAL_CLUSTER="node-1=http://10.0.100.1:2380,node-2=http://10.0.100.2:2380"
# ETCD_INITIAL_CLUSTER_STATE="existing"


```

We'll use the values returned by the command we execute on `node-1` to create the configuration of the other nodes. And our configuration file will be something like:

```bash
echo "
ETCD_NAME="node-2"
ETCD_INITIAL_CLUSTER="node-1=http://10.0.100.1:2380,node-2=http://10.0.100.2:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"

ETCD_INITIAL_CLUSTER_TOKEN="${ETCD_TOKEN}"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${NODE_IP}:2380"
ETCD_DATA_DIR="${ETCD_DATA_DIR}"
ETCD_LISTEN_PEER_URLS="http://${NODE_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="http://${NODE_IP}:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://${NODE_IP}:2379"
" | sudo tee -a /pg_ha/config/etcd.conf

```

Note that the first 3 lines of the configuration file is exactly the same as the result of the `etcdctl member add` command.

The remaining steps are the same as the first node:

```bash
# We make sure Postgres owns the pg_ha folder
sudo chown -R postgres:postgres /pg_ha

# Enable and start the service
sudo systemctl enable --now etcd

# Then we check if running
systemctl status etcd

# We should see something like:
# root@node-2:~# systemctl status etcd
# ● etcd.service - etcd - highly-available key value store
#      Loaded: loaded (/etc/systemd/system/etcd.service; enabled; vendor preset: enabled)
#      Active: active (running) since Tue 2023-06-27 12:55:35 UTC; 7s ago
#        Docs: https://etcd.io/docs
#              man:etcd
#    Main PID: 20044 (etcd)
#       Tasks: 7 (limit: 2349)
#      Memory: 7.0M
#         CPU: 126ms
#      CGroup: /system.slice/etcd.service
#              └─20044 /usr/bin/etcd
# 
# Jun 27 12:55:35 node-2 etcd[20044]: added member 73fec614f5089c49 [http://10.0.100.28:2380] to cluster 19eb16c>
# 
```

If everything went well we can now check the list of nodes:

```bash
etcdctl member list

# We should see something like:
# 73fec614f5089c49: name=node-1 peerURLs=http://10.0.100.1:2380 clientURLs=http://10.0.100.1:2379 isLeader=true
# e9778bdd4c014314: name=node-2 peerURLs=http://10.0.100.2:2380 clientURLs=http://10.0.100.2:2379 isLeader=false
```

And also check the cluster health:

```bash
etcdctl cluster-health

# We should see something like:
# member 73fec614f5089c49 is healthy: got healthy result from http://10.0.100.1:2379
# member e9778bdd4c014314 is healthy: got healthy result from http://10.0.100.2:2379
# cluster is healthy
```

We then repeat this for all remaining nodes.


[<<- Back to Patroni index](/patroni)
