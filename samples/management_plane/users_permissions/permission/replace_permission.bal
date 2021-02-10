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
    string containerId = "my_container";
    string userId = "my_user";
    string permissionId = "my_permission";

    string permissionModeReplace = "Read";
    string permissionResourceReplace = string `dbs/${databaseId}/colls/${containerId}`;
    cosmosdb:Permission replacedPermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };
    log:print("Replace permission");
    cosmosdb:Result replacePermissionResult = checkpanic managementClient->replacePermission(databaseId, userId, replacedPermission);
    log:print("Success!");
}
