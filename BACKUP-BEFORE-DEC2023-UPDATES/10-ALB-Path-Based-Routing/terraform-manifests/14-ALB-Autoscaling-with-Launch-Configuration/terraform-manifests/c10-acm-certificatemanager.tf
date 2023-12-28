# Get DNS information from AWS Route53
data "aws_route53_zone" "mydomain" {
  name = "devopsincloud.com"
}

# ACM Module - To create and Verify SSL Certificates
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.0"

  domain_name = trimsuffix(data.aws_route53_zone.mydomain.name, ".") 
  zone_id     = data.aws_route53_zone.mydomain.id
  subject_alternative_names = [
    "apps.devopsincloud.com",
    "app1.devopsincloud.com",
    "app2.devopsincloud.com",
    "default.devopsincloud.com",
    "custom-header.devopsincloud.com",
    "redirects1.devopsincloud.com",
    "lb-to-db1.devopsincloud.com",
    "asg-lc2.devopsincloud.com",
  ]
}