###### Target Tracking Scaling Policies ######
# TTS - Scaling Policy-1: Based on CPU Utilization
# Define Autoscaling Policies and Associate them to Autoscaling Group
resource "aws_autoscaling_policy" "avg_cpu_policy_greater_than_xx" {
  name                   = "avg-cpu-policy-greater-than-xx"
  policy_type = "TargetTrackingScaling" # Important Note: The policy type, either "SimpleScaling", "StepScaling" or "TargetTrackingScaling". If this value isn't provided, AWS will default to "SimpleScaling."    
  autoscaling_group_name = aws_autoscaling_group.my_asg.id 
  estimated_instance_warmup = 180 # defaults to ASG default cooldown 300 seconds if not set
  # CPU Utilization is above 50
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }  
 
}

# TTS - Scaling Policy-2: Based on ALB Target Requests
resource "aws_autoscaling_policy" "alb_target_requests_greater_than_yy" {
  name                   = "alb-target-requests-greater-than-yy"
  policy_type = "TargetTrackingScaling" # Important Note: The policy type, either "SimpleScaling", "StepScaling" or "TargetTrackingScaling". If this value isn't provided, AWS will default to "SimpleScaling."    
  autoscaling_group_name = aws_autoscaling_group.my_asg.id 
  estimated_instance_warmup = 120 # defaults to ASG default cooldown 300 seconds if not set  
  # Number of requests > 10 completed per target in an Application Load Balancer target group.
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      #resource_label =  "${module.alb.lb_arn_suffix}/${module.alb.target_group_arn_suffixes[0]}"    
      resource_label =  "${module.alb.arn_suffix}/${module.alb.target_groups["mytg1"].arn_suffix}"  # UPDATED NOV2023      
    }  
    target_value = 10.0
  }   

  # Added depends_on to ensure the ALB and its listeners are fully created 
  # and routing traffic to the target group before this Target Tracking 
  # Scaling Policy is attached. Without this, Terraform may try to create 
  # the policy too early and fail with: 
  # "ValidationError: The load balancer does not route traffic to the target group"
  depends_on = [
    aws_autoscaling_group.my_asg,
    module.alb
  ] 
}

# Updated Nov2023
output "asg_build_resource_label" {
  value =  "${module.alb.arn_suffix}/${module.alb.target_groups["mytg1"].arn_suffix}"  
}

