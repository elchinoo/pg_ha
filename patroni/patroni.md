# Patroni: Configuring ETCD

It's now time to configure the Patroni service.

## Execute on all nodes

The below commands need to be executed in all nodes, and can be done in parallel:

```bash 
# We'll export some variables to make it easier to create our config file
# We start with the node name
export NODE_NAME=`hostname -f`

# The local IP
export NODE_IP=`hostname -i | awk '{print $1}'`
# We can alternativelly find the IP with something like:
# export NODE_IP=`ip -f inet addr show eth0 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`


# We'll also create variables to store the PATH
BASE_DIR="/pg_ha"
CFG_DIR="${BASE_DIR}/config"
CFG_PATH="${CFG_DIR}/patroni.yaml"
PGPASS="${CFG_DIR}/pgpass"
DATADIR="${BASE_DIR}/data/postgres/15"

# Postgres bin dir
PG_BIN_DIR="/usr/lib/postgresql/15/bin"

# Some patroni information
NAMESPACE="percona_lab"
SCOPE="cluster_1"

```

We'll now create the configuration file:

```bash
echo "
namespace: ${NAMESPACE}
scope: ${SCOPE}
name: ${NODE_NAME}

restapi:
    listen: 0.0.0.0:8008
    connect_address: ${NODE_IP}:8008

etcd:
    host: ${NODE_IP}:2379

bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        slots:
            percona_cluster_1:
              type: physical
        postgresql:
            use_pg_rewind: true
            use_slots: true
            parameters:
                wal_level: logical
                hot_standby: "on"
                wal_keep_size: 4096
                max_wal_senders: 5
                max_replication_slots: 10
                wal_log_hints: "on"
                archive_mode: "on"
                archive_timeout: 1800s
                logging_collector: 'on'

    # some desired options for 'initdb'
    initdb: # Note: It needs to be a list (some options need values, others are switches)
        - encoding: UTF8
        - data-checksums

    pg_hba: # Add following lines to pg_hba.conf after running 'initdb'
        - host replication replicator 127.0.0.1/32 trust
        - host replication replicator 0.0.0.0/0 md5
        - host all all 0.0.0.0/0 md5
        - host all all ::0/0 md5

    # Some additional users which needs to be created after initializing new cluster
    users:
        admin:
            password: qaz123
            options:
                - createrole
                - createdb
        charly:
            password: qaz123
            options:
                - createrole
                - createdb

postgresql:
    cluster_name: cluster_1
    listen: 0.0.0.0:5432
    connect_address: ${NODE_IP}:5432
    data_dir: ${DATADIR}
    bin_dir: ${PG_BIN_DIR}
    pgpass: ${PGPASS}

    authentication:
        replication:
            username: replicator
            password: passRepl01
        superuser:
            username: postgres
            password: passPG59

    parameters:
        unix_socket_directories: "/var/run/postgresql/"

    create_replica_methods:
        - basebackup

    basebackup:
        checkpoint: 'fast'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
" | sudo tee -a ${CFG_PATH}

```

We also need to change the SystemD unity file to use our custom configuration file:

```bash
cp /usr/lib/systemd/system/patroni.service /etc/systemd/system/
sed -i "s|^EnvironmentFile=-/etc/patroni_env.conf|EnvironmentFile=-${CFG_DIR}/patroni_env.conf|g" /etc/systemd/system/patroni.service
sed -i "s|^Environment=PATRONI_CONFIG_LOCATION=/etc/patroni/patroni.yml|Environment=PATRONI_CONFIG_LOCATION=${CFG_PATH}|g" /etc/systemd/system/patroni.service
chown -R postgres:postgres ${BASE_DIR}
```

Some OSes don't come with a default Patroni unity file. We can manually create it on `/etc/systemd/system` and the file we just change will look like:

```ini
# It's not recommended to modify this file in-place, because it will be
# overwritten during package upgrades.  If you want to customize, the
# best way is to create a file "/etc/systemd/system/patroni.service",
# containing
#       .include /lib/systemd/system/patroni.service
#       Environment=PATRONI_CONFIG_LOCATION=...
# For more info about custom unit files, see
# http://fedoraproject.org/wiki/Systemd#How_do_I_customize_a_unit_file.2F_add_a_custom_unit_file.3F

[Unit]
Description=PostgreSQL high-availability manager
After=syslog.target network.target

[Service]
Type=simple

User=postgres
Group=postgres

# Read in configuration file if it exists, otherwise proceed
EnvironmentFile=-/pg_ha/config/patroni_env.conf

# The default is the user's home directory, and if you want to change it, you must provide an absolute path.
# WorkingDirectory=/home/sameuser

# Where to send early-startup messages from the server
# This is normally controlled by the global default set by systemd
#StandardOutput=syslog
# Location of Patroni configuration
Environment=PATRONI_CONFIG_LOCATION=/pg_ha/config/patroni.yaml

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000

# Pre-commands to start watchdog device
# Uncomment if watchdog is part of your patroni setup
#ExecStartPre=-/usr/bin/sudo /sbin/modprobe softdog
#ExecStartPre=-/usr/bin/sudo /bin/chown postgres /dev/watchdog

# Start the patroni process
ExecStart=/usr/bin/patroni ${PATRONI_CONFIG_LOCATION}

# Send HUP to reload from patroni.yml
ExecReload=/bin/kill -s HUP $MAINPID

# Only kill the patroni process, not it's children, so it will gracefully stop postgres
KillMode=process

# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=30

# Restart the service if it crashed
Restart=on-failure

[Install]
WantedBy=multi-user.target

```

Now it's time to start Patroni. We'll do it in all the nodes but not in parallel. We'll start first `node-1`, wait for the service to come to live, and then proceed with the other nodes one-by-one, always waiting for them to sync with the primary node.

```bash
# Reload the systemd daemon to apply our changes
systemctl daemon-reload

# Enable and start the Patroni service
sudo systemctl enable --now patroni

# Check the service to see if any error
journalctl -fu patroni

# If everything goes well we can check the cluster
patronictl -c $CFG_PATH list $SCOPE

```

The result for the first node should be something like the result below

```bash
root@node-1:~# patronictl -c $CFG_PATH list $SCOPE
+ Cluster: cluster_1 --+---------+---------+----+-----------+
| Member | Host        | Role    | State   | TL | Lag in MB |
+--------+-------------+---------+---------+----+-----------+
| node-1 | 10.0.100.1  | Leader  | running |  1 |           |
+--------+-------------+---------+---------+----+-----------+

```

With the remaining nodes adding its info to the result:

```bash
root@node-1:~# patronictl -c $CFG_PATH list $SCOPE
+ Cluster: cluster_1 --+---------+---------+----+-----------+
| Member | Host        | Role    | State   | TL | Lag in MB |
+--------+-------------+---------+---------+----+-----------+
| node-1 | 10.0.100.1  | Leader  | running |  1 |           |
| node-2 | 10.0.100.2  | Replica | running |  1 |         0 |
+--------+-------------+---------+---------+----+-----------+

```

We have now a fully functional Patroni cluster. There are improvements we can and need to do, for example configuring the Watchdog service, installing and configuring Patroni to use pgbackrest for both backup and archiving, but this is for the next sessions!

[<<- Back to Patroni index](/patroni)
