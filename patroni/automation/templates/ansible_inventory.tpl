db_server:
  hosts:
%{ for index, host in pg_db_nodes ~}    
    node-${index + 1}:
      ansible_host: ${host.ip}
      ansible_user: ${host.ssh_user}
      update_name: ${host.update}
%{ endfor ~}

etcd_server:
  hosts:
%{ for index, host in pg_dcs_nodes ~}    
    node-${index + 1}:
      ansible_host: ${host.ip}
      ansible_user: ${host.ssh_user}
      update_name: ${host.update}
%{ endfor ~}