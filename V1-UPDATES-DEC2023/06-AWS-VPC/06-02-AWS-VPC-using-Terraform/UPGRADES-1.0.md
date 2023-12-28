# Terraform Manifest Upgrades

## Step-01: c1-versions.tf
```t
# Terraform Block
terraform {
  required_version = ">= 1.6" # which means any version equal & above 0.14 like 0.15, 0.16 etc and < 1.xx
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }        
  }
}
```

## Step-02: c4-02-vpc-module.tf
```t
  source  = "terraform-aws-modules/vpc/aws"
  #version = "2.78.0"
  #version = "~> 2.78"
  version = "5.2.0"
```
