variable "aws_region" {
  description = "AWS region for the database foundation."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project prefix used in resource names."
  type        = string
  default     = "deployboard"
}

variable "environment" {
  description = "Environment represented by this first database."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR range for the Cluster 1 learning VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "Two availability zones required by the RDS subnet group."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones are required."
  }
}

variable "db_instance_class" {
  description = "Small Graviton instance for the learning database."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Initial PostgreSQL storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial application database name."
  type        = string
  default     = "deployboard_dev"
}

variable "db_master_username" {
  description = "RDS administrator username; password is managed by AWS Secrets Manager."
  type        = string
  default     = "deployboard_admin"
}

variable "deletion_protection" {
  description = "Protect RDS from deletion. Keep false while learning teardown; enable for stable environments."
  type        = bool
  default     = false
}

variable "ssm_bridge_instance_type" {
  description = "Small EC2 instance used only for SSM port forwarding to private RDS."
  type        = string
  default     = "t3.micro"
}
