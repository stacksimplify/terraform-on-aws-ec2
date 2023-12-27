---
title: Terraform DNS to DB Demo on AWS with EC2
description: Create a DNS to DB Demo on AWS with Route53, ALB, EC2 and RDS Database with 3 Applications
---
# Terraform DNS to DB Demo on AWS with EC2

## Pre-requisites
- Copy `terraform-manifests` from `10-ALB-Path-Based-Routing`
- You need a Registered Domain in AWS Route53 to implement this usecase
- Copy your `terraform-key.pem` file to `terraform-manifests/private-key` folder

## Step-01: Introduction
### Step-01-01: Create RDS Database Terraform Configs
- Create RDS DB Security Group
- Create RDS DB Variables with `sensitive` argument for DB password
- Create RDS DB Module
- Create RDS DB Outputs

### Step-01-02: Create EC2 Instance Terraform Configs
- Create EC2 Instance Module for new App3
- Create `tmpl` file for userdata (Use Terraform templatefle function)
- Create Outputs for EC2 Instance
- App Port 8080 inbound rule added to Private_SG module `"http-8080-tcp"`

### Step-01-03: Create ALB Terraform Configs
- Create ALB TG for App3 UMS with Port 8080
- Enable Stickiness for App3 UMS TG
- Create HTTPS Listener Rule for (/*)
- Listener Rule Priorities `priority = 1`
  - app1 - `priority = 1`
  - app2 - `priority = 2`
  - Root Context "/*" - `priority = 3`

### Step-01-04: Create Jumpbox server to have mysql client installed
- Using jumpbox userdata, mysql client should be auto-installed.
- Connect to Jumpbox to test if default db and tables created.
- Connect via Jumpbox to DB to verify webappdb, Tables and Content inside

### Step-01-05: Create DNS Name AWS Route53 Record Set
- Give `dns-to-db` DNS name for Route53 record

[![Image](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-2.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-3.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-3.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-4.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-dns-to-db-4.png)

## Step-03: Terraform RDS Database Configurations
- Create RDS DB Security Group
- Create RDS DB Variables with `sensitive` argument for DB password
- Create RDS DB Module
- Create RDS DB Outputs
### Step-03-01: c5-06-securitygroup-rdsdbsg.tf
- Create AWS RDS Database Security Group which will allow access to DB from any subnet inside a VPC.
```t
# Security Group for AWS RDS DB
module "rdsdb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  #version = "4.0.0"
  version = "5.1.0"  

  name        = "rdsdb-sg"
  description = "Access to MySQL DB for entire VPC CIDR Block"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]  
  tags = local.common_tags  
}
```

### Step-03-02: c13-01-rdsdb-variables.tf
- Understand about Terraform Variables `Sensitive Flag`
```t
# Terraform AWS RDS Database Variables
# Place holder file for AWS RDS Database

# DB Name
variable "db_name" {
  description = "AWS RDS Database Name"
  type        = string
}
# DB Instance Identifier
variable "db_instance_identifier" {
  description = "AWS RDS Database Instance Identifier"
  type        = string
}
# DB Username - Enable Sensitive flag
variable "db_username" {
  description = "AWS RDS Database Administrator Username"
  type        = string
}
# DB Password - Enable Sensitive flag
variable "db_password" {
  description = "AWS RDS Database Administrator Password"
  type        = string
  sensitive   = true
}

```
### Step-03-03: rdsdb.auto.tfvars
```t
# RDS Database Variables
db_name = "webappdb"
db_instance_identifier = "webappdb"
db_username = "dbadmin"
```
### Step-03-04: secrets.tfvars
```t
db_password = "dbpassword11"
```
### Step-03-05: c13-02-rdsdb.tf
```t
# Create AWS RDS Database
module "rdsdb" {
  source  = "terraform-aws-modules/rds/aws"
  #version = "2.34.0"
  #version = "3.0.0"
  version = "6.3.0"
  
  identifier = var.db_instance_identifier

  #name     = var.db_name  # Initial Database Name - DEPRECATED
  db_name     = var.db_name  # Added as part of Module v6.3.0
  username = var.db_username
  password = var.db_password
  manage_master_user_password = false # Added as part of Module v6.3.0
  port     = 3306


  multi_az               = true
  create_db_subnet_group = true # Added as part of Module v6.3.0
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.rdsdb_sg.security_group_id]

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0.35"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.large"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = false


  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.common_tags
  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}
```
### Step-03-06: c13-03-rdsdb-outputs.tf
```t
# RDS DB Outputs
output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.rdsdb.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rdsdb.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.rdsdb.db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.rdsdb.db_instance_endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = module.rdsdb.db_instance_hosted_zone_id
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = module.rdsdb.db_instance_id
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.rdsdb.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.rdsdb.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.rdsdb.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.rdsdb.db_instance_username
  sensitive   = true
}

output "db_instance_password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = module.rdsdb.db_instance_password
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = module.rdsdb.db_instance_port
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.rdsdb.db_subnet_group_id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = module.rdsdb.db_subnet_group_arn
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = module.rdsdb.db_parameter_group_id
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = module.rdsdb.db_parameter_group_arn
}

output "db_enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the monitoring role"
  value       = module.rdsdb.enhanced_monitoring_iam_role_arn
}


```

## Step-04: Create new EC2 Instance Module for App3 UMS
- **UMS:** User Management Web Application
- Create EC2 Instance Module for new App3
- Create `tmpl` file for userdata (Use Terraform templatefle function)
- Create Outputs for EC2 Instance
- App Port 8080 inbound rule added to Private_SG module `"http-8080-tcp"`

### Step-04-01: Terraform templatefile function
- [Terraform templatefile function](https://www.terraform.io/docs/language/functions/templatefile.html)
- `templatefile` reads the file at the given path and renders its content as a template using a supplied set of template variables.
```t
# Change Directory 
cd 13-DNS-to-DB/templatefile-function-demo
# Terraform Console
terraform console

# Terraform Tempaltefile Function
templatefile("app3-ums-install.tmpl",{rds_db_endpoint = "mydatabase"}) 
```
### Step-04-02: app3-ums-install.tmpl
```sh
#! /bin/bash
sudo amazon-linux-extras enable java-openjdk11
sudo yum clean metadata && sudo yum -y install java-11-openjdk
mkdir /home/ec2-user/app3-usermgmt && cd /home/ec2-user/app3-usermgmt
wget https://github.com/stacksimplify/temp1/releases/download/1.0.0/usermgmt-webapp.war -P /home/ec2-user/app3-usermgmt 
export DB_HOSTNAME=${rds_db_endpoint}
export DB_PORT=3306
export DB_NAME=webappdb
export DB_USERNAME=dbadmin
export DB_PASSWORD=dbpassword11
java -jar /home/ec2-user/app3-usermgmt/usermgmt-webapp.war > /home/ec2-user/app3-usermgmt/ums-start.log &
```
### Step-04-03: c7-06-ec2instance-private-app3.tf
```t
# AWS EC2 Instance Terraform Module
# EC2 Instances that will be created in VPC Private Subnets for App2
module "ec2_private_app3" {
  depends_on = [ module.vpc ] # VERY VERY IMPORTANT else userdata webserver provisioning will fail
  source  = "terraform-aws-modules/ec2-instance/aws"
  #version = "2.17.0"
  version = "5.5.0"
  # insert the 10 required variables here
  name                   = "${var.environment}-app3"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  #user_data = file("${path.module}/app3-ums-install.tmpl") - THIS WILL NOT WORK, use Terraform templatefile function as below.
  #https://www.terraform.io/docs/language/functions/templatefile.html
  user_data =  templatefile("app3-ums-install.tmpl",{rds_db_endpoint = module.rdsdb.db_instance_address})    
  tags = local.common_tags

# Changes as part of Module version from 2.17.0 to 5.5.0
  for_each = toset(["0", "1"])
  subnet_id =  element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [module.private_sg.security_group_id]
}
```

### Step-04-04: c7-02-ec2instance-outputs.tf
- Create Outputs for new App3 EC2 Instance
```t
# App3 - Private EC2 Instances
## ec2_private_instance_ids
output "app3_ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_private_app3.id
}
## ec2_private_ip
output "app3_ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value       = module.ec2_private_app3.private_ip 
}
```
### Step-04-05: c5-04-securitygroup-privatesg.tf
```t
  ingress_rules = ["ssh-tcp", "http-80-tcp", "http-8080-tcp"]
```

## Step-05: c10-02-ALB-application-loadbalancer.tf 
- Create ALB TG for App3 UMS with Port 8080
- Create HTTPS Listener Rule for (/*)
- Listener Rule Priorities like `priority = 1`
### Step-05-01: Create App3 Target Group
- Create App3 Target Group
```t

  # Target Group-3: mytg3       
   mytg3 = {
      # VERY IMPORTANT: We will create aws_lb_target_group_attachment resource separately, refer above GitHub issue URL.
      create_attachment = false
      name_prefix                       = "mytg3-"
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version = "HTTP1"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/login"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      tags = local.common_tags # Target Group Tags 
    }# END of Target Group-3: mytg3


# mytg3: LB Target Group Attachment
resource "aws_lb_target_group_attachment" "mytg3" {
  for_each = {for k,v in module.ec2_private_app3: k => v}
  target_group_arn = module.alb.target_groups["mytg3"].arn
  target_id        = each.value.id
  port             = 8080
}

```
### Step-05-02: Create Listener Rules for App3
```t
        # Rule-3: myapp3-rule
        myapp3-rule = {
          priority = 30          
          actions = [{
            type = "weighted-forward"
            target_groups = [
              {
                target_group_key = "mytg3"
                weight           = 1
              }
            ]
            stickiness = {
              enabled  = true
              duration = 3600
            }
          }]
          conditions = [{
            path_pattern = {
              values = ["/*"]
            }
          }]
        }# End of myapp3-rule Block
```
### Step-05-03: Implement Rule Priority for all 3 Listener Rules
- Listener Rule Priorities
- **/app1*:** `priority = 1`
- **/app2*:** `priority = 2`
- **Root Context /*:** `priority = 3`

## Step-06: Automate Jumpbox server to have mysql client installed
- Using jumpbox userdata, `mysql client` should be auto-installed.
- We will use jumpbox to connect to RDS MySQL DB by installing MySQL Client
### Step-06-01: jumpbox-install.sh
```t
#! /bin/bash
sudo yum update -y
sudo rpm -e --nodeps mariadb-libs-*
sudo amazon-linux-extras enable mariadb10.5 
sudo yum clean metadata
sudo yum install -y mariadb
sudo mysql -V
sudo yum install -y telnet
```
## Step-07: c12-route53-dnsregistration.tf
- Update the DNS name as desired to match our demo
```t
  name    = "dns-to-db1.devopsincloud.com"
```
## Step-08: Execute Terraform Commands
```t
# Terraform Init
terraform init 

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan -var-file="secrets.tfvars"

# Terraform Apply
terraform apply -var-file="secrets.tfvars"
```

## Step-09: Verify AWS Resources cretion on Cloud
1. EC2 Instances App1, App2, App3, Bastion Host
2. RDS Databases
3. ALB Listeners and Routing Rules
4. ALB Target Groups App1, App2 and App3 if they are healthy

## Step-10: Connect to DB
- Connect to Jumpbox to test if default db and tables created.
- Connect via Jumpbox to DB to verify webappdb, Tables and Content inside
```t
# Connect to MySQL DB
mysql -h webappdb.cxojydmxwly6.us-east-1.rds.amazonaws.com -u dbadmin -pdbpassword11
mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
```
- **Important Note:** If you the tables created and `default admin user` present in `user` that confirms our `User Management Web Application` is up and running on `App3 EC2 Instances`

## Step-11: Access Applications and Test
```t
# App1
https://dns-to-db.devopsincloud.com/app1/index.html

# App2
https://dns-to-db.devopsincloud.com/app2/index.html

# App3
https://dns-to-db.devopsincloud.com
Username: admin101
Password: password101
1. Create a user, List User
2. Verify user in DB
```

## Step-12: Additional Troubleshooting for App3
- Connect to App3 Instances
```t
# Connect to App3 EC2 Instance from Jumpbox
ssh -i /tmp/terraform-key.pem ec2-user@<App3-Ec2Instance-1-Private-IP>

# Check logs
cd app3-usermgmt
more ums-start.log

# For further troubleshooting
- Shutdown one EC2 instance from App3 and test with 1 instance
```

## Step-13: Clean-Up
```t
# Destroy Resources
terraform destroy -auto-approve

# Delete Files
rm -rf .terraform*
rm -rf terraform.tfstate
```

## References
- [AWS VPC Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS Security Group Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest)
- [AWS EC2 Instance Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest)
- [AWS Application Load Balancer Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
- [AWS ACM Certificate Manager Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest)
- [AWS RDS Database Terraform Module](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest)







