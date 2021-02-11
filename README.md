Ballerina Connector For Azure Cosmos DB
===================

[![Build](https://github.com/sachinira/module-ballerinax-azure-cosmosdb/workflows/CI/badge.svg)](https://github.com/sachinira/module-ballerinax-azure-cosmosdb/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/sachinira/module-ballerinax-azure-cosmosdb/feature7)](https://github.com/sachinira/module-ballerinax-azure-cosmosdb/commits/feature7)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# What is Azure Cosmos DB
The Azure Cosmos DB is Microsoft’s highly scalable NOSQL  database in Azure technology stack. It is called a globally 
distributed multi-model database which  is used for managing data across the world. Key purposes of the Azure CosmosDB 
is to achieve low latency and high availability while maintaining a flexible scalability. Cosmos DB is a superset of 
Azure Document DB and is available in all Azure regions.

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

        When the Azure Cosmos DB account is created, it automatically creates the Primary Key  credentials. Using the 
        portal you can obtain them easily. <br/>
        https://docs.microsoft.com/en-us/azure/cosmos-db/database-security#primary-keys
        
        - Obtaining Resource Token
        
        The person who possess the Master Key of the Cosmos DB account is capable of creating permissions to each user. 
        By using this concept, a ballerina service which uses the Cosmos DB connector can act as a token broker, which 
        issues tokens with specific access rights to users (involves a middle-tier service that serves as the 
        authentication and authorization broker between a client and a back-end service). This is handled by using 
        Resource Tokens. 

        Resource tokens provide user-based permissions to individual account resources, including collections, documents, 
        attachments, stored procedures, triggers, and user-defined functions. They are auto-generated when a database 
        user is granted permissions to a resource and re-generated in response to a request referencing that permission. 
        By default, they are valid for one hour, with the maximum timespan of five hours.

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
Cosmos DB Account. For executing management plane opeartions, the `ManagementClient` should be configured.
```ballerina
cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: <BASE_URL>,
    masterOrResourceToken: <MASTER_OR_RESOURCE_TOKEN>
};

cosmosdb:ManagementClient managementClient = new(configuration);
```
Notes: <br/> You have to specify the `Base URI` and `Master-Token` or `Resource-Token`  

### Step 4: Create new Database
You have to create a database in Azure Account to create a document. For this you have to provide a unique database ID 
which does not already exist in the specific Cosmos DB account. The ID for this example will be `my_database`.  This 
operation will return a record of type Result. This will contain the success as `true` if the operation is successful. 
```ballerina
cosmosdb:Result result = managementClient->createDatabase("my_database");
```
### Step 5: Create new Container
Then, you have to create a container inside the created database. As the REST api version which is used in this 
implementation of the connector strictly supports the partition key, it is a necessity to provide the partition key 
definition in the creation of a container. For this container it will be created inside `my_database` and ID will 
be `my_container`. The path for partition key is `/gender`. We can set the version of the partition key to 1 or 2
```ballerina
cosmosdb:PartitionKey partitionKeyDefinition = {
    paths: ["/gender"],
    keyVersion: 2
};
cosmosdb:Result containerResult = check managementClient->    
            createContainer("my_database", "my_container", partitionKeyDefinition);
```
Notes: <br/> For this operation, you have to have an understanding on how to select a suitable partition key according 
to the nature of documents stored inside. The guide to select a better partition key can be found here. 
https://docs.microsoft.com/en-us/azure/cosmos-db/partitioning-overview#choose-partitionkey


### Step 6: Initialize the Cosmos DB Data Plane Client
For continuing with the data plane operations in Cosmos DB you have to make use of the Data Plane client provided by the 
ballerina connector. For this, the same connection configuration as the `ManagementClient` can be used.
```ballerina
cosmosdb:CoreClient azureCosmosClient = new(configuration);
```
### Step 7: Create a Document
Now, with all the above steps followed you can create a new document inside Cosmos Container. As Cosmos DB is designed 
to store and query JSON-like documents, the document you intend to store must be a JSON object. Then, the document must 
have a unique ID to identify it. In this case the document ID will be `my_document`
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
Notes: <br/> As we have selected `/gender` as the partition key for `my_container`, the document we create should include that 
path with a valid value.

### Step 8: List the Documents
For listing the existing documents inside this Cosmos Container you have to give `my_database` and `my_container` as 
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
have created, you have to give `my_database` and `my_container` as parameters. The SQL query must be provided as a string. 
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
Notes: <br/> As the Cosmos Containers are creating logical partitions with the partition key we provide, we have to 
provide the value of partition key, if the querying must be done in that logical partition.

### Step 10: Delete a given Document
Finally, you can delete the document you have created. For this operation to be done inside the container created, 
you have to give `my_database` and `my_container` as parameters. Apart from that, the target document to delete
`my_document` and `value of the partition key` of that document must be provided.
```ballerina
 _ = check azureCosmosClient->deleteDocument("my_database", "my_container" 
                                 "my_document", valueOfPartitionKey);
```
# Samples
## Management Plane Operations
- ## Databases
Management of databases is a common practice in every organization. It is a kind of task which is usually done with the 
administrator privileges in normal cases. The databases in Azure Cosmos DB are like namespaces and it acts as a unit of 
management for containers. One Cosmos DB account can contain one or more Databases inside it. Using the Ballerina 
connector itself, we can manage these databases. As database operations are more of management operation type, they are 
included inside the management client of the connector.
### Creating a Database 
Creation of databases is a common capability of every database. For creating a database in Azure we have to provide a 
unique database ID which does not already exist in the specific cosmos DB account. This operation will return a record 
of type Result. This will contain the success as true if the operation is successful.

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";

    log:print("Creating database");
    cosmosdb:Result databaseResult = checkpanic managementClient->createDatabase(databaseId);
    log:print("Success!");
}
```
Notes: <br/> For creation of a database we can configure a `throughputOption` which is an integer value or a json object. 
For example:
 
```ballerina
cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);
 
public function main() {
    string databaseId = "my_database";

    int throughput = 600;
    cosmosdb:Result databaseResult = check managementClient-> createDatabase(databaseId, throughput);

    // or

    json maxThroughput = {"maxThroughput": 4000};
    cosmosdb:Result databaseResult = check managementClient->createDatabase(databaseId, maxThroughput);
}
```
These options for throughput are only allowed in the Cosmos DB account type known as `provisioned throughput` accounts. 
For the account type which is called `serverless(preview)` we cannot specify any throughput because it is not providing 
support for provisioned throughput for containers or databases inside it. More information about serverless accounts 
can be found here:
https://docs.microsoft.com/en-us/azure/cosmos-db/serverless

### Get one Database
This operation is related to reading information about a database which is already created inside the cosmos DB account. 
It mainly returns the ID of the database with resourceId. We can use the results to refer to a database by it’s 
`resourceId` which will be useful in query operations and creating offers.

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";

    log:print("Reading database by id");
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    log:print("Success!");
}
```
### List All Databases
When there is a need to list down all the databases available inside a Cosmos DB account. This operation will return a 
stream of databases to the user each containing a record of type `Database`.  

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    log:print("Getting list of databases");
    stream<cosmosdb:Database> databaseList = checkpanic managementClient->listDatabases(10);
    log:print("Success!");
}
```
### Delete a Database
This operation can be used for deleting a database inside an Azure Cosmos DB account. It returns true if the database is
deleted successfully or else returns an error in case there is a problem.

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";

    log:print("Deleting database");
    _ = checkpanic managementClient->deleteDatabase(databaseId);
    log:print("Success!");
}
```

- ## Containers
A container in cosmos DB is a schema agnostic and it is a unit of scalability for the Cosmos DB. It is horizontally 
partitioned and distributed across multiple regions. This is done according to the partition key and the items added to 
the container and the provisioned throughput is distributed across a set of logical partitions.  
### Creating a Container
A container can be created inside an existing database in the cosmos DB account. As the REST api version which is used 
in this implementation of the connector strictly supports the partition key, it is a necessity to provide the partition 
key in the creation of a container. 

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";

    log:print("Creating container");
    cosmosdb:PartitionKey partitionKey = {
        paths: ["/id"],
        keyVersion: 2
    };
    cosmosdb:Result containerResult = checkpanic managementClient->createContainer(databaseId, containerId, partitionKey);
    log:print("Success!");
}
```
Notes: <br/> Apart from this the creation of containers allows several optional parameters to provide more specialized 
characteristics to the container which is created.  
- `IndexingPolicy` - can be used in creating a container, if we want to enable an Indexing policy for a specified path,
the special optional parameter can be used. 
- `throughputOption` - is used in creation of a container to configure a throughputOption which is an integer value or a 
json object.

Get one Container
This operation is related to reading information about a container which is already created inside a database. It mainly 
returns the ID of the container, The indexing policy and partition key along with the resourceId.

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";

    log:print("Reading container info");
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);
    log:print("Success!");
}
```
### List all Containers
When there is a need to list down all the containers available inside a database. This operation will return a stream of 
containers to the user each containing a record of type Container.  

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";

    log:print("Getting list of containers");
    stream<cosmosdb:Container> containerList = checkpanic managementClient->listContainers(databaseId, 2);
    log:print("Success!");
}
```

Notes: <br/> The optional parameter `maxItemCount` can be provided as an int to this function as the second argument. 
This item count decides the number of items returned per page. If this is not specified the number to return will be 
100 records per page by default.

### Delete a Container
This operation can be used for deleting a container inside a database. It returns true if the container is deleted 
successfully or else returns an error in case there is a problem.

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";

    log:print("Deleting the container");
    _ = checkpanic managementClient->deleteContainer(databaseId, containerId);
    log:print("Success!");
}
```
- ## Users
User management operations in Cosmos DB are strictly related with the `Master Key/Primary Key` of the Cosmos DB account. 
A user acts as a namespace, scoping permissions on collections, documents, attachment, stored procedures, triggers, and 
user-defined functions. The user construct lives under a database resource and thus cannot cross the database boundary 
it is under. The ballerina connector implementation facilitates creating a new user, replacing user ID, get, list and 
delete of users in a Cosmos DB account.
https://docs.microsoft.com/en-us/rest/api/cosmos-db/users

### Create User
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";

    log:print("Creating user");
    cosmosdb:Result userCreationResult = checkpanic managementClient->createUser(databaseId, userId);
    log:print("Success!");
}
```

### Replace User ID
``` ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string oldUserId = "my_user";
    string newUserId = "my_new_user";

    log:print("Replace user id");
    cosmosdb:Result userReplaceResult = checkpanic managementClient->replaceUserId(databaseId, oldUserId, newUserId);
    log:print("Success!");
}
```
### Get User
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";

    log:print("Get user information");
    cosmosdb:User user  = checkpanic managementClient->getUser(databaseId, userId);
    log:print("Success!");
}
```
### List Users
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";

    log:print("List users");
    stream<cosmosdb:User> userList = checkpanic managementClient->listUsers(databaseId);
    log:print("Success!");
}
```
### Delete User
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";
    
    log:print("Delete user");
    _ = checkpanic  managementClient->deleteUser(databaseId, userId);
    log:print("Success!");
}
```

- ## Permissions
Permissions are related to the Users in the Cosmos DB. The person who possesses the `Master Token` of the Cosmos DB 
account is capable of creating permissions to each user. By using this concept, a ballerina service which uses the 
Cosmos DB connector can act as a token broker, which issues tokens with specific access rights to users (involves a 
middle-tier service that serves as the authentication and authorization broker between a client and a back-end service). 
This is granted by using `Resource Token`. 

Resource tokens provide user-based permissions to individual account resources, including collections, documents, 
attachments, stored procedures, triggers, and user-defined functions. They are auto-generated when a database user is 
granted permissions to a resource and re-generated in response to a request referencing that permission. By default, 
they are valid for one hour, with the maximum timespan of five hours. As the use of Master Token should be limited to 
scenarios that require full privileges to the content of an account, for more granular access, we should use Resource 
Tokens. More information on token types can be found here: 
https://docs.microsoft.com/en-us/azure/cosmos-db/secure-access-to-data

### Create Permission
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string containerId = "my_container";
    string userId = "my_user";

    string permissionId = "my_permission";
    string permissionMode = "All";
    string permissionResource = string `dbs/${databaseId}/colls/${containerId}`;
    
    cosmosdb:Permission newPermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };
        
    log:print("Create permission for a user");
    cosmosdb:Result createPermissionResult = checkpanic managementClient->createPermission(databaseId, userId, <@untainted>newPermission);
    log:print("Success!");
}
```
### Replace Permission

```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string containerId = "my_container";
    string userId = "my_user";
    string permissionId = "my_permission";

    string permissionModeReplace = "Read";
    string permissionResourceReplace = string `dbs/${databaseId}/colls/${containerId}`;
    cosmosdb:Permission replacedPermission = {
        id: permissionId,
        permissionMode: permissionModeReplace,
        resourcePath: permissionResourceReplace
    };
    log:print("Replace permission");
    cosmosdb:Result replacePermissionResult = checkpanic managementClient->replacePermission(databaseId, userId, replacedPermission);
    log:print("Success!");
}
```
### Get Permission
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";
    string permissionId = "my_permission";

    log:print("Get intormation about one permission");
    cosmosdb:Permission permission = checkpanic managementClient->getPermission(databaseId, userId, permissionId);
    log:print("Success!");
}
```
### List Permission
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";

    log:print("List permissions");
    stream<cosmosdb:Permission> permissionList = checkpanic managementClient->listPermissions(databaseId, userId);
    log:print("Success!");
}
```
### Delete Permission
```ballerina
import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() { 
    string databaseId = "my_database";
    string userId = "my_user";
    string permissionId = "my_permission";
    
    log:print("Delete permission");
    _ = checkpanic managementClient->deletePermission(databaseId, userId, permissionId);
    log:print("Success!");
}
```
- ## Offers
Cosmos DB Containers have either user-defined performance levels or pre-defined performance levels defined for each of 
them. The operations on offers support replacing existing offers, listing and reading them and querying offers.

Note: <br/>Operations on offers are not supported in Serverless accounts because they don’t specifically have a 
predefined throughput level.

## Data Plane operations
- ## Documents
Azure cosmos DB allows the execution of  CRUD operations on items separately. As we are using the Core API underneath 
the connector, an item may refer to a document in the container. SQL API stores entities in JSON in a hierarchical 
key-value document.  The max document size in Cosmos DB is 2 MB.

### Create a Document
```ballerina
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
    // Assume partition key of this container is set as /gender which is an int of 0 or 1
    string containerId = "my_container";
    string documentId = "my_document";

    log:print("Create a new document");
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
    int partitionKeyValue = 0;

    cosmosdb:Document document = {
        id: documentId,
        documentBody: documentBody
    };

    cosmosdb:Result documentResult = checkpanic azureCosmosClient->createDocument(databaseId, containerId, document, partitionKeyValue); 
    log:print("Success!");
}
```
### Replace Document
```ballerina
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
    // Assume partition key of this container is set as /gender which is an int of 0 or 1
    string containerId = "my_container";
    string documentId = "my_document";
    //We have to give  the currently existing partition key of this document we can't replace that
    int partitionKeyValue = 0; 

    log:print("Replacing document");
    json newDocumentBody = {
        "LastName": "Helena",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        gender: 0
    };

    cosmosdb:Document newDocument = {
        id: documentId,
        documentBody: newDocumentBody
    };
    cosmosdb:Result replsceResult = checkpanic azureCosmosClient->replaceDocument(databaseId, containerId, newDocument, partitionKeyValue);
    log:print("Success!");
}
```
### Get one Document
```ballerina
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
    // Assume partition key of this container is set as /gender which is an int of 0 or 1
    string containerId = "my_container";
    string documentId = "my_document";
    int partitionKeyValue = 0;
    
    log:print("Read the  document by id");
    cosmosdb:Document returnedDocument = checkpanic azureCosmosClient->getDocument(databaseId, containerId, documentId, partitionKeyValue);
    log:print("Success!");
}
```
### List Documents
```ballerina
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

    log:print("Getting list of documents");
    stream<cosmosdb:Document> documentList = checkpanic azureCosmosClient->getDocumentList(databaseId, containerId);
    log:print("Success!");
}
```
### Delete Document
```ballerina
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
    // Assume partition key of this container is set as /gender which is an int of 0 or 1
    string containerId = "my_container";
    string documentId = "my_document";
    int partitionKeyValue = 0;
    
    log:print("Deleting the document");
    _ = checkpanic azureCosmosClient->deleteDocument(databaseId, containerId, documentId, partitionKeyValue);
    log:print("Success!");
}
```
### Querying  Documents
When executing a SQL query using the connector, there are specific ways you can write the query itself and provide the 
optional parameters. As specified in the Cosmos DB documentation, SQL queries can be written in different ways for 
querying Cosmos DB.
Cosmos DB Ballerina connector allows the option to either to provide a query as a normal ballerina string or explicitly 
specify the query parameters which matches with the SQL queries compatible with the REST API.

```ballerina
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

    log:print("Query1 - Select all from the container where gender 0");
    string selectAllQuery = string `SELECT * FROM ${containerId.toString()} f WHERE f.gender = ${0}`;
    int partitionKeyValueMale = 0;
    int maxItemCount = 10;
    stream<json> queryResult = checkpanic azureCosmosClient->queryDocuments(databaseId, containerId, selectAllQuery, [], 
            maxItemCount, partitionKeyValueMale);
    var document = queryResult.next();
    log:print("Success!");
}
```
## Javascript language integrated functions. 
Cosmos DB Supports Javascript language integrated queries to execute because it has built in support for javascript 
inside the database engine. It allows stored procedures and the triggers to execute in the same scope as the database 
session. More information about Javascript language integrated functions can be found here:
https://docs.microsoft.com/en-us/azure/cosmos-db/stored-procedures-triggers-udfs

The ballerina connector supports the creation, modification , listing and deletion of Stored procedures, Triggers and 
User Defined Functions.

- ## Stored procedures
A Stored procedure is a piece of application logic written in JavaScript that is registered and executed against a 
collection as a single transaction.

- ## User Defined functions
User Defined Function - is a side effect free piece of application logic written in JavaScript. They can be used to 
extend the Cosmos DB query language to support a custom application logic. They are read only once created. You can 
refer to them when writing queries.

- ## Triggers
Trigger  is a piece of application logic that can be executed before (pre-triggers) and after (post-triggers) creation, 
deletion, and replacement of a document. They do not take any parameters.

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
