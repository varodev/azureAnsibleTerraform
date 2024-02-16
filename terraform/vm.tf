variable "prefix" {
  default = "caso2"
}

resource "azurerm_resource_group" "caso2" {
  name     = "${var.prefix}-resources"
  location = "France Central"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.caso2.location
  resource_group_name = azurerm_resource_group.caso2.name
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.caso2.name
  location            = azurerm_resource_group.caso2.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "sec" {
  name                = "secure"
  location            = azurerm_resource_group.caso2.location
  resource_group_name = azurerm_resource_group.caso2.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.caso2.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.caso2.location
  resource_group_name = azurerm_resource_group.caso2.name

  ip_configuration {
    name                          = "mainip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "sec" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.sec.id
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.caso2.location
  resource_group_name   = azurerm_resource_group.caso2.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.prefix
    admin_username = "alvmorapa"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}