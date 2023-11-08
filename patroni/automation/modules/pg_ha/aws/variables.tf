# Percona Distribution for PostgreSQL: High Availability with Streaming Replication
#   - (Percona Distribution for PostgreSQL-based deployment)
# @author: Charly Batista <charly.batista@percona.com>
# @date: 2023-10-05
# 

# variables.tf 
# Variables and configuration settings
# 

variable "environment" {
  description = ""
  type        = string
  default     = "Dev"
}

variable "region" {
  description = ""
  type        = string
  default     = "us-west-2"
}

variable "zone" {
  description = ""
  type        = string
  default     = "us-west-2c"
}

variable "ami" {
  description = ""
  type        = string
  default     = "ami-03f65b8614a860c29"
}


# Product
variable "product" {
  description = ""
  type        = string
  default     = "Percona Distribution for PostgreSQL: High Availability with Patroni and Streaming Replication"
}

variable "team" {
  description = ""
  type        = string
  default     = "Tech Lead"
}

variable "owner" {
  description = ""
  type        = string
  default     = "Charly El-Chinoo Batista"
}


# Network
variable "vpc_name" {
  description = ""
  type        = string
  default     = "PGHA_vpc"
}

variable "gw_name" {
  description = ""
  type        = string
  default     = "PGHA_gw"
}

variable "router_name" {
  description = ""
  type        = string
  default     = "PGHA_router"
}

variable "priv_subnet_name" {
  description = ""
  type        = string
  default     = "PGHA_psnet"
}

variable "sg_name" {
  description = ""
  type        = string
  default     = "PGHA_sg"
}

# PostgreSQL instances
variable "pg_instance_type" {
  description = ""
  type        = string
  default     = "t2.small"
}

variable "pg_vol_type" {
  description = ""
  type        = string
  default     = "gp2"
}

variable "pg_vol_size" {
  description = ""
  type        = number
  default     = 64
}

variable "pg_vol_device" {
  description = ""
  type        = string
  default     = "/dev/sdf"
}

variable "host_type_db" {
  description = ""
  type        = string
  default     = "PostgreSQL"
}

variable "pg_base_name" {
  description = ""
  type        = string
  default     = "PGHA-db"
}

variable "pg_num_nodes" {
  description = ""
  type        = number
  default     = 3
}


# DCS instances
variable "dcs_instance_type" {
  description = ""
  type        = string
  default     = "t2.small"
}

variable "dcs_vol_type" {
  description = ""
  type        = string
  default     = "gp2"
}

variable "dcs_vol_size" {
  description = ""
  type        = number
  default     = 32
}

variable "dcs_vol_device" {
  description = ""
  type        = string
  default     = "/dev/sdf" # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html#available-ec2-device-names
}

variable "dcs_base_name" {
  description = ""
  type        = string
  default     = "PGHA-dcs"
}

variable "dcs_num_nodes" {
  description = ""
  type        = number
  default     = 0
}

variable "dcs_use_pg_node" {
  description = ""
  type        = bool
  default     = true
}

# HAProxy instances
variable "prx_instance_type" {
  description = ""
  type        = string
  default     = "t2.small"
}

variable "prx_base_name" {
  description = ""
  type        = string
  default     = "PGHA-prx"
}

variable "prx_num_nodes" {
  description = ""
  type        = number
  default     = 1
}

# pgbackrest instances
variable "bkp_instance_type" {
  description = ""
  type        = string
  default     = "t2.small"
}

variable "bkp_vol_type" {
  description = ""
  type        = string
  default     = "gp2"
}

variable "bkp_vol_size" {
  description = ""
  type        = number
  default     = 300
}

variable "bkp_vol_device" {
  description = ""
  type        = string
  default     = "/dev/sdf"
}

variable "bkp_base_name" {
  description = ""
  type        = string
  default     = "PGHA-bkp"
}

variable "bkp_num_nodes" {
  description = ""
  type        = number
  default     = 2
}

# PMM instances
variable "pmm_instance_type" {
  description = ""
  type        = string
  default     = "t2.small"
}

variable "pmm_vol_type" {
  description = ""
  type        = string
  default     = "gp2"
}

variable "pmm_vol_size" {
  description = ""
  type        = number
  default     = 300
}

variable "pmm_vol_device" {
  description = ""
  type        = string
  default     = "/dev/sdf"
}

variable "pmm_base_name" {
  description = ""
  type        = string
  default     = "PGHA-pmm"
}

variable "pmm_num_nodes" {
  description = ""
  type        = number
  default     = 0
}

### Ansible ###
variable "ansible_cmd" {
  description = ""
  type        = string
  default     = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook"
}

variable "ansible_params" {
  description = ""
  type        = string
  default     = ""
}

variable "ansible_playbook" {
  description = ""
  type        = string
  default     = "pg_ha.yaml"
}

### User and auth ###
variable "percona_user" {
  description = ""
  type        = string
  default     = "charly.batista@percona.com"
}

variable "ssh_user" {
  description = ""
  type        = string
  default     = "ubuntu"
}

variable "ssh_key_name" {
  description = ""
  type        = string
  default     = "PGHA_W2_SSH_Key_AUTO"
}

variable "ssh_pub_key_value" {
  description = ""
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINAY1h4DXe9W+L/bkK+O0FC/Hy7thkJKfX9YCTIGoXfp PGHA_W2_SSH_Key_AUTO"
}

variable "ssh_priv_key_path" {
  description = ""
  type        = string
  default     = "~/keys/aws/PGHA_W2_SSH_Key_AUTO"
}

