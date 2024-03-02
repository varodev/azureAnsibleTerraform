#prefijo de nombre de recursos
variable "prefix" {
  default = "caso2"
}

variable "pwd" {
  default = "Password1234!"
}

#Creación de grupo de recursos de la práctica
resource "azurerm_resource_group" "caso2" {
  name     = "${var.prefix}-resources"
  location = "France Central"
}

#VNET de VMs
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.caso2.location
  resource_group_name = azurerm_resource_group.caso2.name
}

#Ip pública
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-publicip"
  resource_group_name = azurerm_resource_group.caso2.name
  location            = azurerm_resource_group.caso2.location
  allocation_method   = "Dynamic"
  domain_name_label   = "alvmorapa"
}

# Grupo de seguridad de la VNET principal
resource "azurerm_network_security_group" "sec" {
  name                = "secure"
  location            = azurerm_resource_group.caso2.location
  resource_group_name = azurerm_resource_group.caso2.name

  # Habilitar puerto SSH en Firewal de Azure (Grupo de Seguridad)
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

# Crear subred dentro de la VNET
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.caso2.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Crear NIC para la VM asociada a la subred previa
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

# Asociar grupo de seguridad a la NIC creada
resource "azurerm_network_interface_security_group_association" "sec" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.sec.id
}

# VM de despliegues
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.caso2.location
  resource_group_name   = azurerm_resource_group.caso2.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  # Referencia al OS base
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
    admin_password = var.pwd
  }
  
  # Habilitar login por password
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Escritura de ficheros de autenticación de ACR para Ansible
resource "null_resource" "acr" {
  connection {
    type     = "ssh"
    user     = "alvmorapa"
    password = var.pwd
    host     = azurerm_public_ip.public_ip.ip_address
  }

  provisioner "file" {
    destination = "/tmp/acr"
    content     = <<EOF
    ACR_USERNAME=${azurerm_container_registry.acr.admin_username}
    ACR_PASSWORD=${azurerm_container_registry.acr.admin_password}
    ACR_NAME=${azurerm_container_registry.acr.login_server}
    EOF
  }
}