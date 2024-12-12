#!/bin/bash

# Set environment
region="southcentralus"
environment="dev"
subscription_id="aa491e2b-0acc-4729-be48-2eac028ab1c4"
metastore_name="metastore_azure_southcentralus"
account_id="b4fa54e6-433b-4bda-b689-4631e7882ea3"
prefix="dev"

aad_groups='["account_unity_admin","data_engineer","data_analyst","data_scientist"]'

# Function to deploy a Terraform module
deploy_adb_workspace() {
  local module_path=$1

  echo "Deploying module: ${module_path}"

  pushd "${module_path}" || exit 1

  terraform init || { echo "Terraform init failed"; exit 1; }
  terraform apply -auto-approve \
    -var="region=${region}" \
    -var="environment=${environment}" \
    -var="subscription_id=${subscription_id}" \
    || { echo "Terraform apply failed"; exit 1; }

  popd || exit 1
}

deploy_metastore_and_users() {
    local module_path=$1

    echo "Deploying module: ${module_path}"

    pushd "${module_path}" || exit 1

    terraform init || { echo "Terraform init failed"; exit 1; }
      terraform apply -auto-approve \
        -var="region=${region}" \
        -var="environment=${environment}" \
        -var="subscription_id=${subscription_id}" \
        -var="resource_group=${workspace_resource_group}" \
        -var="databricks_workspace_name=${workspace_name}" \
        -var="databricks_workspace_host_url=${workspace_host_url}" \
        -var="databricks_workspace_id=${workspace_id}" \
        -var="metastore_name=${metastore_name}" \
        -var="aad_groups=${aad_groups}" \
        -var="account_id=${account_id}" \
        -var="prefix=${prefix}" \
        || { echo "Terraform apply failed"; exit 1; }

    popd || exit 1
}

deploy_adb_unity_catalog(){
    local module_path=$1
    echo "Deploying module: ${module_path}"

    pushd "${module_path}" || exit 1
    
    terraform init || { echo "Terraform init failed"; exit 1; }
    terraform apply -auto-approve \
        -var="environment=${environment}" \
        -var="subscription_id=${subscription_id}" \
        -var="databricks_workspace_host_url=${workspace_host_url}" \
        -var="databricks_workspace_id=${workspace_id}" \
        -var="metastore_id=${metastore_id}" \
        -var="azurerm_storage_account_unity_catalog_id=${azurerm_storage_account_unity_catalog_id}" \
        -var="azure_storage_account_name"=${azure_storage_account_name} \
        -var="azurerm_databricks_access_connector_id=${azurerm_databricks_access_connector_id}" \
        -var="databricks_groups=${databricks_groups}" \
        -var="databricks_users=${databricks_users}" \
        -var="databricks_sps=${databricks_sps}" \
        -var="aad_groups=${aad_groups}" \
        -var="account_id=${account_id}" \
        || { echo "Terraform apply failed"; exit 1; }

    popd || exit 1
}

# Deploy Azure Databricks Workspace
workspace_module_path="../../modules/adb-workspace"
deploy_adb_workspace "${workspace_module_path}"

# Capture Workspace Outputs
workspace_name=$(terraform -chdir=${workspace_module_path} output -raw databricks_workspace_name)
workspace_resource_group=$(terraform -chdir=${workspace_module_path} output -raw resource_group)
workspace_host_url=$(terraform -chdir=${workspace_module_path} output -raw databricks_workspace_host_url)
workspace_id=$(terraform -chdir=${workspace_module_path} output -raw databricks_workspace_id)

# Export outputs as environment variables
export TF_VAR_databricks_workspace_name=${workspace_name}
export TF_VAR_resource_group=${workspace_resource_group}
export TF_VAR_databricks_workspace_host_url=${workspace_host_url}
export TF_VAR_databricks_workspace_id=${workspace_id}

# Deploy Metastore and Users
metastore_module_path="../../modules/metastore-and-users"
deploy_metastore_and_users "${metastore_module_path}"

# Capture Metastore Outputs
metastore_id=$(terraform -chdir=${metastore_module_path} output -raw metastore_id)
azurerm_storage_account_unity_catalog_id=$(terraform -chdir=${metastore_module_path} output -json | jq -r '.azurerm_storage_account_unity_catalog.value.id')
azure_storage_account_name=$(echo "$azurerm_storage_account_unity_catalog_id" | awk -F'/' '{print $NF}') # get storage account name
azurerm_databricks_access_connector_id=$(terraform -chdir=${metastore_module_path} output -json| jq -r '.azurerm_databricks_access_connector_id.value')
databricks_groups=$(terraform -chdir=${metastore_module_path} output -json databricks_groups)
databricks_users=$(terraform -chdir=${metastore_module_path} output -json databricks_users)
databricks_sps=$(terraform -chdir=${metastore_module_path} output -json databricks_sps)

# Export outputs as environment variables
export TF_VAR_metastore_id=${metastore_id}
export TF_VAR_azurerm_storage_account_unity_catalog_id=${azurerm_storage_account_unity_catalog_id}
export TF_VAR_azure_storage_account_name=${azure_storage_account_name}
export TF_VAR_azurerm_databricks_access_connector_id=${azurerm_databricks_access_connector_id}
export TF_VAR_databricks_groups=${databricks_groups}
export TF_VAR_databricks_users=${databricks_users}
export TF_VAR_databricks_sps=${databricks_sps}

# Deploy Unity Catalog
unity_catalog_module_path="../../modules/adb-unity-catalog"
deploy_adb_unity_catalog "${unity_catalog_module_path}"

echo "All modules deployed successfully."
