variable "default_user" {}
variable "default_password" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "frontend_subnet" {
  description = "The frontend subnet where resources will be created"
  default     = "myFrontendSubnet"
}
variable "backend_subnet" {
  description = "The backend subnet where resources will be created"
  default     = "myBackendendSubnet"
}
variable "location" {
  description = "The location where resources will be created"
  default     = "Japan West"
}
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "myResourceGroup"
}

#  Imported using the resource
# terraform import azurerm_resource_group.mygroup /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/"${resource_group_name}"
terraform import azurerm_resource_group.mygroup /subscriptions/"${subscription_id}"/resourceGroups/"${resource_group_name}"

# Create an application gateway public ip
resource "azurerm_public_ip" "pip" {
  name                         = "my-pip-keisen-prd"
  location                     = "${location}"
  resource_group_name          = "${resource_group_name}"
  public_ip_address_allocation = "dynamic"
}

# Create an application gateway
resource "azurerm_application_gateway" "network" {
  name                = "my-application-gateway-keisen-prd"
  resource_group_name = "${resource_group_name}"
  location            = "${location}"

  sku {
    name           = "Standard_Small"
    tier           = "Standard"
    capacity       = 2
  }

  gateway_ip_configuration {
      name         = "my-gateway-ip-configuration"
      subnet_id    = "${azurerm_virtual_network.vnet.id}/subnets/${frontend_subnet}"
  }

  frontend_port {
      name         = "${azurerm_virtual_network.vnet.name}-feport"
      port         = 80
  }

  frontend_ip_configuration {
      name         = "${azurerm_virtual_network.vnet.name}-feip"  
      public_ip_address_id = "${azurerm_public_ip.pip.id}"
  }

  backend_address_pool {
      name = "${azurerm_virtual_network.vnet.name}-beap"
  }

  backend_http_settings {
      name                  = "${azurerm_virtual_network.vnet.name}-be-htst"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
     request_timeout        = 1
  }

  http_listener {
        name                                  = "${azurerm_virtual_network.vnet.name}-httplstn"
        frontend_ip_configuration_name        = "${azurerm_virtual_network.vnet.name}-feip"
        frontend_port_name                    = "${azurerm_virtual_network.vnet.name}-feport"
        protocol                              = "Http"
  }

  request_routing_rule {
          name                       = "${azurerm_virtual_network.vnet.name}-rqrt"
          rule_type                  = "Basic"
          http_listener_name         = "${azurerm_virtual_network.vnet.name}-httplstn"
          backend_address_pool_name  = "${azurerm_virtual_network.vnet.name}-beap"
          backend_http_settings_name = "${azurerm_virtual_network.vnet.name}-be-htst"
  }
}