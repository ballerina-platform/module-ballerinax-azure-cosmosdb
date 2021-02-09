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

    // Create a container
    log:print("Creating container");
    cosmosdb:PartitionKey partitionKey = {
        paths: ["/id"],
        keyVersion: 2
    };
    cosmosdb:Result containerResult = checkpanic managementClient->createContainer(databaseId, containerId, partitionKey);
    log:print("Success!");
}