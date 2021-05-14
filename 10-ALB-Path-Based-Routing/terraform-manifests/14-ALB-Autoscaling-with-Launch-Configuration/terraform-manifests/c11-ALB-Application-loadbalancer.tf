# Terraform AWS Application Load Balancer (ALB)
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.12.0"

  name = "alb-basic"
  load_balancer_type = "application"
  vpc_id = module.vpc.vpc_id
  subnets = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1],
    module.vpc.public_subnets[2]
  ]
  security_groups = [module.loadbalancer_sg.this_security_group_id]
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




  # Target Groups
  target_groups = [
    {
      name_prefix      = "app1-"
      backend_protocol = "HTTP"
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
        protocol            = "HTTP"
        matcher             = "200-399"
      }      
    },
  ]


  tags = local.common_tags 



  # HTTPS Listener
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.this_acm_certificate_arn
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed message - for Root Context"
        status_code  = "200"
      }
    }, 
  ]

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
        path_patterns = ["/*"]
      }]
    },
  ]
}

/* -- IMPORTANT NOTE --
As on Today, Target Group Attachments Not Supported
https://github.com/terraform-aws-modules/terraform-aws-alb
With that said, to register EC2 Instances to ALB TG, we need to use 
Terraform resource  "aws_alb_target_group_attachment"
*/
/*
# App1 - aws_alb_target_group_attachment
resource "aws_alb_target_group_attachment" "app1_alb_target_group_attachment_80" {
  count            = length(module.ec2_private_app1.id)
  target_group_arn = module.alb.target_group_arns[0]
  target_id        = module.ec2_private_app1.id[count.index]
  port             = 80
}
*/
