#!/bin/bash
ROOTDIR=$(cd `dirname $0` && pwd -P)
NETWORK="pratigo_net"
# Gateway será detectado automaticamente
#
if [ ! -f "$ROOTDIR/config.env" ]; then
BYellow='\033[1;33m'
NC='\033[0m' # No Color
    echo -e "${BYellow}create config.env file to start.${NC}"
    exit 1
fi
#
NetworkExternalExist=$(docker network inspect $(docker network ls -q) | grep "$NETWORK") 
if [[ -z ${NetworkExternalExist} ]]
  then
  docker network create $NETWORK &>/dev/null
  echo "Network "$NETWORK" created"
fi
NETWORK_GATEWAY=$(docker network inspect --format='{{(index .IPAM.Config 0).Gateway}}' "$NETWORK")
if [[ -z ${NETWORK_GATEWAY} ]]
  then
    echo -e "Gateway not detected"
    exit 1
fi
#
mkdir -p "$ROOTDIR/data"

sudo systemctl stop apache &>/dev/null
sudo systemctl stop apache2 &>/dev/null
sudo systemctl stop httpd &>/dev/null
sudo systemctl stop nginx &>/dev/null

export COMPOSE_IGNORE_ORPHANS=true
echo "Base"
docker-compose --env-file "$ROOTDIR/config.env" -f "$ROOTDIR/compose/docker-compose.yml" up -d
echo "DONE!"

echo "Containers started."
