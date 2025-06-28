#!/bin/bash

containerIDs="db-ms-budget db-api-gateway db-ms-house mb-ms-notifier ms-customer ms-notifier ms-sales-and-stock ms-notification ms-payment"

statusLived="live"
statusdead="exited"
notExistContainer="None"
retryCount=3

function getContainerStatus(){
 containerExist=$(docker ps -a --format "{{.State}}" --filter name=$1) 
if [[ -z ${containerExist} ]]
  then
  echo "${notExistContainer}" 
else
  if [ "${containerExist}" != "exited" ]
  then
    echo "${statusLived}"
  else
    echo "${statusdead}"
  fi
fi
}

function stopContainer(){
 docker stop $1 &>/dev/null
}

for containerID in ${containerIDs}
 do
 for ((i=1;i<=${retryCount};i++))
 do
  status=$(getContainerStatus ${containerID} )
  if [ "${status}" == ${statusdead} ]
  then
  stopContainer ${containerID}
  echo "Container ${containerID} already stopped"
  break
  fi
  if [ "${status}" == ${notExistContainer} ]
  then
  echo "Container ${containerID} not existed"
  break
  fi
  if [ "${status}" == ${statusLived} ]
  then
   echo "Container ${containerID} is lived, stop container"
   stopContainer ${containerID}
   verifyStatus=$(getContainerStatus ${containerID} )
   if [ "${verifyStatus}" == ${statusdead} ]
   then
    echo "stop container ${containerID} success "
    break
   else
   echo "${i} retry stop container"
   stopContainer ${containerID}
   fi
  fi
 done
done
