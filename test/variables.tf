variable "env" {
  default = "test"
  description = "test or production envirionment"
}

variable "region" {
  default = "us-east-2"
  description = "test: us-east-2(Ohio), production: us-east-1(N.Virgina)"
}

variable "domain" {
  description = "Root domain address for services"
}

variable "elasticbeanstalk-zone-id" {}

variable "elasticbeanstalk-java8" {
  description = "Elasticbeanstalk Java8 solution stack"
}

variable "elasticbeanstalk-tomcat" {
  description = "Elasticbeanstalk Tomcat solution stack"
}

variable "name-prefix" {
  description = "Name prefix for services. This will be used as CName prefix as well."
}

variable "tags" {
  type = "map"
}

variable "vpc-cidr" {
  description = "VPC CIDR"
}

variable "privateA-cidr" {
  description = "Private A subnet cidr"
}

variable "privateA-subnets" {
  type = "list"
  description = "A list of private A subnet cidrs"
}

variable "privateB-cidr" {
  description = "Private B subnet cidr"
}

variable "privateB-subnets" {
  type = "list"
  description = "A list of private B subnets cidrs"
}

variable "publicA-cidr" {
  description = "Private A subnet cidr"
}

variable "publicA-subnets" {
  type = "list"
  description = "A list of public A subnets cidrs"
}

variable "publicB-cidr" {
  description = "Private A subnet cidr"
}

variable "publicB-subnets" {
  type = "list"
  description = "A list of public B subnets cidrs"
}

variable "inbound-cidrs" {
  type = "list"
  description = "CIDRs to allow inbound traffic"
}

variable "internal-service-cidrs" {
  type = "list"
  description = "Companys' services CIDRs to allow inbound traffic"
}

variable "ssh-key" {
  description = "ssh key name for ec2 instances"
}

variable "eb-ec2-key" {
  description = "ssh key name for elastic beanstalk instances"
}