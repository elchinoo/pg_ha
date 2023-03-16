# Lab Repo: PostgreSQL High Availability

PostgreSQL is a powerful and *open-source* RDBMS that is widely used today, not only for startups but also large corporations. It is known for its scalability, reliability, and robustness, making it a popular choice for businesses of all sizes. 

However, some tasks are not as easy or trivial as they might look, for example, build a highly available Postgres environment. This is where this material comes handy, specially because learning PostgreSQL high availability is essential for anyone who needs to ensure the reliability and availability of their Postgre database, and who wants to scale their application and provide disaster recovery capabilities. By mastering these skills, one can improve performance and resilience of the application, and gain a competitive advantage in the marketplace.

One of the first problems is to choose between the many options in the market, because there are several Postgre HA solutions available, each with its own strengths and weaknesses. Here we'll test some of the most popular solutions and see how and where we may use them.

We'll start with Patroni, an open-source tool that automates PostgreSQL HA *using a distributed configuration store like ZooKeeper, etcd, Consul or Kubernetes*. It provides automated failover and recovery, and supports multiple nodes and clusters. We'll add pgBackRest to our setup, a tool that *aims to be a reliable, easy-to-use backup and restore solution that can seamlessly scale up to the largest databases and workloads by utilizing algorithms that are optimized for database-specific requirements*.

 - [Patroni: A Template for PostgreSQL HA with ZooKeeper, etcd or Consul](patroni)

I hope you enjoy the ride and learn something on the way!