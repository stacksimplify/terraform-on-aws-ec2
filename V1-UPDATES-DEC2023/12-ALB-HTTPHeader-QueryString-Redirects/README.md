---
title: AWS ALB Different Listener Rules for Routing
description: Create AWS Application Load Balancer Custom HTTP Header, 302 Redirects with Query String and Host Headers
---
# AWS ALB Query String, Host Header Redirects and Custom Header Routing

## Pre-requisites
- You need a Registered Domain in AWS Route53 to implement this usecase
- Copy your `terraform-key.pem` file to `terraform-manifests/private-key` folder

## Step-01: Introduction
- We are going to implement four AWS ALB Application HTTPS Listener Rules
- Rule-1 and Rule-2 will outline the Custom HTTP Header based Routing
- Rule-3 and Rule-4 will outline the HTTP Redirect using Query String and Host Header based rules
- **Rule-1:** custom-header=my-app-1 should go to App1 EC2 Instances
- **Rule-2:** custom-header=my-app-2 should go to App2 EC2 Instances   
- **Rule-3:** When Query-String, website=aws-eks redirect to https://stacksimplify.com/aws-eks/ 
- **Rule-4:** When Host Header = azure-aks.devopsincloud.com, redirect to https://stacksimplify.

- Understand about Priority feature for Rules `priority = 2`

[![Image](https://stacksimplify.com/course-images/terraform-aws-alb-custom-header-routing-redirects302-querystring-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-alb-custom-header-routing-redirects302-querystring-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-alb-custom-header-routing-redirects302-querystring-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-alb-custom-header-routing-redirects302-querystring-2.png)

## Step-02: c10-02-ALB-application-loadbalancer.tf
- Define different HTTPS Listener Rules for ALB Load Balancer
### Step-02-01: Rule-1: Custom Header Rule for App-1
- Rule-1: custom-header=my-app-1 should go to App1 EC2 Instances
```t
        # Rule-1: myapp1-rule - custom-header=my-app-1 should go to App1 EC2 Instances
        myapp1-rule = {
          priority = 1
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
            http_header = {
              http_header_name = "custom-header"
              values           = ["app-1", "app1", "my-app-1"]
            }
          }]
        }# End of myapp1-rule
```
### Step-02-02: Rule-2: Custom Header Rule for App-1
- Rule-2: custom-header=my-app-2 should go to App2 EC2 Instances    
```t
        # Rule-2: myapp2-rule - custom-header=my-app-2 should go to App2 EC2 Instances    
        myapp2-rule = {
          priority = 2
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
            http_header = {
              http_header_name = "custom-header"
              values           =  ["app-2", "app2", "my-app-2"]
            }
          }]
        }# End of myapp2-rule Block
  
```
### Step-02-03: Rule-3: Query String Redirect
- Rule-3: When Query-String, website=aws-eks redirect to https://stacksimplify.com/aws-eks/
```t
  # Rule-3: When Query-String, website=aws-eks redirect to https://stacksimplify.com/aws-eks/
        # Rule-3: Query String Redirect Redirect Rule
        my-redirect-query = {
          priority = 3
          actions = [{
            type        = "redirect"
            status_code = "HTTP_302"
            host        = "stacksimplify.com"
            path        = "/aws-eks/"
            query       = ""
            protocol    = "HTTPS"
          }]

          conditions = [{
            query_string = {
              key   = "website"
              value = "aws-eks"
            }
          }]
        }# End of Rule-3 Query String Redirect Redirect Rule
```
### Step-02-04: Rule-4: Host Header Redirect
- Rule-4: When Host Header = azure-aks.devopsincloud.com, redirect to https://stacksimplify.com/azure-aks/azure-kubernetes-service-introduction/
```t
  # Rule-4: When Host Header = azure-aks.devopsincloud.com, redirect to https://stacksimplify.com/azure-aks/azure-kubernetes-service-introduction/
        # Rule-4: Host Header Redirect
        my-redirect-hh = {
          priority = 4
          actions = [{
            type        = "redirect"
            status_code = "HTTP_302"
            host        = "stacksimplify.com"
            path        = "/azure-aks/azure-kubernetes-service-introduction/"
            query       = ""
            protocol    = "HTTPS"
          }]

          conditions = [{
            host_header = {
              values = ["azure-aks11.devopsincloud.com"]
            }
          }]
        }# Rule-4: Host Header Redirect 
```

## Step-03: c12-route53-dnsregistration.tf
```t
# DNS Registration 
## Default DNS
resource "aws_route53_record" "default_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = "myapps11.devopsincloud.com"
  type    = "A"
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }  
}

## Testing Host Header - Redirect to External Site from ALB HTTPS Listener Rules
resource "aws_route53_record" "app1_dns" {
  zone_id = data.aws_route53_zone.mydomain.zone_id 
  name    = "azure-aks11.devopsincloud.com"
  type    = "A"
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }  
}
```
## Step-04: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terrform Apply
terraform apply -auto-approve
```

## Step-06: Verify HTTP Header Based Routing (Rule-1 and Rule-2)
- Rest Clinets we can use
- https://restninja.io/ 
- https://www.webtools.services/online-rest-api-client
- https://reqbin.com/
```t
# Verify Rule-1 and Rule-2
https://myapps.devopsincloud.com
custom-header = my-app-1  - Should get the page from App1 
custom-header = my-app-2  - Should get the page from App2
```

## Step-07: Verify Rule-3 
- When Query-String, website=aws-eks redirect to https://stacksimplify.com/aws-eks/
```t
# Verify Rule-3
https://myapps.devopsincloud.com/?website=aws-eks 
Observation: 
1. Should Redirect to https://stacksimplify.com/aws-eks/
```

## Step-08: Verify Rule-4
-  When Host Header = azure-aks.devopsincloud.com, redirect to https://stacksimplify.com/azure-aks/azure-kubernetes-service-introduction/
```t
# Verify Rule-4
http://azure-aks.devopsincloud.com
Observation: 
1. Should redirect to https://stacksimplify.com/azure-aks/azure-kubernetes-service-introduction/
```

## Step-09: Clean-Up
```t
# Destroy Resources
terraform destroy -auto-approve

# Delete Files
rm -rf .terraform*
rm -rf terraform.tfstate
```


## References
- [Terraform AWS ALB](https://github.com/terraform-aws-modules/terraform-aws-alb)
