variable "name_prefix" {
  description = "Prefix used for naming RDS resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs the DB subnet group will use"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID that is allowed to reach the database"
  type        = string
}

variable "engine" {
  description = "Database engine: postgres or mysql"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be either \"postgres\" or \"mysql\"."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t4g.micro for dev, db.t4g.medium for prod)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "hotelbooking"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "app_admin"
}

variable "db_password" {
  description = "Master password for the database. Pass via TF_VAR_db_password or a secrets manager, never commit it."
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ standby (recommended for prod)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to RDS resources"
  type        = map(string)
  default     = {}
}
