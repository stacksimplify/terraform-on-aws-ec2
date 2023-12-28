# Terraform Variables and Datasources

## Step-00: Pre-requisite Note
- Create a `terraform-key` in AWS EC2 Key pairs which we will reference in our EC2 Instance

## Step-01: Introduction
### Terraform Concepts
- Terraform Input Variables
- Terraform Datasources
- Terraform Output Values

### What are we going to learn ?
1. Learn about Terraform `Input Variable` basics
  - AWS Region
  - Instance Type
  - Key Name 
2. Define `Security Groups` and Associate them as a `List item` to AWS EC2 Instance  
  - vpc-ssh
  - vpc-web
3. Learn about Terraform `Output Values`
  - Public IP
  - Public DNS
4. Get latest EC2 AMI ID Using `Terraform Datasources` concept
5. We are also going to use existing EC2 Key pair `terraform-key`
6. Use all the above to create an EC2 Instance in default VPC


## Step-02: c2-variables.tf - Define Input Variables in Terraform
- [Terraform Input Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Terraform Input Variable Usage - 10 different types](https://github.com/stacksimplify/hashicorp-certified-terraform-associate/tree/main/05-Terraform-Variables/05-01-Terraform-Input-Variables)
```t
# AWS Region
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"  
}

# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"  
}

# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  default = "terraform-key"
}
```
- Reference the variables in respective `.tf`fies
```t
# c1-versions.tf
region  = var.aws_region

# c5-ec2instance.tf
instance_type = var.instance_type
key_name = var.instance_keypair  
```

## Step-03: c3-ec2securitygroups.tf - Define Security Group Resources in Terraform
- [Resource: aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
```t
# Create Security Group - SSH Traffic
resource "aws_security_group" "vpc-ssh" {
  name        = "vpc-ssh"
  description = "Dev VPC SSH"
  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
  name        = "vpc-web"
  description = "Dev VPC web"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
- Reference the security groups in `c5-ec2instance.tf` file as a list item
```t
# List Item
vpc_security_group_ids = [aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id]  
```

## Step-04: c4-ami-datasource.tf - Define Get Latest AMI ID for Amazon Linux2 OS
- [Data Source: aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)
```t
# Get latest AMI ID for Amazon Linux2 OS
# Get Latest AWS AMI ID for Amazon2 Linux
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-gp2" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}
```
- Reference the datasource in `c5-ec2instance.tf` file
```t
# Reference Datasource to get the latest AMI ID
ami = data.aws_ami.amzlinux2.id 
```

## Step-05: c5-ec2instance.tf - Define EC2 Instance Resource
- [Resource: aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
```t
# EC2 Instance
resource "aws_instance" "myec2vm" {
  ami = data.aws_ami.amzlinux2.id 
  instance_type = var.instance_type
  user_data = file("${path.module}/app1-install.sh")
  key_name = var.instance_keypair
  vpc_security_group_ids = [aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id]  
  tags = {
    "Name" = "EC2 Demo 2"
  }
}
```


## Step-06: c6-outputs.tf - Define Output Values 
- [Output Values](https://www.terraform.io/docs/language/values/outputs.html)
```t
# Terraform Output Values
output "instance_publicip" {
  description = "EC2 Instance Public IP"
  value = aws_instance.myec2vm.public_ip
}

output "instance_publicdns" {
  description = "EC2 Instance Public DNS"
  value = aws_instance.myec2vm.public_dns
}
```

## Step-07: Execute Terraform Commands
```t
# Terraform Initialize
terraform init
Observation:
1) Initialized Local Backend
2) Downloaded the provider plugins (initialized plugins)
3) Review the folder structure ".terraform folder"

# Terraform Validate
terraform validate
Observation:
1) If any changes to files, those will come as printed in stdout (those file names will be printed in CLI)

# Terraform Plan
terraform plan
Observation:
1) Verify the latest AMI ID picked and displayed in plan
2) Verify the number of resources that going to get created
3) Verify the variable replacements worked as expected

# Terraform Apply
terraform apply 
[or]
terraform apply -auto-approve
Observations:
1) Create resources on cloud
2) Created terraform.tfstate file when you run the terraform apply command
3) Verify the EC2 Instance AMI ID which got created
```

## Step-08: Access Application
```t
# Access index.html
http://<PUBLIC-IP>/index.html
http://<PUBLIC-IP>/app1/index.html

# Access metadata.html
http://<PUBLIC-IP>/app1/metadata.html
```

## Step-09: Clean-Up
```t
# Terraform Destroy
terraform plan -destroy  # You can view destroy plan using this command
terraform destroy

# Clean-Up Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```
  