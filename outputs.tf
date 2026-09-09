output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = module.ecs.alb_dns_name
}

output "db_endpoint" {
  description = "RDS connection endpoint (private, reachable only from ECS)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}
