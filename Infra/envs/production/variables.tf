variable "region" {
  default = ""
}

variable "environment" {
  default = "stg"
}

variable "subscription_id" {
  default = ""
}

variable "aad_groups" {
  default = [""]
}

variable "metastore_name"{
  default = "metastore_azure_stg"
}

variable "account_id" {
  description = "Databricks Account Level ID"
  default = "b4fa54e6-433b-4bda-b689-4631e7882ea3"
}