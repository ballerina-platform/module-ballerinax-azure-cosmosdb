The Cosmos DB connector allows you to connect to a Azure Cosmos DB resource from Ballerina and perform various operations such as  `find`, `create`, `read`, `update`, and `delete` operations of `Databases`, `Containers`, `User Defined Functions`, `Tiggers`, `Stored Procedures`, `Users`, `Permissions` and `Offers`.

## Compatibility

|                             |       Version               |
|:---------------------------:|:---------------------------:|
| Ballerina Language          | Swan Lake Preview4          |
| Cosmos DB API Version       | 2018-12-31                  |

## CosmosDB Clients

There is only one client provided by Ballerina to interact with CosmosDB.

1. **azure_cosmosdb:Client** - This connects to the running CosmosDB resource and perform different actions

    ```ballerina
    AzureCosmosConfiguration azureConfig = {
    baseUrl : <BASE_URL>, 
    keyOrResourceToken : <"KEY_OR_RESOURCE_TOKEN">, 
    host : <"HOST">, 
    tokenType : <"TOKEN_TYPE">, 
    tokenVersion : <"TOKEN_VERSION">, 
    secureSocketConfig :{
                            trustStore: {
                            path: <BALLERINA_TRUSTSTORE>, 
                            password: <"SSL_PASSWORD">
                            }
                        }
    };
    Client azureClient = check new (azureConfig);
    ```
  
## Sample

First, import the `ballerinax/azure_cosmosdb` module into the Ballerina project.

```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb;

public function main() {

    AzureCosmosConfiguration config = {
    baseUrl : "https://cosmosconnector.documents.azure.com:443/", 
    keyOrResourceToken : "mytokenABCD==", 
    host : "cosmosconnector.documents.azure.com:443", 
    tokenType : "master", 
    tokenVersion :1.0, 
    secureSocketConfig :{
                            trustStore: {
                            path: getConfigValue("b7a_home") + "/truststore/path/trutstore.p12", 
                            password: "mypwd"
                            }
                        }
    };

    azure_cosmosdb:Client azureCosmosClient = new(config);

    Database database1 = azureCosmosClient->createDatabase("mydatabase");

    @tainted ResourceProperties propertiesNewCollection = {
            databaseId: database1.id, 
            containerId: "mycontainer"
    };
    PartitionKey pk = {
        paths: ["/AccountNumber"], 
        kind :"Hash", 
        'version: 2
    };
    Container container1 = azureCosmosClient->createContainer(propertiesNewCollection,pk);

    @tainted ResourceProperties properties = {
            databaseId: database1.id, 
            containerId: container1.id
    };
    Document document1 = { id: "documentid1", documentBody :{ "LastName": "Sheldon", "AccountNumber": 1234 }, partitionKey : [1234] };
    Document document2 = { id: "documentid2", documentBody :{ "LastName": "West", "AccountNumber": 7805 }, partitionKey : [7805] };
    Document document3 = { id: "documentid3", documentBody :{ "LastName": "Moore", "AccountNumber": 5678 }, partitionKey : [5678] };
    Document document4 = { id: "documentid4", documentBody :{ "LastName": "Hope", "AccountNumber": 2343 }, partitionKey : [2343] };

    log:printInfo("------------------ Inserting Documents -------------------");
    azureCosmosClient->createDocument(properties, document1);
    azureCosmosClient->createDocument(properties, document2);
    azureCosmosClient->createDocument(properties, document3);
    azureCosmosClient->createDocument(properties, document4);
  
    log:printInfo("------------------ List Documents -------------------");
    DocumentList documentList = azureCosmosClient->getDocumentList(properties)

    log:printInfo("------------------ Get One Document -------------------");
    Document document = azureCosmosClient->getDocument(properties, document1.id, [1234])

    log:printInfo("------------------ Query Documents -------------------");
    Query cqlQuery = {
        query: string `SELECT * FROM ${container1.id.toString()} f WHERE f.Address.City = 'Seattle'`, 
        parameters: []
    };
    var result = AzureCosmosClient->queryDocuments(properties, [1234], cqlQuery);     
    log:printInfo("Returned Filtered documents '" + result.toString() + "'.");

    log:printInfo("------------------ Delete Document -------------------");
    var result = AzureCosmosClient->deleteDocument(properties, document.id, [1234]);  

}
```