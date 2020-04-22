# The AWS EC2 private key
output "ec2_private_key" {
  description = "The AWS EC2 private key"
  value       = tls_private_key.ec2_private_key.private_key_pem
}

# The AWS EC2 key name
output "ec2_key_name" {
  description = "The AWS EC2 key name"
  value       = module.key_pair.this_key_pair_key_name
}

# The secret id for the BIG-IP password
output "bigip_pw_secret_id" {
  description = "The AWS secret id for the BIG-IP password"
  value       = aws_secretsmanager_secret.bigip.id
}

# Security group for port 80 traffic
output "web_server_sg" {
  description = "Security group for web-server with HTTP ports"
  value       = module.web_server_sg.this_security_group_id
}

# Security group for BIG-IP virtual server ports
output "bigip_vip_range_sg" {
  description = "Security group for BIG-IP virtual server ports"
  value       = module.bigip_vip_range_sg.this_security_group_id
}

# Security group for port 8443 traffic
output "bigip_mgmt_secure_sg" {
  description = "Security group for BIG-IP MGMT Interface"
  value       = module.bigip_mgmt_secure_sg.this_security_group_id

}

# Security group for SSH traffic
output "ssh_secure_sg" {
  description = "Security group for SSH ports open within VPC"
  value       = module.ssh_secure_sg.this_security_group_id

}

# Security group for Grafana dashboard
output "grafana_sg" {
  description = "Security group for Grafana Dashboard"
  value       = module.grafana_sg.this_security_group_id

}

# Security group for Graphite/StatsD dashboard
output "graphite_statsd_sg" {
  description = "Security group for Graphite and StatsD"
  value       = module.graphite_statsd_sg.this_security_group_id

}
