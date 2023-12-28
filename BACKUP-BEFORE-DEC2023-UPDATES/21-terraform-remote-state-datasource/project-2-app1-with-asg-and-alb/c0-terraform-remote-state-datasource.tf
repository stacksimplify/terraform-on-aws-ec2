# Terraform Remote State Datasource
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-for-ec2"
    key    = "dev/project1-vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

/*
1. Security Group 
vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
ingress_cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]

2. Bastion Host
subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[0]

3. ALB
subnets = data.terraform_remote_state.vpc.outputs.public_subnets

4. ASG
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets 

5. Null Resource
    command = "echo VPC created on `date` and VPC ID: ${data.terraform_remote_state.vpc.outputs.vpc_id} >> creation-time-vpc-id.txt"
*/