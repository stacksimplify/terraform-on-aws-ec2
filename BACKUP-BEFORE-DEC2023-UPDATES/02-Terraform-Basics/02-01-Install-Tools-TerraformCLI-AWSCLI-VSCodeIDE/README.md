# Terraform & AWS CLI Installation

## Step-01: Introduction
- Install Terraform CLI
- Install AWS CLI
- Install VS Code Editor
- Install HashiCorp Terraform plugin for VS Code


## Step-02: MACOS: Terraform Install
- [Download Terraform MAC](https://www.terraform.io/downloads.html)
- [Install CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Unzip the package
```
# Copy binary zip file to a folder
mkdir /Users/<YOUR-USER>/Documents/terraform-install
COPY Package to "terraform-install" folder

# Unzip
unzip <PACKAGE-NAME>
unzip terraform_0.14.3_darwin_amd64.zip

# Copy terraform binary to /usr/local/bin
echo $PATH
mv terraform /usr/local/bin

# Verify Version
terraform version

# To Uninstall Terraform (NOT REQUIRED)
rm -rf /usr/local/bin/terraform
``` 

## Step-03: MACOS: IDE for Terraform - VS Code Editor
- [Microsoft Visual Studio Code Editor](https://code.visualstudio.com/download)
- [Hashicorp Terraform Plugin for VS Code](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)


### Step-04: MACOS: Install AWS CLI
- [AWS CLI Install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [Install AWS CLI - MAC](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html#cliv2-mac-install-cmd)

```
# Install AWS CLI V2
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
which aws
aws --version

# Uninstall AWS CLI V2 (NOT REQUIRED)
which aws
ls -l /usr/local/bin/aws
sudo rm /usr/local/bin/aws
sudo rm /usr/local/bin/aws_completer
sudo rm -rf /usr/local/aws-cli
```


## Step-05: MACOS: Configure AWS Credentials 
- **Pre-requisite:** Should have AWS Account.
  - [Create an AWS Account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start)
- Generate Security Credentials using AWS Management Console
  - Go to Services -> IAM -> Users -> "Your-Admin-User" -> Security Credentials -> Create Access Key
- Configure AWS credentials using SSH Terminal on your local desktop
```
# Configure AWS Credentials in command line
$ aws configure
AWS Access Key ID [None]: AKIASUF7DEFKSIAWMZ7K
AWS Secret Access Key [None]: WL9G9Tl8lGm7w9t7B3NEDny1+w3N/K5F3HWtdFH/
Default region name [None]: us-east-1
Default output format [None]: json

# Verify if we are able list S3 buckets
aws s3 ls
```
- Verify the AWS Credentials Profile
```
cat $HOME/.aws/credentials 
```

## Step-06: WindowsOS: Terraform & AWS CLI Install
- [Download Terraform](https://www.terraform.io/downloads.html)
- [Install CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Unzip the package
- Create new folder `terraform-bins`
- Copy the `terraform.exe` to a `terraform-bins`
- Set PATH in windows 
- Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

## Step-07: LinuxOS: Terraform & AWS CLI Install
- [Download Terraform](https://www.terraform.io/downloads.html)
- [Linux OS - Terraform Install](https://learn.hashicorp.com/tutorials/terraform/install-cli)