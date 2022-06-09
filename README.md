# terraform-aws-ecs-linux

Autoscaling Linux ECS cluster

## EFS Usage

When building a cluster with efs_mount=true initially the EC2 instances will be launched before the EFS mounts are created. This will result in the following error:

"Failed to resolve "fs-123abc.efs.us-west-2.amazonaws.com" - check that your file system ID is correct."

To resolve this you will simply have to wait for the EFS mount targets to finish initializing and then terminate your initial EC2 instances. This will cause the auto scaling group to rebuild the EC2 instances and on retry the mount will be successful.

This is currently a bug in our code and will be fixed at a later date.
