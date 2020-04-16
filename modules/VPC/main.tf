variable "name" {}
variable "env" {}
variable "tags" {
  type = "map"
}
variable "az" {
  type = "list"
  description = "List of AZs. This will affect subnet and NAT numbers."
}
variable "vpcCidr" {}
variable "publicACidr" {}
variable "publicBCidr" {}
variable "privateACidr" {}
variable "privateBCidr" {}
variable "imexCidrs" {
  type = "list"
}
variable "internalServiceCidrs" {
  type = "list"
  description = "ie. ERP, API, etc."
}
variable "enableDnsHostname" {
  default = true
}
variable "enableDnsSupport" {
  default = false
}

#################### VPC ####################

resource "aws_vpc" "Main" {
  cidr_block = "${var.vpcCidr}"
  instance_tenancy = "default"
  enable_dns_hostnames = "${var.enableDnsHostname}"
  enable_dns_support = "${var.enableDnsSupport}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-VPC"))}"
}

#################### Public Subnets ####################

resource "aws_subnet" "PublicA" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  cidr_block = "${cidrsubnet(var.publicACidr, 2, count.index)}"
  vpc_id = "${aws_vpc.Main.id}"
  availability_zone = "${var.az[count.index]}"
  map_public_ip_on_launch = true

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-PublicA${count.index}"))}"
}

resource "aws_subnet" "PublicB" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  cidr_block = "${cidrsubnet(var.publicBCidr, 2, count.index)}"
  vpc_id = "${aws_vpc.Main.id}"
  availability_zone = "${var.az[count.index]}"
  map_public_ip_on_launch = true

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-PublicB${count.index}"))}"
}

#################### Private Subnets ####################

resource "aws_subnet" "PrivateA" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  cidr_block = "${cidrsubnet(var.privateACidr, 2, count.index)}"
  vpc_id = "${aws_vpc.Main.id}"
  availability_zone = "${var.az[count.index]}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-PrivateA${count.index}"))}"
}

resource "aws_subnet" "PrivateB" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  cidr_block = "${cidrsubnet(var.privateBCidr, 2, count.index)}"
  vpc_id = "${aws_vpc.Main.id}"
  availability_zone = "${var.az[count.index]}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-PrivateB${count.index}"))}"
}

#################### Internet Gateway ####################

resource "aws_internet_gateway" "IGW" {
  vpc_id = "${aws_vpc.Main.id}"
  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-IGW"))}"
}

#################### Elastic IP ####################

resource "aws_eip" "EIP" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-NAT-${count.index}"))}"
}

#################### NAT Gateway ####################
resource "aws_nat_gateway" "NAT-A" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  allocation_id = "${element(aws_eip.EIP.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.PublicA.*.id, count.index)}"
  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-NAT-A${count.index}"))}"
  depends_on = ["aws_internet_gateway.IGW"]
}

#################### Route Tables ####################
resource "aws_route_table" "Public" {
  vpc_id = "${aws_vpc.Main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-Public"))}"
}

resource "aws_route_table" "Private" {
  vpc_id = "${aws_vpc.Main.id}"
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.NAT-A.*.id, count.index)}"
  }

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-Private"))}"
}

resource "aws_route_table_association" "PublicA" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  route_table_id = "${aws_route_table.Public.id}"
  subnet_id = "${element(aws_subnet.PublicA.*.id, count.index)}"
}

resource "aws_route_table_association" "PublicB" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  route_table_id = "${aws_route_table.Public.id}"
  subnet_id = "${element(aws_subnet.PublicB.*.id, count.index)}"
}

resource "aws_route_table_association" "PrivateA" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  route_table_id = "${element(aws_route_table.Private.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.PrivateA.*.id, count.index)}"
}

resource "aws_route_table_association" "PrivateB" {
  count = "${length(var.az) > 4 ? 4 : length(var.az)}"
  route_table_id = "${element(aws_route_table.Private.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.PrivateB.*.id, count.index)}"
}

#################### VPC Security Group ####################
resource "aws_security_group" "Main" {
  name = "${var.name}-Main-SG-${var.env}"
  description = "${var.name} VPC Main Security Group"
  vpc_id = "${aws_vpc.Main.id}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-Main-SG"))}"
}

resource "aws_security_group_rule" "Allow_SSH" {
  from_port = 22
  cidr_blocks = "${var.imexCidrs}"
  protocol = "tcp"
  security_group_id = "${aws_security_group.Main.id}"
  to_port = 22
  type = "ingress"
}

resource "aws_security_group_rule" "Allow_MYSQL" {
  from_port = 3306
  cidr_blocks = "${var.imexCidrs}"
  protocol = "tcp"
  security_group_id = "${aws_security_group.Main.id}"
  to_port = 3306
  type = "ingress"
}

resource "aws_security_group_rule" "Allow_HTTPS" {
  from_port = 443
  source_security_group_id = "${aws_security_group.EBSG.id}"
  protocol = "tcp"
  security_group_id = "${aws_security_group.Main.id}"
  to_port = 443
  type = "ingress"
}

resource "aws_security_group_rule" "Allow_INT_HTTPS" {
  from_port = 443
  source_security_group_id = "${aws_security_group.EBSG_Allow_INT.id}"
  protocol = "tcp"
  security_group_id = "${aws_security_group.Main.id}"
  to_port = 443
  type = "ingress"
}

resource "aws_security_group_rule" "Allow_All" {
  from_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Main.id}"
  to_port = 0
  type = "egress"
}

#################### Elasticbeanstalk (ELB) Security Group ####################

resource "aws_security_group" "EBSG" {
  name = "${var.name}-EB-SG-${var.env}"
  description = "Elastic Beanstalk Default Security Group"
  vpc_id = "${aws_vpc.Main.id}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-EB-SG-${var.env}"))}"
}

resource "aws_security_group_rule" "EB_Allow_HTTP_In" {
  from_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.EBSG.id}"
  to_port = 80
  type = "ingress"
}

resource "aws_security_group_rule" "EB_Allow_HTTPS_In" {
  from_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.EBSG.id}"
  to_port = 443
  type = "ingress"
}

resource "aws_security_group_rule" "EB_Allow_HTTP_Out" {
  from_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.EBSG.id}"
  to_port = 80
  type = "egress"
}

resource "aws_security_group_rule" "EB_Allow_HTTPS_Out" {
  from_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.EBSG.id}"
  to_port = 443
  type = "egress"
}

resource "aws_security_group" "EBSG_Allow_INT" {
  name = "${var.name}-EB-SG-INT-${var.env}"
  description = "Elastic Beanstalk Security Group for internal services"
  vpc_id = "${aws_vpc.Main.id}"

  tags = "${merge(var.tags, map("Env", var.env, "Name", "${var.name}-EB-SG-INT-${var.env}"))}"
}

resource "aws_security_group_rule" "EB_Allow_INT_HTTP_In" {
  from_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0", "${var.imexCidrs}", "${var.vpcCidr}"]
  security_group_id = "${aws_security_group.EBSG_Allow_INT.id}"
  to_port = 80
  type = "ingress"
}

resource "aws_security_group_rule" "EB_Allow_INT_HTTPS_In" {
  from_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0", "${var.imexCidrs}", "${var.vpcCidr}"]
  security_group_id = "${aws_security_group.EBSG_Allow_INT.id}"
  to_port = 443
  type = "ingress"
}

resource "aws_security_group_rule" "EB_Allow_INT_HTTP_Out" {
  from_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.EBSG_Allow_INT.id}"
  to_port = 80
  type = "egress"
}

resource "aws_security_group_rule" "EB_Allow_INT_HTTPS_Out" {
  from_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.EBSG_Allow_INT.id}"
  to_port = 443
  type = "egress"
}


output "vpcId" {
  value = "${aws_vpc.Main.id}"
}


output "privateASubnetIds" {
  value = "${aws_subnet.PrivateA.*.id}"
}
output "privateBSubnetIds" {
  value = "${aws_subnet.PrivateB.*.id}"
}

output "publicASubnetIds" {
  value = "${aws_subnet.PublicA.*.id}"
}

output "publicBSubnetIds" {
  value = "${aws_subnet.PublicB.*.id}"
}

output "publicSubnetIds" {
  value = "${concat(aws_subnet.PublicA.*.id, aws_subnet.PublicB.*.id)}"
}

output "privateSubnetIds" {
  value = "${concat(aws_subnet.PrivateA.*.id, aws_subnet.PrivateB.*.id)}"
}

output "publicSubnetCIDRs" {
  value = "${concat(
  aws_subnet.PublicA.*.cidr_block,
  aws_subnet.PublicB.*.cidr_block
  )}"
}

output "privateSubnetCIDRs" {
  value = "${concat(
  aws_subnet.PrivateA.*.cidr_block,
  aws_subnet.PrivateB.*.cidr_block
  )}"
}

output "vpcSecurityGroupId" {
  value = "${aws_security_group.Main.id}"
}

output "ebSecurityGroupId" {
  value = "${aws_security_group.EBSG.id}"
}

output "ebINTSecurityGroupId" {
  value = "${aws_security_group.EBSG_Allow_INT.id}"
}