# Display information about the infrasturcture your Terraform code has built
# once completed.

output "public_dns" {
  value = "${azurerm_public_ip.stateless.fqdn}"
}

output "url" {
  value = "http://${azurerm_public_ip.stateless.fqdn}"
}