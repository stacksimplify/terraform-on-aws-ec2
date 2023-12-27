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
# AWS EC2 Instance Terraform Module
# EC2 Instances that will be created in VPC Private Subnets for App1
module "ec2_private_app1" {
  depends_on = [ module.vpc ] # VERY VERY IMPORTANT else userdata webserver provisioning will fail
  source  = "terraform-aws-modules/ec2-instance/aws"
  #version = "2.17.0"
  version = "5.5.0"    
  # insert the 10 required variables here
  name                   = "${var.environment}-app1"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  user_data = file("${path.module}/app1-install.sh")
  tags = local.common_tags


# Changes as part of Module version from 2.17.0 to 5.5.0
  for_each = toset(["0", "1"])
  subnet_id =  element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [module.private_sg.security_group_id]
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
  #version = "2.17.0"
  version = "5.5.0"    
  # insert the 10 required variables here
  name                   = "${var.environment}-app2"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  user_data = file("${path.module}/app2-install.sh")
  tags = local.common_tags

# Changes as part of Module version from 2.17.0 to 5.5.0
  for_each = toset(["0", "1"])
  subnet_id =  element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [module.private_sg.security_group_id]
}
```

## Step-07: c7-02-ec2instance-outputs.tf
- Update App1 and App2 Outputs based on new module names
```t

# Private EC2 Instances - App1
## ec2_private_instance_ids
output "ec2_private_instance_ids_app1" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app1: ec2private.id ]   
}

## ec2_private_ip
output "ec2_private_ip_app1" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app1: ec2private.private_ip ]  
}


# Private EC2 Instances - App2
## ec2_private_instance_ids
output "ec2_private_instance_ids_app2" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app2: ec2private.id ]   
}

## ec2_private_ip
output "ec2_private_ip_app2" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app2: ec2private.private_ip ]  
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
  #version = "2.14.0"
  version = "5.0.0"

  domain_name  = trimsuffix(data.aws_route53_zone.mydomain.name, ".")
  zone_id      = data.aws_route53_zone.mydomain.zone_id 

  subject_alternative_names = [
    "*.devopsincloud.com"
  ]
  tags = local.common_tags

  # Validation Method
  validation_method = "DNS"
  wait_for_validation = true  
}

# Output ACM Certificate ARN
output "acm_certificate_arn" {
  description = "The ARN of the certificate"
  value       = module.acm.acm_certificate_arn
}
```

## Step-09: c10-02-ALB-application-loadbalancer.tf
- [Terraform ALB Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
- [Terraform ALB Module - Complete Example](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest/examples/complete-alb)
### Step-09-01: Create Target Groups mytg1 and mytg2
```t
# Target Groups
  target_groups = {
  # Target Group-1: mytg1
   mytg1 = {
      # VERY IMPORTANT: We will create aws_lb_target_group_attachment resource separately when we use create_attachment = false, refer above GitHub issue URL.
      ## Github ISSUE: https://github.com/terraform-aws-modules/terraform-aws-alb/issues/316
      ## Search for "create_attachment" to jump to that Github issue solution
      create_attachment = false
      name_prefix                       = "mytg1-"
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version = "HTTP1"
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
      }# End of Health Check Block
      tags = local.common_tags # Target Group Tags 
    } # END of Target Group-1: mytg1

  # Target Group-2: mytg2 
   mytg2 = {
      # VERY IMPORTANT: We will create aws_lb_target_group_attachment resource separately when we use create_attachment = false, refer above GitHub issue URL.
      ## Github ISSUE: https://github.com/terraform-aws-modules/terraform-aws-alb/issues/316
      ## Search for "create_attachment" to jump to that Github issue solution      
      create_attachment = false
      name_prefix                       = "mytg2-"
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version = "HTTP1"
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
      tags = local.common_tags # Target Group Tags 
    } # END of Target Group-2: mytg2
  } # END OF target_groups
```

### Step-09-02: Create Load Balancer Target Group Attachment
```t
# mytg1: LB Target Group Attachment
resource "aws_lb_target_group_attachment" "mytg1" {
  for_each = {for k,v in module.ec2_private_app1: k => v}
  target_group_arn = module.alb.target_groups["mytg1"].arn
  target_id        = each.value.id
  port             = 80
}
 
# mytg2: LB Target Group Attachment
resource "aws_lb_target_group_attachment" "mytg2" {
  for_each = {for k,v in module.ec2_private_app2: k => v}
  target_group_arn = module.alb.target_groups["mytg2"].arn
  target_id        = each.value.id
  port             = 80
}
```

### Step-09-03: Listener-1: HTTP to HTTPS Redirect
```t
    # Listener-1: my-http-https-redirect
    my-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }    
    }# End my-http-https-redirect Listener

```
### Step-09-04: Create HTTPS Listener with HTTP Rules for App1 and App2
```t
    # Listener-2: my-https-listener
    my-https-listener = {
      port                        = 443
      protocol                    = "HTTPS"
      ssl_policy                  = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn             = module.acm.acm_certificate_arn

       # Fixed Response for Root Context 
       fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed Static message - for Root Context"
        status_code  = "200"
      }# End of Fixed Response

      # Load Balancer Rules
      rules = {
        # Rule-1: myapp1-rule
        myapp1-rule = {
          actions = [{
            type = "weighted-forward"
            target_groups = [
              {
                target_group_key = "mytg1"
                weight           = 1
              }
            ]
            stickiness = {
              enabled  = true
              duration = 3600
            }
          }]
          conditions = [{
            path_pattern = {
              values = ["/app1*"]
            }
          }]
        }# End of myapp1-rule
        # Rule-2: myapp2-rule
        myapp2-rule = {
          actions = [{
            type = "weighted-forward"
            target_groups = [
              {
                target_group_key = "mytg2"
                weight           = 1
              }
            ]
            stickiness = {
              enabled  = true
              duration = 3600
            }
          }]
          conditions = [{
            path_pattern = {
              values = ["/app2*"]
            }
          }]
        }# End of myapp2-rule Block
      }# End Rules Block
    }# End my-https-listener Block
```

## Step-10: c12-route53-dnsregistration.tf
- [Route53 Record Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
```t
# DNS Registration 
resource "aws_route53_record" "apps_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = "apps.devopsincloud.com"
  type    = "A"
  alias {
    #name                   = module.alb.this_lb_dns_name
    #zone_id                = module.alb.this_lb_zone_id
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
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
