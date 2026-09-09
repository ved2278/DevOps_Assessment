output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "Connection endpoint for the database (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Hostname of the database, without port"
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}
