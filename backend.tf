# Backend configuration notes for the dev environment.
#
# This environment uses a local backend (declared in main.tf) on purpose,
# so `terraform init` and `terraform plan -refresh=false` work without any
# pre-existing AWS state infrastructure. See backend.tf.example-s3 for how
# to switch to a real S3 + DynamoDB backend when actually deploying.
