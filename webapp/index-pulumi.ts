 
// przed wykonaniem należy ustawić tajne hasło w konsoli za pomocą komendy: pulumi config set --secret sqlPassword {{ hasło }}

//Importowanie wymaganych modułów
import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
//Wczytanie konfiguracji i pobranie tajnego hasła
const config = new pulumi.Config();
const password = config.requireSecret("sqlPassword");
// Utworzenie nowej grupy zasobów
const resourceGroup = new azure.core.ResourceGroup("web", {
    location: "East US",
});
// Utworzenie nowego serwera SQL
const sqlServer = new azure.sql.SqlServer("web", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    version: "15.0",
    administratorLogin: "webadmin",
    administratorLoginPassword: password,
});
// Utworzenie nowej bazy danych SQL
const database = new azure.sql.Database("web", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    serverName: sqlServer.name,
    requestedServiceObjectiveName: "Basic",
});
// Utworzenie nowego planu usługi aplikacji
const appServicePlan = new azure.appservice.Plan("web", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    kind: "App",
    sku: {
        tier: "Basic",
        size: "B1",
    },
});
// Utworzenie nowej usługi aplikacji
const app = new azure.appservice.AppService("web", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    appServicePlanId: appServicePlan.id,
    appSettings: {
        "DATABASE_SERVER": sqlServer.fullyQualifiedDomainName,
        "DATABASE_NAME": database.name,
        "DATABASE_USER": sqlServer.administratorLogin,
        "DATABASE_PASSWORD": password,
    },
    siteConfig: {
        dotnetFrameworkVersion: "v4.0",
        scmType: "LocalGit",
    },
});
// Eksportowanie URL usługi aplikacji
export const webappUrl = app.defaultSiteHostname;