# Azure Databricks Unity Catalog

This repo contains terrafrom code to create a Databricks workspace and Databricks Unity Catalog. Also C# code to retrieve the catolg table content using JDBC connection and REST API file to use Azure Databrucsk REST API to get the catalog table content.

## Prerequisites

- Azure Databrick Premium Tier
- AAD Dummy Groups

## Terraform

1. Create Azure Databricks workspace - `Infra/adb-workspace` has a tarraform code to create a Databricks workspace.
2. Create Azure Databricks Unity Catalog - READ `Infra/READ.me` for full instruction. `adb-unity-catalog` has a terraform code to create a Databricks Unity Catalog, sync users from AAD, create storage account and link the external location, create catalog and schemas and assign permissions to the groups.

## C# Code

`CSharp` folder contains a C# code to retrieve the catalog table content using JDBC connection.

## REST API

Example usage of a Databricks REST API