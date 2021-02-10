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
    string oldUserId = "my_user";
    string newUserId = "my_new_user";

    log:print("Replace user id");
    cosmosdb:Result userReplaceResult = checkpanic managementClient->replaceUserId(databaseId, oldUserId, newUserId);
    log:print("Success!");
}
