# BIG-IP Public IP Address
output "bigip_public_ips" {
  description = "The BIG-IP public IP addresses"
  value       = aws_eip.bigip_eip[*].public_ip
}

# BIG-IP Public DNS
output "bigip_public_dns" {
  description = "The BIG-IP public DNS records"
  value       = aws_eip.bigip_eip[*].public_dns
}

# BIG-IP Private IP Address
output "bigip_private_ips" {
  description = "The BIG-IP private IP addresses"
  value       = sort(aws_network_interface.bigip_interface.private_ips)
}

# BIG-IP Primary Public IP Address
output "bigip_primary_public_ip" {
  description = "The BIG-IP primary public IP addresses"
  value       = data.aws_network_interface.bigip_interface.association[0].public_ip
}

# BIG-IP Primary Public DNS
output "bigip_primary_public_dns" {
  description = "The BIG-IP primary DNS record"
  value       = data.aws_network_interface.bigip_interface.association[0].public_dns_name
}

# BIG-IP Primary Private IP Address
output "bigip_primary_private_ip" {
  description = "The BIG-IP primary private IP addresses"
  value       = data.aws_network_interface.bigip_interface.private_ip
}
