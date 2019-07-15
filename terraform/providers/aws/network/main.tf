variable "environment" { }
variable "region" { }
variable "service" { }
variable "owner" { }

variable "vpc_domain" { }
variable "vpc_cidr" { }
variable "zone_count" { default = 1 }

variable "nat_azs" { }
variable "nat_cidrs" { }
variable "nat_eip_ids" { }
variable "default_sg_ids" { default = ""}

provider "aws" {
  region = "${var.region}"
}

resource "aws_route53_zone" "root" {
  count      = "${var.zone_count}"
  name       = "${var.vpc_domain}"
  comment    = "${var.environment} private domain"
  vpc_id     = "${module.vpc.vpc_id}"
  vpc_region = "${var.region}"

  lifecycle { create_before_destroy = true }

  tags {
    Name        = "${var.environment}-dns"
    Environment = "${var.environment}"
  }
}

module "vpc" {
  source = "./vpc"

  environment         = "${var.environment}"
  service             = "${var.service}"
  owner               = "${var.owner}"
  region              = "${var.region}"
  vpc_cidr            = "${var.vpc_cidr}"
}

module "nat" {
  source = "./nat"

  environment           = "${var.environment}"
  service               = "${var.service}"
  owner                 = "${var.owner}"
  region                = "${var.region}"
  availability_zones    = "${var.nat_azs}"
  vpc_cidr              = "${var.vpc_cidr}"
  vpc_id                = "${module.vpc.vpc_id}"
  subnet_cidrs          = "${var.nat_cidrs}"
  route_table_id        = "${module.vpc.public_route_table_id}"
  eip_ids               = "${var.nat_eip_ids}"
}


# VPC
output "vpc_id"                  { value = "${module.vpc.vpc_id}" }
output "vpc_zone_id"             { value = "${aws_route53_zone.root.zone_id}" }
output "vpc_default_sg_id"       { value = "${module.vpc.default_security_group_id}" }
output "public_route_table_id"   { value = "${module.vpc.public_route_table_id}" }
output "private_route_table_ids" { value = "${module.nat.private_route_table_ids}" }

# NAT
output "nat_private_ips"  { value = "${module.nat.private_ips}" }
output "nat_public_ips"   { value = "${module.nat.public_ips}" }