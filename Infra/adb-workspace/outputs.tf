output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}