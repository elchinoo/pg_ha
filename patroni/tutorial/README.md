# Patroni: A Template for PostgreSQL HA with ZooKeeper, etcd or Consul

According to its [Github repo[1]](https://github.com/zalando/patroni) Patroni is a template for you to create your own customized, high-availability solution using Python and - for maximum accessibility - a distributed configuration store like ZooKeeper, etcd, Consul or Kubernetes. Database engineers, DBAs, DevOps engineers, and SREs who are looking to quickly deploy HA PostgreSQL in the datacenter-or anywhere else-will hopefully find it useful.

Here we'll use Ubuntu 22 and the PostgreSQL 15 provided by Percona for simplicity. We can find the full documentation in their [website here[2]](https://docs.percona.com/postgresql/15/index.html) including instructions to install in other Linux distros like RedHat.

This tutorial will be divided into below steps:
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


## References

[1] https://github.com/zalando/patroni

[2] https://docs.percona.com/postgresql/15/index.html
