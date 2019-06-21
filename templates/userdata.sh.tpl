#!/bin/bash -ex

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bootstrap_container_instance.html
echo "ECS_CLUSTER=${CLUSTER_ID}" >> /etc/ecs/ecs.config
