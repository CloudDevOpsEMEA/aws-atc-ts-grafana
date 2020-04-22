variable "owner" {
  description = "Owner for resources created by this module"
  type        = string
  default     = "terraform-aws-bigip-demo"
}

variable "environment" {
  description = "Environment tag for resources created by this module"
  type        = string
  default     = "demo"
}

variable "random_id" {
  description = "A random id used for the name wihtin tags"
  type        = string
}

variable "vpc_subnet_id" {
  description = "The id of the target subnet"
  type        = string
}

variable "sec_group_ids" {
  description = "The ids of the target security groups"
  type        = list(string)
}

variable "ec2_key_name" {
  description = "The name of the SSH key to use for the EC2 instances"
  type        = string
}

variable "server_count" {
  description = "The number of webservers"
  type        = number
}

variable "tenant" {
  description = "The Big-IP tenant that will manage this server"
  type        = string
}

variable "application" {
  description = "The Big-IP application that will expose this server"
  type        = string
}

variable "autodiscovery_tag" {
  description = "AWS tag used by BIG-IP for autodiscovery"
  type        = string
}

variable "docker_command" {
  description = "The docker command to start the webserver"
  type        = string
}
