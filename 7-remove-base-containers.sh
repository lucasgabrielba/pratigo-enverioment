#!/bin/bash

containerIDs="db-ms-budget db-api-gateway db-ms-house mb-ms-notifier db-ms-customer ms-notifier ms-sales-and-stock ms-notification ms-payment"

existContainer="Exist"
notExistContainer="None"
retryCount=3

function getContainerStatus(){
 containerExist=$(docker ps -a --format "{{.State}}" --filter name=$1) 
if [[ -z ${containerExist} ]]
  then
  echo "${notExistContainer}" 
else
  echo "${existContainer}"
fi
}

function stopContainer(){
 docker stop $1 &>/dev/null && docker rm -v $1 &>/dev/null && docker rmi $1 &>/dev/null
}

for containerID in ${containerIDs}
 do
 for ((i=1;i<=${retryCount};i++))
 do
  status=$(getContainerStatus ${containerID} )
  if [ "${status}" == ${notExistContainer} ]
  then
  echo "Container ${containerID} not existed"
  docker rmi $1 &>/dev/null
  else
   stopContainer ${containerID}
   echo "Container ${containerID} exist, remove container"
  break
  fi
 done
done

docker rmi postgres:11.5 &>/dev/null
docker rmi rabbitmq:3.9-management &>/dev/null

