variable "name" {}
variable "env" {}
variable "domain" {}
variable "ebZoneId" {}
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

#################### Elastic Beanstalk ####################

module "erp" {
  source = "../../../modules/ElasticBeanstalk-Nodejs"

  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.ebZoneId}"
  name = "xxsvc-${var.name}"
  cname = "${var.name}"
  description = "XXSVC ERP Service"
  solutionStackName = "64bit Amazon Linux 2018.03 v4.8.3 running Node.js"
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
  allowHTTPS = "true"
  httpsListenerProtocol = "HTTPS"
  httpsInstancePort = "80"
  httpsInstanceProtocal = "HTTP"
  securityGroupId = "${var.ebSecurityGroupId}"
  sslCertificateId = "${var.ebCertificateArn}"
  vpcId = "${var.vpcId}"
  elbSubnetIds = "${join(",", var.ebPublicSubnetIds)}"
  subnetIds = "${join(",", var.ebPrivateSubnetIds)}"
}

#################### RDS ####################

module "erpDB" {
  source = "../../../modules/RDS-MySQL"

  engine = "mysql"
  engineVersion = "5.7.23"
  port = "3306"
  allocatedStorage = "7"
  storageType = "gp2"
  instanceClass = "db.t2.small"
  identifier = "xxsvc-erp-mysql${var.env}"
  multiAz = false
  username = "dbmaster"
  password = "weriiie8ejdaalk6jdfleeiososRD2774ap"
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
  finalSnapshotIdentifier = "xxsvc-erp-mysql${var.env}-final-snapshot"
  sgCidrBlocks = "${concat(var.rdsSGPublicSubnetCidrs, var.rdsSGPrivateSubnetCidrs)}"
  tags = "${var.tags}"
}