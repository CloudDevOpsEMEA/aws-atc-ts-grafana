# Big-IP Data
output "bigip_data" {
  value = <<EOF
  
      bigip_private_ips : ${join(", ", module.bigip.bigip_private_ips)}
      bigip_public_ips  : ${join(", ", module.bigip.bigip_public_ips)}
      bigip_public_dns  : ${join(", ", module.bigip.bigip_public_dns)}
      bigip_mgmt_url    : https://${module.bigip.bigip_primary_public_dns}:8443
      aws_secret_name   : ${module.security.ec2_key_name}
    EOF
}

# WebServers Nginx
output "webservers_nginx_one" {
  value = <<EOF

      private_ips : ${join(", ", module.nginx_webserver_one.webserver_private_ips)}
      public_ips  : ${join(", ", module.nginx_webserver_one.webserver_public_ips)}
      public_dns  : ${join(", ", module.nginx_webserver_one.webserver_public_dns)}
    EOF
}

output "webservers_nginx_two" {
  value = <<EOF

      private_ips : ${join(", ", module.nginx_webserver_two.webserver_private_ips)}
      public_ips  : ${join(", ", module.nginx_webserver_two.webserver_public_ips)}
      public_dns  : ${join(", ", module.nginx_webserver_two.webserver_public_dns)}
    EOF
}

# WebServers Broken
output "webservers_broken" {
  value = <<EOF

      private_ips : ${join(", ", module.broken_webserver.webserver_private_ips)}
      public_ips  : ${join(", ", module.broken_webserver.webserver_public_ips)}
      public_dns  : ${join(", ", module.broken_webserver.webserver_public_dns)}
    EOF
}

# Graphite and Grafana
output "graphite_grafana" {
  value = <<EOF
  
      private_ips  : ${module.graphite_grafana.graphite_grafana_private_ip}
      public_ips   : ${module.graphite_grafana.graphite_grafana_public_ip}
      public_dns   : ${module.graphite_grafana.graphite_grafana_public_dns}
      graphite_url : http://${module.graphite_grafana.graphite_grafana_public_dns}
      grafana_url  : http://${module.graphite_grafana.graphite_grafana_public_dns}:3000
    EOF
}