# Terraform Settings Block
terraform {

cloud {
  organization = "BarrantesOrg"
  workspaces {
    name = "Terraform-Udemy"
  }
}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "~> 5.0" # Optional but recommended in production
    }
  }
}

# Provider Block
provider "aws" {
  profile = "default" # AWS Credentials Profile configured on your local desktop terminal  $HOME/.aws/credentials
  region  = "us-west-1"
}

# Resource Block
resource "aws_instance" "ec2demo" {
  ami           = "ami-0c716727a318bbe42" # Redhat us-west-1, update as per your region
  instance_type = "t2.micro"
}
