# Define CloudWatch Alarms for Autoscaling Groups

# Autoscaling - Scaling Policy for High CPU
resource "aws_autoscaling_policy" "high_cpu" {
  name                   = "high-cpu"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_asg.name 
}

# Cloud Watch Alarm to trigger the above scaling policy when CPU Utilization is above 80%
# Also send the notificaiton email to users present in SNS Topic Subscription
resource "aws_cloudwatch_metric_alarm" "app1_asg_cwa_cpu" {
  alarm_name          = "App1-ASG-CWA-CPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_asg.name 
  }

  alarm_description = "This metric monitors ec2 cpu utilization and triggers the ASG Scaling policy to scale-out if CPU is above 80%"
  
  ok_actions          = [aws_sns_topic.myasg_sns_topic.arn]  
  alarm_actions     = [
    aws_autoscaling_policy.high_cpu.arn, 
    aws_sns_topic.myasg_sns_topic.arn
    ]
}
