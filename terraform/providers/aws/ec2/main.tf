variable "environment" { }
variable "owner" { }
variable "region" { }

variable "availability_zones" { }
variable "vpc_id" { }
variable "vpc_cidr" { }
variable "route_table_id" { }
variable "subnet_cidrs" { }
variable "subnet_type" { }
variable "public_ip_required" { }
variable "default_sg_ids" { default = "" }

variable "image" { }
variable "flavor" { }
variable "service" { }
variable "app" { }
variable "count" { }

provider "aws" {
  region = "${var.region}"
}

module subnets {
  source = "../network/subnet"

  name               = "${var.service}-${var.app}"
  environment        = "${var.environment}"
  owner              = "${var.owner}"
  vpc_id             = "${var.vpc_id}"
  cidrs              = "${var.subnet_cidrs}"
  region             = "${var.region}"
  availability_zones = "${var.availability_zones}"
  route_table_ids    = "${var.route_table_id}"
  subnet_type        = "${var.subnet_type}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/userdata.sh.tpl")}"

  # userdata variables
  vars {}
}

resource "aws_instance" "nodes" {
  count                  = "${var.count}"
  ami                    = "${var.image}"
  instance_type          = "${var.flavor}"
  availability_zone      = "${element(split(",",var.availability_zones),count.index)}"
  vpc_security_group_ids = ["${split(",", replace("${aws_security_group.sg.id},${var.default_sg_ids}", "/,$/", ""))}"]
  subnet_id              = "${element(split(",", module.subnets.subnet_ids), count.index)}"
  associate_public_ip_address = "${var.public_ip_required}"

  root_block_device {
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = "${data.template_file.userdata.rendered}"

  lifecycle { create_before_destroy = true }

  tags {
    Name               = "${var.service}-${var.app}-${format("%02d", count.index+1)}"
    Environment        = "${var.environment}"
    Service            = "${var.service}"
    App                = "${var.app}"
    Owner              = "${var.owner}"
  }
}

output "instance_ids"   { value = "${join(",", aws_instance.nodes.*.id)}" }
output "instance_ips"   { value = "${join(",", aws_instance.nodes.*.private_ip)}" }