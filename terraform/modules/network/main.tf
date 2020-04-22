#
# Create the VPC 
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc-%s", var.owner, var.random_id)
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = [var.availability_zone]

  public_subnets = ["10.0.0.0/24"]

  vpc_tags = {
    Name        = format("%s-vpc-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }

  public_subnet_tags = {
    Name        = format("%s-pub-subnet-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }

  public_route_table_tags = {
    Name        = format("%s-pub-rt-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }

  igw_tags = {
    Name        = format("%s-igw-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}
