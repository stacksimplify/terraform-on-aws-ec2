# Terraform Manifest Upgrades

 ## Step-01: c10-02-ALB-application-loadbalancer.tf
```t
# Terraform AWS Application Load Balancer (ALB)
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  #version = "5.16.0"
  version = "9.3.0"

  name = "${local.name}-alb"
  load_balancer_type = "application"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  #security_groups = [module.loadbalancer_sg.this_security_group_id]
  security_groups = [module.loadbalancer_sg.security_group_id]

  # For example only
  enable_deletion_protection = false

# Listeners
  listeners = {
    # Listener-1: my-http-listener
    my-http-listener = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "mytg1"
      }         
    }# End of my-http-listener
  }# End of listeners block

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
      }# End of health_check Block
      tags = local.common_tags # Target Group Tags 
    } # END of Target Group: mytg1
  } # END OF target_groups Block
  tags = local.common_tags # ALB Tags
}

# Load Balancer Target Group Attachment
resource "aws_lb_target_group_attachment" "external" {
  for_each = {for k, v in module.ec2_private: k => v}
  target_group_arn = module.alb.target_groups["mytg1"].arn
  target_id        = each.value.id
  port             = 80
}
```

 ## Step-02: c10-03-ALB-application-loadbalancer-outputs.tf
 ```t
 # Terraform AWS Application Load Balancer (ALB) Outputs
output "lb_id" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.id
}

output "lb_arn" {
  description = "The ID and ARN of the load balancer we created."
  value       = module.alb.arn
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.dns_name
}

output "lb_arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch."
  value       = module.alb.arn_suffix
}

output "lb_zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records."
  value       = module.alb.zone_id
}

output "listener_rules" {
  description = "Map of listeners rules created and their attributes"
  value       = module.alb.listener_rules
}

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = module.alb.listeners
}

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.alb.target_groups
}
 ```