variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway (costs money; can disable for plan-only review)"
  type        = bool
  default     = true
}

variable "container_image" {
  description = "Container image for the app service"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27"
}

variable "container_port" {
  description = "Port the app container listens on"
  type        = number
  default     = 80
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "ecs_task_cpu" {
  description = "Fargate task CPU units"
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Fargate task memory in MB"
  type        = string
  default     = "1024"
}

variable "db_engine" {
  description = "Database engine: postgres or mysql"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class for prod (larger, tuned for real load)"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "hotelbooking"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "app_admin"
}

variable "db_password" {
  description = "Master password. Must be supplied via TF_VAR_db_password or a secrets manager — no default in prod."
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "Multi-AZ standby (on in prod for availability)"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Automated backup retention in days (longer in prod)"
  type        = number
  default     = 30
}

variable "db_deletion_protection" {
  description = "Deletion protection (on in prod to prevent accidental destroy)"
  type        = bool
  default     = true
}
