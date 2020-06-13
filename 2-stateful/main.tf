# Include the Azure RM provider.
provider "azurerm" {
  features {}
  version = "~> 2.13"
}

# Include the random provider to generate random passwords.
provider "random" {
  version = "~> 2.2"
}

# Include the Kubernetes provider, using variables from the Kubernetes cluster
# that will be created later.
provider "kubernetes" {
  version = "~> 1.11"

  host = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  load_config_file = false
  client_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
  client_key = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
}

# Resource group - everything in Azure belongs to this, a collection to hold all
# of your resources.
resource "azurerm_resource_group" "stateful" {
    location    = var.location
    name        = var.resource_group
}

# Virtual Network - Terraform builds this automatically for us within the
# resource group.
resource "azurerm_virtual_network" "vnet" {
  address_space         = [var.address_space]
  location              = azurerm_resource_group.stateful.location
  name                  = var.virtual_network_name
  resource_group_name   = azurerm_resource_group.stateful.name
}

# Subnet - the portion of the VNet that will be used to host the AKS cluster..
resource "azurerm_subnet" "subnet_aks" {
  address_prefixes      = [var.subnet_aks_prefix]
  name                  = "${var.prefix}-subnet-aks"
  resource_group_name   = azurerm_resource_group.stateful.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
}

# Subnet - the portion of the VNet that will be used to host the app gateway..
resource "azurerm_subnet" "subnet_agw" {
  address_prefixes      = [var.subnet_agw_prefix]
  name                  = "${var.prefix}-subnet-agw"
  resource_group_name   = azurerm_resource_group.stateful.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
}

# Security Group - define a set of rules for the VM that we're creating. For
# this server, we're allowing both HTTP and SSH access.
resource "azurerm_network_security_group" "stateful" {
  location              = var.location
  name                  = "${var.prefix}-sg"
  resource_group_name   = azurerm_resource_group.stateful.name

  security_rule {
    name                       = "HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 101
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
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
}

# Associate the security gropu with the subnet.
resource "azurerm_subnet_network_security_group_association" "stateful" {
  subnet_id                 = azurerm_subnet.subnet_agw.id
  network_security_group_id = azurerm_network_security_group.stateful.id
}

# Public IP - our VM will need a public IP to be internet addressable.
resource "azurerm_public_ip" "stateful" {
  allocation_method   = "Dynamic"
  domain_name_label   = var.hostname
  location            = var.location
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.stateful.name
}

# MySQL database password - create the MySQL password randomly.
resource "random_string" "mysql_password" {
  length = 12
  special = false
  upper = true
  lower = true
  number = true
}

# MySQL - create a MySQL database server.
resource "azurerm_mysql_server" "stateful" {
  location            = azurerm_resource_group.stateful.location
  name                = "${var.prefix}-mysql"
  resource_group_name = azurerm_resource_group.stateful.name

  administrator_login           = "mysqladmin"
  administrator_login_password  = random_string.mysql_password.result

  sku_name    = "B_Gen5_1"
  storage_mb  = 5120
  version     = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
}

# MySQL database - create the MySQL database required.
resource "azurerm_mysql_database" "stateful" {
  charset             = "UTF8"
  collation           = "utf8_unicode_ci"
  name                = var.prefix
  resource_group_name = azurerm_resource_group.stateful.name
  server_name         = azurerm_mysql_server.stateful.name
}

# Kubernetes CLuster - fire up a Kubernetes cluster within AKS.
resource "azurerm_kubernetes_cluster" "stateful" {
  dns_prefix          = "${var.prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  name                = "${var.prefix}-aks"
  resource_group_name = var.resource_group

  default_node_pool {
    availability_zones    = [1]
    enable_auto_scaling   = true
    enable_node_public_ip = false
    max_count             = var.aks_vms_max
    max_pods              = 30
    min_count             = var.aks_vms
    name                  = "default"
    node_count            = var.aks_vms
    node_taints           = []
    os_disk_size_gb       = 30
    type                  = "VirtualMachineScaleSets"
    vm_size               = var.aks_vm_size
    vnet_subnet_id        = azurerm_subnet.subnet_aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  network_profile {
    docker_bridge_cidr = "172.28.0.1/25"
    dns_service_ip     = "172.29.0.10"
    load_balancer_sku  = "standard"
    network_plugin     = "azure"
    network_policy     = "calico"
    pod_cidr           = null
    service_cidr       = "172.29.0.0/24"
  }
}

# Application Gateway - create the front end load balancer for serving the 
# application.
resource "azurerm_application_gateway" "stateful" {
  name                = "${var.prefix}-agw"
  location            = var.location
  resource_group_name = azurerm_resource_group.stateful.name
  
  backend_address_pool {
    name = "bepool"
  }

  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    cookie_based_affinity = "Enabled"
    port                  = 80
    protocol              = "Http"
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.stateful.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  gateway_ip_configuration {
    name      = "appGatewayIP"
    subnet_id = azurerm_subnet.subnet_agw.id
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name               = "rule1"
    http_listener_name = "httpListener"
    rule_type          = "Basic"

    backend_address_pool_name  = "bepool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
  }

  sku {
    capacity  = var.agw_sku_capacity
    name      = var.agw_sku_name
    tier      = var.agw_sku_tier
  }

  lifecycle {
    ignore_changes = [redirect_configuration, ssl_certificate, backend_address_pool, backend_http_settings, http_listener, request_routing_rule, probe, frontend_port, gateway_ip_configuration, url_path_map, tags["ingress-for-aks-cluster-id"], tags["last-updated-by-k8s-ingress"], tags["managed-by-k8s-ingress"]]
  }
}