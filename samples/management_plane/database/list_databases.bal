import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    // Get a list of databases
    log:print("Getting list of databases");
    stream<cosmosdb:Database> databaseList = checkpanic managementClient->listDatabases(10);
    log:print("Success!");
}
