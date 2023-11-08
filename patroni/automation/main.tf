# Percona Distribution for PostgreSQL: High Availability with Streaming Replication
#   - (Percona Distribution for PostgreSQL-based deployment)
# @author: Charly Batista <charly.batista@percona.com>
# @date: 2023-10-05
# 

# main.tf 
#
# - Create VPC
# - Create Internet Gateway
# - Create Custom Route Table
# - Create Subnet
# - Associate the subnet with the route table
# - Create a Security Group (Ports 22, 5432 and 6432)
# - Provision extra EBS voumes to be used by the nodes
# - Create the nodes within the correct subnet to get an external IP
# - Associate the volumes to the nodes

terraform {
  required_version = ">= 1.1.0"
}

module "pg_ha" {
  source = "./modules/pg_ha/aws/"

  # AWS configuration block
  region = "us-west-2"
  zone   = "us-west-2c"
  ami    = "ami-03f65b8614a860c29"

  # Node block
  pg_num_nodes    = 2
  dcs_num_nodes   = 1
  dcs_use_pg_node = true
}

############################### Inventory and Host servers
resource "local_file" "ansible_inventory" {
  content = templatefile(
    "./templates/ansible_inventory.tpl",
    {
      # 
      pg_db_nodes   = module.pg_ha.db_nodes,
      pg_dcs_nodes = module.pg_ha.dcs_nodes,
    }
  )
  filename = "./inventory/inventory.yaml"
}


output "db_nodes_dbg" {
  value = module.pg_ha.db_nodes
}

output "dcs_nodes_dbg" {
  value = module.pg_ha.dcs_nodes
}

############################### Host servers END
