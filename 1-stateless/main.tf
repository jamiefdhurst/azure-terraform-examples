# Include the Azure RM provider.
provider "azurerm" {
  features {}
  version = "~> 2.13"
}

# Resource group - everything in Azure belongs to this, a collection to hold all
# of your resources.
resource "azurerm_resource_group" "stateless" {
    location    = var.location
    name        = var.resource_group
}

# Virtual Network - Terraform builds this automatically for us within the
# resource group.
resource "azurerm_virtual_network" "vnet" {
  address_space         = [var.address_space]
  location              = azurerm_resource_group.stateless.location
  name                  = var.virtual_network_name
  resource_group_name   = azurerm_resource_group.stateless.name
}

# Subnet - the portion of the VNet that will be used to host the VM(s) in.
resource "azurerm_subnet" "subnet" {
  address_prefixes      = [var.subnet_prefix]
  name                  = "${var.prefix}-subnet"
  resource_group_name   = azurerm_resource_group.stateless.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
}

# Security Group - define a set of rules for the VM that we're creating. For
# this server, we're allowing both HTTP and SSH access.
resource "azurerm_network_security_group" "stateless" {
  location              = var.location
  name                  = "${var.prefix}-sg"
  resource_group_name   = azurerm_resource_group.stateless.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
}

# Public IP - our VM will need a public IP to be internet addressable.
resource "azurerm_public_ip" "stateless" {
  allocation_method   = "Dynamic"
  domain_name_label   = var.hostname
  location            = var.location
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.stateless.name
}

# Network Interface - this will be required by the VM and will dynamically
# allocate an IP within the subnet, along with the public IP created above.
resource "azurerm_network_interface" "stateless" {
  location                  = var.location
  name                      = "${var.prefix}-nic"
  resource_group_name       = azurerm_resource_group.stateless.name

  ip_configuration {
    name                            = "${var.prefix}-ipconfig"
    subnet_id                       = azurerm_subnet.subnet.id
    private_ip_address_allocation   = "Dynamic"
    public_ip_address_id            = azurerm_public_ip.stateless.id
  }
}

# Associate the security group and network interface
resource "azurerm_network_interface_security_group_association" "stateless" {
  network_interface_id      = azurerm_network_interface.stateless.id
  network_security_group_id = azurerm_network_security_group.stateless.id
}

# Virtual Machine - create our machine and deploy the default website.
resource "azurerm_virtual_machine" "web" {
  delete_os_disk_on_termination = "true"
  location                      = var.location
  name                          = "${var.hostname}-web"
  network_interface_ids         = [azurerm_network_interface.stateless.id]
  resource_group_name           = azurerm_resource_group.stateless.name
  vm_size                       = var.vm_size

  os_profile {
    admin_password  = var.admin_password
    admin_username  = var.admin_username
    computer_name   = var.hostname
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    offer       = var.image_offer
    publisher   = var.image_publisher
    sku         = var.image_sku
    version     = var.image_version
  }

  storage_os_disk {
    name                = "${var.hostname}-disk"
    managed_disk_type   = "Standard_LRS"
    caching             = "ReadWrite"
    create_option       = "FromImage"
  }

  # Copy the file over to the VM once created
  provisioner "file" {
    destination = "/home/${var.admin_username}/setup.sh"
    source      = "bin/setup.sh"

    connection {
      host      = azurerm_public_ip.stateless.fqdn
      password  = var.admin_password
      type      = "ssh"
      user      = var.admin_username
    }
  }

  # Run the shell script we copied over
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.admin_username}/setup.sh",
      "sudo /home/${var.admin_username}/setup.sh",
    ]

    connection {
      host      = azurerm_public_ip.stateless.fqdn
      password  = var.admin_password
      type      = "ssh"
      user      = var.admin_username
    }
  }
}