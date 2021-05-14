# EC2 Demo 13 - Autoscaling with Target Tracking Policy

## Step-01: Introduction
### V1-Terraform-Manifests: LC & ASG & TTSP & ALB & Notifications
#### Module-1: ASG & LC & ALB
- Create Launch Configuration
- Create Autoscaling Group
- Map it with ALB (Application Load Balancer)

#### Module-2: - TTSP (Target Tracking Scaling Policies)
- Create `Resource: aws_autoscaling_policy` 
- ASGAverageCPUUtilization
- ALBRequestCountPerTarget
- Terraform Import for `ALBRequestCountPerTarget` Resource Label finding
#### Module-3: Autoscaling Notifications
- Create SNS Topic `aws_sns_topic`
- Create SNS Topic Subscription `aws_sns_topic_subscription`
- Create Autoscaling Notification Resource  `aws_autoscaling_notification`
#### Module-4: Scheduled Actions
- Create a scheduled action to `increase capacity at 7am`
- Create a scheduled action to `decrease capacity at 5pm`
```t
# Import State
$ terraform import aws_autoscaling_schedule.resource-name auto-scaling-group-name/scheduled-action-name
terraform import aws_autoscaling_schedule.capacity_increase_during_business_hours	 myapp1-asg-20210329100544375800000007/capacity_increase_during_business_hours	
-> using terraform import get values for recurrence argument (cron format)

# UTC Timezone converter
https://www.worldtimebuddy.com/utc-to-est-converter
```

### Module-5: Changes to ASG
- Change Desired capacity to 3 `desired_capacity = 3` and test
- Any change to ASG, do a instance refresh
- Instance Refresh is not available in this ASG module, we will learn this during Launch Template + ASG with Resources
```t
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
```

## Module-6: Change to Launch Configuration
- What happens?
- In next scale-in event changes will be adjusted [or] if instance refresh present and configured in this module it updates ASG with new LC ID, instance refresh should kick in.
- We will test this with next scale-in event - Run postman runner test
- Lets see that practically




## Step-02: ASG with ELB with Simple Scaling 
### V2-Terraform-Manifests: Simple Scaling 
- Implement Simple Scaling 

### V3-Terraform-Manifests: Step Scaling & 


### V5-Terraform-Manifests: Lifecycle Hooks

### V6-Terraform-Manifests: Modify LC and ASG

### V7-Terraform-Manifests: Monitoring

### Instance Refresh






## Step-02: Get Resource LABEL for TTS Policy ALBRequestCount policy

```
```
$ terraform import aws_autoscaling_policy.test-policy asg-name/policy-name

terraform import aws_autoscaling_policy.dkalyan-test-policy myapp1-asg-20210329045302504300000007/TP1
```

```

## References
- [Data Source: aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids)
- [Resource: aws_autoscaling_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy)
- [Resource: aws_autoscaling_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_notification)
- [Resource: aws_autoscaling_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule)
- [Pre-defined Metrics - Autoscaling](https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_PredefinedMetricSpecification.html)
