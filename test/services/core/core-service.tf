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

#################### RDS ####################
module "CoreDB" {
  source = "../../../modules/RDS-MySQL"

  engine = "mysql"
  engineVersion = "5.7.19"
  port = "3306"
  allocatedStorage = "10"
  storageType = "gp2"
  instanceClass = "db.t2.small"
  identifier = "xxsvc-core-mysql${var.env}"
  multiAz = false
  username = "dbmaster"
  password = "e9lsellzsefelwruMajet6breSwuseqUctyTRR"
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
  finalSnapshotIdentifier = "core-mysql${var.env}-final-snapshot"
  sgCidrBlocks = "${concat(var.rdsSGPublicSubnetCidrs, var.rdsSGPrivateSubnetCidrs)}"
  tags = "${var.tags}"
}

#################### Beanstalk ####################
module "APIGateway" {
  source = "../../../modules/ElasticBeanstalk-Java"

  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.ebZoneId}"
  name = "xxsvc-${var.name}-apigw"
  cname = "gw"
  description = "API Gateway Service"
  solutionStackName = "${var.ebStackJava}"
  instanceType = "t2.micro"
  ec2keyName = "${var.ec2KeyName}"
  deploymentPolicy = "AllAtOnce"
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
  securityGroupId = "${var.ebSecurityGroupId}"
  sslCertificateId = "${var.ebCertificateArn}"
  healthCheckPath = "/api/v1/actuator/health"
  vpcId = "${var.vpcId}"
  elbSubnetIds = "${join(",", var.ebPublicSubnetIds)}"
  subnetIds = "${join(",", var.ebPrivateSubnetIds)}"
  elbScheme = "public"
}

module "Eureka" {
  source = "../../../modules/ElasticBeanstalk-Java"

  env = "${var.env}"
  domain = "${var.domain}"
  ebZoneId = "${var.ebZoneId}"
  name = "xxsvc-${var.name}-eureka"
  cname = "eureka"
  description = "Eureka Service"
  solutionStackName = "${var.ebStackJava}"
  instanceType = "t2.micro"
  ec2keyName = "${var.ec2KeyName}"
  deploymentPolicy = "AllAtOnce"
  az = "${var.az}"
  minSize = "1"
  maxSize = "1"
  breachDuration = "20"
  lowerBreachScaleIncrement = "-1"
  lowerThreshold = "10"
  measureName = "CPUUtilization"
  unit = "Percent"
  upperBreachScaleIncrement = "1"
  upperThreshold = "20"
  allowHTTP = "false"
  allowHTTPS = "true"
  httpsListenerProtocol = "HTTPS"
  securityGroupId = "${var.ebSecurityGroupId}"
  sslCertificateId = "${var.ebCertificateArn}"
  healthCheckPath = "/actuator/health"
  vpcId = "${var.vpcId}"
  elbSubnetIds = "${join(",", var.ebPublicSubnetIds)}"
  subnetIds = "${join(",", var.ebPrivateSubnetIds)}"
  elbScheme = "public"
}
