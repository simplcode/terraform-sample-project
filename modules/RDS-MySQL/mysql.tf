variable "engine" {}
variable "engineVersion" {}
variable "port" {}
variable "allocatedStorage" { default = 10 }
variable "storageType" { default = "gp2" }
variable "instanceClass" {}
variable "identifier" {}
variable "multiAz" { default = true }
variable "username" {}
variable "password" {}
variable "vpcId" {}
variable "subnetIds" {
  type = "list"
  description = "Subnet IDs for RDS"
}
variable "vpcSecurityGroupIds" {
  type = "list"
  description = "VPC의 security group id"
}
variable "applyImmediately" { default = false }
variable "allowMajorVersionUpgrade" { default = false }
variable "publiclyAccessible" { default = false }
variable "replicateSourceDb" { default = "" }
variable "storageEncrypted" { default = true }
variable "backupRetentionPeriod" { default = "0"}
variable "skipFinalSnapshot" { default = false }
variable "finalSnapshotIdentifier" {}
variable "snapshot_identifier" {
  default = ""
  description = "Specifies snapshot ID to create this db from a snapshot (e.g: rds:production-2018-01-01-00-00)"
}
variable "sgCidrBlocks" {
  type = "list"
  description = "RDS의 security group에 추가할 CIDR blocks"
}
variable "tags" { type = "map" }

resource "aws_db_instance" "RDS" {
  engine = "${var.engine}"
  engine_version = "${var.engineVersion}"
  port = "${var.port}"
  allocated_storage = "${var.allocatedStorage}"
  storage_type = "${var.storageType}"
  instance_class = "${var.instanceClass}"
  identifier = "${var.identifier}"
  multi_az = "${var.multiAz}"
  username = "${var.username}"
  password = "${var.password}"
  db_subnet_group_name = "${aws_db_subnet_group.Default.id}"
  apply_immediately = "${var.applyImmediately}"
  allow_major_version_upgrade = "${var.allowMajorVersionUpgrade}"
  publicly_accessible = "${var.publiclyAccessible}"
  replicate_source_db = ""
  storage_encrypted = "${var.storageEncrypted}"
  backup_retention_period = "${var.backupRetentionPeriod}"
  skip_final_snapshot = "${var.skipFinalSnapshot}"
  final_snapshot_identifier = "${var.finalSnapshotIdentifier}"
  snapshot_identifier = "${var.snapshot_identifier}"
  vpc_security_group_ids = ["${concat(var.vpcSecurityGroupIds, list(aws_security_group.RDS-SG.id))}"]
  tags = "${var.tags}"
}

######### DB Subnet Group #########

resource "aws_db_subnet_group" "Default" {
  name = "${var.identifier}-sg"
  description = "db subnet group"
  subnet_ids = ["${var.subnetIds}"]

  tags = "${var.tags}"
}

######### DB Security Group #########

resource "aws_security_group" "RDS-SG" {
  name = "${var.identifier}-sg"
  description = "${var.identifier} security group"

  vpc_id = "${var.vpcId}"
}

resource "aws_security_group_rule" "Allow_3306" {
  from_port = 3306
  cidr_blocks = ["${var.sgCidrBlocks}"]
  protocol = "tcp"
  security_group_id = "${aws_security_group.RDS-SG.id}"
  to_port = 3306
  type = "ingress"
}

resource "aws_security_group_rule" "Allow_All" {
  from_port = 0
  cidr_blocks = ["0.0.0.0/0"]
  protocol = "tcp"
  security_group_id = "${aws_security_group.RDS-SG.id}"
  to_port = 0
  type = "egress"
}

output "address" {
  value = "${aws_db_instance.RDS.address}"
}

output "arn" {
  value = "${aws_db_instance.RDS.arn}"
}

output "allocated_storage" {
  value = "${aws_db_instance.RDS.allocated_storage}"
}

output "availability_zone" {
  value = "${aws_db_instance.RDS.availability_zone}"
}

output "endpoint" {
  value = "${aws_db_instance.RDS.endpoint}"
}

output "endpointJDBCURL" {
  value = "jdbc:mysql://${aws_db_instance.RDS.endpoint}"
}

output "id" {
  value = "${aws_db_instance.RDS.id}"
}

output "identifier" {
  value = "${aws_db_instance.RDS.identifier}"
}

output "hosted_zone_id" {
  value = "${aws_db_instance.RDS.hosted_zone_id}"
}

output "resource_id" {
  value = "${aws_db_instance.RDS.resource_id}"
}

output "status" {
  value = "${aws_db_instance.RDS.status}"
}

output "username" {
  value = "${aws_db_instance.RDS.username}"
}