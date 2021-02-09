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
    string documentId = "my_document";

    // Create a new document
    log:print("Create a new document");
    json documentBody = {
        "LastName": "keeeeeee",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        gender: 0
    };
    int partitionKeyValue = 0;

    cosmosdb:Document document = {
        id: documentId,
        documentBody: documentBody
    };

    cosmosdb:Result documentResult = checkpanic azureCosmosClient->createDocument(databaseId, containerId, document, partitionKeyValue); 
    log:print("Success!");
}
