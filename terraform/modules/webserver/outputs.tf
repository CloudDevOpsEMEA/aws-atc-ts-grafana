# WebServer Public IP Addresses
output "webserver_public_ips" {
  description = "List of WebServer public IP addresses"
  value       = aws_instance.webserver[*].public_ip
}

# WebServer Private IP Addresses
output "webserver_private_ips" {
  description = "List of WebServer private IP addresses"
  value       = aws_instance.webserver[*].private_ip
}

# WebServer Public DNS Names
output "webserver_public_dns" {
  description = "List of WebServer public DNS Names"
  value       = aws_instance.webserver[*].public_dns
}
