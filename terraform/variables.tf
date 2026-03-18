variable "dd_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "dd_site" {
  description = "Datadog site (e.g. datadoghq.com, datadoghq.eu)"
  type        = string
  default     = "datadoghq.com"
}

variable "dd_env" {
  description = "DD_ENV tag value"
  type        = string
  default     = "corndog-260318"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type — needs enough RAM for all containers"
  type        = string
  default     = "t3.xlarge"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access (leave empty to disable SSH)"
  type        = string
  default     = ""
}

variable "repo_url" {
  description = "Git repo URL to clone on the instance"
  type        = string
  default     = ""
}

variable "repo_branch" {
  description = "Git branch to check out"
  type        = string
  default     = "main"
}
