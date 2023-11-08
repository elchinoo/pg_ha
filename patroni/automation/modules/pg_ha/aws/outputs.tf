locals {
  lc_db_nodes = {
    for k, nip in aws_instance.pg_ha_node.*.public_ip : k => {
      ip       = nip
      update   = true
      ssh_user = var.ssh_user
    }
  }

  # I haven't found a function to concatenate 2 objects.
  # The function merge will replace the values for the objects with the same ID (literally merge them)
  #   and in this case we'll lose IP nodes if the user decides to use a combination of DB and DCS only nodes
  #   to run the DCS servers
  merged = concat(aws_instance.pg_ha_node.*.public_ip, aws_instance.dcs_ha_node.*.public_ip)
  lc_dcs_nodes = {
    for pkey, pval in local.merged : pkey => {
      ip       = pval
      update   = pkey < length(aws_instance.pg_ha_node.*.public_ip) ? false : true
      ssh_user = var.ssh_user
    }
  }

} # End locals


output "db_nodes" {
  value       = local.lc_db_nodes
  description = "List of PostgreSQL nodes public IPs"
}

output "dcs_nodes" {
  value       = local.lc_dcs_nodes
  description = "List of DCS nodes public IPs"
}

output "ssh_user" {
  value       = var.ssh_user
  description = "SSH username"
}

# pg_db_pub_ip   = aws_instance.pg_ha_node.*.public_ip,
# pg_etcd_pub_ip = var.dcs_use_pg_node ? aws_instance.pg_ha_node.*.public_ip : [],
# ssh_user       = var.ssh_user,