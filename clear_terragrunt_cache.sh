#!/bin/bash

echo "Removing terragrunt-cache files"
find . -type d -name ".terragrunt-cache" -prune -print -exec rm -rf {} \;
echo "Removing erraform.lock.hcl files"
find . -type f -name ".terraform.lock.hcl" -print -exec rm -f {} \;

