variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "owner" {
  description = "Owner prefix for all AWS resource names (e.g. anat)"
  type        = string
  default     = "anat"
}

variable "project" {
  description = "Project name — combined with owner for resource naming"
  type        = string
  default     = "trainings-tracker"
}

variable "your_ip" {
  description = "Your public IP with /32 mask for SSH access (e.g. 1.2.3.4/32). Find it at whatismyip.com"
  type        = string
}

variable "db_password" {
  description = "MySQL RDS password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "MySQL RDS username"
  type        = string
  default     = "trainings"
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "trainings_tracker"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "anat-trainings-tracker-key"
}

# Convenience local — used in all resource Name tags
locals {
  name_prefix = "${var.owner}-${var.project}"
}
