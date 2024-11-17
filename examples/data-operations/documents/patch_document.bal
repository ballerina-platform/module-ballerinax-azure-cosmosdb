import ballerina/log;
import ballerina/os;
import ballerinax/azure_cosmosdb as cosmosdb;

cosmosdb:ConnectionConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:DataPlaneClient azureCosmosClient = check new (config);

public function main() returns error? {
    string databaseId = "my_database";
    string containerId = "my_container";
    string documentId = "my_document";
    int partitionKeyValue = 0; // Adjust this according to your partition key strategy

    json patchOperations = {
        "operations": [
            {
                "op": "set",
                "path": "/FirstName",
                "value": "Alan Updated"
            },
            {
                "op": "add",
                "path": "/NewField",
                "value": "New Value"
            }
        ]
    };

    // Remove the condition as it may not be applicable directly in the patchDocument call.
    // You might want to check if your connector supports conditional updates in a different manner.

    log:printInfo("Patching a document in Cosmos DB");

    // Call to patchDocument should not include the condition directly
    cosmosdb:DocumentResponse response = check azureCosmosClient->patchDocument(databaseId, containerId, documentId, patchOperations, partitionKeyValue);
    log:printInfo("Document patched successfully: " + response.toString());
}
