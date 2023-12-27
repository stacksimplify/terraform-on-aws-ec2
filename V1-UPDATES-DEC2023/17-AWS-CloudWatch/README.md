---
title: AWS CloudWatch using Terraform
description: Create CloudWatch Alarms for ASG, ALB, Synthetics, CIS Alarams 
---
# CloudWatch + ALB + Autoscaling with Launch Templates

## Step-01: Introduction
- Create the following Alarms using CloudWatch with the end to end usecase we have built so far
  - AWS Application Load Balancer Alarms
  - AWS Autoscaling Group Alarms
  - AWS CIS Alarms (Center for Internet Security)
- AWS CloudWatch Synthetics
  - Implement a Heart Beat Monitor 


[![Image](https://stacksimplify.com/course-images/terraform-aws-cloudwatch-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-cloudwatch-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-cloudwatch-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-cloudwatch-2.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-cloudwatch-3.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-cloudwatch-3.png)

## Step-02: Copy all files from Section-15
- Copy all the files from `15-Autoscaling-with-Launch-Templates\terraform-manifests` 

## Step-03: c12-route53-dnsregistration.tf
- Change the DNS name as per your demo content 
```t
  name    = "cloudwatch1.devopsincloud.com"
```

## Step-04: c14-01-cloudwatch-variables.tf
- Create a place holder file to define CloudWatch Variables

## Step-05: c14-02-cloudwatch-asg-alarms.tf
```t
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
```

## Step-06: c14-03-cloudwatch-alb-alarms.tf
```t
# Define CloudWatch Alarms for ALB
# Alert if HTTP 4xx errors are more than threshold value
resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  alarm_name          = "App1-ALB-HTTP-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = "2" # "2"
  evaluation_periods  = "3" # "3"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "120"
  statistic           = "Sum"
  threshold           = "5"  # Update real-world value like 100, 200 etc
  treat_missing_data  = "missing"  
  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
  alarm_description = "This metric monitors ALB HTTP 4xx errors and if they are above 100 in specified interval, it is going to send a notification email"
  ok_actions          = [aws_sns_topic.myasg_sns_topic.arn]  
  alarm_actions     = [aws_sns_topic.myasg_sns_topic.arn]
}

# Per AppELB Metrics
## - HTTPCode_ELB_5XX_Count
## - HTTPCode_ELB_502_Count
## - TargetResponseTime
# Per AppELB, per TG Metrics
## - UnHealthyHostCount
## - HealthyHostCount
## - HTTPCode_Target_4XX_Count
## - TargetResponseTime
```

## Step-07: c14-04-cloudwatch-cis-alarms.tf
- [Terraform AWS CloudWatch Module](https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws/latest)
- [AWS CIS Alarms](https://registry.terraform.io/modules/terraform-aws-modules/cloudwatch/aws/latest/submodules/cis-alarms)
- [CIS AWS Foundations Benchmark controls](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cis-controls.html)

```t
# Create Log Group for CIS
resource "aws_cloudwatch_log_group" "cis_log_group" {
  name = "cis-log-group-${random_pet.this.id}"
}

# Define CIS Alarms
module "all_cis_alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/cis-alarms"
  version = "2.0.0"

  disabled_controls = ["DisableOrDeleteCMK", "VPCChanges"]
  log_group_name = aws_cloudwatch_log_group.cis_log_group.name 
  alarm_actions  = [aws_sns_topic.myasg_sns_topic.arn]
  tags = local.common_tags
}
```

## Step-08: AWS CloudWatch Synthetics - Run manually and Understand
- Understand AWS CloudWatch Synthetics
- Create CloudWatch Synthetics using AWS management console and explore more about it

## Step-09: AWS CloudWatch Synthetics using Terraform
- Review the following files
- **File-1:** `sswebsite2\nodejs\node_modules\sswebsite2.js`
- **File-2:** sswebsite2v1.zip

### Step-09-01: Create Folder Structure
- `nodejs\node_modules\`

### Step-09-02: Create sswebsite2.js file
- Use `Heart Beat Monitor` sample from AWS Management Console - AWS CloudWatch Sythetic Service
- Update your Application DNS Name
```t
# Before 
    const urls = ['https://stacksimplify.com'];

# After 
    const urls = ['https://yourapp.com'];
```
### Step-09-03: Create ZIP file
```t
cd sswebsite2
zip -r sswebsite2v1.zip nodejs
```
### Step-09-04: c14-05-cloudwatch-synthetics.tf - Create IAM Policy and Role
```t
# AWS IAM Policy
resource "aws_iam_policy" "cw_canary_iam_policy" {
  name        = "cw-canary-iam-policy"
  path        = "/"
  description = "CloudWatch Canary Synthetic IAM Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "cloudwatch:PutMetricData",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "cloudwatch:namespace": "CloudWatchSynthetics"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "logs:CreateLogStream",
                "s3:ListAllMyBuckets",
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "s3:GetBucketLocation",
                "xray:PutTraceSegments"
            ],
            "Resource": "*"
        }
    ]
})
}

# AWS IAM Role
resource "aws_iam_role" "cw_canary_iam_role" {
  name                = "cw-canary-iam-role"
  description = "CloudWatch Synthetics lambda execution role for running canaries"
  path = "/service-role/"
  #assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}" 
  managed_policy_arns = [aws_iam_policy.cw_canary_iam_policy.arn]
}
```

### Step-09-05: c14-05-cloudwatch-synthetics.tf - Create S3 Bucket
```t
# Create S3 Bucket
resource "aws_s3_bucket" "cw_canary_bucket" {
  bucket = "cw-canary-bucket-${random_pet.this.id}"
  acl    = "private"
  force_destroy = true

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
```
### Step-09-06: c14-05-cloudwatch-synthetics.tf - Create AWS CloudWatch Canary Resource
```t

# AWS CloudWatch Canary
resource "aws_synthetics_canary" "sswebsite2" {
  name                 = "sswebsite2"
  artifact_s3_location = "s3://${aws_s3_bucket.cw_canary_bucket.id}/sswebsite2"
  execution_role_arn   = aws_iam_role.cw_canary_iam_role.arn 
  handler              = "sswebsite2.handler"
  zip_file             = "sswebsite2/sswebsite2v1.zip"
  runtime_version      = "syn-nodejs-puppeteer-3.1"
  start_canary = true

  run_config {
    active_tracing = true
    memory_in_mb = 960
    timeout_in_seconds = 60
  }
  schedule {
    expression = "rate(1 minute)"
  }
}
```
### Step-09-07: c14-05-cloudwatch-synthetics.tf - Create AWS CloudWatch Metric Alarm for Canary Resource
```t
# AWS CloudWatch Metric Alarm for Synthetics Heart Beat Monitor when availability is less than 10 percent
resource "aws_cloudwatch_metric_alarm" "synthetics_alarm_app1" {
  alarm_name          = "Synthetics-Alarm-App1"
  comparison_operator = "LessThanThreshold"
  datapoints_to_alarm = "1" # "2"
  evaluation_periods  = "1" # "3"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"  
  treat_missing_data  = "breaching" # You can also add "missing"
  dimensions = {
    CanaryName = aws_synthetics_canary.sswebsite2.id 
  }
  alarm_description = "Synthetics alarm metric: SuccessPercent  LessThanThreshold 90"
  ok_actions          = [aws_sns_topic.myasg_sns_topic.arn]  
  alarm_actions     = [aws_sns_topic.myasg_sns_topic.arn]
}
```


## Step-10: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
```

## Step-11: Verify Resources
0. Confirm SNS Subscription in your email
1. Verify EC2 Instances
2. Verify Launch Templates (High Level)
3. Verify Autoscaling Group (High Level)
4. Verify Load Balancer
5. Verify Load Balancer Target Group - Health Checks
6. Cloud Watch
- ALB Alarm
- ASG Alarm
- CIS Alarms
- Synthetics
7. Access and Test
```t
# Access and Test
http://cloudwatch.devopsincloud.com
http://cloudwatch.devopsincloud.com/app1/index.html
http://cloudwatch.devopsincloud.com/app1/metadata.html
```

## Step-11: Clean-Up
```t
# Delete Resources
terraform destroy -auto-approve

# Delete Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```



## Additional Knowledge
```t
terraform import aws_cloudwatch_metric_alarm.test alarm-12345
terraform import aws_cloudwatch_metric_alarm.temp1 alb-4xx-temp-1
```


## References
- [ALL CW Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html)
- [ALB CW Metrics](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html)
- [CloudWatch Concepts](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html)

