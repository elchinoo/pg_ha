#!/bin/bash
# set -e

for i in `ls ./playbooks/ --ignore='group_vars'` 
do 
  ansible-playbook ./playbooks/$i; 
  RET=$?
  if [ $RET -ne 0 ] 
  then  
    echo "Error while executing file ${i} \n" >&2
    exit $RET
  fi
done
