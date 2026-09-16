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

# Origin Access Control (OAC)
# the identity CloudFront uses when requesting files from s3
resource "aws_cloudfront_origin_access_control" "website" {
    name = "${var.project_name}-${var.environment}-oac"
    description = "OAC for ${var.project_name} static website"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}

# CloudFront distribution
# CDN (Content Delivery Network) - that serves our website files to users globally
resource "aws_cloudfront_distribution" "website" {
    enabled = true
    default_root_object = "index.html"
    comment = "${var.project_name}-${var.environment}"

    origin {
        domain_name = aws_s3_bucket.website.bucket_regional_domain_name
        origin_id = "s3-${aws_s3_bucket.website.id}"
        origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    }

    default_cache_behavior {
        target_origin_id = "s3-${aws_s3_bucket.website.id}"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods = ["GET", "HEAD"]
        cached_methods = ["GET", "HEAD"]
        compress = true

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

# IAM policy doc (resource based policy)
# Principal - CloudFront service
# Action - s3:GetObject only (least privilege)
# Resource - every file inside the bucket
# Condition - ONLY requests from OUR distribution
data "aws_iam_policy_document" "website_bucket_policy" {
    statement {
        sid = "AllowCloudFrontOnly"
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }

        actions = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.website.arn}/*"]

        condition {
            test = "StringEquals"
            variable = "AWS:SourceArn"
            values = [aws_cloudfront_distribution.website.arn]
        }
    }
}

# attach the policy to the s3 bucket
resource "aws_s3_bucket_policy" "website" {
    bucket = aws_s3_bucket.website.id
    policy = data.aws_iam_policy_document.website_bucket_policy.json
}