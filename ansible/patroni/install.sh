#!/bin/bash

ansible-playbook -l db_server ./01-hostname.yaml
RET=$?
if [ $RET -ne 0 ] 
then  
  echo "Error while executing 01-hostname.yaml" >&2
  return $RET
fi

ansible-playbook -l db_server ./02-percona_add_repo.yaml
RET=$?
if [ $RET -ne 0 ] 
then  
  echo "Error while executing 02-percona_add_repo.yaml" >&2
  return $RET
fi

ansible-playbook -l db_server ./03-packages_install.yaml
RET=$?
if [ $RET -ne 0 ] 
then  
  echo "Error while executing 03-packages_install.yaml" >&2
  return $RET
fi

ansible-playbook -l db_server ./04-etcd_setup.yaml
RET=$?
if [ $RET -ne 0 ] 
then  
  echo "Error while executing 04-etcd_setup.yaml" >&2
  return $RET
fi

ansible-playbook -l db_server ./05-patroni_setup.yaml
RET=$?
if [ $RET -ne 0 ] 
then  
  echo "Error while executing 05-patroni_setup.yaml" >&2
  return $RET
fi