# Dev environment sizing.
# db_password is intentionally NOT set here — export TF_VAR_db_password
# before running terraform, or wire this up to a secrets manager.

aws_region = "us-east-1"

enable_nat_gateway = true

container_image = "public.ecr.aws/nginx/nginx:1.27"
container_port  = 80

ecs_desired_count = 1
ecs_task_cpu      = "256"
ecs_task_memory   = "512"

db_engine          = "postgres"
db_engine_version  = "16.4"
db_instance_class  = "db.t4g.micro"
db_allocated_storage = 20

db_multi_az                = false
db_backup_retention_period = 1
db_deletion_protection     = false
