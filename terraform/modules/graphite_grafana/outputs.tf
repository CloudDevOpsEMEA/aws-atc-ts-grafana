# Graphite and Grafana Public IP Address
output "graphite_grafana_public_ip" {
  description = "Graphite and Grafana public IP addresses"
  value       = aws_instance.graphite_grafana.public_ip
}

# Graphite and Grafana Private IP Address
output "graphite_grafana_private_ip" {
  description = "Graphite and Grafana private IP addresses"
  value       = aws_instance.graphite_grafana.private_ip
}

# Graphite and Grafana Public DNS Name
output "graphite_grafana_public_dns" {
  description = "Graphite and Grafana public DNS Names"
  value       = aws_instance.graphite_grafana.public_dns
}
