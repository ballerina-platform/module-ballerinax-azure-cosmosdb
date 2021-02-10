Ballerina Connector For Azure Cosmos DB
===================

## Connector Overview
Azure Cosmos DB Ballerina connector is a connector for connecting to Azure Cosmos DB via Ballerina language easily. 
It provides capability to connect to Azure Cosmos DB and to execute basic database operations like Create, Read, 
Update and Delete databases and containers, Executing SQL queries to query containers etc. Apart from this it allows 
the special features provided by Cosmos DB like operations on javascript language integrated queries, management of users 
and permissions. This connector promotes easy integration and access to Cosmos DB via ballerina by handling most of the 
burden on ballerina developers  in configuring a new connection to the Cosmos DB from scratch. 

Ballerina Cosmos DB connector uses the SQL(Core) API which has the full support for all the operations and where used 
extensively by the existing developer community. The reason for the use of SQL API is to provide a developer a better 
experience in querying, setting up a database and managing it because most/majority of the developer community has 
familiarity with the use of SQL. For version 0.1.0 of this connector, version 2018-12-31 of Azure Cosmos DB Core REST API 
is used.

![connecting to Cosmos DB](resources/connector.gif)

## Key features of Azure Cosmos DB 
- Has a guaranteed low latency that is backed by a comprehensive set of Service Level Agreements (SLAs).
- Five Different types of Consistency levels: strong, bounded staleness, session, consistent prefix, and eventual.
- Multi-model approach which provides the ability to use document, key-value, wide-column, or graph-based data. 
- An enterprise grade security. 
- Automatic updates and patching.
- Capacity management with serverless, automatic scaling options. 

## Prerequisites
- Azure Account to access azure portal. <br/>
https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/

- Azure Cosmos DB account. <br/>
https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account/

- Azure Cosmos DB Credentials.
    - Master Key
    - URI

    When the Azure Cosmos DB account is created, it automatically creates the client  credentials. Using the portal 
    you can obtain them easily. <br/>
    https://azure.microsoft.com/en-au/features/azure-portal/

- Java 11 installed. <br/>
    Java Development Kit (JDK) with version 11 is required.

- Ballerina SLP8 installed. <br/>
    Ballerina Swan Lake Preview Version 8 is require

## Supported Versions
|                           |    Version                  |
|:-------------------------:|:---------------------------:|
| Cosmos DB API Version     | 2018-12-31                  |
| Ballerina Language        | Swan-Lake-Preview8          |
| Java Development Kit (JDK)| 11                          |
|

## Limitations
- Only data plane operations are supported from the connector. (Some Management plane operations are not supported)
- Changing the type of throughput in databases (Auto Scaling -> Manual) is not allowed.
- Only Core(SQL) API is supported.

## Quickstart(s)
### Import Cosmos DB Package

```ballerina
import ballerinax/azure.cosmosdb as cosmosdb;
```
### Initialize the cosmos DB Management Plane Client
```ballerina
cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: <BASE_URL>,
    masterOrResourceToken: <MASTER_OR_RESOURCE_TOKEN>
};

cosmosdb:ManagementClient managementClient = new(configuration);
```
### Create new Database
```ballerina
cosmosdb:Result result = managementClient->createDatabase(<DATABASE_ID>);
```
### Create new Container
```ballerina
cosmosdb:PartitionKey partitionKey = {
    paths: ["/id"],
    keyVersion: 2
};
cosmosdb:Result containerResult = check managementClient->    
            createContainer(<DATABASE_ID>, <CONTAINER_ID>, partitionKey);
```
### Initialize the Cosmos DB Data Plane Client
```ballerina
cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: <BASE_URL>,
    masterOrResourceToken: <MASTER_OR_RESOURCE_TOKEN>
};

cosmosdb:CoreClient azureCosmosClient = new (configuration);
```
### Create a Document
```ballerina
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
int valueOfPartitionKey = 0;

cosmosdb:Document document = {
    id: <DOCUMENT_ID>,
    documentBody: documentBody
};

cosmosdb:Result documentResult = check azureCosmosClient-> 
        createDocument(<DATABASE_ID>, <CONTAINER_ID>, document,  
                                            <VALUE_OF_PARTITION_KEY>);
```
### List the Documents
```ballerina
stream<cosmosdb:Document> documentList = check azureCosmosClient-> 
                            getDocumentList(<DATABASE_ID>, <CONTAINER_ID>);
 
var document = documentList.next();
io:println(document?.value);
```
### Query Documents
```ballerina
string selectAllQuery = string `SELECT * FROM ${containerId.toString()} 
                                                    f WHERE f.gender = ${0}`;
int partitionKeyValueMale = 0;
int maxItemCount = 10;
stream<json> queryResult = check azureCosmosClient->    
        queryDocuments(<DATABASE_ID>, <CONTAINER_ID>, selectAllQuery,  
                                [],maxItemCount, partitionKeyValueMale);

error? e =  resultStream.forEach(function (json document){
                log:printInfo(document);
            });
```
### Delete a given Document
```ballerina
 _ = check azureCosmosClient->deleteDocument(<DATABASE_ID>, <CONTAINER_ID> 
                                 <DOCUMENT_ID>, <VALUE_OF_PARTITION_KEY>);
```
## Contributing to Ballerina
As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct
All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links
* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
