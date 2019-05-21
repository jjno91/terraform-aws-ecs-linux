#################################################
# ECS
#################################################

resource "aws_ecs_cluster" "this" {
  name = "${var.env}-linux"
}

#################################################
# EC2
#################################################

data "aws_ami" "this" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name_filter}"]
  }
}

data "template_file" "userdata" {
  count    = "${var.efs_mount ? 0 : 1}"
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"

  vars = {
    CLUSTER_ID = "${aws_ecs_cluster.this.id}"
  }
}

data "template_file" "efs_userdata" {
  count    = "${var.efs_mount ? 1 : 0}"
  template = "${file("${path.module}/templates/userdata-efs.sh.tpl")}"

  vars = {
    CLUSTER_ID     = "${aws_ecs_cluster.this.id}"
    EFS_ID         = "${aws_efs_file_system.this.id}"
    EFS_MOUNT_PATH = "${var.efs_mount_path}"
  }
}

resource "aws_efs_file_system" "this" {
  count          = "${var.efs_mount ? 1 : 0}"
  creation_token = "${var.env}-ecs-linux"
  encrypted      = true
  tags           = "${merge(map("Name", "${var.env}-ecs-linux"), var.tags)}"

  lifecycle {
    # require manual deletion due to lack of backup plan
    prevent_destroy = true
  }
}

resource "aws_efs_mount_target" "this" {
  count           = "${var.efs_mount ? length(var.subnet_ids) : 0}"
  file_system_id  = "${aws_efs_file_system.this.id}"
  subnet_id       = "${element(var.subnet_ids, count.index)}"
  security_groups = ["${aws_security_group.this.id}"]
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.env}-ecs-linux-"
  image_id               = "${data.aws_ami.this.image_id}"
  instance_type          = "${var.instance_type}"
  ebs_optimized          = true
  user_data              = "${var.efs_mount ? base64encode(data.template_file.efs_userdata.rendered) : base64encode(data.template_file.userdata.rendered)}"
  vpc_security_group_ids = ["${aws_security_group.this.id}"]
  tags                   = "${merge(map("Name", "${var.env}-ecs-linux"), var.tags)}"

  block_device_mappings {
    device_name = "${var.sized_block_device}"

    ebs {
      volume_size = "${var.ec2_disk_size}"
    }
  }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.this.name}"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "volume"
    tags          = "${merge(map("Name", "${var.env}-ecs-linux"), var.tags)}"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = "${merge(map("Name", "${var.env}-ecs-linux"), var.tags)}"
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix         = "${var.env}-ecs-linux-"
  min_size            = "${var.min_size}"
  max_size            = "${var.max_size}"
  vpc_zone_identifier = ["${var.subnet_ids}"]

  launch_template = {
    id      = "${aws_launch_template.this.id}"
    version = "$$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]
}

#################################################
# Auto-Scaling
#################################################

resource "aws_autoscaling_policy" "up" {
  name                   = "scale-up"
  scaling_adjustment     = "${var.scaling_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scaling_cooldown}"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"
}

resource "aws_cloudwatch_metric_alarm" "high" {
  alarm_name          = "${var.env}-ecs-linux-high-usage"
  alarm_description   = "This metric monitors high utililization of ECS resources"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  namespace           = "AWS/ECS"
  metric_name         = "${var.scaling_metric}"
  period              = "${var.scaling_metric_period}"
  evaluation_periods  = "${var.scaling_evaluation_periods}"
  threshold           = "${var.scaling_high_bound}"
  alarm_actions       = ["${aws_autoscaling_policy.up.arn}"]

  dimensions {
    ClusterName = "${var.env}-linux"
  }
}

resource "aws_autoscaling_policy" "down" {
  name                   = "scale-down"
  scaling_adjustment     = "-${var.scaling_adjustment}"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scaling_cooldown}"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"
}

resource "aws_cloudwatch_metric_alarm" "low" {
  alarm_name          = "${var.env}-ecs-linux-low-usage"
  alarm_description   = "This metric monitors low utililization of ECS resources"
  comparison_operator = "LessThanOrEqualToThreshold"
  statistic           = "Average"
  namespace           = "AWS/ECS"
  metric_name         = "${var.scaling_metric}"
  period              = "${var.scaling_metric_period}"
  evaluation_periods  = "${var.scaling_evaluation_periods}"
  threshold           = "${var.scaling_low_bound}"
  alarm_actions       = ["${aws_autoscaling_policy.down.arn}"]

  dimensions {
    ClusterName = "${var.env}-linux"
  }
}

#################################################
# IAM
#################################################

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${var.env}-ecs-linux-"
  assume_role_policy = "${data.aws_iam_policy_document.this.json}"
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = "${aws_iam_role.this.name}"
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.env}-ecs-linux-"
  role        = "${aws_iam_role.this.name}"
}

#################################################
# Security Group
#################################################

resource "aws_security_group" "this" {
  name_prefix = "${var.env}-ecs-linux-"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(map("Name", "${var.env}-ecs-linux"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  description              = "self"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.this.id}"
  source_security_group_id = "${aws_security_group.this.id}"
}

resource "aws_security_group_rule" "egress" {
  description       = "all"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.this.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}
