############################### -- PostgreSQL instances
resource "aws_ebs_volume" "dcs_ha_node-vol" {
  type              = var.dcs_vol_type
  size              = var.dcs_vol_size
  availability_zone = var.zone

  tags = {
    Name             = "${var.dcs_base_name}-${count.index + 1}-vol"
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    PerconaCreatedBy = var.percona_user
  }

  count = var.dcs_num_nodes
}

resource "aws_instance" "dcs_ha_node" {
  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  ami               = var.ami
  instance_type     = var.dcs_instance_type
  subnet_id         = aws_subnet.pg_ha-priv_subnet.id
  key_name          = var.ssh_key_name
  availability_zone = var.zone

  tags = {
    Name             = "${var.dcs_base_name}-${count.index + 1}"
    Product          = var.product
    Team             = var.team
    Owner            = var.owner
    Environment      = var.environment
    HostType         = var.host_type_db
    PerconaCreatedBy = var.percona_user
  }

  security_groups = [aws_security_group.pg_ha-sg.id]

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname ${var.dcs_base_name}-${count.index + 1}"]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_priv_key_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.public_ip} | tee -a ~/.ssh/known_hosts | tee ./tmp/known_hosts"
  }

  depends_on = [aws_security_group.pg_ha-sg]
  count      = var.dcs_num_nodes
}

resource "aws_volume_attachment" "dcs_ha_node-att" {
  device_name = var.dcs_vol_device
  volume_id   = element(aws_ebs_volume.dcs_ha_node-vol.*.id, count.index)
  instance_id = element(aws_instance.dcs_ha_node.*.id, count.index)
  count       = var.dcs_num_nodes
}
############################### -- PostgreSQL instances END