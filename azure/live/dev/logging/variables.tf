variable "subscription_id" {
  type        = string
  description = "subscription id for all resources."
  default     = "2ab939f0-b0e1-4dd2-b4ab-7f5d959219af"
}

variable "owner" {
  description = "Tag value for Owner - resource owner"
  type        = string
  default     = "rodm"
}

variable "prefix" {
  description = "Prefix for az resources."
  type        = string
  default     = "ber"
}

variable "project_name" {
  description = "Project name for az resources."
  type        = string
  default     = "loggin"
}

variable "env" {
  description = "Env for az resources."
  type        = string
  default     = "dev"
}

# azure region
variable "location" {
  type        = string
  description = "Azure region where resources will be created"
  default     = "eastus"
}

variable "graylog_rg" {
  default = "ber-dev-eastus-graylog-rg"
}

variable "graylog_rg_location" {
  default = "ber-dev-eastus-graylog-rg"
}

#VNet
variable "vnet_name" {
  default = "ber-dev-network-vnet"
}

variable "vnet_rg" {
  default = "ber-dev-network-rg"
}

# Subnets
variable "subnet_frontend"{
  default = "ber-dev-app-subnet"
}

variable "subnet_backend"{
  default = "ber-dev-management-subnet"
}

# VM 
variable "frontend_instance_size" {
  type        = string
  default = "Standard_B2s"
}

variable "backend_instance_size" {
  type        = string
  default = "Standard_B2s"
}

# Application Gateway
variable "app_gateway_name" {
  default = "ber-dev-waf-gateway"
}

variable "app_gateway_rg" {
  default = "ber-dev-waf-rg"
}

variable "storage_rg" {
  default = "ber-dev-storage-rg"
}

variable "storage_account_name" {
  default = "berdevgraylogsta"
}

#variable "vnet_cidr" {
#  default = "10.10.0.0/16"
#}

#variable "subnet_graylog" {
#  default = "10.20.7.0/24"
#}

#variable "subnet_appgw" {
#  default = "10.20.5.0/24"
#}


variable "graylog_count" {
  default = 2
}
