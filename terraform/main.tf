resource "azurerm_resource_group" "event_stream_rg" {
  name     = "evnt-stream-rg"
  location = "East US"
}

# Get the current client configuration for access policies
data "azurerm_client_config" "current" {}

data "azurerm_eventhub_namespace_authorization_rule" "eventhub_ns_auth_rule" {
  name                = azurerm_eventhub_namespace_authorization_rule.eventhub_auth_key.name
  resource_group_name = azurerm_resource_group.event_stream_rg.name
  namespace_name      = azurerm_eventhub_namespace.envt_hub_stream_ns.name
}

resource "azurerm_eventhub_namespace" "envt_hub_stream_ns" {
  name                = "evnt-hub-stream-ns"
  location            = azurerm_resource_group.event_stream_rg.location
  resource_group_name = azurerm_resource_group.event_stream_rg.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

resource "azurerm_eventhub" "evnt_hub_store" {
  name              = "evnt_hub_store"
  namespace_id      = azurerm_eventhub_namespace.envt_hub_stream_ns.id
  partition_count   = 2
  message_retention = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "eventhub_auth_key" {
  name                = "event-hub-auth-key"
  namespace_name      = azurerm_eventhub_namespace.envt_hub_stream_ns.name
  resource_group_name = azurerm_resource_group.event_stream_rg.name

  listen = true
  send   = true
  manage = true
}

resource "azurerm_key_vault" "main" {
  name                = "eventhubs-stream-kv"
  location            = azurerm_resource_group.event_stream_rg.location
  resource_group_name = azurerm_resource_group.event_stream_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # protects against accidental deletion
  soft_delete_retention_days = 7

  # prevents permanent deletion during retention period
  purge_protection_enabled   = false
  rbac_authorization_enabled = true

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }

  depends_on = [
    azurerm_resource_group.event_stream_rg,     
    azurerm_eventhub_namespace_authorization_rule.eventhub_auth_key
  ]

}

# Grant the admin the Key Vault Secrets role
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "wait_for_key_vault_rbac" {
  depends_on = [
    azurerm_role_assignment.kv_admin
  ]

  create_duration = "50s"
}

resource "azurerm_key_vault_secret" "vault_secret" {
  name         = "key-vault-secret-event-hub"
  value        = azurerm_eventhub_namespace_authorization_rule.eventhub_auth_key.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    time_sleep.wait_for_key_vault_rbac,
    azurerm_eventhub_namespace_authorization_rule.eventhub_auth_key
  ]
}


# Azure Databricks Setup

resource "time_sleep" "wait_for_databricks_workspace" {
  depends_on = [
    azurerm_databricks_workspace.databricks
  ]

  create_duration = "30s"
}

data "databricks_current_user" "current_user" {
  depends_on = [
    time_sleep.wait_for_databricks_workspace
  ]
}

resource "azurerm_databricks_workspace" "databricks" {
  name                = "evnt-stream-bricks"
  resource_group_name = azurerm_resource_group.event_stream_rg.name
  location            = azurerm_resource_group.event_stream_rg.location
  sku                 = "premium"

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

resource "databricks_cluster" "evnt_stream_cluster" {
  cluster_name            = "event_stream_cluster"
  spark_version           = "17.3.x-scala2.13"
  node_type_id            = "Standard_DC4as_v5"
  autotermination_minutes = 20

  data_security_mode = "DATA_SECURITY_MODE_DEDICATED"
  kind               = "CLASSIC_PREVIEW"
  is_single_node     = true
  single_user_name   = data.databricks_current_user.current_user.user_name

  custom_tags = {
    environment = "development"
    managed_by  = "terraform"
  }

  depends_on = [
    time_sleep.wait_for_databricks_workspace
  ]
}

# Fetch credentials in azure key vault: create secret scope in databricks
data "azurerm_key_vault" "kv_credentials" {
  name                = azurerm_key_vault.main.name
  resource_group_name = azurerm_resource_group.event_stream_rg.name
}

# Create the Key Vault-backed Secret Scope in Databricks
resource "databricks_secret_scope" "kv_databricks_scope" {
  name = "azure-keyvault-databricks-scope"

  keyvault_metadata {
    resource_id = data.azurerm_key_vault.kv_credentials.id
    dns_name    = data.azurerm_key_vault.kv_credentials.vault_uri
  }
}

# grant databricks permission to key vault
resource "azurerm_role_assignment" "databricks_kv_secrets_user" {
  scope                = data.azurerm_key_vault.kv_credentials.id
  role_definition_name = "Key Vault Secrets User"

  # Azure principal object id
  principal_id         = "96e76deb-66b5-4440-9d70-f5bc065371f1"
}


# Databricks Notebook
# -----------------------------------------------------
# locals {
#   databricks_project_path = "/Workspace${data.databricks_current_user.current_user.home}/eventhub_streaming_pipeline"
# }

# resource "databricks_directory" "project_folder" {
#   path = local.databricks_project_path

#   depends_on = [
#     time_sleep.wait_for_databricks_workspace
#   ]
# }

# resource "databricks_notebook" "stream_processor" {
#   path     = "${local.databricks_project_path}/data_stream_events"
#   language = "PYTHON"
#   source   = "${path.module}/../data_stream_events.py"

#   depends_on = [
#     databricks_directory.project_folder
#   ]
# }

# resource "databricks_workspace_file" "requirements_file" {
#   path   = "${local.databricks_project_path}/requirements.txt"
#   source = "${path.module}/../requirements.txt"

#   depends_on = [
#     databricks_directory.project_folder
#   ]
# }

# resource "databricks_library" "python_libraries" {
#   cluster_id   = databricks_cluster.evnt_stream_cluster.id
#   requirements = databricks_workspace_file.requirements_file.path

#   depends_on = [
#     databricks_workspace_file.requirements_file,
#     databricks_cluster.evnt_stream_cluster
#   ]
# }
