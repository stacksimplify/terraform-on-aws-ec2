# Terraform Manifest Upgrades

## Step-01: c14-03-cloudwatch-alb-alarms.tf
```t
# Before
  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }

# After
  dimensions = {
    LoadBalancer = module.alb.arn_suffix # UPDATED 
  }  
```

## Step-02: c14-05-cloudwatch-synthetics.tf
```t
# Create S3 Bucket
resource "aws_s3_bucket" "cw_canary_bucket" {
  bucket = "cw-canary-bucket-${random_pet.this.id}"
  #acl    = "private" # UPDATED 
  force_destroy = true

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
# Create S3 Bucket Ownership control - ADDED NEW
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.cw_canary_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
# Create S3 Bucket ACL - ADDED NEW
resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]
  bucket = aws_s3_bucket.cw_canary_bucket.id
  acl    = "private"
}
```
