# {{ etcd_register }}
ETCD_INITIAL_CLUSTER_TOKEN="{{ etcd_token }}"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://{{ ansible_default_ipv4.address }}:2380"
ETCD_DATA_DIR="{{ etcd_data_dir }}"
ETCD_LISTEN_PEER_URLS="http://{{ ansible_default_ipv4.address }}:2380"
ETCD_LISTEN_CLIENT_URLS="http://{{ ansible_default_ipv4.address }}:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://{{ ansible_default_ipv4.address }}:2379"