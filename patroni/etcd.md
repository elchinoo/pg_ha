# Patroni: Configuring ETCD

Okay, time to start configuring the ETCD service, and the first thing we'll do is to personalise the SystemD unit file to reflect our configuration and folder changes:

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
# We'll export some variables to make it easier to create our config file
# We start with the node name
export NODE_NAME='node-1'

# The local IP
export NODE_IP='10.0.0.1'
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

[Back to Patroni index](../)