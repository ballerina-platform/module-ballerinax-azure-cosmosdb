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

    // Get a list of containers
    log:print("Getting list of containers");
    stream<cosmosdb:Container> containerList = checkpanic managementClient->listContainers(databaseId, 2);
    log:print("Success!");
}