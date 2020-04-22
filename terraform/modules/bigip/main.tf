#
# Fetch the release info and download URL for the ATC modules
#
data "http" "do_release_info" {
  url = format("https://api.github.com/repos/F5Networks/f5-declarative-onboarding/releases/tags/%s", var.do_version)

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "as3_release_info" {
  url = format("https://api.github.com/repos/F5Networks/f5-appsvcs-extension/releases/tags/%s", var.as3_version)

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "ts_release_info" {
  url = format("https://api.github.com/repos/F5Networks/f5-telemetry-streaming/releases/tags/%s", var.ts_version)

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  do_url  = regex(".*\"(https.*noarch.rpm)\"", data.http.do_release_info.body)[0]
  as3_url = regex(".*\"(https.*noarch.rpm)\"", data.http.as3_release_info.body)[0]
  ts_url  = regex(".*\"(https.*noarch.rpm)\"", data.http.ts_release_info.body)[0]
}

#
# Ensure Secret exists
#
data "aws_secretsmanager_secret" "password" {
  name = var.bigip_pw_secret_id
}

#
# Find BIG-IP AMI
#
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["${var.f5_ami_search_name}"]
  }
}

# 
# Create Network Interfaces
#
resource "aws_network_interface" "bigip_interface" {
  subnet_id         = var.vpc_subnet_id
  security_groups   = var.subnet_security_group_ids
  private_ips_count = var.extra_private_ips

  tags = {
    Name        = format("%s-mgmt-intf-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

data "aws_network_interface" "bigip_interface" {
  id = aws_network_interface.bigip_interface.id
}

#
# add an elastic IP to the BIG-IP management interface
#
resource "aws_eip" "bigip_eip" {
  count = 1 + var.extra_private_ips

  network_interface         = aws_network_interface.bigip_interface.id
  vpc                       = true
  associate_with_private_ip = sort(aws_network_interface.bigip_interface.private_ips)[count.index]

  tags = {
    Name        = format("%s-mgmt-eip-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

#
# Deploy BIG-IP
#
resource "aws_instance" "f5_bigip" {
  instance_type        = var.ec2_instance_type
  ami                  = data.aws_ami.f5_ami.id
  iam_instance_profile = aws_iam_instance_profile.bigip_profile.name
  key_name             = var.ec2_key_name
  monitoring           = true

  root_block_device {
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.bigip_interface.id
    device_index         = 0
  }

  user_data = templatefile(
    "${path.module}/f5_onboard.sh",
    {
      DO_URL      = local.do_url,
      AS3_URL     = local.as3_url,
      TS_URL      = local.ts_url,
      libs_dir    = var.libs_dir,
      onboard_log = var.onboard_log,
      secret_id   = var.bigip_pw_secret_id
    }
  )

  depends_on = [aws_eip.bigip_eip]

  tags = {
    Name        = format("%s-f5-bigip-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
    Role        = "bigip"
    CWLogGroup  = format("%s-f5-bigip-cloudwatch-lg-%s", var.owner, var.random_id)
    CWLogStream = format("%s-f5-bigip-cloudwatch-ls-%s", var.owner, var.random_id)
  }
}

resource "aws_cloudwatch_log_group" "f5_bigip_cloudwatch_lg" {
  name = format("%s-f5-bigip-cloudwatch-lg-%s", var.owner, var.random_id)

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_cloudwatch_log_stream" "f5_bigip_cloudwatch_ls" {
  name           = format("%s-f5-bigip-cloudwatch-ls-%s", var.owner, var.random_id)
  log_group_name = aws_cloudwatch_log_group.f5_bigip_cloudwatch_lg.name
}
