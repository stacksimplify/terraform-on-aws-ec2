---
title: Build Terraform Module from Scratch
description: Create Terraform Modules locally
---
# Build a Terraform Module

## Step-01: Introduction
- Build a Terraform Module
    - Create a Terraform module
    - Use local Terraform modules in your configuration
    - Configure modules with variables
    - Use module outputs
    - We are going to write a local re-usable module for the following usecase.
- **Usecase: Hosting a static website with AWS S3 buckets**
1. Create an S3 Bucket
2. Create Public Read policy for the bucket
3. Once above two are ready, we can deploy Static Content 
4. For steps, 1 and 2 we are going to create a re-usable module in Terraform
- **How are we going to do this?**
- We are going to do this in 3 sections
- **Section-1 - Full Manual:** Create Static Website on S3 using AWS Management Consoleand host static content and test 
- **Section-2 - Terraform Resources:** Automate section-1 using Terraform Resources
- **Section-3 - Terraform Modules:** Create a re-usable module for hosting static website by referencing section-2 terraform configuration files. 

## Step-02: Hosting a Static Website with AWS S3 using AWS Management Console
- **Reference Sub-folder:** v1-create-static-website-on-s3-using-aws-mgmt-console
- We are going to host a static website with AWS S3 using AWS Management console
### Step-02-01: Create AWS S3 Bucket
- Go to AWS Services -> S3 -> Create Bucket 
- **Bucket Name:** mybucket-1045 (Note: Bucket name should be unique across AWS)
- **Region:** US.East (N.Virginia)
- Rest all leave to defaults
- Click on **Create Bucket**

### Step-02-02: Enable Static website hosting
- Go to AWS Services -> S3 -> Buckets -> mybucket-1045 -> Properties Tab -> At the end
- Edit to enable **Static website hosting**
- **Static website hosting:** enable
- **Index document:** index.html
- Click on **Save Changes**

### Step-02-03: Remove Block public access (bucket settings)
- Go to AWS Services -> S3 -> Buckets -> mybucket-1045 -> Permissions Tab 
- Edit **Block public access (bucket settings)** 
- Uncheck **Block all public access**
- Click on **Save Changes**
- Provide text `confirm` and Click on **Confirm**

### Step-02-04: Add Bucket policy for public read by bucket owners
- Update your bucket name in the below listed policy
- **Location:** v1-create-static-website-on-s3-using-aws-mgmt-console/policy-public-read-access-for-website.json
```json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "PublicReadGetObject",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
              "s3:GetObject"
          ],
          "Resource": [
              "arn:aws:s3:::mybucket-1045/*"
          ]
      }
  ]
}
```
- Go to AWS Services -> S3 -> Buckets -> mybucket-1045 -> Permissions Tab 
- Edit -> **Bucket policy** -> Copy paste the policy above with your bucket name
- Click on **Save Changes**

### Step-02-05: Upload index.html
- **Location:** v1-create-static-website-on-s3-using-aws-mgmt-console/index.html
- Go to AWS Services -> S3 -> Buckets -> mybucket-1045 -> Objects Tab 
- Upload **index.html**

### Step-02-06: Access Static Website using S3 Website Endpoint
- Access the newly uploaded index.html to S3 bucket using browser
```
# Endpoint Format
http://example-bucket.s3-website.Region.amazonaws.com/

# Replace Values (Bucket Name, Region)
http://mybucket-1045.s3-website.us-east-1.amazonaws.com/
```

### Step-02-07: Conclusion
- We have used multiple manual steps to host a static website on AWS
- Now all the above manual steps automate using Terraform in next step

## Step-03: Create Terraform Configuration to Host a Static Website on AWS S3
- **Reference Sub-folder:** v2-host-static-website-on-s3-using-terraform-manifests
- We are going to host a static website on AWS S3 using general terraform configuration files
### Step-03-01: Create Terraform Configuration Files step by step
1. versions.tf
2. main.tf
3. variables.tf
4. outputs.tf
5. terraform.tfvars

### Step-03-02: Execute Terraform Commands & Verify the bucket
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Format
terraform fmt

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify 
1. Bucket has static website hosting enabled
2. Bucket has public read access enabled using policy
3. Bucket has "Block all public access" unchecked
```

### Step-03-03: Upload index.html and test
```
# Endpoint Format
http://example-bucket.s3-website.Region.amazonaws.com/

# Replace Values (Bucket Name, Region)
http://mybucket-1046.s3-website.us-east-1.amazonaws.com/
```
### Step-03-04: Destroy and Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Terraform files 
rm -rf .terraform*
rm -rf terraform.tfstate*
```


### Step-03-05: Conclusion
- Using above terraform configurations we have hosted a static website in AWS S3 in seconds. 
- In next step, we will convert these **terraform configuration files** to a Module which will be re-usable just by calling it.


## Step-04: Build a Terraform Module to Host a Static Website on AWS S3
- **Reference Sub-folder:** v3-build-a-module-to-host-static-website-on-aws-s3
- We will build a Terraform module to host a static website on AWS S3

### Step-04-01: Create Module Folder Structure
- We are going to create `modules` folder and in that we are going to create a module named `aws-s3-static-website-bucket`
- We will copy required files from previous section for this respective module.
- Terraform Working Directory: v3-build-a-module-to-host-static-website-on-aws-s3
    - modules
        - Module-1: aws-s3-static-website-bucket
            - main.tf
            - variables.tf
            - outputs.tf
            - README.md
            - LICENSE
- Inside `modules/aws-s3-static-website-bucket`, copy below listed three files from `v2-host-static-website-on-s3-using-terraform-manifests`
    - main.tf
    - variables.tf
    - outputs.tf


### Step-04-02: Call Module from Terraform Work Directory (Root Module)
- Create Terraform Configuration in Root Module by calling the newly created module
- c1-versions.tf
- c2-variables.tf
- c3-s3bucket.tf
- c4-outputs.tf
```t
module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"
  bucket_name = var.my_s3_bucket
  tags = var.my_s3_tags
}
```
### Step-04-03: Execute Terraform Commands
```
# Terraform Initialize
terraform init
Observation: 
1. Verify ".terraform", you will find "modules" folder in addition to "providers" folder
2. Verify inside ".terraform/modules" folder too.

# Terraform Validate
terraform validate

# Terraform Format
terraform fmt

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve

# Verify 
1. Bucket has static website hosting enabled
2. Bucket has public read access enabled using policy
3. Bucket has "Block all public access" unchecked
```

### Step-04-04: Upload index.html and test
```
# Endpoint Format
http://example-bucket.s3-website.Region.amazonaws.com/

# Replace Values (Bucket Name, Region)
http://mybucket-1047.s3-website.us-east-1.amazonaws.com/
```

### Step-04-05: Destroy and Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Terraform files 
rm -rf .terraform*
rm -rf terraform.tfstate*
```

### Step-04-06: Understand terraform get command
- We have used `terraform init` to download providers from terraform registry and at the same time to download `modules` present in local modules folder in terraform working directory. 
- Assuming we already have initialized using `terraform init` and later we have created `module` configs, we can `terraform get` to download the same.
- Whenever you add a new module to a configuration, Terraform must install the module before it can be used. 
- Both the `terraform get` and `terraform init` commands will install and update modules. 
- The `terraform init` command will also initialize backends and install plugins.
```
# Delete modules in .terraform folder
ls -lrt .terraform/modules
rm -rf .terraform/modules
ls -lrt .terraform/modules

# Terraform Get
terraform get
ls -lrt .terraform/modules
```
### Step-04-07: Major difference between Local and Remote Module
- When installing a remote module, Terraform will download it into the .terraform directory in your configuration's root directory. 
- When installing a local module, Terraform will instead refer directly to the source directory. 
- Because of this, Terraform will automatically notice changes to local modules without having to re-run terraform init or terraform get.

## Step-05: Conclusion
- Created a Terraform module
- Used local Terraform modules in your configuration
- Configured modules with variables
- Used module outputs



















