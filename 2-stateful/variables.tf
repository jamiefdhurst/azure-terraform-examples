# This file stores the definitions of the variables you can set within your
# Terraform code, which can be set within a terraform.tfvars file.

variable "resource_group" {
  description = "The name of your Azure Resource Group"
  default     = "stateful-resource-group"
}

variable "prefix" {
  description = "This prefix will be included in the name of some resources"
  default     = "stateful"
}

variable "hostname" {
  description = "Azure application gateway hostname"
  default     = "stateful"
}

variable "location" {
  description = "The region where resources is created"
  default     = "uksouth"
}

variable "virtual_network_name" {
  description = "The name for your virtual network"
  default     = "vnet"
}

variable "address_space" {
  description = "The address space that is used by the virtual network"
  default     = "10.0.0.0/16"
}

variable "subnet_aks_prefix" {
  description = "The address space to use for the subnet for AKS"
  default     = "10.0.10.0/24"
}

variable "subnet_agw_prefix" {
  description = "The address space to use for the subnet for AGW"
  default     = "10.0.12.0/24"
}

variable "source_network" {
  description = "Allow access from this network prefix. Defaults to '*'."
  default     = "*"
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy onto AKS."
  default     = "1.16.9"
}

variable "aks_vm_size" {
  description = "Size of VM(s) to use for AKS nodes."
  default     = "Standard_B2s"
}

variable "aks_vms" {
  description = "Number of VMs to use for AKS nodes."
  default     = 2
}

variable "aks_vms_max" {
  description = "Number of VMs to scale up to if required for AKS nodes."
  default     = 2
}

variable "agw_sku_name" {
  description = "The Application Gateway SKU name"
  default     = "Standard_Small"
}

variable "agw_sku_tier" {
  description = "The Application Gateway SKU tier"
  default     = "Standard"
}

variable "agw_sku_capacity" {
  description = "Capacity for gateway. Accepted values are in the range 1 to 32"
  default     = 1
}
