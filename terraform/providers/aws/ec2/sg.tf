#
# Security group for the node
#
resource "aws_security_group" "sg" {
  name = "${var.service}-${var.app}"
  description = "${var.app} security group"
  vpc_id = "${var.vpc_id}"

  lifecycle { create_before_destroy = true }

  ingress { # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  egress { # ICMP
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [ "${var.vpc_cidr}" ]
  }
  egress { # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.service}-${var.app}"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
  }
}