# Setup using tarballs

This runbook will use the tarball files from the Percona Repositories (https://docs.percona.com/postgresql/16/tarball.html).

We'll work with a non-privileged user and only use root to create the folders but they can also be in the user `/home` folder.

## Initial setup

We'll use below variables to make life easier:

```bash
WORK_DIR=/pg-ha
BIN_DIR_PG=${WORK_DIR}/percona-postgresql16/bin
BIN_ETCD=${WORK_DIR}/percona-etcd/bin/etcd
BIN_PATRONI=${WORK_DIR}/percona-patroni/bin/patroni

CONFIG_DIR=${WORK_DIR}/config

DATA_DIR=${WORK_DIR}/data
DATA_DIR_PG=${DATA_DIR}/pgdata
DATA_DIR_ETCD=${DATA_DIR}/etcd

TMP_DIR=${WORK_DIR}/tmp

PGPASS="${CONFIG_DIR}/pgpass"

PG_USER=postgres

```

The first thing we need to do is to create the `PG_USER` and the folders:

```bash

sudo hostnamectl set-hostname pg-node-1

sudo adduser ${PG_USER}

sudo mkdir -p ${WORK_DIR}
sudo mkdir -p ${DATA_DIR}
sudo mkdir -p ${CONFIG_DIR}
sudo mkdir -p ${TMP_DIR}

sudo chown -R ${PG_USER}:${PG_USER} ${WORK_DIR}

sudo cp /home/postgres/.bashrc /home/postgres/.bashrc-bak

echo '
####### 
# Percona config for pg-ha
WORK_DIR=/pg-ha
BIN_DIR_PG=${WORK_DIR}/percona-postgresql16/bin
BIN_ETCD=${WORK_DIR}/percona-etcd/bin/etcd
BIN_PATRONI=${WORK_DIR}/percona-patroni/bin/patroni

CONFIG_DIR=${WORK_DIR}/config

DATA_DIR=${WORK_DIR}/data
DATA_DIR_PG=${DATA_DIR}/pgdata
DATA_DIR_ETCD=${DATA_DIR}/etcd

TMP_DIR=${WORK_DIR}/tmp

PGPASS="${CONFIG_DIR}/pgpass"

PG_USER=postgres
PGDATA=${DATA_DIR_PG}

export PATH=${WORK_DIR}/percona-haproxy/sbin/:${WORK_DIR}/percona-patroni/bin/:${WORK_DIR}/percona-pgbackrest/bin/:${WORK_DIR}/percona-pgbadger/:${WORK_DIR}/percona-pgbouncer/bin/:${WORK_DIR}/percona-pgpool-II/bin/:${WORK_DIR}/percona-postgresql16/bin/:${WORK_DIR}/percona-etcd/bin/:/opt/percona-perl/bin/:/opt/percona-tcl/bin/:/opt/percona-python3/bin/:$PATH

#######
' | sudo tee -a /home/postgres/.bashrc

```

## Download the packages

From now on all the commands SHALL be run as `PG_USER`. We'll use `sudo` when we need to escalate privileges, for example to create the `systemd` configuration files.

We need to download the tarballs from Percona and also the `ETCD` drivers. We'll use the drivers from the `pypi` project (https://pypi.org).

```bash
sudo su - ${PG_USER}

curl \
  https://downloads.percona.com/downloads/postgresql-distribution-16/16.3/binary/tarball/percona-postgresql-16.3-ssl3-linux-x86_64.tar.gz \
  -o ${TMP_DIR}/percona-postgresql-16.3-ssl3-linux-x86_64.tar.gz

curl \
  https://files.pythonhosted.org/packages/a1/da/616a4d073642da5dd432e5289b7c1cb0963cc5dde23d1ecb8d726821ab41/python-etcd-0.4.5.tar.gz \
  -o ${TMP_DIR}/python-etcd-0.4.5.tar.gz

curl \
  https://files.pythonhosted.org/packages/9c/eb/6d1ef4d6a3e8b74e45c502cbd3ea6c5c6c786d003829db9369c2530f5e3f/etcd3-0.12.0.tar.gz \
  -o ${TMP_DIR}/etcd3-0.12.0.tar.gz

```

We'll also need some additional libraries to be able to compile the driver (dnspython, tenacity, protobuf, grpcio):

```bash

# https://pypi.org/project/dnspython/
curl \
  https://files.pythonhosted.org/packages/87/a1/8c5287991ddb8d3e4662f71356d9656d91ab3a36618c3dd11b280df0d255/dnspython-2.6.1-py3-none-any.whl#sha256=5ef3b9680161f6fa89daf8ad451b5f1a33b18ae8a1c6778cdf4b43f08c0a6e50 \
  -o ${TMP_DIR}/dnspython-2.6.1-py3-none-any.whl


# https://pypi.org/project/tenacity/
curl \
  https://files.pythonhosted.org/packages/b6/cb/b86984bed139586d01532a587464b5805f12e397594f19f931c4c2fbfa61/tenacity-9.0.0-py3-none-any.whl#sha256=93de0c98785b27fcf659856aa9f54bfbd399e29969b0621bc7f762bd441b4539 \
  -o ${TMP_DIR}/tenacity-9.0.0-py3-none-any.whl

# https://pypi.org/project/protobuf/
curl \
  https://files.pythonhosted.org/packages/4c/98/db690e43e2f28495c8fc7c997003cbd59a6db342914b404e216c9b6791f0/protobuf-5.27.3-cp38-abi3-manylinux2014_x86_64.whl#sha256=a55c48f2a2092d8e213bd143474df33a6ae751b781dd1d1f4d953c128a415b25 \
  -o ${TMP_DIR}/protobuf-5.27.3-cp38-abi3-manylinux2014_x86_64.whl

# https://pypi.org/project/grpcio/
curl \
  https://files.pythonhosted.org/packages/12/75/b25d1f130db4a294214ac300a38cc1f5a853ee8ea2e0e2529a200d3e6165/grpcio-1.65.4-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl#sha256=74c34fc7562bdd169b77966068434a93040bfca990e235f7a67cdf26e1bd5c63 \
  -o ${TMP_DIR}/grpcio-1.65.4-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

```

### Extract and install the packages

After downloaded the packages need to be extracted:

```bash

tar -xvf ${TMP_DIR}/percona-postgresql-16.3-ssl3-linux-x86_64.tar.gz -C ${WORK_DIR}
tar -xvf ${TMP_DIR}/python-etcd-0.4.5.tar.gz -C ${TMP_DIR}
tar -xvf ${TMP_DIR}/etcd3-0.12.0.tar.gz -C ${TMP_DIR}

```

Note that we extracted the `Percona` package into the `workdir` while we kept the `etcd` drivers in the `tmp` folder. This is because we'll need to kinda `"compile"` the drivers using the `python3` from the `Percona` package. But before we do that we need to create a symbolik link pointing the `python` package to the `/opt` folder. This is needed because the way the `Percona` packages were compiled:

```bash

sudo ln -vis ${WORK_DIR}/percona-python3 /opt/
sudo ln -vis ${WORK_DIR}/percona-tcl /opt/
sudo ln -vis ${WORK_DIR}/percona-perl  /opt/

```

Now we can finish installing the drivers:

```bash

cd ${TMP_DIR}
/opt/percona-python3/bin/pip3 install dnspython-2.6.1-py3-none-any.whl
/opt/percona-python3/bin/pip3 install tenacity-9.0.0-py3-none-any.whl
/opt/percona-python3/bin/pip3 install protobuf-5.27.3-cp38-abi3-manylinux2014_x86_64.whl
/opt/percona-python3/bin/pip3 install grpcio-1.65.4-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl


cd ${TMP_DIR}/python-etcd-0.4.5
/opt/percona-python3/bin/python3 setup.py install

cd ${TMP_DIR}/etcd3-0.12.0
/opt/percona-python3/bin/python3 setup.py install

```
## Configuration files

It's now time to create the configuration files and start the services.

### ETCD: First node

We'll start with the ETCD cluster. 

I will use the below info as the servers info. Please `CHANGE THE VALUES for your servers`!

```bash

SRV1_NAME='pg-node-1'
SRV2_NAME='pg-node-2'
SRV3_NAME='pg-node-3'

SRV1_IP='12.0.1.242'
SRV2_IP='12.0.1.125'
SRV3_IP='12.0.1.239'


ETCD_TOKEN='PostgreSQL_HA_Cluster_1'
CONFIG_FILE_PATH=${CONFIG_DIR}/etcd.yaml
```

The first node is the bootstrap node and the configuration will be something like:

```bash
echo "
# ETCD V3.5 Configuration file by Percona
# ${CONFIG_DIR}/etcd.yaml
name: ${SRV1_NAME}
data-dir: ${DATA_DIR_ETCD}
initial-cluster: '${SRV1_NAME}=http://${SRV1_IP}:2380'
initial-cluster-token: '${ETCD_TOKEN}'
initial-cluster-state: 'new'
listen-peer-urls: 'http://${SRV1_IP}:2380'
listen-client-urls: 'http://${SRV1_IP}:2379'
initial-advertise-peer-urls: 'http://${SRV1_IP}:2380'
advertise-client-urls: 'http://${SRV1_IP}:2379'
" | tee ${CONFIG_DIR}/etcd.yaml

```

We now need to create the `systemd` unity file:

```bash

echo "
[Unit]
Description=etcd - highly-available key value store
Documentation=https://etcd.io/docs
Documentation=man:etcd
After=network.target
Wants=network-online.target

[Service]
Environment=DAEMON_ARGS=
Environment=ETCD_NAME=%H
Environment=DATA_DIR_ETCD=${DATA_DIR_ETCD}
EnvironmentFile=-${CONFIG_DIR}/%p
Type=notify
User=${PG_USER}
PermissionsStartOnly=true
ExecStart=${BIN_ETCD} --config-file ${CONFIG_DIR}/etcd.yaml
Restart=on-abnormal
#RestartSec=10s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
Alias=etcd2.service

" | sudo tee /etc/systemd/system/etcd.service

```

Now it's time to reload `systemd`, start the service, and check if running fine:

```bash

sudo systemctl daemon-reload
sudo systemctl enable --now etcd
systemctl status etcd
etcdctl --endpoints=${SRV1_IP}:2379 member list

```

### ETCD: Remaining nodes

Before we start adding the next nodes let's define the helper variables:

```bash

SRV1_NAME='pg-node-1'
SRV2_NAME='pg-node-2'
SRV3_NAME='pg-node-3'

SRV1_IP='12.0.1.242'
SRV2_IP='12.0.1.125'
SRV3_IP='12.0.1.239'

# Same for all of them
ETCD_TOKEN='PostgreSQL_HA_Cluster_1'
CONFIG_FILE_PATH=${CONFIG_DIR}/etcd.yaml

```

For the remaining nodes we need to first add the nodes to the cluster. Note that we need to do `ONE BY ONE`, and we can only add node-3 after we fully add node-2, and so on and so forth. To add a new node we run the below command:

```bash
etcdctl --endpoints=${SRV1_IP}:2379 member add ${SRV2_NAME} --peer-urls=http://${SRV2_IP}:2380

```

It will return something like:

```bash

ETCD_NAME="pg-node-2"
ETCD_INITIAL_CLUSTER="pg-node-1=http://12.0.1.242:2380,pg-node-2=http://12.0.1.125:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://12.0.1.125:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"

```

We'll will use that information to change the new node configuration file:

```bash
echo "
# ETCD V3.5 Configuration file by Percona
# ${CONFIG_DIR}/etcd.yaml
name: ${SRV2_NAME}
data-dir: ${DATA_DIR_ETCD}
initial-cluster: 'pg-node-1=http://12.0.1.242:2380,pg-node-2=http://12.0.1.125:2380'
initial-cluster-token: '${ETCD_TOKEN}'
initial-cluster-state: 'existing'
listen-peer-urls: 'http://${SRV2_IP}:2380'
listen-client-urls: 'http://${SRV2_IP}:2379'
initial-advertise-peer-urls: 'http://${SRV2_IP}:2380'
advertise-client-urls: 'http://${SRV2_IP}:2379'
" | tee ${CONFIG_DIR}/etcd.yaml

```

Note that the variables `initial-cluster` and `initial-cluster-state` are the ones coming from the result of the `etcdctl member add` command. Also make sure to change the IP's accordingly to reflect your own setup. This file needs to be saved in the same path as the one in node-1: `${CONFIG_DIR}/etcd.yaml`.

We now need to configure `systemd`:

```bash

echo "
[Unit]
Description=etcd - highly-available key value store
Documentation=https://etcd.io/docs
Documentation=man:etcd
After=network.target
Wants=network-online.target

[Service]
Environment=DAEMON_ARGS=
Environment=ETCD_NAME=%H
Environment=DATA_DIR_ETCD=${DATA_DIR_ETCD}
EnvironmentFile=-${CONFIG_DIR}/%p
Type=notify
User=${PG_USER}
PermissionsStartOnly=true
ExecStart=${BIN_ETCD} --config-file ${CONFIG_DIR}/etcd.yaml
Restart=on-abnormal
#RestartSec=10s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
Alias=etcd2.service

" | sudo tee /etc/systemd/system/etcd.service

```

Also, reload, start the service, and check if running fine:

```bash

sudo systemctl daemon-reload
sudo systemctl enable --now etcd
systemctl status etcd
etcdctl --endpoints=${SRV1_IP}:2379 member list

```

Repeat this procedure for all the remaining nodes!

### Patroni

Before we start to create the configuration files we need to define some auxiliary variables:

```bash
NAMESPACE="percona_lab"
SCOPE="cluster_1"

SRV1_NAME='pg-node-1'
SRV2_NAME='pg-node-2'
SRV3_NAME='pg-node-3'

SRV1_IP='12.0.1.242'
SRV2_IP='12.0.1.125'
SRV3_IP='12.0.1.239'
```

Now, the configuration file:

```bash

echo "
namespace: ${NAMESPACE}
scope: ${SCOPE}
name: ${SRV1_NAME}

restapi:
    listen: 0.0.0.0:8008
    connect_address: ${SRV1_IP}:8008

etcd3:
    hosts: ${SRV1_IP}:2379,${SRV2_IP}:2379,${SRV3_IP}:2379

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
                hot_standby: 'on'
                wal_keep_size: 4096
                max_wal_senders: 5
                max_replication_slots: 10
                wal_log_hints: 'on'
                archive_mode: 'on'
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
    connect_address: ${SRV1_IP}:5432
    data_dir: ${DATA_DIR_PG}
    bin_dir: ${BIN_DIR_PG}
    pgpass: ${PGPASS}

    authentication:
        replication:
            username: replicator
            password: passRepl01
        superuser:
            username: postgres
            password: passPG99

    parameters:
        unix_socket_directories: '/tmp/'

    create_replica_methods:
        - basebackup

    basebackup:
        checkpoint: 'fast'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
" | tee ${CONFIG_DIR}/patroni.yaml

```

Make sure to change the IP's, names, and passwords to reflect your environment!

The next step is to create the `systemd` unity file:

```bash

echo "
[Unit]
Description=PostgreSQL high-availability manager
After=syslog.target network.target

[Service]
Type=simple

User=${PG_USER}
Group=${PG_USER}

EnvironmentFile=-${CONFIG_DIR}/patroni_env.conf
Environment=PATRONI_CONFIG_LOCATION=${CONFIG_DIR}/patroni.yaml

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000

# Start the patroni process
ExecStart=${BIN_PATRONI} \${PATRONI_CONFIG_LOCATION}

# Send HUP to reload from patroni.yml
ExecReload=/bin/kill -s HUP \$MAINPID

# Only kill the patroni process, not it's children, so it will gracefully stop postgres
KillMode=process

# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=30

# Restart the service if it crashed
Restart=on-failure

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/patroni.service

```

Time to reload the `systemd` and start the `Patroni` service.

```bash

sudo systemctl daemon-reload
sudo systemctl enable --now patroni
sudo journalctl -fu patroni

```

Repeat the process for all the remaining nodes always `making sure to change the IP's and names accordingly`!

We should now have a Patroni cluster running!
