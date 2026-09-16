output "bucket_name" {
    description = "S3 bucket name"
    value = aws_s3_bucket.website.id
}

output "bucket_arn" {
    description = "S3 bucket ARN - needed when writing IAM policies"
    value = aws_s3_bucket.website.arn
}

output "cloudfront_domain" {
  description = "Your website URL — use this to access the site"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_id" {
  description = "Distribution ID — needed for cache invalidation"
  value       = aws_cloudfront_distribution.website.id
}