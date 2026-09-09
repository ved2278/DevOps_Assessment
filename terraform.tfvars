# Prod environment sizing.
# db_password has no default — export TF_VAR_db_password before running
# terraform, or wire this up to a secrets manager (e.g. AWS Secrets Manager
# + a data source, omitted here to keep the assessment scope focused).

aws_region = "us-east-1"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]

enable_nat_gateway = true

container_image = "public.ecr.aws/nginx/nginx:1.27"
container_port  = 80

ecs_desired_count = 2
ecs_task_cpu      = "512"
ecs_task_memory   = "1024"

db_engine            = "postgres"
db_engine_version    = "16.4"
db_instance_class    = "db.t4g.medium"
db_allocated_storage = 100

db_multi_az                = true
db_backup_retention_period = 30
db_deletion_protection     = true
