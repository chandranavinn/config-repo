output "rds_endpoint" {
  description = "Private PostgreSQL endpoint."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "PostgreSQL port."
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Initial application database."
  value       = aws_db_instance.postgres.db_name
}

output "master_secret_arn" {
  description = "AWS-managed Secrets Manager secret containing the RDS administrator credentials."
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

output "ssm_bridge_instance_id" {
  description = "Instance ID used for SSM remote-host port forwarding."
  value       = aws_instance.ssm_bridge.id
}

output "vpc_id" {
  description = "VPC to reuse when Cluster 1 EKS is added."
  value       = aws_vpc.main.id
}
