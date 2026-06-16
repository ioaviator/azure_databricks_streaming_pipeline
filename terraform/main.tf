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
    environment = "Development"
  }
}

resource "azurerm_eventhub_namespace_authorization_rule" "eventhub_auth_key" {
  name                = "event-hub-auth-key"
  namespace_name      = azurerm_eventhub_namespace.envt_hub_stream_ns.name
  resource_group_name = azurerm_resource_group.event_stream_rg.name

  listen = true
  send   = true
  manage = true
}

resource "azurerm_eventhub" "evnt_hub_store" {
  name              = "evnt_hub_store"
  namespace_id      = azurerm_eventhub_namespace.envt_hub_stream_ns.id
  partition_count   = 2
  message_retention = 1
}

resource "azurerm_key_vault" "main" {
  name                = "eventhubs-stream-kv"
  location            = azurerm_resource_group.event_stream_rg.location
  resource_group_name = azurerm_resource_group.event_stream_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Soft delete protects against accidental deletion
  soft_delete_retention_days = 7

  # Purge protection prevents permanent deletion during retention period
  purge_protection_enabled   = false
  rbac_authorization_enabled = true

  tags = {
    environment = "development"
    managed_by  = "terraform"
  }

  depends_on = [azurerm_resource_group.event_stream_rg]

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

  create_duration = "60s"
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

resource "azurerm_databricks_workspace" "databricks" {
  name                = "evnt-stream-bricks"
  resource_group_name = azurerm_resource_group.event_stream_rg.name
  location            = azurerm_resource_group.event_stream_rg.location
  sku                 = "premium"

  tags = {
    Environment = "Development"
  }
}
