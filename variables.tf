variable "name_prefix" {
  description = "Prefix used for naming ECS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region, used for CloudWatch log configuration"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the ALB target group is created in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ECS/Fargate tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID for the ECS tasks"
  type        = string
}

variable "container_image" {
  description = "Container image to run (e.g. nginx:1.27 or a placeholder backend image)"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Environment variables passed to the app container"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Path the ALB target group uses for health checks"
  type        = string
  default     = "/"
}

variable "task_cpu" {
  description = "Fargate task CPU units (e.g. 256, 512)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate task memory in MB (e.g. 512, 1024)"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_container_insights" {
  description = "Whether to enable ECS Container Insights"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to ECS resources"
  type        = map(string)
  default     = {}
}
