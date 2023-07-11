# Patroni: Configuring pgbackrest


## Backup server

```bash
# Install and enable the REPO
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb

percona-release enable-only ppg-15
apt-get update

# Upgrade and install needed packages
apt-get upgrade -y
apt install -y vim wget screen


# Install pgbackrest
apt install -y percona-pgbackrest

# Create the folders
mkdir -p /pg_ha/{config,certs}

# Auxiliary vars
export SRV_NAME="bkp-srv"
export NODE1_NAME="node-1"
export NODE2_NAME="node-2"
export NODE3_NAME="node-3"

# Create the configuration file
echo "
# /etc/pgbackrest.conf

[global]

# Server repo details
repo1-path=/pg_ha/pgbackrest

### Retention ###
#  - repo1-retention-archive-type
#  - If set to full pgBackRest will keep archive logs for the number of full backups defined by repo-retention-archive
repo1-retention-archive-type=full

# repo1-retention-archive
#  - Number of backups worth of continuous WAL to retain
#  - NOTE: WAL segments required to make a backup consistent are always retained until the backup is expired regardless of how this option is configured
#  - If this value is not set and repo-retention-full-type is count (default), then the archive to expire will default to the repo-retention-full
# repo1-retention-archive=2

# repo1-retention-full
#  - Full backup retention count/time.
#  - When a full backup expires, all differential and incremental backups associated with the full backup will also expire. 
#  - When the option is not defined a warning will be issued. 
#  - If indefinite retention is desired then set the option to the max value. 
repo1-retention-full=4

# Server general options
process-max=12
log-level-console=info
#log-level-file=debug
log-level-file=info
start-fast=y
delta=y
backup-standby=y

########## Server TLS options ##########
tls-server-address=*
tls-server-cert-file=/pg_ha/certs/${SRV_NAME}.crt
tls-server-key-file=/pg_ha/certs/${SRV_NAME}.key
tls-server-ca-file=/pg_ha/certs/ca.crt

### Auth entry ###
tls-server-auth=${NODE1_NAME}=cluster_1
tls-server-auth=${NODE2_NAME}=cluster_1
tls-server-auth=${NODE3_NAME}=cluster_1

### Clusters and nodes ###
[cluster_1]
pg1-host=${NODE1_NAME}
pg1-host-port=8432
pg1-port=5432
pg1-path=/pg_ha/data/postgres/15/
pg1-host-type=tls
pg1-host-cert-file=/pg_ha/certs/${SRV_NAME}.crt
pg1-host-key-file=/pg_ha/certs/${SRV_NAME}.key
pg1-host-ca-file=/pg_ha/certs/ca.crt
pg1-socket-path=/var/run/postgresql


pg2-host=${NODE2_NAME}
pg2-host-port=8432
pg2-port=5432
pg2-path=/pg_ha/data/postgres/15/
pg2-host-type=tls
pg2-host-cert-file=/pg_ha/certs/${SRV_NAME}.crt
pg2-host-key-file=/pg_ha/certs/${SRV_NAME}.key
pg2-host-ca-file=/pg_ha/certs/ca.crt
pg2-socket-path=/var/run/postgresql

pg3-host=${NODE3_NAME}
pg3-host-port=8432
pg3-port=5432
pg3-path=/pg_ha/data/postgres/15/
pg3-host-type=tls
pg3-host-cert-file=/pg_ha/certs/${SRV_NAME}.crt
pg3-host-key-file=/pg_ha/certs/${SRV_NAME}.key
pg3-host-ca-file=/pg_ha/certs/ca.crt
pg3-socket-path=/var/run/postgresql

" | sudo tee /pg_ha/config/pgbackrest.conf

mv /etc/pgbackrest.conf  /etc/pgbackrest.conf.orig
ln -vis /pg_ha/config/pgbackrest.conf /etc/


## Create systemd unity file
echo "
# /etc/systemd/system/pgbackrest.service
[Unit]
Description=pgBackRest Server
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=postgres
Restart=always
RestartSec=1
ExecStart=/usr/bin/pgbackrest server
#ExecStartPost=/bin/sleep 3
#ExecStartPost=/bin/bash -c "[ ! -z $MAINPID ]"
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
"|  sudo tee /etc/systemd/system/pgbackrest.service


## Change folder owner of the folder /pg_ha
chown -R postgres: /pg_ha

## Create the certificate files
### We define the path
export CA_PATH="/pg_ha/certs"

### We firstly create the CA certificates and keys
sudo -iu postgres openssl req -new -x509 -days 365 -nodes -out ${CA_PATH}/ca.crt -keyout ${CA_PATH}/ca.key -subj "/CN=root-ca"

### Create the certificate for the backup server
sudo -iu postgres openssl req -new -nodes -out ${CA_PATH}/${SRV_NAME}.csr -keyout ${CA_PATH}/${SRV_NAME}.key -subj "/CN=${SRV_NAME}"

### We'll create one certificate for database node
sudo -iu postgres openssl req -new -nodes -out ${CA_PATH}/${NODE1_NAME}.csr -keyout ${CA_PATH}/${NODE1_NAME}.key -subj "/CN=${NODE1_NAME}"
sudo -iu postgres openssl req -new -nodes -out ${CA_PATH}/${NODE2_NAME}.csr -keyout ${CA_PATH}/${NODE2_NAME}.key -subj "/CN=${NODE2_NAME}"
sudo -iu postgres openssl req -new -nodes -out ${CA_PATH}/${NODE3_NAME}.csr -keyout ${CA_PATH}/${NODE3_NAME}.key -subj "/CN=${NODE3_NAME}"

### Now we sign all certificates with the "root-ca" key
sudo -iu postgres openssl x509 -req -in ${CA_PATH}/${SRV_NAME}.csr -days 365 -CA ${CA_PATH}/ca.crt -CAkey ${CA_PATH}/ca.key -CAcreateserial -out ${CA_PATH}/${SRV_NAME}.crt
sudo -iu postgres openssl x509 -req -in ${CA_PATH}/${NODE1_NAME}.csr -days 365 -CA ${CA_PATH}/ca.crt -CAkey ${CA_PATH}/ca.key -CAcreateserial -out ${CA_PATH}/${NODE1_NAME}.crt
sudo -iu postgres openssl x509 -req -in ${CA_PATH}/${NODE2_NAME}.csr -days 365 -CA ${CA_PATH}/ca.crt -CAkey ${CA_PATH}/ca.key -CAcreateserial -out ${CA_PATH}/${NODE2_NAME}.crt
sudo -iu postgres openssl x509 -req -in ${CA_PATH}/${NODE3_NAME}.csr -days 365 -CA ${CA_PATH}/ca.crt -CAkey ${CA_PATH}/ca.key -CAcreateserial -out ${CA_PATH}/${NODE3_NAME}.crt

### Remove temporary files
rm ${CA_PATH}/*.csr

# Reload, enable, and start the service
sudo systemctl daemon-reload
sudo systemctl enable --now pgbackrest

```

## Database servers
```bash
# Install pgbackrest
apt install -y percona-pgbackrest

# Create the cert folders
mkdir -p /pg_ha/certs

# Create the configuration file
export NODE_NAME=`hostname -f`
echo "
# /etc/pgbackrest.conf
[global]
repo1-host=bkp-srv
repo1-host-user=postgres
repo1-host-type=tls
repo1-host-cert-file=/pg_ha/certs/${NODE_NAME}.crt
repo1-host-key-file=/pg_ha/certs/${NODE_NAME}.key
repo1-host-ca-file=/pg_ha/certs/ca.crt

# general options
process-max=16
log-level-console=info
log-level-file=debug

# tls server options
tls-server-address=*
tls-server-cert-file=/pg_ha/certs/${NODE_NAME}.crt
tls-server-key-file=/pg_ha/certs/${NODE_NAME}.key
tls-server-ca-file=/pg_ha/certs/ca.crt
tls-server-auth=bkp-srv=cluster_1

[cluster_1]
pg1-path=/pg_ha/data/postgres/15
" | sudo tee /pg_ha/config/pgbackrest.conf

mv /etc/pgbackrest.conf  /etc/pgbackrest.conf.orig
ln -vis /pg_ha/config/pgbackrest.conf /etc/


## Create systemd unity file
echo "
# /etc/systemd/system/pgbackrest.service
[Unit]
Description=pgBackRest Server
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=postgres
Restart=always
RestartSec=1
ExecStart=/usr/bin/pgbackrest server
#ExecStartPost=/bin/sleep 3
#ExecStartPost=/bin/bash -c "[ ! -z $MAINPID ]"
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
"|  sudo tee /etc/systemd/system/pgbackrest.service

# Reload, enable, and start the service
sudo systemctl daemon-reload
sudo systemctl enable --now pgbackrest

#### Change Postgres configuration on Patroni to use pgbackrest ####
## This only need to be done in one of the nodes

patronictl -c /pg_ha/config/patroni.yaml edit-config

## Change the content to:
loop_wait: 10
maximum_lag_on_failover: 1048576
postgresql:
  parameters:
    archive_command: pgbackrest --stanza=cluster_1 archive-push "/pg_ha/data/postgres/15/pg_wal/%f"
    archive_mode: true
    archive_timeout: 1800s
    hot_standby: true
    logging_collector: 'on'
    max_replication_slots: 10
    max_wal_senders: 5
    wal_keep_size: 4096
    wal_level: logical
    wal_log_hints: true
  recovery_conf:
    recovery_target_timeline: latest
    restore_command: pgbackrest --config=/etc/pgbackrest.conf --stanza=cluster_1 archive-get %f "%p"
  use_pg_rewind: true
  use_slots: true
retry_timeout: 10
slots:
  percona_cluster_1:
    type: physical
ttl: 30

## Create the stanzas and backups from the **BACKUP SERVER**
sudo -iu postgres pgbackrest --stanza=cluster_1 stanza-create

## Create a backup full
sudo -iu postgres pgbackrest --stanza=cluster_1 --type=full backup

## Create an incremental backup
sudo -iu postgres pgbackrest --stanza=cluster_1 --type=incr backup

## Check backup info
sudo -iu postgres pgbackrest --stanza=cluster_1 info

## Expire (remove) a backup. Careful because if remove a backup full it will remove all dependent incremental backups 
sudo -iu postgres pgbackrest --stanza=cluster_1 expire --set=20230617-021338F


```


[<<- Back to Patroni index](/patroni)