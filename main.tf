provider "azurerm" {
  version = "=2.5.0"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.rgName}"
  location = "${var.location}"
}

/*
resource "azurerm_availability_set" "DemoAset" {
  name                = "example-aset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
*/

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnetName}"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${var.rgName}"
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnetName}"
  resource_group_name  = "${var.rgName}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "example" {
  name                = "${var.nicName}"
  location            = "${var.location}"
  resource_group_name = "${var.rgName}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "${var.vmName}"
  resource_group_name = "${var.rgName}"
  location            = "${var.location}"
  depends_on          = [azurerm_resource_group.rg]
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
