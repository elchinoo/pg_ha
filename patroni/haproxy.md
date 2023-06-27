# Patroni: Configuring HAProxy

We start here installing HAProxy:

```bash
sudo apt install -y haproxy

```

Configure the hostnames and the host file:

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
```

We then need to change the SystemD configuration like we did for ETCD and Patroni

```bash
# We copy the unit file to the personalized unit files folder, this way we don't risk to have our changes overwritten when updating our services
sudo cp /usr/lib/systemd/system/haproxy.service /etc/systemd/system/

# We change the path to the configuration file
sudo sed -i 's|^Environment="CONFIG=/etc/haproxy/haproxy.cfg"|Environment="CONFIG=/pg_ha/config/haproxy.conf"|g' /etc/systemd/system/haproxy.service

# We reload the SystemD configuration
sudo systemctl daemon-reload
```

Create our directory tree:

```bash
#####
# I will create the following tree on my root directory to store our setup:
#   /pg_ha
#       |- config
#           |- haproxy.conf
#           |- <...>
#####
sudo mkdir -p /pg_ha/config
```

And then the configuration file:

```bash
echo "
global
    maxconn 100

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
# listen HAProxy-Statistics *:8182
    option httplog
    stats uri /haproxy?stats
    stats refresh 20s
    stats realm PSQL Haproxy\ Statistics  # Title text for popup window
    stats show-node
    stats show-legends
    stats show-desc PSQL load balancer stats (master)
    stats auth pgadmin:Perc0naP4ss


listen primary
    bind *:5000
    option httpchk /primary
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node1 lab-node1:6432 maxconn 100 check port 8008
    server node2 lab-node2:6432 maxconn 100 check port 8008
    server node3 lab-node3:6432 maxconn 100 check port 8008

listen standbys
    balance roundrobin
    bind *:5001
    option httpchk /replica
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node1 lab-node1:6432 maxconn 100 check port 8008
    server node2 lab-node2:6432 maxconn 100 check port 8008
    server node3 lab-node3:6432 maxconn 100 check port 8008
" | tee -a /pg_ha/config/haproxy.conf
```

And now we start the service:

```bash
# Enable and start the service
sudo systemctl enable --now haproxy

# Check if the service is running
systemctl status haproxy

# We should see something like:
# root@node-1:~# systemctl status haproxy
# ● haproxy.service - HAProxy Load Balancer
#      Loaded: loaded (/etc/systemd/system/haproxy.service; enabled; vendor preset: enabled)
#      Active: active (running) since Tue 2023-06-27 15:12:40 UTC; 10min ago
#        Docs: man:haproxy(1)
#              file:/usr/share/doc/haproxy/configuration.txt.gz
#    Main PID: 1791 (haproxy)
#       Tasks: 2 (limit: 2349)
#      Memory: 71.1M
#         CPU: 99ms
#      CGroup: /system.slice/haproxy.service
#              ├─1791 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /run/haproxy-master.sock
#              └─1793 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -S /run/haproxy-master.sock
# 
# Jun 27 15:12:40 ip-10-0-100-30 systemd[1]: Starting HAProxy Load Balancer...

```

If you got here following all ETCD, Patroni, and HAProxy you have now a fully functional Postgres+Patroni cluster with HAProxy in front of it, capable of send all incoming connections on the port 5000 to the primary and connections on the port 5001 to the replicas. It will also check with Patroni to be able to find who is the primary and replicas, and act in case of a Patroni failover.

There are still improvements on HAProxy side, for example, create other HAProxy nodes and have it highly available as well because it became, at this point, as a single point of failure, but this will be done in a next session!

[<<- Back to Patroni index](/patroni)