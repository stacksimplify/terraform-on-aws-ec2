# Output variable definitions
output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.mywebsite.id
}

output "arn" {
  description = "ARN of the S3 Bucket"
  value       = aws_s3_bucket.mywebsite.arn
}

output "bucket_domain_name" {
  description = "Bucket Domain Name of the S3 Bucket"
  value       = aws_s3_bucket.mywebsite.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional Domain Name of the S3 Bucket"
  value       = aws_s3_bucket.mywebsite.bucket_regional_domain_name
}

output "bucket_region" {
  description = "S3 Bucket Region"
  value       = aws_s3_bucket.mywebsite.region
}


# Static Website URL
output "static_website_url" {
  value = "http://${aws_s3_bucket.mywebsite.bucket}.s3-website.${aws_s3_bucket.mywebsite.region}.amazonaws.com"
}
