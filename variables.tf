variable "name_prefix" {
  description = "Prefix used for naming all network resources (e.g. hotelbook-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnet internet egress"
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Port the application container listens on, used to scope the ECS security group"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port the database listens on, used to scope the RDS security group"
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Common tags applied to all network resources"
  type        = map(string)
  default     = {}
}
