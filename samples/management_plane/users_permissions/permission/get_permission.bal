import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";
    string permissionId = "my_permission";

    log:print("Get intormation about one permission");
    cosmosdb:Permission permission = checkpanic managementClient->getPermission(databaseId, userId, permissionId);
    log:print("Success!");
}
