#
# Read setup specific variables from external yaml file
#
locals {
  setup = yamldecode(file(var.setupfile))
}

data "http" "example" {
  url = "https://checkpoint-api.hashicorp.com/v1/check/terraform"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

#
# Provider section
#
provider "aws" {
  region     = local.setup.aws.region
  access_key = local.setup.aws.access_key_id
  secret_key = local.setup.aws.secret_access_key
}

provider "local" {
  version = "~> 1.4"
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

#
# Create a random id used in the name of all resources
#
resource "random_id" "id" {
  byte_length = 2

}

#
# Create network components (vpc)
#
module network {
  source = "./modules/network"

  owner             = local.setup.owner
  environment       = local.setup.aws.environment
  random_id         = random_id.id.hex
  availability_zone = local.setup.aws.availability_zone
}

#
# Create security components (security groups)
#
module security {
  source = "./modules/security"

  owner                = local.setup.owner
  environment          = local.setup.aws.environment
  random_id            = random_id.id.hex
  bigip_admin_password = local.setup.bigip.admin_password
  vpc_id               = module.network.vpc_id
  vs_from_port         = local.setup.aws.vs_from_port
  vs_to_port           = local.setup.aws.vs_to_port
}

#
# Create BIG-IP (1 NIC)
#
module bigip {
  source = "./modules/bigip"

  owner       = local.setup.owner
  environment = local.setup.aws.environment
  random_id   = random_id.id.hex

  ec2_key_name       = module.security.ec2_key_name
  bigip_pw_secret_id = module.security.bigip_pw_secret_id
  ec2_instance_type  = local.setup.bigip.ec2_instance_type

  do_version  = local.setup.bigip.do_version
  as3_version = local.setup.bigip.as3_version
  ts_version  = local.setup.bigip.ts_version
  cfe_version = local.setup.bigip.cfe_version

  subnet_security_group_ids = [
    module.security.ssh_secure_sg,
    module.security.bigip_vip_range_sg,
    module.security.bigip_mgmt_secure_sg
  ]

  vpc_subnet_id      = module.network.vpc_subnet_id
  f5_ami_search_name = local.setup.bigip.ami_search_name
  extra_private_ips  = local.setup.bigip.extra_private_ips
}

#
# Create Nginx WebServers
#
module nginx_webserver_one {
  source = "./modules/webserver"

  owner         = local.setup.owner
  environment   = local.setup.aws.environment
  random_id     = random_id.id.hex
  vpc_subnet_id = module.network.vpc_subnet_id
  ec2_key_name  = module.security.ec2_key_name
  server_count  = local.setup.webservers.nginx_one.count

  sec_group_ids = [
    module.security.ssh_secure_sg,
    module.security.web_server_sg
  ]

  tenant            = local.setup.webservers.nginx_one.tenant
  application       = local.setup.webservers.nginx_one.application
  autodiscovery_tag = local.setup.webservers.nginx_one.autodiscovery_tag
  docker_command    = local.setup.webservers.nginx_one.docker_command
}

module nginx_webserver_two {
  source = "./modules/webserver"

  owner         = local.setup.owner
  environment   = local.setup.aws.environment
  random_id     = random_id.id.hex
  vpc_subnet_id = module.network.vpc_subnet_id
  ec2_key_name  = module.security.ec2_key_name
  server_count  = local.setup.webservers.nginx_two.count

  sec_group_ids = [
    module.security.ssh_secure_sg,
    module.security.web_server_sg
  ]

  tenant            = local.setup.webservers.nginx_two.tenant
  application       = local.setup.webservers.nginx_two.application
  autodiscovery_tag = local.setup.webservers.nginx_two.autodiscovery_tag
  docker_command    = local.setup.webservers.nginx_two.docker_command
}

#
# Create Broken WebServers
#
module broken_webserver {
  source = "./modules/webserver"

  owner         = local.setup.owner
  environment   = local.setup.aws.environment
  random_id     = random_id.id.hex
  vpc_subnet_id = module.network.vpc_subnet_id
  ec2_key_name  = module.security.ec2_key_name
  server_count  = local.setup.webservers.broken.count

  sec_group_ids = [
    module.security.ssh_secure_sg,
    module.security.web_server_sg
  ]

  tenant            = local.setup.webservers.broken.tenant
  application       = local.setup.webservers.broken.application
  autodiscovery_tag = local.setup.webservers.broken.autodiscovery_tag
  docker_command    = local.setup.webservers.broken.docker_command
}

#
# Create Graphite Instance
#
module graphite_grafana {
  source = "./modules/graphite_grafana"

  owner         = local.setup.owner
  environment   = local.setup.aws.environment
  random_id     = random_id.id.hex
  vpc_subnet_id = module.network.vpc_subnet_id
  ec2_key_name  = module.security.ec2_key_name

  sec_group_ids = [
    module.security.web_server_sg,
    module.security.grafana_sg,
    module.security.graphite_statsd_sg
  ]
}

#
# Write output files
#
resource "local_file" "ec2_private_key" {
  content         = module.security.ec2_private_key
  filename        = var.ec2privatekey
  file_permission = "400"
}

data "template_file" "ansible_dynamic_inventory_config" {
  template = file("${path.module}/templates/aws_ec2.yml.tpl")
  vars = {
    region      = local.setup.aws.region
    environment = local.setup.aws.environment
  }
}

resource "local_file" "ansible_dynamic_inventory_config" {
  content  = data.template_file.ansible_dynamic_inventory_config.rendered
  filename = var.awsinventoryconfig
}

data "template_file" "generate_load_script" {
  template = file("${path.module}/templates/generate_load.sh.tpl")
  vars = {
    bigip_address = module.bigip.bigip_public_dns[0]
  }
}

resource "local_file" "generate_load_script" {
  content  = data.template_file.generate_load_script.rendered
  filename = var.generateloadscript
}
