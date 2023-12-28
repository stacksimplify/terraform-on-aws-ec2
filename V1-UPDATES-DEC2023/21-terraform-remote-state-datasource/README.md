---
title: Terraform Remote State Datasource Demo
description: Terraform Remote State Datasource Demo with two projects
---
# Terraform Remote State Storage Demo with Project-1 and Project-2
## Step-01: Introduction
- Understand [Terraform Remote State Storage](https://www.terraform.io/docs/language/state/remote-state-data.html)
- Terraform Remote State Storage Demo with two projects

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-2.png)

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-3.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-3.png)

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-4.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-4.png)

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-5.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-5.png)

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-6.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-6.png)

[![Image](https://stacksimplify.com/course-images/terraform-remote-state-datasource-7.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-remote-state-datasource-7.png)

## Step-02: Copy Project 1 VPC from Section 19
- Copy `project-1-aws-vpc` from `19-Remote-State-Storage-with-AWS-S3-and-DynamoDB`

## Step-03: Copy Project 2 App1 with ASG and ALB from Section 15
- Copy `terraform-manifests\*` all files from Section `15-Autoscaling-with-Launch-Templates` and copy to `project-2-app1-with-asg-and-alb`

## Step-04: Remove VPC related TF Config Files from Project-2
- Remove the following 4 files related to VPC from Project-2 `project-2-app1-with-asg-and-alb`
- c4-01-vpc-variables.tf
- c4-02-vpc-module.tf
- c4-03-vpc-outputs.tf
- vpc.auto.tfvars

## Step-05: Project-2: c0-terraform-remote-state-datasource.tf 
- Create [terraform_remote_state Datasource](https://www.terraform.io/docs/language/state/remote-state-data.html) 
- In this datasource, we will provide the Terraform State file information of our Project-1-AWS-VPC
```t
# Terraform Remote State Datasource
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-for-ec2"
    key    = "dev/project1-vpc/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Step-06: Project-2: Update Security Groups VPC ID
- c5-03-securitygroup-bastionsg.tf
- c5-04-securitygroup-privatesg.tf
- c5-05-securitygroup-loadbalancersg.tf
```t
# Before
  vpc_id      = module.vpc.vpc_id
# After
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id 
```

## Step-07: Project-2: Update Bastion EC2 Instance VPC Subnet ID
- c7-03-ec2instance-bastion.tf
```t
# Before
  subnet_id = module.vpc.public_subnets[0]
# After
  subnet_id = data.terraform_remote_state.vpc.outputs.public_subnets[0]
```

## Step-08: Project-2: c8-elasticip.tf
```t
# Before
  depends_on = [ module.ec2_public, module.vpc ]
# After
  depends_on = [ module.ec2_public, /*module.vpc*/ ]
``` 

## Step-09: Project-2: c10-02-ALB-application-loadbalancer.tf
```t
# Before
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
# After
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id 
  subnets = data.terraform_remote_state.vpc.outputs.public_subnets
```

## Step-10: Project-2: c12-route53-dnsregistration.tf
```t
# Add DNS name relevant to demo
  name    = "tf-multi-app-projects.devopsincloud.com"
```
## Step-11: Project-2: Create S3 Bucket and DynamoDB Table for Remote State Storage
- Create S3 Bucket and DynamoDB Table for Remote State Storage
- Leverage Same S3 bucket `terraform-on-aws-for-ec2` with different folder for project-2 state file `dev/project2-app1/terraform.tfstate`
- Also create a new DynamoDB Table for project-2
- Create Dynamo DB Table
  - **Table Name:** dev-project2-app1
  - **Partition key (Primary Key):** LockID (Type as String)
  - **Table settings:** Use default settings (checked)
  - Click on **Create**

## Step-12: Project-2: c1-versions.tf
- Update `c1-versions.tf` with Remote State Backend
```t
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-on-aws-for-ec2"
    key    = "dev/project2-app1/terraform.tfstate"
    region = "us-east-1" 

    # Enable during Step-09     
    # For State Locking
    dynamodb_table = "dev-project2-app1"    
  }     
```
## Step-13: c13-03-autoscaling-resource.tf
```t
# Before
  vpc_zone_identifier = module.vpc.private_subnets

# After
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets 

```

## Step-14: Project-1: Execute Terraform Commands
- Create Project-1 Resources (VPC)
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Terraform State List
terraform state list

# Observations
1. Verify VPC Resources created
2. Verify S3 bucket and terraform.tfstate file for project-1
```

## Step-15: Project-2: Execute Terraform Commands
- Create Project-2 Resources (VPC)
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Terraform State List
terraform state list
```

## Step-16: Verify Project-2 Resources
1. Verify S3 bucket and terraform.tfstate file for project-2
2. Verify Security Groups
3. Verify EC2 Instances (Bastion Host and ASG related EC2 Instances)
4. Verify Application Load Balancer and Target Group
5. Verify Autoscaling Group and Launch template
6. Access Application and Test
```t
# Access Application
https://tf-multi-app-projects1.devopsincloud.com
https://tf-multi-app-projects1.devopsincloud.com/app1/index.html
https://tf-multi-app-projects1.devopsincloud.com/app1/metadata.html
```

## Step-17: Project-2 Clean-Up
```t
# Change Directory 
cd project-2-app1-with-asg-and-alb
# Terraform Destroy
terraform destroy -auto-approve

# Delete files
rm -rf .terraform*
```

## Step-18: Project-1 Clean-Up
```t
# Change Directory
cd project-1-aws-vpc

# Terraform Destroy
terraform destroy -auto-approve

# Delete files
rm -rf .terraform*
```




## References
- [The terraform_remote_state Data Source](https://www.terraform.io/docs/language/state/remote-state-data.html)
- [S3 as Remote State Datasource](https://www.terraform.io/docs/language/settings/backends/s3.html)