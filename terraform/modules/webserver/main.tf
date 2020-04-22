data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "webserver" {
  count = var.server_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_name
  monitoring             = true
  vpc_security_group_ids = var.sec_group_ids
  subnet_id              = var.vpc_subnet_id

  # build user_data file from template
  user_data = templatefile(
    "${path.module}/bootstrap.sh",
    {
      DOCKER_COMMAND = var.docker_command
    }
  )

  tags = {
    Name          = format("%s-webserver-%s-%s", var.owner, var.autodiscovery_tag, var.random_id)
    Terraform     = "true"
    Environment   = var.environment
    Owner         = var.owner
    Role          = "webserver"
    Tenant        = var.tenant
    Application   = var.application
    Autodiscovery = var.autodiscovery_tag
  }
}
