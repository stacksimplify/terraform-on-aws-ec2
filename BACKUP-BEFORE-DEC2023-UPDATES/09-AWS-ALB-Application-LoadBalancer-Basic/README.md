# AWS Application Load Balancer Basics with Terraform

## Step-01: Introduction
- Create [AWS ALB Application Load Balancer Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
- Re-use AWS Security Group created for Load Balancers

## Step-02: Create ALB Basic Manually
### Step-02-01: Create EC2 Instance with Userdata
- Go to AWS Services -> EC2 -> Instances -> Launch Instances
- **Step 1: Choose an Amazon Machine Image (AMI):** Amazon Linux 2 AMI (HVM), SSD Volume Type
- **Step 2: Choose an Instance Type:** t2.micro
- **Step 3: Configure Instance Details:** 
  - Number of Instances: 2
  - Userdata: select `file` and reference  `terraform-manifests/app1-install.sh` for userdata
  - Rest all defaults  
- **Step 4: Add Storage:** leave to defaults
- **Step 5: Add Tags:** 
  - Key: Name
  - Value: ALB-Manual-Test-1
- **Step 6: Configure Security Group:** 
  - Security Group Name: ALB-Manual-TestSG1
  - Add SSH and HTTP rules for entire internet edge 0.0.0.0/0
- **Step 7: Review Instance Launch:** Click on Launch
- **Select an existing key pair or create a new key pair:** terraform-key
- Click on Launch Instance
- Verify once the EC2 Instance is created and wait for Instances to be in `2/2 checks passed`
- Access Instances and verify 
```
# Access App1 from both Instances
http://<public-ip-instance-1>/app1/index.html
http://<public-ip-instance-1>/app1/metadata.html
http://<public-ip-instance-2>/app1/index.html
http://<public-ip-instance-2>/app1/metadata.html
```

### Step-02-02: Create Target Group
- Go to AWS Services -> EC2 -> Target Groups -> Create target group
- **Choose a target type:** Instances
- **Target Group Name:** app1-tg
- **Protocol:** HTTP
- **Port:** 80
- **VPC:** default-vpc
- **Protocol Version:** HTTP1
- **Health Check Protocol:** HTTP
- **Health check path:** /app1/index.html
- **Advanced Health Check Settings - Port:** Traffic Port
- **Healthy threshold:** 5
- **Unhealthy threshold:** 2
- **Timeout:** 5 seconds
- **Interval:** 30 seconds
- **Success codes:** 200-399
- **Tags:** App = app1-tg
- Click **Next**
- **Register targets**
  - **Select EC2 Instances:** select EC2 Instances
  - **Ports for the selected instances:** 80
  - Click on **Include as pending below**
- Click on **Create target group**

## Step-02-03: Create Application Load Balancer
- Go to AWS Services -> EC2 -> Load Balancing -> Load Balancers -> Create Load Balancer
- **Select load balancer type:** Application Load Balancer
- **Step 1: Configure Load Balancer**
  - **Name:** alb-basic-test
  - **Scheme:** internet-facing
  - **IP address type:** ipv4
  - **Listeners:** 
    - Load Balancer Protocol: HTTP
    - Load Balancer Port: 80
  - **Availability Zones:**
    - VPC: default-vpc
    - Availability Zones: us-east-1a, us-east-1b, us-east-1c  (Verify first where EC2 Instances created)        
- **Step 2: Configure Security Settings** 
  - Click **Next**
- **Step 3: Configure Security Groups**
  - Assign a security group: create new security group
  - Security group name: loadbalancer-alb-sg
  - Rule: HTTP Port 80 from internet 0.0.0.0/0
- **Step 4: Configure Routing**
  - Target group: Existing Target Group
  - Name: app1-tg
  - Click **Next**
- **Step 5: Register Targets**
  - Click **Next Review**
- **Step 6: Review** Click on **Create**

## Step-02-04: Verify the following
- Wait for Load Balancer to be in `active` state
- Verify ALB Load Balancer 
  - Description Tab
  - Listeners Tab
  - Listeners Tab -> Rules
- Verify Target Groups
  -  They should be in `HEALTHY`
- Access using Load Balancer DNS
```
# Access Application
http://alb-basic-test-1565875067.us-east-1.elb.amazonaws.com
http://alb-basic-test-1565875067.us-east-1.elb.amazonaws.com/app1/index.html
http://alb-basic-test-1565875067.us-east-1.elb.amazonaws.com/app1/metadata.html
```

## Step-02-05: Clean-Up
- Delete Load Balacner
- Delete Target Groups
- Delete EC2 Instances
    
## Step-03: Copy all files from previous section 
- We are going to copy all files from previous section `08-AWS-ELB-Classic-LoadBalancer`
- Files from `c1 to c9`
- Create the files for ALB Basic
  - c10-01-ALB-application-loadbalancer-variables.tf
  - c10-02-ALB-application-loadbalancer.tf
  - c10-03-ALB-application-loadbalancer-outputs.tf

## Step-04: c10-02-ALB-application-loadbalancer.tf
- Create AWS Application Load Balancer Terraform configuration using [ALB Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
```t
# Terraform AWS Application Load Balancer (ALB)
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.16.0"

  name = "${local.name}-alb"
  load_balancer_type = "application"
  vpc_id = module.vpc.vpc_id
  subnets = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1]
  ]
  security_groups = [module.loadbalancer_sg.this_security_group_id]
  # Listeners
    http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]  
  # Target Groups
  target_groups = [
    # App1 Target Group
    {
      name_prefix      = "app1-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/app1/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }      
      protocol_version = "HTTP1"
      # App1 Target Group - Targets
      targets = {
        my_app1_vm1 = {
          target_id = module.ec2_private.id[0]
          port      = 80
        },
        my_app1_vm2 = {
          target_id = module.ec2_private.id[1]
          port      = 80
        }        
      }
      tags = local.common_tags # Target Group Tags
    }     
  ]
  tags = local.common_tags # ALB Tags
}
```
## Step-05: c10-03-ALB-application-loadbalancer-outputs.tf
```t
# Terraform AWS Application Load Balancer (ALB) Outputs
output "this_lb_id" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.this_lb_id
}

output "this_lb_arn" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.this_lb_arn
}

output "this_lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.this_lb_dns_name
}

output "this_lb_arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch."
  value       = module.alb.this_lb_arn_suffix
}

output "this_lb_zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records."
  value       = module.alb.this_lb_zone_id
}

output "http_tcp_listener_arns" {
  description = "The ARN of the TCP and HTTP load balancer listeners created."
  value       = module.alb.http_tcp_listener_arns
}

output "http_tcp_listener_ids" {
  description = "The IDs of the TCP and HTTP load balancer listeners created."
  value       = module.alb.http_tcp_listener_ids
}

output "https_listener_arns" {
  description = "The ARNs of the HTTPS load balancer listeners created."
  value       = module.alb.https_listener_arns
}

output "https_listener_ids" {
  description = "The IDs of the load balancer listeners created."
  value       = module.alb.https_listener_ids
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = module.alb.target_group_arns
}

output "target_group_arn_suffixes" {
  description = "ARN suffixes of our target groups - can be used with CloudWatch."
  value       = module.alb.target_group_arn_suffixes
}

output "target_group_names" {
  description = "Name of the target group. Useful for passing to your CodeDeploy Deployment Group."
  value       = module.alb.target_group_names
}

output "target_group_attachments" {
  description = "ARNs of the target group attachment IDs."
  value       = module.alb.target_group_attachments
}
```


## Step-06: Execute Terraform Commands
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
1. Verify EC2 Instances
2. Verify Load Balancer SG
3. Verify ALB Listeners and Rules
4. Verify ALB Target Groups, Targets (should be healthy) and Health Check settings
5. Access sample app using Load Balancer DNS Name
# Example: from my environment
http://hr-stag-alb-1575108738.us-east-1.elb.amazonaws.com 
http://hr-stag-alb-1575108738.us-east-1.elb.amazonaws.com/app1/index.html
http://hr-stag-alb-1575108738.us-east-1.elb.amazonaws.com/app1/metadata.html
```

## Step-07: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete files
rm -rf .terraform*
rm -rf terraform.tfstate*
```

