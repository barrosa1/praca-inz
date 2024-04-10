# Konfiguracja dostawcy Azure
provider "azurerm" {
  features {}
}
# Zmienna dla hasła administratora serwera SQL
variable "admin_password" {
  description = "The password associated with the SQL Server administrator login"
  sensitive   = true
}
# Utworzenie grupy zasobów
resource "azurerm_resource_group" "web" {
  name     = "web-resources"
  location = "East US"
}
# Utworzenie serwera SQL
resource "azurerm_sql_server" "web" {
  name                         = "web-sql-server"
  resource_group_name          = azurerm_resource_group.web.name
  location                     = azurerm_resource_group.web.location
  version                      = "15.0"
  administrator_login          = "webadmin"
  administrator_login_password = var.admin_password
}
# Utworzenie bazy danych SQL
resource "azurerm_sql_database" "web" {
  name                          = "web-db"
  resource_group_name           = azurerm_resource_group.web.name
  location                      = azurerm_resource_group.web.location
  server_name                   = azurerm_sql_server.web.name
  requested_service_objective_name = "Basic"
  collation                     = "SQL_Latin1_General_CP1_CI_AS"
}
# Utworzenie planu usługi aplikacji
resource "azurerm_app_service_plan" "web" {
  name                = "web-plan"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  sku {
    tier = "Basic"
    size = "B1"
  }
}
# Utworzenie usługi aplikacji
resource "azurerm_app_service" "web" {
  name                = "web-webapp"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  app_service_plan_id = azurerm_app_service_plan.web.id
  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }
  app_settings = {
    "DATABASE_SERVER" = azurerm_sql_server.web.fully_qualified_domain_name
    "DATABASE_NAME"   = azurerm_sql_database.web.name
    "DATABASE_USER"   = azurerm_sql_server.web.administrator_login
    "DATABASE_PASSWORD" = var.admin_password
  }
}
#Wyjście z URL-em usługi aplikacji
output "webapp_url" {
  value = azurerm_app_service.web.default_site_hostname
}