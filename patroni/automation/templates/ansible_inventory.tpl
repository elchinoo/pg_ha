db_server:
  hosts:
%{ for index, host in pg_db_pub_ip ~}    
    node-${index + 1}:
      ansible_host: ${host}
      ansible_user: ${ssh_user}
%{ endfor ~}

etcd_server:
  hosts:
%{ for index, host in pg_etcd_pub_ip ~}    
    node-${index + 1}:
      ansible_host: ${host}
      ansible_user: ${ssh_user}
%{ endfor ~}