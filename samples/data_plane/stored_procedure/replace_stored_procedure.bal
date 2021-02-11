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
    string existingStoredProcedureId = "my_stored_procedure"

    // Replace stored procedure
    log:print("Replacing stored procedure");
    string newStoredProcedureBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;
    cosmosdb:StoredProcedure newStoredProcedure = {
        id: existingStoredProcedureId,
        storedProcedure: newStoredProcedureBody
    };
    cosmosdb:Result storedProcedureReplaceResult = checkpanic azureCosmosClient->replaceStoredProcedure(databaseId, 
            containerId, newStoredProcedure);
    log:print("Success!");
}
