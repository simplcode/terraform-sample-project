variable "numberOfInstances" {
  default = 1
}
variable "env" {}
variable "domain" {}
variable "name" {}
variable "tags" {
  type = "map"
}
variable "ami-id" {}
variable "instance-type" {}
variable "volume-type" {
  default = "gp2"
}
variable "volume-size" {}
variable "subnet-ids" {
  type = "list"
}
variable "vpc-sg-ids" {
  type = "list"
}
variable "key-name" {}
variable "bastion-ip" {}
variable "imex-cidrs" {
  type = "list"
}
variable "setup-scripts" {
  type = "list"
}

data "aws_route53_zone" "selected" {
  name = "${var.domain}"
  private_zone = false
}

resource "aws_instance" "EC2" {
  count = "${var.numberOfInstances}"
  ami           = "${var.ami-id}"
  instance_type = "${var.instance-type}"

  key_name = "${var.key-name}"
  root_block_device = {
    volume_type = "${var.volume-type}"
    volume_size = "${var.volume-size}"
  }
  subnet_id = "${var.subnet-ids[count.index]}"
  vpc_security_group_ids = ["${var.vpc-sg-ids}"]

  ##### Provisioners #####

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/${var.key-name}.pem")}"
  }

  # firewall & hostname setup
  provisioner "remote-exec" {
    inline = [
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "sudo ufw allow from ${var.imex-cidrs[0]} to any port 22",
      "sudo ufw allow from ${var.imex-cidrs[1]} to any port 22",
      "sudo ufw allow from ${var.imex-cidrs[2]} to any port 22",
      "sudo ufw allow from ${var.imex-cidrs[3]} to any port 22",
      "sudo ufw allow from ${var.bastion-ip} to any port 22",
      "yes | sudo ufw enable",
      "sudo hostnamectl set-hostname ${var.name}${count.index+1}${var.env}.${var.domain}"
    ]
  }

  # setup scripts
  provisioner "remote-exec" {
    scripts = ["${var.setup-scripts}"]
  }

  tags = "${merge(var.tags, map("Env", var.env, "Name", var.name))}"
}

resource "aws_eip" "EC2" {
  count = "${var.numberOfInstances}"
  instance = "${element(aws_instance.EC2.*.id, count.index)}"
  vpc = true
}

resource "aws_route53_record" "CNAME" {
  count = "${var.numberOfInstances}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name = "${var.name}${count.index+1}${var.env}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_eip.EC2.*.public_ip, count.index)}"]
}

output "Server-EIP" {
  value = "${aws_eip.EC2.*.public_ip}"
}

output "Server-PrivateIP" {
  value = "${aws_instance.EC2.*.private_ip}"
}

output "Server-Domain" {
  value = "${aws_route53_record.CNAME.*.fqdn}"
}