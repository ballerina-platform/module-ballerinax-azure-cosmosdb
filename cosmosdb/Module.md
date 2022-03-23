## Overview
It provides the capability to connect to Azure Cosmos DB and execute CRUD (Create, Read, Update, and Delete) operations 
for databases and containers, to execute SQL queries to query containers, etc. In addition, it allows the special 
features provided by Cosmos DB such as operations on JavaScript language-integrated queries, management of users and 
permissions, etc.

This module supports [Azure Cosmos DB(SQL) API](https://docs.microsoft.com/en-us/rest/api/cosmos-db/) version `2018-12-31`.
## Prerequisites
Before using this connector in your Ballerina application, complete the following:

* [Create a Microsoft Account with Azure Subscription](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/)
* [Create an Azure Cosmos DB account](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account/)
* Obtain tokens
    1. Go to your Azure Cosmos DB account and click **Keys**.
    2. Copy the URI and PRIMARY KEY in the **Read-write Keys** tab.

## Quickstart
To use the Azure Cosmos DB connector in your Ballerina application, update the .bal file as follows:

### Step 1 - Import connector
Import the `ballerinax/azure_cosmosdb` module into the Ballerina project.
```ballerina
import ballerinax/azure_cosmosdb as cosmosdb;
```
### Step 2 - Create a new connector instance
You can now add the connection configuration with the `Master-Token` or `Resource-Token`, and the resource URI to the
Cosmos DB Account.
```ballerina
cosmosdb:ConnectionConfig configuration = {
    baseUrl: <URI>,
    primaryKeyOrResourceToken: <PRIMARY_KEY>
};
cosmosdb:DataPlaneClient azureCosmosClient = check new (configuration);

```
### Step 3 - Invoke connector operation
1. Create a document <br/>
Once you follow the above steps. you can create a new document inside the Cosmos container as shown below. Cosmos DB is designed to store and query JSON-like documents. Therefore, the document you create must be of the `JSON` type. In this example, the document ID is `my_document`

    ```ballerina
    map<json> document = {
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
    string id = "my_document";

    cosmosdb:DocumentResponse response = check azureCosmosClient-> createDocument("my_database", "my_container", id, document, valueOfPartitionKey);
    ```
**Note:** <br/>
- This document is created inside an already existing container with ID **my_container** and the container was created inside a database with ID **my_database**.
- As this container have selected path **/gender** as the partition key path. The document you create should include that path with a valid value.
- The document is represented as `map<json>`

2. Use `bal run` command to compile and run the Ballerina program

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/tree/main/cosmosdb/samples)**
