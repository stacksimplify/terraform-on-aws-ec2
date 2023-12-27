# Terraform Manifest Upgrades

## Step-01: Private EC2 Instances for App1, App2, and App3
### Changes in following files
1. c7-04-ec2instance-private-app1.tf
2. c7-05-ec2instance-private-app2.tf
3. c7-06-ec2instance-private-app3

### Why changes needed ?
1. `count` meta-argument not supported for creating multiple instances 
2. We need to switch the code to `for_each` to support creating multiple instances
```t
# Change-1: Module Version
  source  = "terraform-aws-modules/ec2-instance/aws"
  #version = "2.17.0"
  version = "5.5.0"  

# Change-2: Change from count to for_each
1. count meta-argument not supported for creating multiple instances 
2. We need to switch the code to for_each to support creating multiple instances

# Changes as part of Module version from 2.17.0 to 5.5.0
  for_each = toset(["0", "1"])
  subnet_id =  element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [module.private_sg.security_group_id]

# BELOW CODE COMMENTED AS PART OF MODULE UPGRADE TO 5.5.0
/*  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]  
  instance_count         = var.private_instance_count
  vpc_security_group_ids = [module.private_sg.this_security_group_id]    
*/
```

## Step-02: c7-02-ec2instance-outputs.tf
- Updated the outputs with `for loop` to support the `for_each` used for creating `ec2_private` instances for App1, App2, and App3
```t
# AWS EC2 Instance Terraform Outputs
# Public EC2 Instances - Bastion Host

## ec2_bastion_public_instance_ids
output "ec2_bastion_public_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_public.id
}

## ec2_bastion_public_ip
output "ec2_bastion_public_ip" {
  description = "List of public IP addresses assigned to the instances"
  value       = module.ec2_public.public_ip 
}

# App1 - Private EC2 Instances
## ec2_private_instance_ids
output "app1_ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app1: ec2private.id ]  
}
## ec2_private_ip
output "app1_ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app1: ec2private.private_ip ]  
}

# App2 - Private EC2 Instances
## ec2_private_instance_ids
output "app2_ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app2: ec2private.id ]  
}
## ec2_private_ip
output "app2_ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app2: ec2private.private_ip ]    
}

# App3 - Private EC2 Instances
## ec2_private_instance_ids
output "app3_ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app3: ec2private.id ]  
}
## ec2_private_ip
output "app3_ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app3: ec2private.private_ip ]  
}
```

## Step-03: c10-02-ALB-application-loadbalancer.tf
```t
# Terraform AWS Application Load Balancer (ALB)
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  #version = "5.16.0"
  version = "9.4.0"

  name = "${local.name}-alb"
  load_balancer_type = "application"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  security_groups = [module.loadbalancer_sg.security_group_id]

  # For example only
  enable_deletion_protection = false

# Listeners
  listeners = {
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
          priority = 10
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
          priority = 20          
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
        # Rule-3: myapp3-rule
        myapp3-rule = {
          priority = 30          
          actions = [{
            type = "weighted-forward"
            target_groups = [
              {
                target_group_key = "mytg3"
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
              values = ["/*"]
            }
          }]
        }# End of myapp3-rule Block
      }# End Rules
    }# End Listener-2: my-https-listener
  }# End Listeners

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
    }# END of Target Group-1: mytg1

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

  # Target Group-3: mytg3       
   mytg3 = {
      # VERY IMPORTANT: We will create aws_lb_target_group_attachment resource separately, refer above GitHub issue URL.
      create_attachment = false
      name_prefix                       = "mytg3-"
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version = "HTTP1"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/login"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      tags = local.common_tags # Target Group Tags 
    }# END of Target Group-3: mytg3
  } # END OF target_groups
  tags = local.common_tags # ALB Tags
}

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

# mytg3: LB Target Group Attachment
resource "aws_lb_target_group_attachment" "mytg3" {
  for_each = {for k,v in module.ec2_private_app3: k => v}
  target_group_arn = module.alb.target_groups["mytg3"].arn
  target_id        = each.value.id
  port             = 8080
}
```

## Step-04: c13-02-rdsdb.tf
```t
# Change-1: Module Upgrade
  source  = "terraform-aws-modules/rds/aws"
  #version = "2.34.0"
  #version = "3.0.0"
  version = "6.3.0"

# Change-2: Additional Changes 
  #name     = var.db_name  # Initial Database Name - DEPRECATED
  db_name     = var.db_name  # Added as part of Module v6.3.0

# Change-3: Added the below argument to false. 
  manage_master_user_password = false # Added as part of Module v6.3.0
1. This is needed to support our App3 DB Password usecase   
```

