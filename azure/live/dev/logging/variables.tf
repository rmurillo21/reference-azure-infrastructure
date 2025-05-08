variable "location" {
  default = "East US"
}

variable "graylog_rg" {
  default = "ber-dev-eastus-graylog-rg"
}

variable "waf_rg" {
  default = "ber-dev-waf-rg"
}

variable "storage_rg" {
  default = "ber-dev-storage-rg"
}

variable "storage_account_name" {
  default = "berdevgraylogsta"
}

variable "vnet_cidr" {
  default = "10.10.0.0/16"
}

variable "subnet_graylog" {
  default = "10.20.7.0/24"
}

variable "subnet_appgw" {
  default = "10.20.5.0/24"
}

variable "app_gateway_name" {
  default = "ber-dev-waf-gateway"
}

variable "graylog_count" {
  default = 2
}
