#!/bin/bash

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
echo "ECS_CLUSTER=${CLUSTER_ID}" >> /etc/ecs/ecs.config

# mount EFS
mkdir -p "${EFS_MOUNT_PATH}"
yum install -y amazon-efs-utils
echo "${EFS_ID}:/ ${EFS_MOUNT_PATH} efs tls,_netdev" >> /etc/fstab
mount -t efs "${EFS_ID}:/" "${EFS_MOUNT_PATH}"
