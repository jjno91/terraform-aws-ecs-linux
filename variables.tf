variable "env" {
  description = "(optional) Unique name of your Terraform environment to be used for naming and tagging resources"
  default     = "default"
}

variable "tags" {
  description = "(optional) Additional tags to be applied to all resources"
  default     = {}
}

variable "vpc_id" {
  description = "(required) ID of the VPC that your ECS cluster will be deployed to"
  default     = ""
}

variable "subnet_ids" {
  description = "(required) IDs of the subnets to which the ECS nodes will be deployed"
  default     = []
}

variable "instance_type" {
  description = "(optional) EC2 instance type for the ASG of your cluster"
  default     = "m5.large"
}

variable "efs_mount" {
  description = "(optional) Add an EFS mount to all ECS cluster nodes"
  default     = "false"
}

variable "efs_throughput_mode" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/efs_file_system.html#throughput_mode"
  default     = "bursting"
}

variable "efs_provisioned_throughput_in_mibps" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/efs_file_system.html#provisioned_throughput_in_mibps"
  default     = "5"
}

variable "efs_mount_path" {
  description = "(optional) File system path for optional EFS mount"
  default     = "/mnt/efs"
}

variable "efs_backup_cold_storage_after" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/backup_plan.html#cold_storage_after"
  default     = "30"
}

variable "efs_backup_delete_after" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/backup_plan.html#delete_after"
  default     = "120"
}

variable "efs_backup_schedule" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/backup_plan.html#schedule"
  default     = "cron(0 5 ? * * *)"
}

variable "ami_name_filter" {
  description = "(optional) Used to lookup the AMI that will be used in the cluster launch template"
  default     = "*h-amazon-ecs-optimized"
}

variable "sized_block_device" {
  description = "(optional) Name of the block device that the launch template will size"
  default     = "/dev/xvdcz"
}

variable "ec2_disk_size" {
  description = "(optional) Size of the root volume for your EC2 container instances"
  default     = "22"
}

variable "min_size" {
  description = "(optional) Minimum node count for ASG"
  default     = "2"
}

variable "max_size" {
  description = "(optional) Maximum node count for ASG"
  default     = "10"
}

variable "scaling_metric" {
  description = "(optional) ECS cluster metric used to calculate scaling operations"
  default     = "MemoryReservation"
}

variable "scaling_metric_period" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html#period"
  default     = "60"
}

variable "scaling_evaluation_periods" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html#evaluation_periods"
  default     = "2"
}

variable "scaling_high_bound" {
  description = "(optional) When scaling_metric is above this bound your cluster will scale up"
  default     = "90"
}

variable "scaling_low_bound" {
  description = "(optional) When scaling_metric is below this bound your cluster will scale down"
  default     = "75"
}

variable "scaling_adjustment" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/autoscaling_policy.html#scaling_adjustment"
  default     = "1"
}

variable "scaling_cooldown" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/autoscaling_policy.html#cooldown"
  default     = "180"
}
