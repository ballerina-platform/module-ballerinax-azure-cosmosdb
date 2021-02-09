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
    int partitionKeyValue = 0; //Existing give the existing partition key and we can't replace that

    // Replace document
    log:print("Replacing document");
    json newDocumentBody = {
        "LastName": "Helena",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        gender: 0
    };

    cosmosdb:Document newDocument = {
        id: documentId,
        documentBody: newDocumentBody
    };
    cosmosdb:Result replsceResult = checkpanic azureCosmosClient->replaceDocument(databaseId, containerId, newDocument, partitionKeyValue);
    log:print("Success!");
}
