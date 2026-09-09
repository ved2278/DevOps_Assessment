############################################
# Dev environment
# Internet -> ALB -> ECS/Fargate -> RDS
############################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend by design: this assessment must run "terraform init"
  # without depending on a pre-existing S3 bucket/DynamoDB lock table.
  # For a real deployment, swap this for an S3 backend with state locking
  # (see backend.tf for the commented-out example).
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  name_prefix = "hotelbooking-dev"
  common_tags = {
    Project     = "hotelbooking"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix           = local.name_prefix
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  enable_nat_gateway     = var.enable_nat_gateway
  container_port         = var.container_port
  db_port                = var.db_port
  tags                   = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix              = local.name_prefix
  private_subnet_ids       = module.network.private_subnet_ids
  rds_security_group_id    = module.network.rds_security_group_id
  engine                   = var.db_engine
  engine_version           = var.db_engine_version
  instance_class           = var.db_instance_class
  allocated_storage        = var.db_allocated_storage
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password
  db_port                  = var.db_port
  multi_az                 = var.db_multi_az
  backup_retention_period  = var.db_backup_retention_period
  deletion_protection      = var.db_deletion_protection
  tags                     = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix            = local.name_prefix
  aws_region             = var.aws_region
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_subnet_ids     = module.network.private_subnet_ids
  alb_security_group_id  = module.network.alb_security_group_id
  ecs_security_group_id  = module.network.ecs_security_group_id
  container_image        = var.container_image
  container_port         = var.container_port
  desired_count           = var.ecs_desired_count
  task_cpu                = var.ecs_task_cpu
  task_memory              = var.ecs_task_memory
  container_environment   = {
    DB_HOST = module.rds.db_address
    DB_NAME = module.rds.db_name
  }
  tags = local.common_tags
}
