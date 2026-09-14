variable "aws_region" {
    description = "AWS region to deploy"
    type = string
    default = "ap-south-1" # Change the region whatever we want
}

variable "project_name" {
    description = "Project name for tagging"
    type = string
    default = "aws-static-website"
}

variable "environment" {
    description = "Environment: dev, qa, stage, prod"
    type = string
    default = "dev"
    
    validation {
        condition = contains( ["dev", "qa", "stage", "prod"],
        var.environment ) 
        error_message = "Must be dev, qa, stage, or prod."
    }
}