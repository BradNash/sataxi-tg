include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/ssm-parameter-store/aws?version=0.9.1"
}

inputs = {
  parameter_write = [
    {
      name        = "/cicd/npm/npm_username"
      value       = "bbdnet2369"
      type        = "SecureString"
      overwrite   = "true"
      description = "NPM username to login"
    },
    {
      name        = "/cicd/npm/npm_password"
      value       = "WelcomeBP@2369"
      type        = "SecureString"
      overwrite   = "true"
      description = "NPM password to login"
    },
    {
      name        = "/cicd/npm/npm_email"
      value       = "bradleyp@bbd.co.za"
      type        = "SecureString"
      overwrite   = "true"
      description = "NPM email to login"
    }
  ]

  tags = {
    Environment = "cicd"
    Owner       = "Terraform OPS"
    CreatedBy   = "Terraform Framework"
  }
}
