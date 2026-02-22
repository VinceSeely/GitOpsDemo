variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "greeting_name" {
  description = "Name to display in the greeting message"
  type        = string
  default     = "La Crosse Dev"
}
