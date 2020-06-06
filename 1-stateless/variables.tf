# This file stores the definitions of the variables you can set within your
# Terraform code, which can be set within a terraform.tfvars file.

variable "resource_group" {
  description = "The name of your Azure Resource Group"
  default     = "my-resource-group"
}

variable "prefix" {
  description = "This prefix will be included in the name of some resources"
  default     = "example"
}

variable "hostname" {
  description = "Virtual machine hostname"
  default     = "example"
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

variable "subnet_prefix" {
  description = "The address space to use for the subnet"
  default     = "10.0.10.0/24"
}

variable "storage_account_tier" {
  description = "Defines the storage tier, one of Standard or Premium"
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication type for storage, e.g. LRS, GRS, etc."
  default     = "LRS"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine"
  default     = "Standard_B1s"
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default     = "Canonical"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default     = "UbuntuServer"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default     = "18.04-LTS"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default     = "latest"
}

variable "admin_username" {
  description = "Administrator user name"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Administrator password"
  default     = "ExamplePassword123!"
}

variable "source_network" {
  description = "Allow access from this network prefix. Defaults to '*'."
  default     = "*"
}