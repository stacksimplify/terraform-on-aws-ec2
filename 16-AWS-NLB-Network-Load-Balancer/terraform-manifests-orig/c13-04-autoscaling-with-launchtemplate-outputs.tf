# Launch Template Outputs
output "launch_template_id" {
  description = "Launch Template ID"
  value = aws_launch_template.my_launch_template.id
}

output "launch_template_latest_version" {
  description = "Launch Template Latest Version"
  value = aws_launch_template.my_launch_template.latest_version
}

# Autoscaling Outputs
output "autoscaling_group_id" {
  description = "Autoscaling Group ID"
  value = aws_autoscaling_group.my_asg.id 
}

output "autoscaling_group_name" {
  description = "Autoscaling Group Name"
  value = aws_autoscaling_group.my_asg.name 
}

output "autoscaling_group_arn" {
  description = "Autoscaling Group ARN"
  value = aws_autoscaling_group.my_asg.arn 
}
