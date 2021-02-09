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

    // Get the list of documents
    log:print("Getting list of documents");
    stream<cosmosdb:Document> documentList = checkpanic azureCosmosClient->getDocumentList(databaseId, containerId);
    log:print("Success!");
}

