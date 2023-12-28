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
  version = "6.0.0"
  name_prefix = "mynlb-"
  #name = "nlb-basic"
  load_balancer_type = "network"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  #security_groups = [module.loadbalancer_sg.this_security_group_id] # Security Groups not supported for NLB
  # TCP Listener 
    http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    }  
  ]  

  #  TLS Listener
  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    },
  ]


  # Target Group
  target_groups = [
    {
      name_prefix      = "app1-"
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/app1/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }      
    },
  ]
  tags = local.common_tags 
}
```
## Step-05: c10-03-NLB-network-loadbalancer-outputs.tf
```t
# Terraform AWS Network Load Balancer (NLB) Outputs
output "lb_id" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.nlb.lb_id
}

output "lb_arn" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.nlb.lb_arn
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.nlb.lb_dns_name
}

output "lb_arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch."
  value       = module.nlb.lb_arn_suffix
}

output "lb_zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records."
  value       = module.nlb.lb_zone_id
}

output "http_tcp_listener_arns" {
  description = "The ARN of the TCP and HTTP load balancer listeners created."
  value       = module.nlb.http_tcp_listener_arns
}

output "http_tcp_listener_ids" {
  description = "The IDs of the TCP and HTTP load balancer listeners created."
  value       = module.nlb.http_tcp_listener_ids
}

output "https_listener_arns" {
  description = "The ARNs of the HTTPS load balancer listeners created."
  value       = module.nlb.https_listener_arns
}

output "https_listener_ids" {
  description = "The IDs of the load balancer listeners created."
  value       = module.nlb.https_listener_ids
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = module.nlb.target_group_arns
}

output "target_group_arn_suffixes" {
  description = "ARN suffixes of our target groups - can be used with CloudWatch."
  value       = module.nlb.target_group_arn_suffixes
}

output "target_group_names" {
  description = "Name of the target group. Useful for passing to your CodeDeploy Deployment Group."
  value       = module.nlb.target_group_names
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
  target_group_arns = module.alb.target_group_arns
# After
  target_group_arns = module.nlb.target_group_arns
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

