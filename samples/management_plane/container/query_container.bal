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

    //Query documents
    log:print("Query1 - Select all from the container where gender 0");
    string selectAllQuery = string `SELECT * FROM ${containerId.toString()} f WHERE f.gender = ${0}`;
    int partitionKeyValueMale = 0;
    int maxItemCount = 10;
    stream<json> queryResult = checkpanic azureCosmosClient->queryDocuments(databaseId, containerId, selectAllQuery, [], 
            maxItemCount, partitionKeyValueMale);
    var document = queryResult.next();
    log:print("Success!");
}