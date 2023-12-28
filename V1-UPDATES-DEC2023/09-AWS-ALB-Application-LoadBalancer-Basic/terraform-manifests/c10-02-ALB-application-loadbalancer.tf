# Terraform AWS Application Load Balancer (ALB)
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  #version = "5.16.0"
  version = "9.4.0"

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
resource "aws_lb_target_group_attachment" "mytg1" {
  for_each = {for k, v in module.ec2_private: k => v}
  target_group_arn = module.alb.target_groups["mytg1"].arn
  target_id        = each.value.id
  port             = 80
}

## k = ec2_instance
## v = ec2_instance_details

## TEMP App Outputs
output "zz_ec2_private" {
  #value = {for k, v in module.ec2_private: k => v}
  value = {for ec2_instance, ec2_instance_details in module.ec2_private: ec2_instance => ec2_instance_details}
}



