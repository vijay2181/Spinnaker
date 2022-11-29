#!/bin/bash

SPINNAKER_VERSION="1.28.1"
MY_IP=`curl http://checkip.amazonaws.com`

############################################### DEPLOY SPINNAKER ##################################################################

sudo apt update -y
sudo apt-get -y install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server


mkdir -p /home/spinnaker/.hal/default/profiles/
touch /home/spinnaker/.hal/default/profiles/front50-local.yml

echo 'spinnaker.s3:
  versioning: false
' > /home/spinnaker/.hal/default/profiles/front50-local.yml


if [ -z "${SPINNAKER_VERSION}" ] ; then
  echo "SPINNAKER_VERSION not set"
  exit
fi

sudo hal config version edit --version $SPINNAKER_VERSION

sudo hal deploy apply

sudo hal deploy connect



################################################ RESTART SPINNAKER ###############################################################

sudo systemctl restart apache2
sudo systemctl restart gate
sudo systemctl restart orca
sudo systemctl restart igor
sudo systemctl restart front50
sudo systemctl restart echo
sudo systemctl restart clouddriver
sudo systemctl restart rosco

sleep 20
echo ""
echo "Spinnaker Installed Successfully...Open Browser And Access The Spinnaker with 'http://${MY_IP}:9000' url"
echo ""
