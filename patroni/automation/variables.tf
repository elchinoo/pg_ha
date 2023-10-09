# Percona Distribution for PostgreSQL: High Availability with Streaming Replication
#   - (Percona Distribution for PostgreSQL-based deployment)
# @author: Charly Batista <charly.batista@percona.com>
# @date: 2023-10-05
# 

# variables.tf 
# Variables and configuration settings
# 
locals {
  environment = "Dev"
  region      = "us-west-2"
  av-zone     = "us-west-2c"
  ami         = "ami-03f65b8614a860c29"

  # Product
  product = "Percona Distribution for PostgreSQL: High Availability with Patroni and Streaming Replication"
  team    = "Tech Lead"
  owner   = "Charly El-Chinoo Batista"

  # Network
  vpc_name = "PGHA_vpc"
  gw_name  = "PGHA_gw"

  router_name      = "PGHA_router"
  priv_subnet_name = "PGHA_psnet"
  sg_name          = "PGHA_sg"

  # PostgreSQL instances
  pg_instance_type = "t2.small"
  pg_vol_type      = "gp2"
  pg_vol_size      = 64
  pg_vol_device    = "/dev/sdb"

  host_type_db = "PostgreSQL"
  pg_base_name = "PGHA-db"
  pg_num_nodes = 3

  # DCS instances
  host_type_dcs     = "DCS"
  dcs_instance_type = "t2.small"
  dcs_vol_type      = "gp2"
  dcs_vol_size      = 32
  dcs_vol_device    = "/dev/sdb"
  dcs_num_nodes     = 3

  dcs_node_name = "pg-dcs"


  # Ansible 
  ansible_cmd      = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook"
  ansible_params   = ""
  ansible_playbook = "pg_ha.yaml"

  # User and auth
  percona_user      = "charly.batista@percona.com"
  ssh_user          = "ubuntu"
  ssh_key_name      = "PGHA_W2_SSH_Key_AUTO"
  ssh_pub_key_value = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPftS5GQY8++kJZNMCK5Uzjz/2KDZOqAruLx5xS/wrCz"
  ssh_priv_key_path = "~/keys/aws/PGHA_W2_SSH_Key"
}