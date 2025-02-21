include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-ssm-parameter-secrets?ref=master"
}

inputs = {
  paramaters = [
  ]
}
