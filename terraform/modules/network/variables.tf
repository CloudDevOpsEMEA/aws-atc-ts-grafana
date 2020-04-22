variable "owner" {
  description = "Owner for resources"
  type        = string
  default     = "terraform-aws-bigip-demo"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "demo"
}

variable "random_id" {
  description = "A random id used in the name for resources"
  type        = string
}

variable "availability_zone" {
  description = "The availability zone"
  type        = string
}
