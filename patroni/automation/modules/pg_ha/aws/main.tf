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
  region = var.region
}

resource "aws_key_pair" "pg_ha-pkey" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_pub_key_value

  tags = {
    PerconaCreatedBy = var.percona_user
  }
}

resource "aws_vpc" "pg_ha-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name             = var.vpc_name
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    PerconaCreatedBy = var.percona_user
  }
}

resource "aws_internet_gateway" "pg_ha-gw" {
  vpc_id     = aws_vpc.pg_ha-vpc.id
  depends_on = [aws_vpc.pg_ha-vpc]

  tags = {
    Name             = var.gw_name
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    PerconaCreatedBy = var.percona_user
  }
}

resource "aws_route_table" "pg_ha-router" {
  vpc_id     = aws_vpc.pg_ha-vpc.id
  depends_on = [aws_internet_gateway.pg_ha-gw]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pg_ha-gw.id
  }

  tags = {
    Name             = var.router_name
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    PerconaCreatedBy = var.percona_user
  }
}

resource "aws_subnet" "pg_ha-priv_subnet" {
  vpc_id                  = aws_vpc.pg_ha-vpc.id
  depends_on              = [aws_route_table.pg_ha-router]
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.zone

  tags = {
    Name             = var.priv_subnet_name
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    PerconaCreatedBy = var.percona_user
  }
}

resource "aws_route_table_association" "pg_ha-priv_subnet-router" {
  subnet_id      = aws_subnet.pg_ha-priv_subnet.id
  depends_on     = [aws_subnet.pg_ha-priv_subnet]
  route_table_id = aws_route_table.pg_ha-router.id
}

resource "aws_security_group" "pg_ha-sg" {
  name       = "pg_ha-sg"
  vpc_id     = aws_vpc.pg_ha-vpc.id
  depends_on = [aws_route_table_association.pg_ha-priv_subnet-router]

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
    Name             = var.sg_name
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    PerconaCreatedBy = var.percona_user
  }
}

