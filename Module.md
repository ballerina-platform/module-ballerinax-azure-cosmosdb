The Cosmos DB connector allows you to connect to a Azure Cosmos DB resource from Ballerina and perform various operations
such as `find`, `create`, `read`, `update`, and `delete` operations of `Databases`, `Containers`, 
`User Defined Functions`, `Tiggers`, `Stored Procedures`, `Users`, `Permissions` and `Offers`.

## Compatibility

|                           |    Version                  |
|:-------------------------:|:---------------------------:|
| Ballerina Language        | Swan-Lake-Preview8          |
| Cosmos DB API Version     | 2018-12-31                  |

## CosmosDB Clients

There is only one client provided by Ballerina to interact with CosmosDB.

1. **cosmosdb:Client** - This connects to the running CosmosDB resource and perform different actions

   ```ballerina
   cosmosdb:AzureCosmosConfiguration azureConfig = {
    baseUrl : <"BASE_URL">,
    keyOrResourceToken : <"KEY_OR_RESOURCE_TOKEN">,
    tokenType : <"TOKEN_TYPE">,
    tokenVersion : <"TOKEN_VERSION">
   };
   cosmosdb:Client azureClient = check new (azureConfig);
   ```

## Sample

First, import the `ballerinax/azure_cosmosdb` module into the Ballerina project.

```ballerina
import ballerina/log;
import ballerinax/cosmosdb;

public function main() {

    cosmosdb:AzureCosmosConfiguration config = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        keyOrResourceToken : "mytokenABCD==",
        tokenType : "master",
        tokenVersion : "1.0"
    };

    cosmosdb:Client azureCosmosClient = new(config);

    cosmosdb:Database database1 = azureCosmosClient->createDatabase("mydatabase");

    cosmosdb:PartitionKey partitionKey = {
        paths: ["/AccountNumber"],
        kind :"Hash",
        'version: 2
    };
    cosmosdb:Container container1 = azureCosmosClient->createContainer(database1.id, "mycontainer", 
                                    partitionKey);

    cosmosdb:Document document1 = { id: "documentid1", documentBody :{ "LastName": "Sheldon", 
                                    "AccountNumber": 1234 }, partitionKey : [1234] };
    cosmosdb:Document document2 = { id: "documentid2", documentBody :{ "LastName": "West", 
                                    "AccountNumber": 7805 }, partitionKey : [7805] };
    cosmosdb:Document document3 = { id: "documentid3", documentBody :{ "LastName": "Moore", 
                                    "AccountNumber": 5678 }, partitionKey : [5678] };
    cosmosdb:Document document4 = { id: "documentid4", documentBody :{ "LastName": "Hope", 
                                    "AccountNumber": 2343 }, partitionKey : [2343] };

    log:printInfo("------------------ Inserting Documents -------------------");
    var output1 = azureCosmosClient->createDocument(database1.id, container1.id, document1);
    var output2 = azureCosmosClient->createDocument(database1.id, container1.id, document2);
    var output3 = azureCosmosClient->createDocument(database1.id, container1.id, document3);
    var output4 = azureCosmosClient->createDocument(database1.id, container1.id, document4);

    log:printInfo("------------------ List Documents -------------------");
    stream<Document> documentList = azureCosmosClient->getDocumentList(database1.id, container1.id)

    log:printInfo("------------------ Get One Document -------------------");
    cosmosdb:Document document = azureCosmosClient->getDocument(database1.id, container1.id, document1.id, 
                                                        [1234])

    log:printInfo("------------------ Query Documents -------------------");
    cosmosdb:Query sqlQuery = {
        query: string `SELECT * FROM ${container1.id.toString()} f WHERE f.Address.City = 'Seattle'`,
        parameters: []
    };
    var resultStream = azureCosmosClient->queryDocuments(database1.id, container1.id, [1234], sqlQuery);
    error? e = resultStream.forEach(function (json document){
                    log:printInfo(document);
                });    

    log:printInfo("------------------ Delete Document -------------------");
    var result = AzureCosmosClient->deleteDocument(database1.id, container1.id, document.id, [1234]);

}
```
