############################################
# RDS module
# Private database, only reachable from ECS
############################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  port                  = var.db_port
  db_subnet_group_name  = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]

  # RDS is intentionally private: no public access, only reachable
  # from the ECS security group via the SG rule created in the network module.
  publicly_accessible = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window            = "03:00-04:00"
  maintenance_window       = "mon:04:30-mon:05:30"

  deletion_protection = var.deletion_protection
  skip_final_snapshot  = var.deletion_protection ? false : true
  final_snapshot_identifier = var.deletion_protection ? "${var.name_prefix}-final-snapshot" : null

  apply_immediately = !var.deletion_protection

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db"
  })

  lifecycle {
    prevent_destroy = false
  }
}
