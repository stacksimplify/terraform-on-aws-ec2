---
title: AWS ALB Host Header based Routing using Terraform
description: Create AWS Application Load Balancer Host Header based Routing Rules usign Terraform
---

# AWS ALB Host Header based Routing using Terraform

## Pre-requisites
- You need a Registered Domain in AWS Route53 to implement this usecase
- Copy your `terraform-key.pem` file to `terraform-manifests/private-key` folder


## Step-01: Introduction
- Implement AWS ALB Host Header based Routing

[![Image](https://stacksimplify.com/course-images/terraform-aws-alb-host-header-based-routing-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-alb-host-header-based-routing-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-alb-host-header-based-routing-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-alb-host-header-based-routing-2.png)

## Step-02: Error Message realted AWS ACM Certificate Limit
- Review the AWS Support Case ID 8245155801 to demonstrate the issue and resolution from AWS
- Understand about how to submit the case related to Limit Increase for ACM Certificates.
- It will take 2 to 3 days to increase the limit and resolve the issue from AWS Side so if you want to ensure that before you hit the limit, if you want to increase you can submit the ticket well in advance.
```t
Error: Error requesting certificate: LimitExceededException: Error: you have reached your limit of 20 certificates in the last year.

  on .terraform/modules/acm/main.tf line 11, in resource "aws_acm_certificate" "this":
  11: resource "aws_acm_certificate" "this" {
```

## Step-03: Our Options to Continue
- **Option-1:** Submit the ticket to AWS and wait till they update the ACM certificate limit
- **Option-2:** Switch to other region and continue with our course. 
- This limit you can hit at any point during your next sections of the course where you exceeded 20 times of certificate creation and deletion.
- With that said knowing to run these Terraform Manifests in other region is a better option.
- I will show you the steps you can perform to switch the region using the terraform manifests if you face this issue.
- Use this folder `terraform-manifests-us-east-2` terraform manifests to create resources in us-east-2 region.
- Review `step-04` for changes we need to perform to switch regions. 

## Step-04: Terraform Configurations to change to run in US-EAST-2 Ohio Region
### Step-04-00: Update terraform.tfvars
```t
# Before
aws_region = "us-east-1"

# After
aws_region = "us-east-2"
```
### Step-04-01: Update vpc.auto.tfvars 
```t
# Before
vpc_availability_zones = ["us-east-1a", "us-east-1b"]

# After
vpc_availability_zones = ["us-east-2a", "us-east-2b"]
```
### Step-04-02: Create new EC2 Key pair in region us-east-2 Ohio
- Go to Services -> EC2 -> Network & Security -> Keypairs
- **Name:** terraform-key-us-east-2	
- **File Format:** pem
- Click on **Create keypair**
- You can have the keypair name same in us-east-2 region also so that you don't need to change anything in `c9-nullresource-provisioners.tf`. Choice is yours.
- To identify the difference, i have given different name here.

### Step-04-03: Copy newly created keypair to private-key folder
- Copy the newly created keypair `terraform-key-us-east-2.pem` to `terraform-manifests\private-key` folder

### Step-04-04: Give permissions as chmod 400
```
# KeyPair Permissions
cd terraform-manifests\private-key
chmod 400 terraform-key-us-east-2.pem
```

### Step-04-05: Update ec2instance.auto.tfvars
```t
# Before
instance_keypair = "terraform-key"

# After
#instance_keypair = "terraform-key"
instance_keypair = "terraform-key-us-east-2"
```

### Step-04-06: Update c9-nullresource-provisioners.tf
```t
# Create a Null Resource and Provisioners
resource "null_resource" "name" {
  depends_on = [module.ec2_public]
  # Connection Block for Provisioners to connect to EC2 Instance
  connection {
    type     = "ssh"
    host     = aws_eip.bastion_eip.public_ip    
    user     = "ec2-user"
    password = ""
    private_key = file("private-key/terraform-key-us-east-2.pem")
  }  

## File Provisioner: Copies the terraform-key.pem file to /tmp/terraform-key-us-east-2.pem
  provisioner "file" {
    source      = "private-key/terraform-key-us-east-2.pem"
    destination = "/tmp/terraform-key-us-east-2.pem"
  }
## Remote Exec Provisioner: Using remote-exec provisioner fix the private key permissions on Bastion Host
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/terraform-key-us-east-2.pem"
    ]
  }
## Local Exec Provisioner:  local-exec provisioner (Creation-Time Provisioner - Triggered during Create Resource)
  provisioner "local-exec" {
    command = "echo VPC created on `date` and VPC ID: ${module.vpc.vpc_id} >> creation-time-vpc-id.txt"
    working_dir = "local-exec-output-files/"
    #on_failure = continue
  }
```

## Step-05: c10-01-ALB-application-loadbalancer-variables.tf
- We will be using these variables in two places
  - c10-02-ALB-application-loadbalancer.tf
  - c12-route53-dnsregistration.tf
- If we are using the values in more than one place its good to variablize that value  
```t
# App1 DNS Name
variable "app1_dns_name" {
  description = "App1 DNS Name"
}

# App2 DNS Name
variable "app2_dns_name" {
  description = "App2 DNS Name"
}
```
## Step-06: loadbalancer.auto.tfvars
```t
# AWS Load Balancer Variables
app1_dns_name = "app16.devopsincloud.com"
app2_dns_name = "app26.devopsincloud.com"
```

## Step-06: c10-02-ALB-application-loadbalancer.tf
### Step-06-01: HTTPS Listener Rule-1
```t
      conditions = [{
        #path_patterns = ["/app1*"]
        host_headers = [var.app1_dns_name]
      }]
```
### Step-06-02: HTTPS Listener Rule-2
```t
      conditions = [{
        #path_patterns = ["/app2*"] 
        host_headers = [var.app2_dns_name]
      }]
```

## Step-07: c12-route53-dnsregistration.tf
### Step-07-01: App1 DNS
```t
## Default DNS
resource "aws_route53_record" "default_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = "myapps.devopsincloud.com"
  type    = "A"
  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = true
  }  
}

# DNS Registration 
## App1 DNS
resource "aws_route53_record" "app1_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = var.app1_dns_name
  type    = "A"
  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = true
  }  
}
```
### Step-07-02: App2 DNS
```t
## App2 DNS
resource "aws_route53_record" "app2_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = var.app2_dns_name
  type    = "A"
  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = true
  }  
}
```

## Step-08: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify
Observation: 
1. Verify EC2 Instances for App1
2. Verify EC2 Instances for App2
3. Verify Load Balancer SG - Primarily SSL 443 Rule
4. Verify ALB Listener - HTTP:80 - Should contain a redirect from HTTP to HTTPS
5. Verify ALB Listener - HTTPS:443 - Should contain 3 rules 
5.1 Host Header app1.devopsincloud.com to app1-tg 
5.2 Host Header app2.devopsincloud.com toto app2-tg 
5.3 Fixed Response: any other errors or any other IP or valid DNS to this LB
6. Verify ALB Target Groups App1 and App2, Targets (should be healthy) 
5. Verify SSL Certificate (Certificate Manager)
6. Verify Route53 DNS Record

# Test (Domain will be different for you based on your registered domain)
# Note: All the below URLS shoud redirect from HTTP to HTTPS
# App1
1. App1 Landing Page index.html at Root Context of App1: http://app1.devopsincloud.com
2. App1 /app1/index.html: http://app1.devopsincloud.com/app1/index.html
3. App1 /app1/metadata.html: http://app1.devopsincloud.com/app1/metadata.html
4. Failure Case: Access App2 Directory from App1 DNS: http://app1.devopsincloud.com/app2/index.html - Should return Directory not found 404

# App2
1. App2 Landing Page index.html at Root Context of App1: http://app2.devopsincloud.com
2. App1 /app2/index.html: http://app1.devopsincloud.com/app2/index.html
3. App1 /app2/metadata.html: http://app1.devopsincloud.com/app2/metadata.html
4. Failure Case: Access App2 Directory from App1 DNS: http://app2.devopsincloud.com/app1/index.html - Should return Directory not found 404
```

## Step-09: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete files
rm -rf .terraform*
rm -rf terraform.tfstate*
```