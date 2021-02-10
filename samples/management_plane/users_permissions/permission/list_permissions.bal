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

    log:print("List permissions");
    stream<cosmosdb:Permission> permissionList = checkpanic managementClient->listPermissions(databaseId, userId);
    log:print("Success!");
}
