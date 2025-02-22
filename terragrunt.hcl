# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  # environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
  account_name        = local.account_vars.locals.account_name
  account_id          = local.account_vars.locals.aws_account_id
  aws_region          = local.region_vars.locals.aws_region
  aws_profile         = local.account_vars.locals.aws_profile
  state_bucket_region = "af-south-1"
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider_overide.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 0.14.8"
}

provider "aws" {
  region = "${local.aws_region}"
  profile = "${local.aws_profile}"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account_id}"]
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "terraform-state-${local.account_name}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.state_bucket_region}"
    profile        = "${local.aws_profile}"
    dynamodb_table = "terraform-locks"

    s3_bucket_tags = {
      Name        = "Terraform State Files"
      Environment = "terraform-state"
    }

  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account service-configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  #local.environment_vars.locals,
)
