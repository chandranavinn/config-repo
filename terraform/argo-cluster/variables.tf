variable "aws_region" {
  description = "AWS region for the Argo CD control-plane cluster."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project prefix used for resource names."
  type        = string
  default     = "deployboard"
}

variable "environment" {
  description = "Environment label for the Argo control-plane cluster."
  type        = string
  default     = "argo"
}

variable "cluster_name" {
  description = "Name of the dedicated EKS cluster that will host Argo CD."
  type        = string
  default     = "deployboard-argo-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for the Argo cluster VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Two AZs for the Argo cluster VPC and EKS node group."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "eks_version" {
  description = "Kubernetes version for the Argo control-plane cluster."
  type        = string
  default     = "1.33"
}

variable "eks_node_instance_type" {
  description = "EC2 type for the Argo control-plane node group."
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "Desired number of Argo control-plane worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of Argo control-plane worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of Argo control-plane worker nodes."
  type        = number
  default     = 3
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD will be installed."
  type        = string
  default     = "argocd"
}

variable "argocd_release_name" {
  description = "Helm release name for Argo CD."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for Argo CD."
  type        = string
  default     = "7.7.1"
}
