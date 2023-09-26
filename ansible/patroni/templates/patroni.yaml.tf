namespace: {{ patroni_namespace }}
scope: {{ patroni_scope }}
name: {{ inventory_hostname }}

restapi:
    listen: {{ patroni_rest_api_listen }}:8008
    connect_address: {{ ansible_default_ipv4.address }}:8008

etcd:
    host: {{ ansible_default_ipv4.address }}:2379

bootstrap:
    dcs:
        ttl: {{ patroni_dcs_ttl }}
        loop_wait: {{ patroni_dcs_loop_wait }}
        retry_timeout: {{ patroni_dcs_retry_timeout }}
        maximum_lag_on_failover: {{ patroni_dcs_max_lag_failover }}
        slots:
            {{ patroni_dcs_slot_name }}:
              type: {{ patroni_dcs_slot_type }}
        postgresql:
            use_pg_rewind: {{ pg_use_pg_rewind }}
            use_slots: {{ pg_use_slots }}
            parameters:
                listen_addresses: "{{ pg_listen_addr_cfg }}"
                port: {{ pg_listen_port }}
                max_connections: {{ pg_max_connections }}
                shared_buffers: {{ pg_shared_buffers }}
                work_mem: {{ pg_work_mem }}
                maintenance_work_mem: {{ pg_maintenance_work_mem }}
                wal_level: {{ pg_wal_level }}
                hot_standby: {{ pg_hot_standby }}
                synchronous_commit: {{ pg_synchronous_commit }}
                wal_compression: {{ pg_wal_compression }}
                checkpoint_timeout: {{ pg_checkpoint_timeout }}
                checkpoint_completion_target: {{ pg_checkpoint_completion_target }}
                min_wal_size: {{ pg_min_wal_size }}
                max_wal_size: {{ pg_max_wal_size }}
                # archive_mode: {{ pg_archive_mode }}
                # archive_library: {{ pg_archive_library }}
                # archive_command: {{ pg_archive_command }}
                wal_keep_size: {{ pg_wal_keep_size }}
                max_wal_senders: {{ pg_max_wal_senders }}
                max_replication_slots: {{ pg_max_replication_slots }}
                wal_log_hints: {{ pg_wal_log_hints }}
                archive_timeout: {{ pg_archive_timeout }}
                logging_collector: {{ pg_logging_collector }}

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
        {{ pg_admin_username }}:
            password: "{{ pg_admin_password }}"
            options:
                - createrole
                - createdb

postgresql:
    cluster_name: {{ pg_cluster_name }}
    listen: {{ pg_listen_addr }}:{{ pg_listen_port }}
    connect_address: {{ ansible_default_ipv4.address }}:{{ pg_listen_port }}
    data_dir: {{ pg_data_dir }}
    bin_dir: {{ pg_bin_dir }}
    pgpass: {{ pg_pass_file }}

    authentication:
        replication:
            username: "{{ pg_repl_username }}"
            password: "{{ pg_repl_password }}"
        superuser:
            username: "{{ pg_super_username }}"
            password: "{{ pg_super_password }}"

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