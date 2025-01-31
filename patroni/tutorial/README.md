# PostgreSQL High Availability

Ensuring high availability (HA) for PostgreSQL is crucial for maintaining uptime, minimizing disruptions, and preventing data loss. In this tutorial, we will build a highly available PostgreSQL cluster using a combination of open-source tools that work together to provide automated failover, load balancing, and disaster recovery.

## Architecture Overview

Our HA setup consists of multiple components, each playing a critical role in ensuring PostgreSQL remains available even in the event of failures:

 - [etcd – Acts as a distributed key-value store for leader election and cluster state coordination](00_01-etcd.md)
 - [Patroni – Manages PostgreSQL replication and automates failover](00_02-patroni.md)
 - [HAProxy – Load balances database connections, ensuring applications always connect to the primary PostgreSQL instance](00_03-haproxy.md)
 - [Keepalived – Provides a virtual IP (VIP) to make HAProxy highly available, preventing a single point of failure](00_04-keepalived.md)
 - [pgBackRest – Handles backups and restores, ensuring data integrity and disaster recovery](00_05-pgbackrest.md)

![PostgreSQL minimalist HA Architecture with Patroni](../..//images/Postgresql-Minimalist_HA.jpg "PostgreSQL minimalist HA Architecture with Patroni").

## Table of Contents

Throughout this tutorial, we will guide you step by step in deploying this architecture, covering installation, configuration, and best practices for each component. By the end, you will have a resilient PostgreSQL cluster capable of automated failover, load balancing, and disaster recovery.

 - [x] [Initial node setup and install the Repo](01-initial_setup.md)
 - [x] [Configure ETCD](02-etcd.md)
 - [x] [Configure Patroni and PostgreSQL](03-patroni.md)
 - [x] [Configure HAProxy](04-haproxy.md)
 - [x] [Configure pgBackRest](05-pgbackrest.md)
 - Configure connection pooler
    - [ ] [pgbouncer](06-pgbouncer.md)
    - [ ] [pgpool](07-pgpool.md)
    - [ ] [pgagroal](08-pgagroal.md)
 - [ ] [Creating a Standby Cluster](09-standby.md)

-----------------------------------------------------------------------------------------------------------------------------------------

Note that we are using Ubuntu 22 and the Percona Distribution for PostgreSQL 15 in this tutorial but if you want to use the [upstream PGDG packages[2]](https://www.postgresql.org/) you just need to change the package following what is in [PGDG website here[3]](https://www.postgresql.org/download/linux/ubuntu/). We can find the full documentation in about Percona Distribution for Postgres in [Percona's documentation here[4]](https://docs.percona.com/postgresql/15/index.html) including instructions to install in other Linux distros like RedHat.


## References

[1] https://github.com/zalando/patroni

[2] https://www.postgresql.org/

[3] https://www.postgresql.org/download/linux/ubuntu/

[4] https://docs.percona.com/postgresql/15/index.html
