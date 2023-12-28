# AWS ALB Context Path based Routing using Terraform

## Step-00: Pre-requisites
- You need a Registered Domain in AWS Route53 to implement this usecase
- Lets discuss more about it
- Go to AWS Services -> Route53 -> Domains -> Registered Domains -> Register Domain
- Choose a domain name: abcabc.com and click on **Check** 
- If available, click on **Add to Cart** and Click on **Continue**
- Provide `Contact Details for Your 1 Domain` and Click on **Continue**
- Terms and Conditions: Check and click on **Complete Order**
- Go back to **Billing** and complete the payment for the domain to be approved
- Copy your `terraform-key.pem` file to `terraform-manifests/private-key` folder

## Step-01: Introduction
- We are going to implement Context Path based Routing in AWS Application Load Balancer using Terraform.
- To achieve that we are going to implement many series of steps. 
- Our core focus in the entire section should be primarily targeted to two things
  - **Listener Indexes:** `https_listener_index = 0`
  - **Target Group Indexes:** `target_group_index = 0`
- If we are good with understanding these indexes and how to reference them, we are good with handling these multiple context paths or multiple header based routes or anything from ALB perspective.   
- We are going to implement the following using AWS ALB 
1. Fixed Response for /* : http://apps.devopsincloud.com   
2. App1 /app1* goes to App1 EC2 Instances: http://apps.devopsincloud.com/app1/index.html
3. App2 /app2* goes to App2 EC2 Instances: http://apps.devopsincloud.com/app2/index.html
4. HTTP to HTTPS Redirect

## Step-02: Copy all files from previous section 
- We are going to copy all files from previous section `09-AWS-ALB-Application-LoadBalancer-Basic`
- Files from `c1 to c10`
- Create new files
  - c6-02-datasource-route53-zone.tf
  - c11-acm-certificatemanager.tf
  - c12-route53-dnsregistration.tf
- Review the files
  - app1-install.sh
  - app2-install.sh  

## Step-03: c5-05-securitygroup-loadbalancersg.tf
- Update load balancer security group to allow port 443
```t
  ingress_rules = ["http-80-tcp", "https-443-tcp"]
```

## Step-04: c6-02-datasource-route53-zone.tf
- Define the datasource for [Route53 Zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone)
```t
# Get DNS information from AWS Route53
data "aws_route53_zone" "mydomain" {
  name = "devopsincloud.com"
}

# Output MyDomain Zone ID
output "mydomain_zoneid" {
  description = "The Hosted Zone id of the desired Hosted Zone"
  value = data.aws_route53_zone.mydomain.zone_id
}
```

## Step-05: c7-04-ec2instance-private-app1.tf
- We will change the module name from `ec2_private` to `ec2_private_app1`
- We will change the `name` to `"${var.environment}-app1"`
```t
# EC2 Instances that will be created in VPC Private Subnets for App1
module "ec2_private_app1" {
  depends_on = [ module.vpc ] # VERY VERY IMPORTANT else userdata webserver provisioning will fail
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
  # insert the 10 required variables here
  name                   = "${var.environment}-app1"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  #monitoring             = true
  vpc_security_group_ids = [module.private_sg.this_security_group_id]
  #subnet_id              = module.vpc.public_subnets[0]  
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]  
  instance_count         = var.private_instance_count
  user_data = file("${path.module}/app1-install.sh")
  tags = local.common_tags
}
```

## Step-06: c7-05-ec2instance-private-app2.tf
- Create new EC2 Instances for App2 Application
- **Module Name:** ec2_private_app2
- **Name:** `"${var.environment}-app2"`
- **User Data:** `user_data = file("${path.module}/app2-install.sh")`
```t
# AWS EC2 Instance Terraform Module
# EC2 Instances that will be created in VPC Private Subnets for App2
module "ec2_private_app2" {
  depends_on = [ module.vpc ] # VERY VERY IMPORTANT else userdata webserver provisioning will fail
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
  # insert the 10 required variables here
  name                   = "${var.environment}-app2"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  #monitoring             = true
  vpc_security_group_ids = [module.private_sg.this_security_group_id]
  #subnet_id              = module.vpc.public_subnets[0]  
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]  
  instance_count         = var.private_instance_count
  user_data = file("${path.module}/app2-install.sh")
  tags = local.common_tags
}
```

## Step-07: c7-02-ec2instance-outputs.tf
- Update App1 and App2 Outputs based on new module names
```t
# App1 - Private EC2 Instances
## ec2_private_instance_ids
output "app1_ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_private_app1.id
}
## ec2_private_ip
output "app1_ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_private_app1.private_ip 
}

# App2 - Private EC2 Instances
## ec2_private_instance_ids
output "app2_ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_private_app2.id
}
## ec2_private_ip
output "app2_ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_private_app2.private_ip 
}
```
## Step-08: c11-acm-certificatemanager.tf
- [Terraform AWS ACM Module](https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest)
- Create a SAN SSL Certificate using DNS Validation with Route53
- This is required for us with ALB Load Balancer HTTPS Listener to associate SSL certificate to it
- Test trimsuffic function using `terraform console`
```t
# Terraform Console
terraform console

# Provide Trim Suffix Function
trimsuffix("devopsincloud.com.", ".")

# Verify Output
"devopsincloud.com"
```
- **ACM Module Terraform Configuration**
```t
# ACM Module - To create and Verify SSL Certificates
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.0"

  domain_name = trimsuffix(data.aws_route53_zone.mydomain.name, ".") 
  zone_id     = data.aws_route53_zone.mydomain.id
  subject_alternative_names = [
    "*.devopsincloud.com"
  ]
  tags = local.common_tags   
}

# Output ACM Certificate ARN
output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value = module.acm.this_acm_certificate_arn
}
```

## Step-09: c10-02-ALB-application-loadbalancer.tf
- [Terraform ALB Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
- [Terraform ALB Module - Complete Example](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest/examples/complete-alb)
### Step-09-01: HTTP to HTTPS Redirect
```t
  # HTTP Listener - HTTP to HTTPS Redirect
    http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]  
```
### Step-09-02: Add Target Group app2
```t
    # App2 Target Group - TG Index = 1
    {
      name_prefix          = "app2-"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/app2/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      protocol_version = "HTTP1"
      # App2 Target Group - Targets
      targets = {
        my_app2_vm1 = {
          target_id = module.ec2_private_app2.id[0]
          port      = 80
        },
        my_app2_vm2 = {
          target_id = module.ec2_private_app2.id[1]
          port      = 80
        }
      }
      tags =local.common_tags # Target Group Tags
    }  
```
### Step-09-03: Add HTTPS Listener
1. Associate SSL Certificate ARN
2. Add fixed response for Root Context `/*`
```t
  # HTTPS Listener
  https_listeners = [
    # HTTPS Listener Index = 0 for HTTPS 443
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.this_acm_certificate_arn
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed Static message - for Root Context"
        status_code  = "200"
      }
    }, 
  ]
```
### Step-09-04: Add HTTPS Listener Rules
- Understand about `https_listener_index`
- Create Rule-1: /app1* should go to App1 EC2 Instances
- Understand about `target_group_index`
- Create Rule-2: /app2* should go to App2 EC2 Instances    
```t

  # HTTPS Listener Rules
  https_listener_rules = [
    # Rule-1: /app1* should go to App1 EC2 Instances
    { 
      https_listener_index = 0
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        path_patterns = ["/app1*"]
      }]
    },
    # Rule-2: /app2* should go to App2 EC2 Instances    
    {
      https_listener_index = 0
      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]
      conditions = [{
        path_patterns = ["/app2*"]
      }]
    },    
  ]
```
## Step-10: c12-route53-dnsregistration.tf
- [Route53 Record Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
```t
# DNS Registration 
resource "aws_route53_record" "apps_dns" {
  zone_id = data.aws_route53_zone.mydomain.id
  name    = "apps9.devopsincloud.com"
  type    = "A"

  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = true
  }
}
```

## Step-11: Execute Terraform Commands
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
5.1 /app1* to app1-tg 
5.2 /app2* to app2-tg 
5.3 /* return Fixed response
6. Verify ALB Target Groups App1 and App2, Targets (should be healthy) 
5. Verify SSL Certificate (Certificate Manager)
6. Verify Route53 DNS Record

# Test (Domain will be different for you based on your registered domain)
# Note: All the below URLS shoud redirect from HTTP to HTTPS
1. Fixed Response: http://apps.devopsincloud.com   
2. App1 Landing Page: http://apps.devopsincloud.com/app1/index.html
3. App1 Metadata Page: http://apps.devopsincloud.com/app1/metadata.html
4. App2 Landing Page: http://apps.devopsincloud.com/app2/index.html
5. App2 Metadata Page: http://apps.devopsincloud.com/app2/metadata.html
```

## Step-12: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete files
rm -rf .terraform*
rm -rf terraform.tfstate*
```


## References
- [Terraform AWS ALB](https://github.com/terraform-aws-modules/terraform-aws-alb)
