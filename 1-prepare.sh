#!/bin/bash
REPODIR="/home/lucas/agileos-environment/repositories"
BASEDIR="/home/lucas/agileos-environment"
NETWORK="agileos_net"
NETWORK_GATEWAY="172.18.0.1"
ROOTDIR=$(cd `dirname $0` && pwd -P)
#
if [ ! -f "$ROOTDIR/config.env" ]; then
BYellow='\033[1;33m'
NC='\033[0m' # No Color
    echo -e "${BYellow}create config.env file to start.${NC}"
    exit 1
fi
if [ -d "$ROOTDIR/services" ]; then rm -Rf $ROOTDIR/services; fi
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
set -o nounset -o pipefail -o errexit
# Load all variables from .env and export them all for Ansible to read
set -o allexport
source "$ROOTDIR/config.env"
if test -z "$BASEDIR" 
then
  echo "BASEDIR=$ROOTDIR" >> "$ROOTDIR/config.env"
  echo "POLINETNAME=$POLINETNAME" >> "$ROOTDIR/config.env"
  echo "POLINETGATEWAY=$NETWORK_GATEWAY" >> "$ROOTDIR/config.env"
fi
if test -z "$REPODIR" 
then
  REPODIR="$ROOTDIR/repositories"
  echo "REPODIR=$REPODIR" >> "$ROOTDIR/config.env"
fi
set +o allexport
# Run Ansible
git config --global --add safe.directory $REPODIR/api-gateway
git config --global --add safe.directory $REPODIR/ms-house
git config --global --add safe.directory $REPODIR/ms-budget
git config --global --add safe.directory $REPODIR/ms-notifier
git config --global --add safe.directory $REPODIR/ms-notification
git config --global --add safe.directory $REPODIR/ms-ms-sales-and-stock
git config --global --add safe.directory $REPODIR/ms-payment

ansible-playbook "$(dirname $0)/ansible/playbook.yml"

# Install dependencies for each repository
repositories=("api-gateway" "ms-house" "ms-notifier", "ms-customer", "ms-sales-and-stock", "ms-notification", "ms-payment")
for repo in "${repositories[@]}"; do
  cd "$REPODIR/$repo"
  echo instaling repositories dependences of "$repo"
   npm cache clean -f
  # rm -rf node_modules
  # rm package-lock.json

  npm install --legacy-peer-deps --force 
  cd "$ROOTDIR"
done

echo "run shell script \"2\", to install base services"
