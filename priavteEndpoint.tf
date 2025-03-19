module "private_endpoint" {
  source = "./private_endpoint"  # Path to your Private Endpoint source module

  name                            = "pe-${var.name}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  subnet_resource_id              = var.private_endpoint_subnet_id
  network_interface_name          = "nic-${var.name}"
  private_service_connection_name = "psc-${var.name}"
  private_connection_resource_id  = azurerm_storage_account.storageacc.id

  #  Allow Customers to Choose Which Private Endpoints to Create
  subresource_names = var.enable_private_endpoints ? var.private_endpoint_subresource_names : []

  tags = var.tags

  #  Enable or Disable Private DNS Zone Management
  private_dns_zone_manage       = var.private_dns_zone_manage
  private_dns_zone_group_name   = var.private_dns_zone_group_name
  private_dns_zone_resource_ids = var.private_dns_zone_resource_ids

  #  IP Configurations (If Any)
  ip_configurations = var.private_endpoint_ip_configurations

  #  Associate Private Endpoint with Application Security Groups (Optional)
  application_security_group_association_ids = var.application_security_group_association_ids

  #  Dependencies (Ensuring Private Endpoint is Created After Storage Account)
  depends_on = [azurerm_storage_account.storageacc]
}
