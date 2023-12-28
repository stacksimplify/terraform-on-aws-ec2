---
title: AWS Network Load Balancer with Terraform
description: Create AWS Network Load Balancer with Terraform - Demo for both TCP and TLS Listeners
---
# AWS Network Load Balancer TCP and TLS with Terraform

## Step-01: Introduction
- Create [AWS Network Load Balancer using Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
- Create TCP Listener
- Create TLS Listener
- Create Target Group

[![Image](https://stacksimplify.com/course-images/terraform-aws-nlb-network-loadbalancer-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-nlb-network-loadbalancer-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-nlb-network-loadbalancer-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-nlb-network-loadbalancer-2.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-nlb-network-loadbalancer-3.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-nlb-network-loadbalancer-3.png)

## Step-02: c5-04-securitygroup-privatesg.tf
- NLB requires private security group EC2 Instances to have the `ingress_cidr_blocks` as `0.0.0.0/0`
```t
# Before
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

# After
  ingress_cidr_blocks = ["0.0.0.0/0"] # Required for NLB
```

## Step-03: c10-01-NLB-network-loadbalancer-variables.tf
- Place holder file for NLB variables. 

## Step-04: c10-02-NLB-network-loadbalancer.tf
- Create [AWS Network Load Balancer using Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
- Create TCP Listener
- Create TLS Listener
- Create Target Group
```t
# Terraform AWS Network Load Balancer (NLB)
module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.4.0"

  name_prefix = "mynlb-"
  load_balancer_type               = "network"
  vpc_id                           = module.vpc.vpc_id
  dns_record_client_routing_policy = "availability_zone_affinity"
  security_groups = [module.loadbalancer_sg.security_group_id]

  # https://github.com/hashicorp/terraform-provider-aws/issues/17281
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

# Listeners
  listeners = {
    # Listener-1: TCP Listener
    my-tcp = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "mytg1"
      }
    }# End Listener-1: TCP Listener
    # Listener-2: TLS Listener (SSL)
    my-tls = {
      port            = 443
      protocol        = "TLS"
      certificate_arn = module.acm.acm_certificate_arn
      forward = {
        target_group_key = "mytg1"
      }
    }# End Listener-2: TLS Listener (SSL)
  }# End Listeners Block

# Target Groups
  target_groups = { 
    # Target Group-1: mytg1
    mytg1 = {
      create_attachment = false          
      name_prefix          = "mytg1-"
      protocol             = "TCP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/app1/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }# End Health Check Block
    }# End Target Group-1: mytg1
  }
  tags = local.common_tags
}# End NLB Module

```
## Step-05: c10-03-NLB-network-loadbalancer-outputs.tf
```t
# Terraform AWS Network Load Balancer (NLB) Outputs
################################################################################
# Load Balancer
################################################################################

output "id" {
  description = "The ID and ARN of the load balancer we created"
  value       = module.nlb.id
}

output "arn" {
  description = "The ID and ARN of the load balancer we created"
  value       = module.nlb.arn
}

output "arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch"
  value       = module.nlb.arn_suffix
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.nlb.dns_name
}

output "zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records"
  value       = module.nlb.zone_id
}

################################################################################
# Listener(s)
################################################################################

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = module.nlb.listeners
}

output "listener_rules" {
  description = "Map of listeners rules created and their attributes"
  value       = module.nlb.listener_rules
}

################################################################################
# Target Group(s)
################################################################################

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.nlb.target_groups
}

################################################################################
# Security Group
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = module.nlb.security_group_arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.nlb.security_group_id
}

################################################################################
# Route53 Record(s)
################################################################################

output "route53_records" {
  description = "The Route53 records created and attached to the load balancer"
  value       = module.nlb.route53_records
}
```
## Step-06: c12-route53-dnsregistration.tf
- **Change-1:** Update DNS Name
- **Change-2:** Update `alias name`
- **Change-3:** Update `alias zone_id` 
```t
# DNS Registration 
resource "aws_route53_record" "apps_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = "nlb1.devopsincloud.com"
  type    = "A"
  alias {
    name                   = module.nlb.lb_dns_name
    zone_id                = module.nlb.lb_zone_id
    evaluate_target_health = true
  }  
}
```
## Step-07: c13-03-autoscaling-resource.tf
- Change the module name for `target_group_arns` to `nlb`
```t
# Before
  target_group_arns = [module.alb.target_groups["mytg1"].arn] 
  # After
  target_group_arns = [module.nlb.target_groups["mytg1"].arn] 
```
## Step-08: c13-06-autoscaling-ttsp.tf
- Comment TTSP ALB policy which is not applicable to NLB
```t
# TTS - Scaling Policy-2: Based on ALB Target Requests
# THIS POLICY IS SPECIFIC TO ALB and NOT APPLICABLE TO NLB
/*
resource "aws_autoscaling_policy" "alb_target_requests_greater_than_yy" {
  name                   = "alb-target-requests-greater-than-yy"
  policy_type = "TargetTrackingScaling" # Important Note: The policy type, either "SimpleScaling", "StepScaling" or "TargetTrackingScaling". If this value isn't provided, AWS will default to "SimpleScaling."    
  autoscaling_group_name = aws_autoscaling_group.my_asg.id 
  estimated_instance_warmup = 120 # defaults to ASG default cooldown 300 seconds if not set  
  # Number of requests > 10 completed per target in an Application Load Balancer target group.
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label =  "${module.alb.lb_arn_suffix}/${module.alb.target_group_arn_suffixes[0]}"    
    }  
    target_value = 10.0
  }    
}
*/
```
## Step-09: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terrafom Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```
## Step-10: Verify the AWS resources created
0. Confirm SNS Subscription in your email
1. Verify EC2 Instances
2. Verify Launch Templates (High Level)
3. Verify Autoscaling Group (High Level)
4. Verify Network Load Balancer 
  - TCP Listener
  - TLS Listener
5. Verify Network Load Balancer Target Group 
  - Health Checks - both nodes should be healthy
6. Access and Test
```t
# Access and Test with Port 80 - TCP Listener
http://nlb.devopsincloud.com
http://nlb.devopsincloud.com/app1/index.html
http://nlb.devopsincloud.com/app1/metadata.html

# Access and Test with Port 443 - TLS Listener
https://nlb.devopsincloud.com
https://nlb.devopsincloud.com/app1/index.html
https://nlb.devopsincloud.com/app1/metadata.html
```

## Step-11: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Clean-Up Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```



## References
-[Complete NLB - Example](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest/examples/complete-nlb)

