#!/bin/bash -ex

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
echo "ECS_CLUSTER=${CLUSTER_ID}" >> /etc/ecs/ecs.config

# mount EFS
mkdir -p "${EFS_MOUNT_PATH}"
yum install -y amazon-efs-utils
echo "${EFS_ID}:/ ${EFS_MOUNT_PATH} efs tls,_netdev" >> /etc/fstab
mount -t efs -o tls "${EFS_ID}:/" "${EFS_MOUNT_PATH}"
#create an empty htaccess file 
sudo touch "${EFS_MOUNT_PATH}/.htaccess"
#increase wp upload limits
sudo cat > "${EFS_MOUNT_PATH}/.htaccess" << EOF
php_value upload_max_filesize 64M
php_value post_max_size 128M
php_value memory_limit 256M
php_value max_execution_time 300
php_value max_input_time 300
#Setting value of output buffering to default in prod 
php_value output_buffering 4096
EOF