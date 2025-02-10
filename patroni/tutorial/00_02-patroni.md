# Patroni: High Availability for PostgreSQL

Patroni is an open-source tool designed to manage and automate the high availability (HA) of PostgreSQL clusters. It ensures that your PostgreSQL database remains available even in the event of hardware failures, network issues, or other disruptions. Patroni achieves this by leveraging distributed consensus systems like ETCD, Consul, or ZooKeeper to manage cluster state and automate failover processes. We'll use ETCD in our Architecture.

Patroni is particularly useful for:
 - Automating failover and promoting a new primary in case of a failure;
 - Preventing split-brain scenarios (where two nodes believe they are the primary);
 - Simplifying the management of PostgreSQL clusters across multiple data centers;
 - Integrating with tools like pgBackRest, HAProxy, and monitoring systems for a complete HA solution.

Patroni operates by coordinating the state of a PostgreSQL cluster using a distributed consensus store (e.g., etcd, Consul, or ZooKeeper). Here's how it works:
    
 - Cluster State Management:
    - When the user installs and configure Patroni it will take over the PostgreSQL service administration and configuration;
    - Patroni uses a distributed consensus store to maintain the state of the PostgreSQL cluster (e.g., PostgreSQL configuration, which node is the primary, which are replicas, and their health status).
    - Each node in the cluster runs a Patroni agent that communicates with the consensus store and other nodes.

 - Leader Election:
    - When the cluster is initialized Patroni initiates a leader election process;
    - When the primary node fails, Patroni initiates a leader election process;
    - When the old Primary is recovered and rejoin the cluster it is added as a new replica;
    - Whenever a new node is added to the cluster it joins as a new replica;
    - The consensus store ensures that only one node is elected as the new primary, preventing split-brain scenarios.

 - Automatic Failover:
    - If the primary node becomes unavailable, Patroni initiates a leader election process with the most up-to-date replicas;
    - When a node is ellected it is automatically promoted to primary;
    - It updates the consensus store and reconfigures the remaining replicas to follow the new primary.

 - Health Checks:
    - Patroni continuously monitors the health of all the PostgreSQL instances;
    - If a node fails or becomes unreachable, Patroni takes corrective actions (e.g., restarting PostgreSQL or initiating a failover process).

 - Configuration Management:
        Patroni manages PostgreSQL configuration files (e.g., postgresql.conf and pg_hba.conf) dynamically, ensuring consistency across the cluster.

## How Patroni Improves High Availability

Patroni enhances PostgreSQL high availability by:

 - Automating Failover: Reduces downtime by automatically promoting a replica to primary when the current primary fails.
 - Preventing Split-Brain: Uses a distributed consensus store to ensure only one primary exists at any time.
 - Self-Healing: Automatically restarts failed PostgreSQL instances or reinitializes broken replicas.
 - Cross-Datacenter Support: Manages clusters across multiple data centers, ensuring continuity even during regional outages.


### Preventing Split-Brain

Split-brain is one of the most feared issues among clustered database users, and it occurs when two or more nodes believe they are the primary, leading to data inconsistencies. Patroni prevents split-brain by using a Distributed Consensus Store. The consensus store ensures that only one node can acquire the leader lock and become the primary. The primary node holds a leader lock in the consensus store. If the lock is lost (e.g., due to network partitioning), the node demotes itself to a replica.

One important aspect of how Patroni works is that it requires a quorum of nodes to agree on the cluster state, preventing isolated nodes from becoming primary, hence strengthening its capabilities of preventing split brain. 

## Watchdog

Patroni can use a watchdog mechanism to improve resilience. But what is watchdog?

A watchdog is a mechanism that ensures a system can recover from critical failures. In the context of Patroni, a watchdog is used to forcibly restart the node and terminating a failed primary node to prevent split-brain scenarios.

There are 2 types of Watchdogs:

 - Hardware Watchdog: A physical device that reboots the server if the operating system becomes unresponsive.
 - Software Watchdog: A software-based mechanism that monitors the system and takes corrective actions (e.g., killing processes or rebooting the node).

Most of the servers in the cloud nowadays use a software watchdog.

### Why Use a Watchdog with Patroni?

While Patroni itself is designed for high availability, a watchdog provides an extra layer of protection against system-level failures that Patroni might not be able to detect, such as kernel panics or hardware lockups.  If the entire operating system becomes unresponsive, Patroni might not be able to function correctly.  The watchdog, operating independently, can detect this and reset the server, bringing it back to a known good state.

Last, but not least, it adds an extra layer of safety, because it helps protecting against scenarios where the consensus store is unavailable or network partitions occur.

## Integrating with Other Tools and Extending Patroni

Patroni integrates well with many other tools to create a comprehensive high-availability solution, like HAProxy to help to load balance directing traffic to both the primary and replica nodes, pgBackRest to helpto ensure robust backup and restore, PMM for monitoring, and other.

Patroni provides hooks that allow you to customize its behavior. One can use hooks to execute custom scripts or commands at various stages of the Patroni lifecycle, such as before and after failover, or when a new instance joins the cluster. This allows the user to integrate Patroni with other systems and automate various tasks. For example, one might use a hook to update the monitoring system when a failover occurs.