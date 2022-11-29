#!/bin/bash

#take ubuntu 22.04
#take t2.xlarge
#30 gb min storage
#open 22,9000,8084 ports

set -e

USER1=ubuntu
CLIENT_ID="f3a741fc3c4fafa3eb27"
CLIENT_SECRET="9a295c8379c274d1cb577853fe30fe2cd54c57fd"
PROVIDER="github"
REDIRECT_URL="http://$(curl http://checkip.amazonaws.com):8084/login"
SPINNAKER_VERSION="1.28.1"

########################## CREATE USER ##############################################################################

if id $USER1 >/dev/null 2>&1; then
        echo "User $USER1 Already Exists, Skipping Now ...."
        echo "ubuntu ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
else
        echo "User $USER1 Does Not Exist, Creating Now ...."
        groupadd ubuntu
		useradd -g ubuntu -G admin -s /bin/bash -d /home/ubuntu ubuntu
		mkdir -p /home/ubuntu
		cp -r /root/.ssh /home/ubuntu/.ssh
		chown -R ubuntu:ubuntu /home/ubuntu
		echo "ubuntu ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
		echo "User $USER1 Created Successfully ...."
fi

apt update -y

## swapon space
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo swapon /swapfile


################################################# INSTALL HALYARD ##################################################################
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update -y
sudo apt-get -y install jq openjdk-11-jdk
curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh
#sudo bash InstallHalyard.sh
echo -e "Y" | sudo bash InstallHalyard.sh
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ubuntu

sudo docker run -p 127.0.0.1:9090:9000 -d --name minio1 \
  -e "MINIO_ACCESS_KEY=minioadmin" \
  -e "MINIO_SECRET_KEY=minioadmin" \
  -v /mnt/data:/data \
  minio/minio server /data

sudo apt-get -y install jq apt-transport-https

MINIO_SECRET_KEY="minioadmin"
MINIO_ACCESS_KEY="minioadmin"

echo $MINIO_SECRET_KEY | hal config storage s3 edit --endpoint http://127.0.0.1:9090 \
    --access-key-id $MINIO_ACCESS_KEY \
    --secret-access-key
hal config storage edit --type s3



########################################### CONFIGURE OAUTH ###########################################################

if [ -z "${CLIENT_ID}" ] ; then
  echo "CLIENT_ID not set"
  exit
fi
if [ -z "${CLIENT_SECRET}" ] ; then
  echo "CLIENT_SECRET not set"
  exit
fi
if [ -z "${PROVIDER}" ] ; then
  echo "PROVIDER not set"
  exit
fi
if [ -z "${REDIRECT_URL}" ] ; then
  echo "REDIRECT_URL not set"
  exit
fi

MY_IP=`curl http://checkip.amazonaws.com`

hal config security authn oauth2 edit \
  --client-id $CLIENT_ID \
  --client-secret $CLIENT_SECRET \
  --provider $PROVIDER
hal config security authn oauth2 enable

hal config security authn oauth2 edit --pre-established-redirect-uri $REDIRECT_URL

hal config security ui edit \
    --override-base-url http://${MY_IP}:9000

hal config security api edit \
    --override-base-url http://${MY_IP}:8084
