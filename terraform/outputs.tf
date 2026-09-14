output "bucket_name" {
    description = "S3 bucket name"
    value = aws_s3_bucket.website.id
}

output "bucket_arn" {
    description = "S3 bucket ARN - needed when writing IAM policies"
    value = aws_s3_bucket.website.arn
}