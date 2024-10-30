variable "region" {
  default = "West US 2"
}

variable "environment" {
  default = "development"
}

variable "subscription_id" {
  default = "aa491e2b-0acc-4729-be48-2eac028ab1c4"
}

variable "aad_groups" {
  default = ["account_unity_admin", "data_engineer", "data_analyst", "data_scientist"]
}

variable "metastore_name"{
  default = "metastore_azure_development"
}

variable "account_id" {
  default = "b4fa54e6-433b-4bda-b689-4631e7882ea3"
}