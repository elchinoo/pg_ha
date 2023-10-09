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

provider "aws" {
  region = local.region
}

resource "aws_key_pair" "pg_ha-pkey" {
  key_name   = local.ssh_key_name
  public_key = local.ssh_pub_key_value

  tags = {
    PerconaCreatedBy = local.percona_user
  }
}

resource "aws_vpc" "pg_ha-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name             = local.vpc_name
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    PerconaCreatedBy = local.percona_user
  }
}

resource "aws_internet_gateway" "pg_ha-gw" {
  vpc_id = aws_vpc.pg_ha-vpc.id

  tags = {
    Name             = local.gw_name
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    PerconaCreatedBy = local.percona_user
  }
}

resource "aws_route_table" "pg_ha-router" {
  vpc_id = aws_vpc.pg_ha-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pg_ha-gw.id
  }

  tags = {
    Name             = local.router_name
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    PerconaCreatedBy = local.percona_user
  }
}


resource "aws_subnet" "pg_ha-priv_subnet" {
  vpc_id                  = aws_vpc.pg_ha-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = local.av-zone

  tags = {
    Name             = local.priv_subnet_name
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    PerconaCreatedBy = local.percona_user
  }
}

resource "aws_route_table_association" "pg_ha-priv_subnet-router" {
  subnet_id      = aws_subnet.pg_ha-priv_subnet.id
  route_table_id = aws_route_table.pg_ha-router.id
}

resource "aws_security_group" "pg_ha-sg" {
  name   = "pg_ha-sg"
  vpc_id = aws_vpc.pg_ha-vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "udp"
    self      = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_subnet.pg_ha-priv_subnet.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = local.sg_name
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    PerconaCreatedBy = local.percona_user
  }
}


############################### -- PostgreSQL pg_standby instances
resource "aws_ebs_volume" "pg_ha_node-vol" {
  type              = local.pg_vol_type
  size              = local.pg_vol_size
  availability_zone = local.av-zone

  tags = {
    Name             = "${local.pg_base_name}-${count.index + 1}-vol"
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    PerconaCreatedBy = local.percona_user
  }
  count = local.pg_num_nodes
}

resource "aws_instance" "pg_ha_node" {
  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  ami               = local.ami
  instance_type     = local.pg_instance_type
  subnet_id         = aws_subnet.pg_ha-priv_subnet.id
  key_name          = local.ssh_key_name
  availability_zone = local.av-zone

  tags = {
    Name             = "${local.pg_base_name}-${count.index + 1}"
    Product          = local.product
    Team             = local.team
    Owner            = local.owner
    Environment      = local.environment
    HostType         = local.host_type_db
    PerconaCreatedBy = local.percona_user
  }

  security_groups = [aws_security_group.pg_ha-sg.id]
  count           = local.pg_num_nodes

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname ${local.pg_base_name}-${count.index + 1}"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.ssh_priv_key_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.public_ip} | tee -a ~/.ssh/known_hosts | tee ./tmp/known_hosts"
  }
}

resource "aws_volume_attachment" "pg_ha_node-att" {
  device_name = local.pg_vol_device
  volume_id   = element(aws_ebs_volume.pg_ha_node-vol.*.id, count.index)
  instance_id = element(aws_instance.pg_ha_node.*.id, count.index)
  count       = local.pg_num_nodes

  # provisioner "local-exec" {
  #   command = "${local.ansible_cmd} -i ${element(aws_instance.pg_ha_node.*.public_ip, count.index)}, --private-key ${local.ssh_priv_key_path} ${local.ansible_secondary_playbook}"
  # }
}
############################### -- PostgreSQL pg_standby instances END

############################### Inventory and Host servers
resource "local_file" "ansible_inventory" {
  content = templatefile(
    "./templates/ansible_inventory.tpl",
    {
      # Secondary
      pg_db_pub_ip   = aws_instance.pg_ha_node.*.public_ip,
      pg_etcd_pub_ip = aws_instance.pg_ha_node.*.public_ip,
      ssh_user       = local.ssh_user,
    }
  )
  filename = "./inventory/inventory.yaml"
}


############################### Host servers END
