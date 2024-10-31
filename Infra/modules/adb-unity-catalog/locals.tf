locals {
  catalog_name              = "${var.environment}_catalog"
  external_location_name    = "${var.environment}-catalog-external-location"
  storage_container_name    = "${var.environment}-catalog"
  environment               = var.environment
}

locals {
  merged_user_sp = merge(var.databricks_users, var.databricks_sps)
}

locals {
  aad_groups = toset(var.aad_groups)
}
