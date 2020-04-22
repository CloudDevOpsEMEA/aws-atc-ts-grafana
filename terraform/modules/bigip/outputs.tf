# BIG-IP Public IP Address
output "bigip_public_ip" {
  description = "The BIG-IP public IP address"
  value       = aws_eip.bigip_eip.public_ip
}

# BIG-IP Public DNS
output "bigip_public_dns" {
  description = "The BIG-IP public DNS record"
  value       = aws_eip.bigip_eip.public_dns
}

# BIG-IP Private IP Address
output "bigip_private_ip" {
  description = "The BIG-IP private IP address"
  value       = sort(aws_network_interface.bigip_interface.private_ips)[0]

}
