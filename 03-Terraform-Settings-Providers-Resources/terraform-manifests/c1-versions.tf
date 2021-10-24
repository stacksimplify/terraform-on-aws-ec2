# Terraform Block
terraform {
  required_version = "~> 1.0" # which means any version equal & above 1.0 like 1.1, 1.2 etc 
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  } 
}  
# Provider Block
provider "aws" {
  region = "us-east-1"
}

/*
Note-1:  AWS Credentials Profile (profile = "default") configured on your local desktop terminal  
$HOME/.aws/credentials
*/

