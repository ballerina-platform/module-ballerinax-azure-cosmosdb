The Azure Cosmos DB is Microsoft’s  NOSQL  database in Azure technology stack. It is called a globally distributed 
multi-model database which  is used for managing data across the world. Key purposes of the Azure CosmosDB is to achieve 
low latency and high availability while maintaining a flexible scalability. 
The Ballerina Cosmos DB connector allows you to connect to a Azure Cosmos DB resource from Ballerina and perform various 
operations such as `find`, `create`, `read`, `update`, and `delete` operations of `Databases`, `Containers`,
`User Defined Functions`, `Tiggers`, `Stored Procedures`, `Users`, `Permissions` and `Offers`. 

## Compatibility

|                           |    Version                  |
|:-------------------------:|:---------------------------:|
| Ballerina Language        | Swan-Lake-Preview8          |
| Cosmos DB API Version     | 2018-12-31                  |

## CosmosDB Clients

There are two clients provided by Ballerina to interact with CosmosDB.

1. **cosmosdb:CoreClient** - This connects to the running CosmosDB databases and containers to execute data-plane 
operations 

   ```ballerina
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : <BASE_URL>,
        masterOrResourceToken : <MASTER_OR_RESOURCE_TOKEN>,
    };
    cosmosdb:CoreClient coreClient = new(configuration);
   ```
2. **cosmosdb:ManagementClient** - This connects to the running CosmosDB databases and containers to execute 
management-plane operations 

   ```ballerina
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : <BASE_URL>,
        masterOrResourceToken : <MASTER_OR_RESOURCE_TOKEN>,
    };
    cosmosdb:ManagementClient managementClient = new(configuration);
   ```

## Samples 
### Creating a database
For creating a database in Azure we have to provide a unique database ID which does not already exist in the specific 
cosmos DB account. This operation will return a record of type Result. This will contain the success as true if the 
operation is successful.

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:ManagementClient managementClient = new(configuration);

    cosmosdb:Result databaseResult = checkpanic managementClient->createDatabase(<DATABASE_ID>);
}
```

### Creating a Container
A container can be created inside an existing database in the cosmos DB account. As the REST api version which is used 
in this implementation of the connector strictly supports the partition key, it is a necessity to provide the 
partition key in the creation of a container. 

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:ManagementClient managementClient = new(configuration);

    cosmosdb:PartitionKey partitionKey = {
        paths: ["/accountNumber"],
        kind :"Hash",
        'version: 2
    };
    cosmosdb:Result containerResult = checkpanic managementClient->createContainer(<DATABASE_ID>, <CONTAINER_ID>, 
            partitionKey);
}
```
### Inserting a Doument
Azure cosmos DB allows the execution of  CRUD operations on items separately. As we are using the Core API underneath 
the connector, an item may refer to a document in the container. SQL API stores entities in JSON in a hierarchical 
key-value document.  The max document size in Cosmos DB is 2 MB.

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:CoreClient coreClient = new (configuration);

    cosmosdb:Document document1 = { id: "documentid1", documentBody :{ "LastName": "Sheldon", accountNumber: 001234222 }
    cosmosdb:Result documentResult1 = checkpanic coreClient->createDocument(<DATABASE_ID>, <CONTAINER_ID>, document1, 
            <VALUE_OF_PARTITIONKEY>); 
}
```
### List Documents
Usually Cosmos DB provides an json array of json objects as the response for list operations. But, the connector 
has handled this array and instead of that it provides streaming capabilities for these kinds of operations. Apart from 
that, Cosmos DB originally allows pagination of results returned list operations.

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:CoreClient coreClient = new (configuration);

    stream<cosmosdb:Document> documentList = checkpanic coreClient->getDocumentList(<DATABASE_ID>, <CONTAINER_ID>);
}
```
### Get Document

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:CoreClient coreClient = new (configuration);

    cosmosdb:Document returnedDocument = checkpanic coreClient->getDocument(<DATABASE_ID>, <CONTAINER_ID>, 
            <DOCUMENT_ID>, <VALUE_OF_PARTITIONKEY>);
}
```

### Query Documents

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:CoreClient coreClient = new (configuration);

    string selectAllQuery = string `SELECT * FROM ${containerId.toString()} f WHERE f.gender = ${0}`;

    stream<json> resultStream = checkpanic coreClient->queryDocuments(<DATABASE_ID>, <CONTAINER_ID>, selectAllQuery, 
            [], <MAX_ITEM_COUNT>, <VALUE_OF_PARTITIONKEY>);

    error? e = resultStream.forEach(function (json document){
                    log:printInfo(document);
                });    

}
```
### Delete Document

```ballerina
import ballerina/log;
import ballerinax/azure.cosmosdb as cosmosdb;

public function main() {
    cosmosdb:AzureCosmosConfiguration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:CoreClient coreClient = new (configuration);

    _ = checkpanic coreClient->deleteDocument(<DATABASE_ID>, <CONTAINER_ID>, <DOCUMENT_ID>, <VALUE_OF_PARTITIONKEY>);

}
```