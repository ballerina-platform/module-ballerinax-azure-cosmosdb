## Overview
Azure Cosmos DB Ballerina connector is a connector for connecting to Azure Cosmos DB via Ballerina language easily.
It provides the capability to connect to Azure Cosmos DB and to execute basic database operations like Create, Read,
Update and Delete Databases and Containers, Executing SQL queries to query Containers, etc. Apart from this, it allows
the special features provided by Cosmos DB like operations on JavaScript language-integrated queries, management of
users and permissions.

This module supports Cosmos DB SQL(Core) API 2018-12-31 version.

## Configuring connector
### Prerequisites
- [Microsoft Account with Azure Subscription](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/)
- [Azure Cosmos DB account](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account/)

### Obtaining tokens
1. Go to your Azure Cosmos DB account and visit `Keys` tab in the left-hand side.
2. Copy the `URI` and `PRIMARY KEY` in the `Read-write Keys` tab.

More information about obtaining tokens can be found [here](https://docs.microsoft.com/en-us/rest/api/cosmos-db/access-control-on-cosmosdb-resources).

## Quickstart
## CRUD operations on Documents
### Step 1: Import Cosmos DB Package
First, import the ballerinax/azure_cosmosdb module into the Ballerina project.
```ballerina
import ballerinax/azure_cosmosdb as cosmosdb;
```
### Step 2: Configure the connection to an existing Azure Cosmos DB account.
You can now make the connection configuration using the `Master-Token` or `Resource-Token`, and the resource URI to the
Cosmos DB Account.
```ballerina
cosmosdb:Configuration configuration = {
    baseUrl: <URI>,
    primaryKeyOrResourceToken: <PRIMARY_KEY>
};
```
**Note:** <br/> You have to specify the `URI` and `PRIMARY_KEY` or `Resource-Token`

### Step 3: Initialize the Cosmos DB Data Plane Client
You can now make the connection configuration using the `Master-Token` or `Resource-Token`, and the resource `URI` to
the Cosmos DB Account. For continuing with the data plane operations in Cosmos DB, you have to make use of the
`DataPlaneClient` provided by the ballerina connector. For this, the connection configuration above is being used.
```ballerina
cosmosdb:DataPlaneClient azureCosmosClient = check new (configuration);
```
### Step 4: Create a document
Now, with all the above steps followed you can create a new document inside the Cosmos container. As Cosmos DB is
designed to store and query JSON-like documents, the document you intend to store must be JSON. Then, the document must
have a unique ID to identify it. In this case, the Document ID will be **my_document**.

```ballerina
record {|string id; json...;|} document = {
        id: "my_document",
        "FirstName": "Alan",
        "FamilyName": "Turing",
        "Parents": [{
            "FamilyName": "Turing",
            "FirstName": "Julius"
        }, {
            "FamilyName": "Stoney",
            "FirstName": "Ethel"
        }],
        "gender": 0
};
int valueOfPartitionKey = 0;

cosmosdb:Document documentResult = azureCosmosClient-> createDocument("my_database", "my_container", document, 
    valueOfPartitionKey);
```
**Note:** <br/>
- This document is created inside an already existing container with ID **my_container** and the container was created
  inside a database with ID **my_document**.
- As this container have selected path **/gender** as the partition key path. The document you create should include that path
  with a valid value.

### Step 5: List the documents
For listing the existing documents inside this Cosmos container you have to give **my_database** and **my_container** as
parameters. Here, you will get a stream of `Document` records as the response. Using the ballerina Stream API you can
access the returned results.
```ballerina
stream<cosmosdb:Document, error>|error result = azureCosmosClient->listTriggers("my_database", "my_container");
if (result is stream<cosmosdb:Document, error>) {
    error? e = result.forEach(function (cosmosdb:Document document) {
        log:printInfo(document.toString());
    });
    log:printInfo("Success!");
} else {
    log:printError(result.message());
}
```
### Step 6: Query documents
Querying documents is one of the main use-cases supported by a database. For querying documents inside the container
you have created, you have to give **my_database** and **my_container** which the querying should be done, as parameters.
A SQL query must be provided, which is represented as a string. When executing a SQL query using the connector, there
are specific ways you can write the query itself. More information on writing queries can be found here:
https://docs.microsoft.com/en-us/rest/api/cosmos-db/querying-cosmosdb-resources-using-the-rest-api

```ballerina
string selectAllQuery = string `SELECT * FROM ${containerId.toString()} f WHERE f.gender = ${0}`;
cosmosdb:ResourceQueryOptions options = {partitionKey : 0, enableCrossPartition: false};

stream<cosmosdb:Document, error>|error result = azureCosmosClient->queryDocuments("my_database", "my_container", 
    selectAllQuery, options);

if (result is stream<cosmosdb:Document, error>) {
    error? e = result.forEach(function (cosmosdb:Document queryResult) {
        log:printInfo(queryResult.toString());
    });
    log:printInfo("Success!");
} else {
    log:printError(result.message());
}
```
**Note:** <br/> As the Cosmos containers are creating logical partitions with the partition key provided, you have to
provide the **value of partition key**, if the querying must be done only considering that logical partition. This logical
partitions are created for easy querying and search of documents. The ID of the document + partition key will create a
unique index for each document stored inside the container.

### Step 7: Delete a given document
Finally, you can delete the document you have created. For this operation to be done inside the container created,
you have to give **my_database** and **my_container** as parameters. Apart from that, the ID of the target document to
delete **my_document** and **value of the partition key** of that document must be provided.
```ballerina
cosmosdb:DeleteResponse = azureCosmosClient->deleteDocument("my_database", "my_container", "my_document", 
    valueOfPartitionKey);
```

### [You can find more samples here](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/tree/main/cosmosdb/samples)
