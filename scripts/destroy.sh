#!/bin/bash
terraform init 
terraform fmt
terraform validate
terraform plan 
terraform destroy auto-approve
