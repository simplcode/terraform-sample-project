variable "name" {}
variable "env" {}
variable "domain" {}
variable "ebZoneId" {}
variable "ebStackJava" {}
variable "ebStackTomcat" {}
variable "az" {
  type = "list"
}
variable "ec2KeyName" {}
variable "vpcId" {}
variable "ebCertificateArn" {}
variable "rdsSGPublicSubnetCidrs" {
  type = "list"
}
variable "rdsSGPrivateSubnetCidrs" {
  type = "list"
}
variable "ebPublicSubnetIds" {
  type = "list"
}
variable "ebPrivateSubnetIds" {
  type = "list"
}
variable "dbSubnetIds" {
  type = "list"
}
variable "vpcSecurityGroupId" {}
variable "ebSecurityGroupId" {}
variable "tags" {
  type = "map"
}

#################### SQS ####################

resource "aws_sqs_queue" "APICalculationSQS" {
  name = "xxsvc-api-calc-${var.env}"
  fifo_queue = false
  visibility_timeout_seconds = 30
  tags = "${merge(var.tags, map("Env", var.env, "Name", "API Calculation Queue"))}"
}

resource "aws_sqs_queue_policy" "APICalculationSQSPolicy" {
  queue_url = "${aws_sqs_queue.APICalculationSQS.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "APICalculationSQSPolicy",
  "Statement": [
    {
      "Sid": "Allow_billingsvc",
      "Effect": "Allow",
      "Principal": {"AWS":["arn:aws:iam::014144415888:user/calcsvc"]},
      "Action": "sqs:*",
      "Resource": "${aws_sqs_queue.APICalculationSQS.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sqs_queue.APICalculationSQS.arn}"
        }
      }
    }
  ]
}
POLICY
}

#################### S3 ####################
resource "aws_s3_bucket" "CalcFiles" {
  bucket = "xxsvc-calc-files-${var.env}"
  acl = "private"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "Calculation file bucket"))}"
}

resource "aws_s3_bucket" "CalcStatic" {
  bucket = "xxsvc-calc-static-${var.env}"
  acl = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  //!!!This's for test Env.
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET","PUT","POST","DELETE"]
    allowed_origins = [
      "http://localhost:8080",
      "http://localhost:8081",
      "http://127.0.0.1:8080",
      "http://127.0.0.1:8081",
      "http://devel.xxservice.com",
      "https://*.xxservice.com"
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
      "Resource":["arn:aws:s3:::xxsvc-calc-static-${var.env}/*"]
    }
  ]
}
  POLICY

  tags = "${merge(var.tags, map("Env", var.env, "Name", "Calculation static bucket"))}"
}

#################### RDS ####################
module "APIDB" {
  source = "../../../modules/RDS-MySQL"

  engine = "mysql"
  engineVersion = "5.7.23"
  port = "3306"
  allocatedStorage = "10"
  storageType = "gp2"
  instanceClass = "db.t2.small"
  identifier = "xxsvc-api-mysql${var.env}"
  multiAz = false
  username = "dbmaster"
  password = "lslkjelfkakljMajet6breSwuseqUcrafUJ"
  vpcId = "${var.vpcId}"
  subnetIds = "${var.dbSubnetIds}"
  vpcSecurityGroupIds = "${list(var.vpcSecurityGroupId, var.ebSecurityGroupId)}"
  applyImmediately = true
  allowMajorVersionUpgrade = true
  publiclyAccessible = false
  replicateSourceDb = ""
  storageEncrypted = false
  backupRetentionPeriod = "3"
  skipFinalSnapshot = true
  finalSnapshotIdentifier = "api-mysql${var.env}-final-snapshot"
  sgCidrBlocks = "${concat(var.rdsSGPublicSubnetCidrs, var.rdsSGPrivateSubnetCidrs)}"
  tags = "${var.tags}"
}

#################### Beanstalk ####################
module "Core" {
  source = "../../../modules/ElasticBeanstalk-Tomcat"

  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.ebZoneId}"
  name = "xxsvc-${var.name}-apicore"
  cname = "api-core.${var.name}"
  description = "Core Service for API"
  solutionStackName = "${var.ebStackTomcat}"
  instanceType = "t2.micro"
  ec2keyName = "${var.ec2KeyName}"
  az = "${var.az}"
  minSize = "1"
  maxSize = "4"
  breachDuration = "20"
  lowerBreachScaleIncrement = "-1"
  lowerThreshold = "10"
  measureName = "CPUUtilization"
  unit = "Percent"
  upperBreachScaleIncrement = "1"
  upperThreshold = "20"
  allowHTTP = "true"
  allowHTTPS = "false"
  httpsListenerProtocol = "HTTPS"
  securityGroupId = "${var.ebSecurityGroupId}"
  sslCertificateId = "${var.ebCertificateArn}"
  healthCheckPath = "/actuator/health"
  vpcId = "${var.vpcId}"
  elbSubnetIds = "${join(",", var.ebPublicSubnetIds)}"
  subnetIds = "${join(",", var.ebPrivateSubnetIds)}"
  elbScheme = "private"
}

module "Calc" {
  source = "../../../modules/ElasticBeanstalk-Tomcat"

  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.ebZoneId}"
  name = "xxsvc-${var.name}-calc"
  cname = "calc.${var.name}"
  description = "Calculation API Service"
  solutionStackName = "${var.ebStackTomcat}"
  instanceType = "t2.micro"
  ec2keyName = "${var.ec2KeyName}"
  az = "${var.az}"
  minSize = "1"
  maxSize = "4"
  breachDuration = "20"
  lowerBreachScaleIncrement = "-1"
  lowerThreshold = "40"
  measureName = "CPUUtilization"
  unit = "Percent"
  upperBreachScaleIncrement = "1"
  upperThreshold = "90"
  allowHTTP = "true"
  allowHTTPS = "false"
  httpsListenerProtocol = "HTTPS"
  securityGroupId = "${var.ebSecurityGroupId}"
  sslCertificateId = "${var.ebCertificateArn}"
  healthCheckPath = "/actuator/health"
  vpcId = "${var.vpcId}"
  elbSubnetIds = "${join(",", var.ebPublicSubnetIds)}"
  subnetIds = "${join(",", var.ebPrivateSubnetIds)}"
  elbScheme = "private"
}


module "Storage" {
  source = "../../../modules/ElasticBeanstalk-Tomcat"

  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.ebZoneId}"
  name = "xxsvc-${var.name}-storage"
  cname = "storage.${var.name}"
  description = "Storage API Service"
  solutionStackName = "${var.ebStackTomcat}"
  instanceType = "t2.micro"
  ec2keyName = "${var.ec2KeyName}"
  az = "${var.az}"
  minSize = "1"
  maxSize = "3"
  breachDuration = "20"
  lowerBreachScaleIncrement = "-1"
  lowerThreshold = "10"
  measureName = "CPUUtilization"
  unit = "Percent"
  upperBreachScaleIncrement = "1"
  upperThreshold = "20"
  allowHTTP = "true"
  allowHTTPS = "false"
  httpsListenerProtocol = "HTTPS"
  securityGroupId = "${var.ebSecurityGroupId}"
  sslCertificateId = "${var.ebCertificateArn}"
  healthCheckPath = "/actuator/health"
  vpcId = "${var.vpcId}"
  elbSubnetIds = "${join(",", var.ebPublicSubnetIds)}"
  subnetIds = "${join(",", var.ebPrivateSubnetIds)}"
  elbScheme = "private"
}
