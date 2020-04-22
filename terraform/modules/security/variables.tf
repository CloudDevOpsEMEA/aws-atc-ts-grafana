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

variable "bigip_admin_password" {
  description = "The BIG-IP admin password"
  type        = string
}

variable "vpc_id" {
  description = "The id of the vpc"
  type        = string
}

variable "vs_from_port" {
  description = "The id of the vpc"
  type        = number
  default     = 8080
}

variable "vs_to_port" {
  description = "The id of the vpc"
  type        = string
  default     = 8090
}
