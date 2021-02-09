import ballerinax/cosmosdb;
import ballerina/log;
import ballerina/config;

cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:CoreClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";

    // List all User defined Functions
    log:print("List  user defined functions");
    stream<cosmosdb:UserDefinedFunction> result5 = checkpanic azureCosmosClient->listUserDefinedFunctions(databaseId, containerId);
    log:print("Success!");
}
