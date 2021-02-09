import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:CoreClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";

    // Get a list of stored procedures
    log:print("List stored procedure");
    stream<cosmosdb:StoredProcedure> result5 = checkpanic azureCosmosClient->listStoredProcedures(databaseId, containerId);
    log:print("Success!");
}
