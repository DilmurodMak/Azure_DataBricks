# // Put users and service principals to their respective groups
# resource "databricks_group_member" "this" {
#   provider = databricks.azure_account
#   for_each = toset(flatten([
#     for group, details in data.azuread_group.this : [
#       for member in details["members"] : jsonencode({
#         group  = var.databricks_groups[details["object_id"]],
#         member = local.merged_user_sp[member]
#       })
#     ]
#   ]))
#   group_id   = jsondecode(each.value).group
#   member_id  = jsondecode(each.value).member
# }

// Identity federation - adding users/groups from Databricks account to workspace
resource "databricks_mws_permission_assignment" "workspace_user_groups" {
  for_each     = data.azuread_group.this
  provider     = databricks.azure_account
  workspace_id = var.databricks_workspace_id
  principal_id = var.databricks_groups[each.value["object_id"]]
  permissions  = each.key == "account_unity_admin" ? ["ADMIN"] : ["USER"]
  # depends_on   = [databricks_group_member.this]
}

// Create storage credentials, external locations, catalogs, schemas, and grants

// Create a container in storage account to be used by the environment catalog as root storage
resource "azurerm_storage_container" "environment_catalog" {
  name                  = local.storage_container_name
  storage_account_name  = var.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

// Storage credential creation to be used to create external location
resource "databricks_storage_credential" "external_mi" {
  name = "${local.environment}-location-mi-credential"
  azure_managed_identity {
    access_connector_id = var.azurerm_databricks_access_connector_id
  }
  owner      = "account_unity_admin"
  comment    = "Storage credential for all external locations"
  # depends_on = [databricks_mws_permission_assignment.workspace_user_groups]
}

// Create external location to be used as root storage by the environment catalog
resource "databricks_external_location" "environment_location" {
  name            = local.external_location_name
  url             = format("abfss://%s@%s.dfs.core.windows.net",
        azurerm_storage_container.environment_catalog.name,
        var.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  owner           = "account_unity_admin"
  comment         = "External location used by ${local.catalog_name} as root storage"
}

// Create environment-specific catalog
resource "databricks_catalog" "environment" {
  metastore_id = var.metastore_id
  name         = local.catalog_name
  comment      = "this catalog is for ${var.environment} env"
  owner        = "account_unity_admin"
  storage_root = replace(databricks_external_location.environment_location.url,  "/$", "") # remove trailing slash
  properties = {
    purpose = var.environment
  }
  depends_on = [databricks_external_location.environment_location]
}

// Grants on environment catalog
resource "databricks_grants" "environment_catalog" {
  catalog = databricks_catalog.environment.name
  grant {
    principal  = "data_engineer"
    privileges = ["USE_CATALOG"]
  }
  grant {
    principal  = "data_scientist"
    privileges = ["USE_CATALOG"]
  }
  grant {
    principal  = "data_analyst"
    privileges = ["USE_CATALOG"]
  }
}

// Create schemas for each layer (bronze, silver, gold) dynamically based on the environment
resource "databricks_schema" "bronze" {
  catalog_name = databricks_catalog.environment.id
  name         = "bronze"
  owner        = "account_unity_admin"
  comment      = "this database is for bronze layer tables/views"
}

// Grants on bronze schema
resource "databricks_grants" "bronze" {
  schema = databricks_schema.bronze.id
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }
}

// Create schema for silver datalake layer in environment
resource "databricks_schema" "silver" {
  catalog_name = databricks_catalog.environment.id
  name         = "silver"
  owner        = "account_unity_admin"
  comment      = "this database is for silver layer tables/views"
}

// Grants on silver schema
resource "databricks_grants" "silver" {
  schema = databricks_schema.silver.id
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }
  grant {
    principal  = "data_scientist"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}

// Create schema for gold datalake layer in environment
resource "databricks_schema" "gold" {
  catalog_name = databricks_catalog.environment.id
  name         = "gold"
  owner        = "account_unity_admin"
  comment      = "this database is for gold layer tables/views"
}

// Grants on gold schema
resource "databricks_grants" "gold" {
  schema = databricks_schema.gold.id
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }
  grant {
    principal  = "data_scientist"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
  grant {
    principal  = "data_analyst"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}