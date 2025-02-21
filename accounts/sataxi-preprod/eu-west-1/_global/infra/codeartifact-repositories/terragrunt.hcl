include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-codeartifact-repositories?master"
}

dependency "batch_job_deploy_lambda" {
  config_path = "${dirname(get_terragrunt_dir())}/../lambda-functions/batch-job-deploy"
}

inputs = {
  domain = "sataxi"
  repositories = [
    {
      name                = "sataxi-pypi"
      external_connection = "public:pypi"
    },
    {
      name                = "sataxi-npm"
      external_connection = "public:npmjs"
    }
  ]
  permissions_policy = {
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codeartifact:PublishPackageVersion",
          "codeartifact:DescribePackageVersion",
          "codeartifact:DescribeRepository",
          "codeartifact:GetPackageVersionReadme",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ListPackages",
          "codeartifact:ListPackageVersions",
          "codeartifact:ListPackageVersionAssets",
          "codeartifact:ListPackageVersionDependencies",
          "codeartifact:ReadFromRepository"
        ],
        Effect    = "Allow",
        Principal = "*"
        Resource  = "*"
      }
    ]
  }
}
