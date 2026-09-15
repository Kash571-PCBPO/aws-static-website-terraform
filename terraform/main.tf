# AWS S3 bucket and all security configuration
# fetches our aws accound id at runtime
data "aws_caller_identity" "current" {}

# S3 bucket
# name format: {project}-{env}-{acc_id}
resource "aws_s3_bucket" "website" {
    bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

# block all public access
# nobody can reach this bucket directly - CloudFront only
resource "aws_s3_bucket_public_access_block" "website" {
    bucket = aws_s3_bucket.website.id

    block_public_acls = true # ACL - Access Control List
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# versioning
# keeps older file versions - recover from accidental deletes
resource "aws_s3_bucket_versioning" "website" {
    bucket = aws_s3_bucket.website.id

    versioning_configuration {
        status = "Enabled"
    }
}

# encryption at rest
# all files stored in this 
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
     bucket = aws_s3_bucket.website.id

     rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
     }
}