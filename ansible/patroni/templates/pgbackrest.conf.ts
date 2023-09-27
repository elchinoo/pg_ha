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