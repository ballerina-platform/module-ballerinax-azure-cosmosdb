Ballerina Connector For Azure Cosmos DB
===================

[![Build](https://github.com/sachinira/module-ballerinax-azure-cosmosdb/workflows/CI/badge.svg)](https://github.com/sachinira/module-ballerinax-azure-cosmosdb/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/sachinira/module-ballerinax-azure-cosmosdb/feature7)](https://github.com/sachinira/module-ballerinax-azure-cosmosdb/commits/feature7)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# What is Azure Cosmos DB
The Azure Cosmos DB is Microsoft’s highly scalable NOSQL  database in Azure technology stack. It is called a globally distributed multi-model database which  is used for managing data across the world. Key purposes of the Azure CosmosDB is to achieve low latency and high availability while maintaining a flexible scalability. Cosmos DB is a superset of Azure Document DB and is available in all Azure regions.

# Key features of Azure Cosmos DB 
- Has a guaranteed low latency that is backed by a comprehensive set of Service Level Agreements (SLAs).
- Five Different types of Consistency levels: Strong, Bounded Staleness, Session, Consistent prefix, and Eventual.
- Multi-model approach which provides the ability to use document, key-value, wide-column, or graph-based data. 
- An enterprise grade security. 
- Automatic updates and patching.
- Capacity management with serverless, automatic scaling options. 

![connecting to Cosmos DB](resources/multi-model.png)

# Connector Overview
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

# Prerequisites
- Azure Account to access Azure portal. <br/>
https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/

- Azure Cosmos DB account. <br/>
https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account/

- Azure Cosmos DB Credentials. <br/>
    - Primary Key or Resource Token
    
        - Obtaining Primary Token

        When the Azure Cosmos DB account is created, it automatically creates the Primary Key  credentials. Using the portal you can obtain them easily. <br/>
        https://docs.microsoft.com/en-us/azure/cosmos-db/database-security#primary-keys
        
        - Obtaining Resource Token
        
        The person who possess the Master Key of the Cosmos DB account is capable of creating permissions to each user. By using this concept, a ballerina service which uses the Cosmos DB connector can act as a token broker, which issues tokens with specific access rights to users (involves a middle-tier service that serves as the authentication and authorization broker between a client and a back-end service). This is handled by using Resource Tokens. 

        Resource tokens provide user-based permissions to individual account resources, including collections, documents, attachments, stored procedures, triggers, and user-defined functions. They are auto-generated when a database user is granted permissions to a resource and re-generated in response to a request referencing that permission. By default, they are valid for one hour, with the maximum timespan of five hours.

        Sample for obtaining the Resource Token can be found here: <br/>

        
    - Base URI

        ![Obtaining Credentials](resources/cred.png)

- Java 11 installed. <br/>
    Java Development Kit (JDK) with version 11 is required.

- Ballerina SLP8 installed. <br/>
    Ballerina Swan Lake Preview Version 8 is required.

# Supported Versions
|                           |    Version                  |
|:-------------------------:|:---------------------------:|
| Cosmos DB API Version     | 2018-12-31                  |
| Ballerina Language        | Swan-Lake-Preview8          |
| Java Development Kit (JDK)| 11                          |

# Limitations
- Only data plane operations are supported from the connector. (Some Management plane operations are not supported)
- Changing the type of throughput in databases (Auto Scaling -> Manual) is not allowed.
- Only Core(SQL) API is supported.

# Quickstart(s)

## Management of Documents

### Step 1: Import Cosmos DB Package
First, import the ballerinax/azure.cosmosdb module into the Ballerina project.
```ballerina
import ballerinax/azure.cosmosdb as cosmosdb;
```
### Step 2: Initialize the cosmos DB Management Plane Client
You can now make the connection configuration using the Master Token or Resource Token,  and the resource URI to the 
Cosmos DB Account. For executing management plane opeartions, the` ManagementClient` should be configured.
```ballerina
cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: <BASE_URL>,
    masterOrResourceToken: <MASTER_OR_RESOURCE_TOKEN>
};

cosmosdb:ManagementClient managementClient = new(configuration);
```
Note: You have to specify the` Base URI` and` Master-Token` or` Resource-Token`  

### Step 4: Create new Database
You have to create a database in Azure Account to create a document. For this you have to provide a unique database ID 
which does not already exist in the specific Cosmos DB account. The ID for this example will be` my_database`.  This 
operation will return a record of type Result. This will contain the success as` true` if the operation is successful. 
```ballerina
cosmosdb:Result result = managementClient->createDatabase("my_database");
```
### Step 5: Create new Container
Then, you have to create a container inside the created database. As the REST api version which is used in this 
implementation of the connector strictly supports the partition key, it is a necessity to provide the partition key 
definition in the creation of a container. For this container it will be created inside` my_database` and ID will 
be` my_container`. The path for partition key is` /gender`. We can set the version of the partition key to 1 or 2
```ballerina
cosmosdb:PartitionKey partitionKeyDefinition = {
    paths: ["/gender"],
    keyVersion: 2
};
cosmosdb:Result containerResult = check managementClient->    
            createContainer("my_database", "my_container", partitionKeyDefinition);
```
Note: For this operation, you have to have an understanding on how to select a suitable partition key according to the 
nature of documents stored inside. The guide to select a better partition key can be found here. 
https://docs.microsoft.com/en-us/azure/cosmos-db/partitioning-overview#choose-partitionkey


### Step 6: Initialize the Cosmos DB Data Plane Client
For continuing with the data plane operations in Cosmos DB you have to make use of the Data Plane client provided by the ballerina connector. For this, the same connection configuration as the` ManagementClient` can be used.
```ballerina
cosmosdb:CoreClient azureCosmosClient = new(configuration);
```
### Step 7: Create a Document
Now, with all the above steps followed you can create a new document inside Cosmos Container. As Cosmos DB is designed to store and query JSON-like documents, the document you intend to store must be a JSON object. Then, the document must have a unique ID to identify it. In this case the document ID will be` my_document`
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
    id: my_document,
    documentBody: documentBody
};

cosmosdb:Result documentResult = check azureCosmosClient-> 
        createDocument("my_database", "my_container", document,  
                                            valueOfPartitionKey);
```
Notes: As we have selected` /gender` as the partition key for` my_container`, the document we create should include that 
path with a valid value.

### Step 8: List the Documents
For listing the existing documents inside this Cosmos Container you have to give` my_database` and` my_container` as 
parameters. Here, you will get a stream of json objects as the response. Using the ballerina Stream API you can access 
the returned results.
```ballerina
stream<cosmosdb:Document> documentList = check azureCosmosClient-> 
                            getDocumentList("my_database", "my_container");
 
var document = documentList.next();
log:print(document?.value);
```
### Step 9: Query Documents
Querying documents is one of the main use-cases supported by a Database. For querying documents inside the database we 
have created, you have to give` my_database` and` my_container` as parameters. The SQL query must be provided as a string. 
When executing a SQL query using the connector, there are specific ways you can write the query itself and provide the 
optional parameters.More information on this can be found here: https://docs.microsoft.com/en-us/rest/api/cosmos-db/querying-cosmosdb-resources-using-the-rest-api

```ballerina
string selectAllQuery = string `SELECT * FROM ${containerId.toString()} 
                                                    f WHERE f.gender = ${0}`;
int partitionKeyValueMale = 0;
int maxItemCount = 10;
stream<json> queryResult = check azureCosmosClient->    
        queryDocuments(<DATABASE_ID>, <CONTAINER_ID>, selectAllQuery,  
                                [], maxItemCount, partitionKeyValueMale);

error? e =  resultStream.forEach(function (json document){
                log:printInfo(document);
            });
```
Notes: As the Cosmos Containers are creating logical partitions with the partition key we provide, we have to 
provide the value of partition key, if the querying must be done in that logical partition.

### Step 10: Delete a given Document
Finally, you can delete the document you have created. For this operation to be done inside the container created, 
you have to give` my_database` and` my_container` as parameters. Apart from that, the target document to delete
` my_document` and` value of the partition key` of that document must be provided.
```ballerina
 _ = check azureCosmosClient->deleteDocument("my_database", "my_container" 
                                 "my_document", valueOfPartitionKey);
```

# Building from the Source

## Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).

   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

   * [OpenJDK](https://adoptopenjdk.net/)

        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Download and install [Ballerina SLP8](https://ballerina.io/). 

## Building the Source

Execute the commands below to build from the source after installing Ballerina SLP8 version.

1. To build the library:
```shell script
    ballerina build
```

2. To build the module without the tests:
```shell script
    ballerina build --skip-tests
```
# Contributing to Ballerina
As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

# Code of Conduct
All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

# Useful Links
* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
