variable "env" {}
variable "az" {
  type = "list"
}
variable "vpcId" {}
variable "rdsSGPublicSubnetCidrs" {
  type = "list"
}
variable "rdsSGPrivateSubnetCidrs" {
  type = "list"
}
variable "dbSubnetIds" {
  type = "list"
}
variable "vpcSecurityGroupId" {}
variable "ebSecurityGroupIds" {
  type = "list"
}
variable "tags" {
  type = "map"
}

#################### RDS ####################

module "xxsvcDB" {
  source = "../../../modules/RDS-MySQL"

  engine = "mysql"
  engineVersion = "5.7.23"
  port = "3306"
  allocatedStorage = "15"
  storageType = "gp2"
  instanceClass = "db.t2.small"
  identifier = "xxsvc-mysql${var.env}"
  multiAz = false
  username = "dbmaster"
  password = "rqweqeNtTTNdfadfUwRab2CeQeFuMsdffe547g"
  vpcId = "${var.vpcId}"
  subnetIds = "${var.dbSubnetIds}"
  vpcSecurityGroupIds = "${concat(list(var.vpcSecurityGroupId), var.ebSecurityGroupIds)}"
  applyImmediately = true
  allowMajorVersionUpgrade = true
  publiclyAccessible = true
  replicateSourceDb = ""
  storageEncrypted = false
  backupRetentionPeriod = "7"
  skipFinalSnapshot = true
  finalSnapshotIdentifier = "xxsvc-mysql${var.env}-final-snapshot"
  sgCidrBlocks = "${concat(var.rdsSGPublicSubnetCidrs, var.rdsSGPrivateSubnetCidrs)}"
  tags = "${var.tags}"
}