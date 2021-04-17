terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.55.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  instance_count      = var.number_of_virtual_machines
  resource_group_name = var.resource_group_packer
  virtual_image_name  = var.image_name_packer
  admin_username      = "udacity"
  public_ssh_key      = file(var.public_ssh_key)
}

data "azurerm_resource_group" "main" {
  name = local.resource_group_name
}

data "azurerm_image" "main" {
  name                = local.virtual_image_name
  resource_group_name = data.azurerm_resource_group.main.name
}

// Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = var.tags
}

// Subnet
resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

// Public IP
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

// Network Interfaces
resource "azurerm_network_interface" "main" {
  count               = local.instance_count
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

// Availability Set for Virtual Machines
resource "azurerm_availability_set" "avset" {
  name                         = "${var.prefix}-avset"
  location                     = data.azurerm_resource_group.main.location
  resource_group_name          = data.azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = var.tags
}

// Network Security Group 
resource "azurerm_network_security_group" "webserver" {
  count               = local.instance_count
  name                = "${var.prefix}-webserverNSG-${count.index}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  security_rule {
    description                = "Explicitly allow access between VMs within virtual network."
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "allowAccessBetweenVMs"
    priority                   = 100
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = azurerm_subnet.internal.address_prefix
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
  }
  security_rule {
    description                = "Allow HTTP access from Internet clients to web servers in virtual network."
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "allowHTTPaccess"
    priority                   = 200
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = var.application_port
    destination_address_prefix = azurerm_subnet.internal.address_prefix
  }
  security_rule {
    description                = "Explicitly deny all other access from Internet to hosts on the virtual network."
    access                     = "Deny"
    direction                  = "Inbound"
    name                       = "denyOtherAccess"
    priority                   = 300
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
  }
  tags = var.tags
}

// Association between a Network Interface and a Network Security Group
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = local.instance_count
  network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
  network_security_group_id = element(azurerm_network_security_group.webserver.*.id, count.index)
}

// Load Balancer
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.prefix}-publicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
  tags = var.tags
}

resource "azurerm_lb_probe" "lb" {
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "${var.prefix}-http-running-probe"
  port                = 80
}

resource "azurerm_lb_backend_address_pool" "lb" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.prefix}-BackEndAddressPool"
}

resource "azurerm_lb_rule" "lb" {
  resource_group_name            = data.azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${var.prefix}-LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb.id
  probe_id                       = azurerm_lb_probe.lb.id
  idle_timeout_in_minutes        = 15
  enable_tcp_reset               = true
}

resource "azurerm_network_interface_backend_address_pool_association" "lb" {
  count                   = local.instance_count
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb.id
  ip_configuration_name   = "primary"
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
}

resource "azurerm_virtual_machine" "main" {
  count                 = local.instance_count
  name                  = "${var.prefix}-vm${count.index}"
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  network_interface_ids = [azurerm_network_interface.main[count.index].id, ]
  vm_size               = "Standard_B1s"
  availability_set_id   = azurerm_availability_set.avset.id
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true
  storage_image_reference {
    id = data.azurerm_image.main.id
  }
  storage_os_disk {
    name              = "${var.prefix}-osdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.prefix}-vm${count.index}"
    admin_username = local.admin_username
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${local.admin_username}/.ssh/authorized_keys"
      key_data = local.public_ssh_key
    }
  }
  tags = var.tags
}
