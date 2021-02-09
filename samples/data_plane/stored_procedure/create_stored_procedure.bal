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

    // ---------------------------------- USE CASE ----------------------------------------------------------
    string storedProcedureId = "my_stored_procedure";
    
    // // Create a stored procedure
    log:print("Creating stored procedure");
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    cosmosdb:StoredProcedure storedProcedureRecord = {
        id: storedProcedureId,
        storedProcedure: storedProcedureBody
    };

    cosmosdb:Result storedProcedureCreateResult = checkpanic azureCosmosClient->createStoredProcedure(databaseId, containerId, storedProcedureRecord);
    log:print("Success!");
}
