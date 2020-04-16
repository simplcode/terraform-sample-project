variable "name" {}
variable "env" {}
variable "tags" {
  type = "map"
}
variable "vpcId" {}
variable "subnetIds" {
  type = "list"
}
variable "lbLogBucket" {}

#################### ALB ####################

resource "aws_lb" "MainLB" {
  name = "${var.name}-Main-LB-${var.env}"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.ALB.id}"]
  subnets = ["${var.subnetIds}"]


  enable_deletion_protection = false

  access_logs {
    bucket = "${var.lbLogBucket}"
    prefix = "${var.env}"
  }

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-LB-${var.env}"))}"
}

resource "aws_lb_listener" "frontend" {

  "default_action" {
    target_group_arn = ""
    type = ""
  }

  load_balancer_arn = "${aws_lb.MainLB.arn}"
  port = 443
  protocol = ""
  ssl_policy = ""
  certificate_arn = ""
}

resource "aws_lb_listener_rule" "" {
  "action" {
    target_group_arn = ""
    type = ""
  }
  "condition" {}
  listener_arn = ""
}

resource "aws_lb_target_group" "" {
  port = 0
  protocol = ""
  vpc_id = ""
}

resource "aws_lb_target_group_attachment" "" {
  target_group_arn = ""
  target_id = ""
  port = 80
}

#################### ALB Security Group ####################

resource "aws_security_group" "ALB" {
  name = "${var.name}-ALB-SG-${var.env}"
  description = "Load Balancer Security Group"
  vpc_id = "${var.vpcId}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-ALB-SG-${var.env}"))}"
}

resource "aws_security_group_rule" "LB_Allow_HTTP_In" {
  from_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ALB.id}"
  to_port = 80
  type = "ingress"
}

resource "aws_security_group_rule" "LB_Allow_HTTPS_In" {
  from_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ALB.id}"
  to_port = 443
  type = "ingress"
}

resource "aws_security_group_rule" "LB_Allow_HTTP_Out" {
  from_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ALB.id}"
  to_port = 80
  type = "egress"
}

resource "aws_security_group_rule" "LB_Allow_HTTPS_Out" {
  from_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ALB.id}"
  to_port = 443
  type = "egress"
}
