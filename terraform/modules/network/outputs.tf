# The id of this VPC
output "vpc_id" {
  description = "The id of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_subnet_id" {
  description = "The id of the subnet"
  value       = module.vpc.public_subnets[0]
}
