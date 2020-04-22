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

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 Networks BIGIP-14.* PAYG - Best 200Mbps*"
}

variable "f5_instance_count" {
  description = "Number of BIG-IPs to deploy"
  type        = number
  default     = 1
}

variable "application_endpoint_count" {
  description = "number of public application addresses to assign"
  type        = number
  default     = 2
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "m4.large"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
}

variable "vpc_subnet_id" {
  description = "AWS VPC Subnet id for BIG-IP"
  type        = string
}

variable "bigip_eip" {
  description = "Enable an Elastic IP address for BIG-IP"
  type        = bool
  default     = true
}

variable "subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP"
  type        = list
  default     = []
}

variable "bigip_pw_secret_id" {
  description = "The AWS secret id for the BIG-IP password"
  type        = string
}

variable "do_version" {
  description = "The version for F5 ATC Declarative Onboarding (DO)"
  type        = string
}

variable "as3_version" {
  description = "The version for F5 ATC Application Services 3 (AS3)"
  type        = string
}

variable "ts_version" {
  description = "The version for F5 ATC Telemetry Streaming (TS)"
  type        = string
}

variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  type        = string
  default     = "/config/cloud/aws/node_modules"
}

variable "onboard_log" {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  type        = string
  default     = "/var/log/startup-script.log"
}
