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
            host_header = {
              values = [var.app1_dns_name]
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
            host_header = {
              values = [var.app2_dns_name]
            }
          }]
        }# End of myapp2-rule Block
      }# End Rules Block
    }# End my-https-listener Block
  }# End Listeners Block

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

  # Target Group-1: mytg2   
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

```
