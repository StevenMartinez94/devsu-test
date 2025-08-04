# Contabo OAuth2 credentials for API access
variable "oauth2_client_id" {
  description = "Contabo OAuth2 Client ID"
  type        = string
  sensitive   = true
}

variable "oauth2_client_secret" {
  description = "Contabo OAuth2 Client Secret"
  type        = string
  sensitive   = true
}

variable "oauth2_user" {
  description = "Contabo username/email"
  type        = string
  sensitive   = true
}

variable "oauth2_pass" {
  description = "Contabo account password"
  type        = string
  sensitive   = true
}

# Instance configuration
variable "product_id" {
  description = "Contabo product ID (VPS plan)"
  type        = string
  default     = "V94" # VPS 20 - 6 vCPUs, 12GB RAM, 100GB NVMe
}

variable "region" {
  description = "Contabo region"
  type        = string
  default     = "US-east" # Available: EU, US-central, US-east, US-west, Asia (SG)
}

variable "image_id" {
  description = "Operating system image UUID"
  type        = string
  default     = "afecbb85-e2fc-46f0-9684-b46b1faf00bb" # Ubuntu 22.04 LTS
}
