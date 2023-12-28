# Launch Template Outputs
## launch_template_id
output "launch_template_id" {
  description = "Launch Template ID"
  value = aws_launch_template.my_launch_template.id 
}
## launch_template_latest_version
output "launch_template_latest_version" {
  description = "Launch Template Latest Version"
  value = aws_launch_template.my_launch_template.latest_version 
}

# Autoscaling Outputs
## autoscaling_group_id
output "autoscaling_group_id" {
  description = "Autoscaling Group ID"
  value = aws_autoscaling_group.my_asg.id 
}

## autoscaling_group_name
output "autoscaling_group_name" {
  description = "Autoscaling Group Name"
  value = aws_autoscaling_group.my_asg.name 
}
## autoscaling_group_arn
output "autoscaling_group_arn" {
  description = "Autoscaling Group ARN"
  value = aws_autoscaling_group.my_asg.arn 
}
