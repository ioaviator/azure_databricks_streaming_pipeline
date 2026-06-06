resource "azurerm_resource_group" "event-stream-rg" {
  name     = "evnt-stream-rg"
  location = "East US"
}

resource "azurerm_eventhub_namespace" "envt_hub_stream_ns" {
  name                = "evnt-hub-stream-ns"
  location            = azurerm_resource_group.event-stream-rg.location
  resource_group_name = azurerm_resource_group.event-stream-rg.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    environment = "Development"
  }
}

resource "azurerm_eventhub" "evnt_hub_store" {
  name              = "evnt_hub_store"
  namespace_id      = azurerm_eventhub_namespace.envt_hub_stream_ns.id
  partition_count   = 2
  message_retention = 1
}


resource "azurerm_databricks_workspace" "databricks" {
  name                = "evnt-bricks"
  resource_group_name = azurerm_resource_group.event-stream-rg.name
  location            = azurerm_resource_group.event-stream-rg.location
  sku                 = "premium"

  tags = {
    Environment = "Development"
  }
}
