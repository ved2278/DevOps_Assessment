# Backend configuration notes for the prod environment.
#
# This environment uses a local backend (declared in main.tf) so that
# `terraform init` and `terraform plan -refresh=false` work without any
# pre-existing AWS state infrastructure. In a real prod deployment this
# MUST be swapped for a remote backend with locking (S3 + DynamoDB, or
# Terraform Cloud) so state is shared safely across the team.
