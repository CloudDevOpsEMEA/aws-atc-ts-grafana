#
# Create EC2 Key Pair
#
resource "tls_private_key" "ec2_private_key" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = format("%s-ec2-key-pair-%s", var.owner, var.random_id)
  public_key = tls_private_key.ec2_private_key.public_key_openssh
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", var.owner, var.random_id)

  tags = {
    Name        = format("%s-bigip-secret-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}
resource "aws_secretsmanager_secret_version" "bigip_pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = var.bigip_admin_password
}

#
# Create a security group for port 80 traffic
#
module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = format("%s-webserver-sg-%s", var.owner, var.random_id)
  description = "Security group for web-server with HTTP ports"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for BIG-IP virtual server ports
#
module "bigip_vip_range_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-bigip-vip-range-sg-%s", var.owner, var.random_id)
  description = "Security group for BIG-IP virtual server ports"
  vpc_id      = var.vpc_id

  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = ["::/0"]
  egress_rules            = ["all-all"]

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8099
      protocol    = "tcp"
      description = "BIG-IP virtual server ports"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

#
# Create a security group for port 8443 traffic
#
module "bigip_mgmt_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-8443"

  name        = format("%s-bigip-mgmt-sg-%s", var.owner, var.random_id)
  description = "Security group for BIG-IP MGMT Interface"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for SSH traffic
#
module "ssh_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = format("%s-ssh-sg-%s", var.owner, var.random_id)
  description = "Security group for SSH ports open within VPC"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for Grafana dashboard
#
module "grafana_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/grafana"

  name        = format("%s-grafana-sg-%s", var.owner, var.random_id)
  description = "Security group for Grafana Dashboard"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Create a security group for Graphite/StatsD dashboard
#
module "graphite_statsd_sg" {
  source = "github.com/boeboe/terraform-aws-security-group//modules/graphite-statsd?ref=v3.7.0.2"

  name        = format("%s-graphite-statsd-sg-%s", var.owner, var.random_id)
  description = "Security group for Graphite and StatsD"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}
