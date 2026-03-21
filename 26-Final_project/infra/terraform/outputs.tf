output "app_instance_public_ip" {
  description = "Public IP of the app EC2 instance"
  value       = aws_instance.app.public_ip
}

output "monitoring_instance_public_ip" {
  description = "Public IP of the monitoring EC2 instance"
  value       = aws_instance.monitoring.public_ip
}

output "app_instance_private_ip" {
  description = "Private IP of the app EC2 instance (used in prometheus.yml)"
  value       = aws_instance.app.private_ip
}

output "monitoring_instance_private_ip" {
  description = "Private IP of the monitoring EC2 instance (used in Promtail config)"
  value       = aws_instance.monitoring.private_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint — use as DB_HOST in app and GitHub Actions secrets"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "app_url" {
  description = "App URL via ALB"
  value       = "http://${aws_lb.app.dns_name}"
}

output "grafana_url" {
  description = "Grafana dashboard URL (stable EIP)"
  value       = "http://${aws_eip.monitoring.public_ip}:3000"
}
