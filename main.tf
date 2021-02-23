#Configure the Microsoft Azure Provider
 provider "azurerm" {
   version = "=1.44.0"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "tf_azure_test" {
  name     = var.resource_group
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.tf_azure_test.location
  address_space       = [var.address_space]
  resource_group_name = azurerm_resource_group.tf_azure_test.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.tf_azure_test.name
  address_prefix       = var.subnet_prefix
}

# Create network security group
resource "azurerm_network_security_group" "tf-test-sg" {
  name                = "${var.prefix}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.tf_azure_test.name

  security_rule {
    name                       = "SSH"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP1"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "sql"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "serv1"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7180"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "serv2"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7190"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "exp"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "tf-test-nic" {
  name                      = "${var.prefix}tf-test-nic"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.tf_azure_test.name
  network_security_group_id = azurerm_network_security_group.tf-test-sg.id

  ip_configuration {
    name                          = "${var.prefix}ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf-test-pip.id
  }
}

# Create public IPs
resource "azurerm_public_ip" "tf-test-pip" {
  name                = "${var.prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.tf_azure_test.name
  allocation_method   = "Dynamic"
  domain_name_label   = var.hostname
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                = "${var.hostname}-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.tf_azure_test.name
  vm_size             = var.vm_size

  network_interface_ids         = [azurerm_network_interface.tf-test-nic.id]
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_os_disk {
    name              = "${var.hostname}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = var.hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = "true"
    ssh_keys {
      key_data = file("NVirginiaClouderaKEY.pub")
      path = "/home/${var.user}/.ssh/authorized_keys"
  }
  }
  

output "public_ip_address" {
  value = azurerm_public_ip.tf-test-pip.ip_address
}
