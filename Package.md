Connects to Azure Cosmos DB from Ballerina.

## Module Overview

The Azure Cosmos DB is Microsoft’s NoSQL database in the Azure technology stack. It is called a globally distributed 
multi-model database which is used for managing data across the world. The key purpose of the Azure Cosmos DB is to 
achieve low latency and high availability while maintaining flexible scalability. 
The Ballerina Cosmos DB connector allows you to connect to an Azure Cosmos DB resource from Ballerina and perform 
various operations such as `find`, `create`, `read`, `update`, and `delete` operations of `Databases`, `Containers`,
`User Defined Functions`, `Tiggers`, `Stored Procedures`, `Users`, `Permissions` and `Offers`.

## Compatibility

|                           |    Version                  |
|:-------------------------:|:---------------------------:|
| Ballerina Language        | Swan Lake Alpha 2           |
| Cosmos DB API Version     | 2018-12-31                  |

## Cosmos DB Clients

There are two clients provided by Ballerina to interact with Cosmos DB.

1. **cosmosdb:DataPlaneClient** - This connects to the running Cosmos DB databases and containers to execute data-plane operations.

   ```ballerina
    cosmosdb:Configuration configuration = {
        baseUrl : <BASE_URL>,
        masterOrResourceToken : <MASTER_OR_RESOURCE_TOKEN>,
    };
    cosmosdb:DataPlaneClient azureCosmosClient = new(configuration);
   ```
2. **cosmosdb:ManagementClient** - This connects to the running Cosmos DB databases and containers to execute management-plane operations.

   ```ballerina
    cosmosdb:Configuration configuration = {
        baseUrl : <BASE_URL>,
        masterOrResourceToken : <MASTER_OR_RESOURCE_TOKEN>,
    };
    cosmosdb:ManagementClient managementClient = new(configuration);
   ```

## Samples 
### Creating a Database
For creating a database in Azure we have to provide a unique database ID that does not already exist in the specific 
Cosmos DB account. This operation will return a record of type Database. 

```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:ManagementClient managementClient = new(configuration);

    var result = managementClient->createDatabase(<DATABASE_ID>); 
    if (result is error) {
        log:printError(result.message());
    }
    if (result is cosmosdb:Database) {
        log:print(result.toString());
        log:print("Success!");
    }
}
```

### Creating a Container
A container can be created inside an existing database in the Cosmos DB account. As the REST API version which is used 
in this implementation of the connector strictly supports the partition key, it is a necessity to provide the 
partition key in the creation of a container. 

```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:ManagementClient managementClient = new(configuration);

    cosmosdb:PartitionKey partitionKey = {
        paths: ["/accountNumber"],
        kind :"Hash",
        'version: 2
    };

    var result = managementClient->createContainer(<DATABASE_ID>, <CONTAINER_ID>, partitionKey);
    if (result is error) {
        log:printError(result.message());
    }
    if (result is cosmosdb:Container) {
        log:print(result.toString());
        log:print("Success!");
    }
}
```
### Inserting a Document
Azure Cosmos DB allows the execution of CRUD operations on items separately. As we are using the Core API underneath the 
connector, an item may refer to a document in the container. SQL API stores entities as JSON in a hierarchical key-value 
document. The max document size in Cosmos DB is 2 MB.
```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

    record {|string id; json...;|} documentBody = {
        id: "documentid1",
        LastName: "Sheldon", 
        accountNumber: 001234222
    };

    var result = azureCosmosClient->createDocument(<DATABASE_ID>, <CONTAINER_ID>, documentBody, 
        <VALUE_OF_PARTITIONKEY>); 
    if (result is error) {
        log:printError(result.message());
    }
    if (result is cosmosdb:Document) {
        log:print(result.toString());
        log:print("Success!");
    }
    
}
```
### List Documents
Usually, Cosmos DB provides an array of JSON objects as the response for list operations. But, the connector has handled 
this array and instead of that, it provides streaming capabilities for these kinds of operations. Apart from 
that, Cosmos DB originally allows pagination of results returned list operations.

```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

    var result = azureCosmosClient->getDocumentList(<DATABASE_ID>, <CONTAINER_ID>);
    if (result is error) {
        log:printError(result.message());
    }
    if (result is stream<cosmosdb:Document>) {
        error? e = result.forEach(function (cosmosdb:Document document) {
            log:print(document.toString());
        });
        log:print("Success!");
    }
}
```
### Get Document
This operation allows to retrieve a document by it's ID. It returns a record type `Document`. Here, you have to provide 
*Database ID*, *Container ID* where the document will be created and the **ID of the document** to retrieve. As the 
partition key is mandatory in the container, for getDocument operation you need to provide the correct 
**value for that partition key**.
```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

    var result = azureCosmosClient->getDocument(<DATABASE_ID>, <CONTAINER_ID>, <DOCUMENT_ID>, 
        <VALUE_OF_PARTITIONKEY>);
    if (result is error) {
        log:printError(result.message());
    }
    if (result is cosmosdb:Document) {
        log:print(result.toString());
        log:print("Success!");
    }
}
```
### Query Documents
Ballerina connector for Azure COsmos DB allows the option to either provide a query as a normal ballerina string that 
matches with the SQL queries compatible with the REST API. This example shows a query that will return all the data 
inside a document such that the value for **/gender** equals 0.
```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

    string selectAllQuery = string `SELECT * FROM ${containerId.toString()} f WHERE f.gender = ${0}`;
 
    ResourceQueryOptions options = {partitionKey : 0, enableCrossPartition: false};
    var result = azureCosmosClient->queryDocuments(DATABASE_ID>, <CONTAINER_ID>, selectAllQuery, 
        options, <MAX_ITEM_COUNT>,);
    if (result is error) {
        log:printError(result.message());
    }
    if (result is stream<cosmosdb:Document>) {
        error? e = result.forEach(function (cosmosdb:Document document) {
            log:print(document.toString());
        });
        log:print("Success!");
    }   

}
```
### Delete Document
Using this connector, deletion of a document that exists inside a container is possible. You have to specify the 
*Database ID*, *Container ID* where the document exists and the **ID of document** you want to delete. The 
**value of the partition key** for that specific document should also be passed to the function.
```ballerina
import ballerina/log;
import ballerinax/azure_cosmosdb as cosmosdb;

public function main() {
    cosmosdb:Configuration configuration = {
        baseUrl : "https://cosmosconnector.documents.azure.com:443",
        masterOrResourceToken : "mytokenABCD==",
    };
    cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

    var result = azureCosmosClient->deleteDocument(<DATABASE_ID>, <CONTAINER_ID>, <DOCUMENT_ID>, 
        <VALUE_OF_PARTITIONKEY>);
    if (result is error) {
        log:printError(result.message());
    }
    if (result is cosmosdb:DeleteResponse) {
        log:print(result.toString());
        log:print("Success!");
    }
}
```
