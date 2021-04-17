output "public_IP_Load_Balancer" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Public HTTP service IP address of the load balancer in front of the webservers."
}
