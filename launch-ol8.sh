#!/bin/sh
# Run the container as local user, default 501 and 20.  
# Rancher Desktop must run at administrative mode to access CE on the host 
export USER_ID=501
export GROUP_ID=20
CONTAINER_NAME=ol8
docker run -it -d \
  --user ${USER_ID}:${GROUP_ID} \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${HOME}/.docker:/home/john/.docker \
  --name ${CONTAINER_NAME} ol8-cli:latest
echo "SSH port is 2222"

