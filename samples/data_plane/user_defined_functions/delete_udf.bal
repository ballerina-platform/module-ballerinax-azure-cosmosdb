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
    string udfId = "my_udf";
    
    // Delete User defined Functions
    log:print("Delete user defined function");
    _ = checkpanic azureCosmosClient->deleteUserDefinedFunction(databaseId, containerId, udfId);
    log:print("Success!");
}
