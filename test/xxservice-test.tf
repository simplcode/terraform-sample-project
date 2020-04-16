#################### Data Sources ####################

provider "aws" {
  version = "~> 2.0"
  region = "${var.region}"
}

/*data "aws_region" "current" {
  current = true
}*/

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_acm_certificate" "xxservice" {
  domain = "*.${var.domain}"
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "api-xxservice" {
  domain = "*.api.${var.domain}"
  statuses = ["ISSUED"]
}

#################### S3 ####################

resource "aws_s3_bucket" "LBLog" {
  bucket = "xxsvc-lb-log-${var.env}"
  acl = "private"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name-prefix} LB log bucket"))}"
}

resource "aws_s3_bucket" "XXSVCFiles" {
  bucket = "xxsvc-files-${var.env}"
  acl = "private"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "XXSVC ${var.name-prefix} files bucket"))}"
}

resource "aws_s3_bucket" "XXSVCStatic" {
  bucket = "xxsvc-static-${var.env}"
  acl = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET","PUT","POST","DELETE"]
    allowed_origins = [
      "http://localhost:8080",
      "http://localhost:8081",
      "http://127.0.0.1:8080",
      "http://127.0.0.1:8081",
      "https://*.api.xxservice.com",
      "https://*.erp.xxservice.com"
    ]
    max_age_seconds = 1800
  }

  //no space at the start!
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::xxsvc-static-${var.env}/*"]
    }
  ]
}
  POLICY

  tags = "${merge(var.tags, map("Env", var.env, "Name", "XXSVC static bucket"))}"
}

#################### VPC ####################

module "VPC" {
  source = "../modules/VPC"

  name = "${var.name-prefix}"
  env = "${var.env}"
  tags = "${var.tags}"
  az = "${data.aws_availability_zones.available.names}"
  vpcCidr = "${var.vpc-cidr}"
  publicACidr = "${var.publicA-cidr}"
  publicBCidr = "${var.publicB-cidr}"
  privateACidr = "${var.privateA-cidr}"
  privateBCidr = "${var.privateB-cidr}"
  imexCidrs = ["${var.inbound-cidrs}"]
  internalServiceCidrs = ["${var.internal-service-cidrs}"]
  enableDnsHostname = true
  enableDnsSupport = true
}

#################### Bastion Server ####################

module "BastionServer" {
  source = "../modules/EC2"

  numberOfInstances = 1
  env = "${var.env}"
  domain = "${var.domain}"
  name = "sgsvcbastion"
  tags = "${var.tags}"
  ami-id = "${data.aws_ami.ubuntu.id}"
  instance-type = "t3.nano"
  volume-size = "20"
  subnet-ids = "${module.VPC.publicASubnetIds}"
  vpc-sg-ids = ["${module.VPC.vpcSecurityGroupId}"]
  key-name = "${var.ssh-key}"
  bastion-ip = ""
  imex-cidrs = "${var.inbound-cidrs}"
  setup-scripts = ["../scripts/add-developers.sh"]
}

#########################################################
#################### Service Modules ####################
#########################################################

//독립적인 DB를 가지지 않는 서비스들을 위한 Database Module
module "XXServiceDB" {
  source = "services/mysql"

  env = "${var.env}"
  az = "${data.aws_availability_zones.available.names}"
  vpcId = "${module.VPC.vpcId}"
  //RDS의 SG를 사용할 subnet 목록
  rdsSGPublicSubnetCidrs = "${module.VPC.publicSubnetCIDRs}"
  rdsSGPrivateSubnetCidrs = "${module.VPC.privateSubnetCIDRs}"
  //RDS를 배치할 subnet 목록
  dbSubnetIds = "${module.VPC.publicBSubnetIds}"
  vpcSecurityGroupId = "${module.VPC.vpcSecurityGroupId}"
  //allow traffic from Elasticbeanstalk services
  ebSecurityGroupIds = "${list(module.VPC.ebINTSecurityGroupId)}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "xxserviceDB"))}"
}

module "CoreService" {
  source = "services/core"

  name = "core"
  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.elasticbeanstalk-zone-id}"
  ebStackJava = "${var.elasticbeanstalk-java8}"
  ebStackTomcat = "${var.elasticbeanstalk-tomcat}"
  az = "${data.aws_availability_zones.available.names}"
  ec2KeyName = "${var.eb-ec2-key}"
  vpcId = "${module.VPC.vpcId}"
  ebCertificateArn = "${data.aws_acm_certificate.xxservice.arn}"
  //RDS의 SG를 사용할 subnet 목록
  rdsSGPublicSubnetCidrs = "${module.VPC.publicSubnetCIDRs}"
  rdsSGPrivateSubnetCidrs = "${module.VPC.privateSubnetCIDRs}"
  //Elasticbeanstalk의 Public LB를 배치할 subnet 목록(외부 공개서비스용: ie. API G.W.)
  ebPublicSubnetIds = "${module.VPC.publicASubnetIds}"
  //Elasticbeanstalk의 Private LB & instance를 배치할 subnet 목록
  ebPrivateSubnetIds = "${module.VPC.privateASubnetIds}"
  //RDS를 배치할 subnet 목록
  dbSubnetIds = "${module.VPC.privateBSubnetIds}"
  vpcSecurityGroupId = "${module.VPC.vpcSecurityGroupId}"
  //allow traffic from XXServices and office
  ebSecurityGroupId = "${module.VPC.ebSecurityGroupId}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "core"))}"
}

module "ErpService" {
  source = "services/erp"

  name = "erp"
  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.elasticbeanstalk-zone-id}"
  az = "${data.aws_availability_zones.available.names}"
  ec2KeyName = "${var.eb-ec2-key}"
  vpcId = "${module.VPC.vpcId}"
  ebCertificateArn = "${data.aws_acm_certificate.xxservice.arn}"
  //RDS의 SG를 사용할 subnet 목록
  rdsSGPublicSubnetCidrs = "${module.VPC.publicSubnetCIDRs}"
  rdsSGPrivateSubnetCidrs = "${module.VPC.privateSubnetCIDRs}"
  //Elasticbeanstalk의 LB를 배치할 subnet 목록
  ebPublicSubnetIds = "${module.VPC.publicBSubnetIds}"
  //Elasticbeanstalk의 instance를 배치할 subnet 목록
  ebPrivateSubnetIds = "${module.VPC.privateASubnetIds}"
  //RDS를 배치할 subnet 목록
  dbSubnetIds = "${module.VPC.privateBSubnetIds}"
  vpcSecurityGroupId = "${module.VPC.vpcSecurityGroupId}"
  //allow traffic from XXServices and office
  ebSecurityGroupId = "${module.VPC.ebINTSecurityGroupId}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "erp"))}"
}

module "APIService" {
  source = "services/api"

  name = "api"
  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.elasticbeanstalk-zone-id}"
  ebStackJava = "${var.elasticbeanstalk-java8}"
  ebStackTomcat = "${var.elasticbeanstalk-tomcat}"
  az = "${data.aws_availability_zones.available.names}"
  ec2KeyName = "${var.eb-ec2-key}"
  vpcId = "${module.VPC.vpcId}"
  ebCertificateArn = "${data.aws_acm_certificate.api-xxservice.arn}"
  //RDS의 SG를 사용할 subnet 목록
  rdsSGPublicSubnetCidrs = "${module.VPC.publicSubnetCIDRs}"
  rdsSGPrivateSubnetCidrs = "${module.VPC.privateSubnetCIDRs}"
  //Elasticbeanstalk의 LB를 배치할 subnet 목록
  ebPublicSubnetIds = "${module.VPC.publicBSubnetIds}"
  //Elasticbeanstalk의 instance를 배치할 subnet 목록
  ebPrivateSubnetIds = "${module.VPC.privateASubnetIds}"
  //RDS를 배치할 subnet 목록
  dbSubnetIds = "${module.VPC.privateBSubnetIds}"
  vpcSecurityGroupId = "${module.VPC.vpcSecurityGroupId}"
  //allow traffic from XXServices and office
  ebSecurityGroupId = "${module.VPC.ebINTSecurityGroupId}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "api"))}"
}
