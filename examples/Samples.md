# Samples
## Data-Plane operations
## Documents
Azure Cosmos DB allows the execution of CRUD operations on items separately. SQL API stores entities in JSON in a hierarchical
key-value document. The max document size in Cosmos DB is 2 MB.

### [Create a document](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/blob/main/samples/data-operations/documents/create_document.bal)
This sample shows how to create a new document inside a container. This document contains information about a person's
family and his/her gender. The container `my_container` has a partition key which has the path `/gender`. Here, you have 
to specify the IDs on the database and the container in which the document needs to be created, a unique ID for the new 
document, and a JSON object that represents the document as parameters. The partition key is required for the container. 
Therefore, the value for that too should be passed as a parameter to the function.

**Note:** <br/> The following are some optional parameters that are supported when creating documents. These options 
can be specified in the `DocumentCreateOptions` record type in the connector.
- **indexingDirective** - This parameter specifies whether the document is included in any predefined indexing policy 
for the container. The value can be `Include` or `Exclude`.
- **isUpsertRequest** - You can set this parameter to `true` to create a new document via an upsert request.
  
### [Replace document](data-operations/documents/replace_document.bal)
This sample shows how to replace an existing document inside a container. This operation is similar to creating a 
document, but the new document replaces an existing one. The partition key of the new document needs to be the same 
as that of the document it is replacing. For more information about replacing partition key values, see [here](https://github.com/Azure/azure-sdk-for-js/issues/6324).


**Note:** <br/> Several Optional Parameters are supported in the replacement of documents. These options can be specified
in `DocumentReplaceOptions` record type in the connector.
- **indexingDirective** - This option is to specify whether the document is included in any predefined indexing policy
  for the container. This is provided by giving **Include** or **Exclude**.

### [Get a document](data-operations/documents/get_document.bal)
This sample shows how to get a document by its ID. It returns ta record of type `Document`. Here, you have to provide
*database ID*, *container ID* where the document will be created and the `ID of the document` to retrieve. As the
partition key is mandatory in the container, for getDocument operation you need to provide the correct
**value for that partition key**.

**Note:** <br/> The following are some optional parameters that are supported when reading documents. These options 
can be specified in the `DocumentReadOptions` record type in the connector.

- **sessionToken** - the client will use a session token internally with each read/query request to ensure that the
  session-level consistency level is maintained.
- **consistancyLevel** - It is the consistency level override. The valid values are: `Strong`, `Bounded`,
  `Session`, or `Eventual`.
  Users must set this level to the same or weaker level than the account’s configured consistency level. More information
  about Cosmos DB consistency levels can be found [here](https://docs.microsoft.com/en-us/azure/cosmos-db/consistency-levels).
  
### [List documents](data-operations/documents/list_documents.bal)
This sample shows how you can get a list of all the documents. For this operation, you will get a stream of documents
represented using the `Document` record type. You have to provide the *database ID* and *container ID* where the document
exists as parameters.

**Note:** <br/> The following are some optional parameters that are supported when listing documents. These options 
can be specified in the `DocumentListOptions` record type in the connector.

- **sessionToken** - The client will use a session token internally with each read/query request to ensure that the
  session-level consistency level is maintained.
- **consistancyLevel** - It is the consistency level override. The valid values are: `Strong`, `Bounded`,
  `Session`, or `Eventual`.
  *Users must set this level to the same or weaker level than the account’s configured consistency level*.
- **changeFeedOption** - Must be set to `Incremental feed`, or omitted otherwise. More information about change feed
  can be found [here](https://docs.microsoft.com/en-us/azure/cosmos-db/change-feed).
- **partitionKeyRangeId** - The partition key range ID for reading data.

### [Delete a document](data-operations/documents/delete_document.bal)
This sample shows how to delete a document which exists inside a container. You have to specify the *database ID*,
*container ID* where the document exists and the **ID of document** you want to delete. The
**value of the partition key** for that specific document should also passed to the function.

**Note:** <br/> The following are some optional parameters that are supported when deleting documents. These options 
can be specified in the `ResourceDeleteOptions` record type in the connector.

- **sessionToken** - the client will use a session token internally with each read/query request to ensure that the
  session-level consistency level is maintained.
  
### [Querying documents](data-operations/documents/query_document.bal)
When executing an SQL query using the connector, there are specific ways you can write the query itself. As specified in
the Cosmos DB documentation, SQL queries can be written in different ways for querying Cosmos DB. Cosmos DB Ballerina
connector allows the option to either provide a query as a normal ballerina string that matches with the SQL queries
compatible with the REST API. This sample shows a query that will return all the data inside a document such that the
value for **/gender** equals 0.

**Note:** <br/>
- The record type `ResourceQueryOptions` can be used to provide several options for executing the qury.
    - **consistancyLevel** - It is the consistency level override. The valid values are: `Strong`, `Bounded`,
      `Session`, or `Eventual`. Users must set this level to the same or weaker level than the account’s configured
      consistency level of the Azure account.
    - **sessionToken** - The client will use a session token internally with each read/query request to ensure that the     
      session-level consistency level is maintained.
    - **partitionKey** - The **value of partition key field** of the container. It only queries the documents which have
      its **partition key value** equals to the given value. If we specify a partitioning key for this field, it is
      mandatory to set `enableCrossPartition` to false.
    - **enableCrossPartition** - Use to provide whether to ignore the partition keys and query across partitions. This
      can be done using a boolean value. By default cross-partitioning is made `true`. Providing only the
      **partitionKey** will not automatically restrict partitioning to one partition.
- The optional **maxItemCount** parameter specifies the maximum number of results returned per page. So, in the
  connector, the user can either get the items on one page or get all the results related to each query.
  
## Stored Procedures
A Stored procedure is a piece of application logic written in JavaScript that is registered and executed against a
collection as a single transaction. You can use stored procedures to manipulate one or more documents within a container
in Cosmos DB.

### [Create a stored procedure](data-operations/stored-procedure/create_stored_procedure.bal)
This sample shows how to create a stored procedure inside a container. This stored procedure will return a
response appending a string inside the function to the response body. For this, you have to provide the *database ID*
and the *container ID* where the stored procedure will be saved in. Apart from that, a *unique ID* for the stored
procedure and a JavaScript function that represents the stored procedure should be provided as parameters.


### [Replace a stored procedure](data-operations/stored-procedure/replace_stored_procedure.bal)
This sample shows how to replace an existing stored procedure. This new stored procedure enhances the capabilities of
the earlier stored procedure by appending the function parameter passed through the request to a string inside the
function and returning it with re response to the caller. For this, you have to provide the *database ID* and the
*container ID* where the stored procedure is saved in. The ID of the stored procedure to replace and any JavaScript
function should also be passed as parameters.

### [List stored procedures](data-operations/stored-procedure/list_stored_procedure.bal)
From this sample, you can get a list of all the stored procedures inside a container. Each record in the result list will
contain a stream of `StoredProcedure` record types and several other important information. You have to provide the
*database ID* and the *container ID* as parameters.

### [Delete a stored procedure](data-operations/stored-procedure/delete_stored_procedure.bal)
This sample shows how to delete a stored procedure that exists inside a container. You have to specify the
*database ID*, *container ID* where the stored procedure exists and the *ID of the stored procedure* you want to delete.

### [Execute a stored procedure](data-operations/stored-procedure/execute_stored_procedure.bal)
A stored procedure is a piece of logic written in JavaScript which can be executed via an API call. Cosmos DB connector
explicitly gives the capability to execute stored procedures. They can be used in Azure databases to execute CRUD
operations on documents and also to read from the request body and write to the response body. More information about
this can be found [here](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-write-stored-procedures-triggers-udfs).

This sample shows how to execute a stored procedure already existing inside a container.

**Note:** <br/> If a stored procedure contains function arguments to be passed to it, you can pass them as an array using
the `parameters` field of record type `StoredProcedureOptions`. For example, if only one parameter is in the JavaScript
function, the argument must be an array with one element as shown in the above sample.

## Management Plane Operations
## Databases
Management of databases is a common practice in every organization. It is a kind of task that is usually done with the
administrator privileges in normal cases. The databases in Azure Cosmos DB are like namespaces and it acts as a unit of
management for containers. One Cosmos DB account can contain one or more databases inside it. Using the Ballerina
connector itself, you can manage these databases. As database operations are more of a management operation type,
they are included inside the management client of the connector.

### [Creating a database](admin-operations/database/create_database.bal)
The creation of databases is a common capability of every database System. For creating a database in Azure, you have to
provide a **unique database ID** that does not already exist in the specific Cosmos DB account. This operation will
return a record of type `Database`. This will contain the success as true if the operation is successful.

**Note:** <br/> For creation of a database you can configure a `throughputOption` which is an integer value or a record
type.
For example:

```ballerina
cosmosdb:ManagementClientConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = check new (config);
 
public function main() {
    string databaseId = "my_database";

    int throughput = 600;
    cosmosdb:Database databaseResult = managementClient-> createDatabase(databaseId, throughput);

    // or

    record {|int maxThroughput;|} maxThroughput = { maxThroughput: 4000 };
    cosmosdb:Database databaseResult = managementClient->createDatabase(databaseId, maxThroughput);
}
```
These options for throughput are only supported in the Cosmos DB account type known as `provisioned throughput`
accounts. For the account type which is called `serverless(preview)` you cannot specify any throughput because it is
not providing support for provisioned throughput for containers or databases inside it.
More information about serverless accounts can be found [here](https://docs.microsoft.com/en-us/azure/cosmos-db/serverless).

### [Get a database](admin-operations/database/get_a_database.bal)
This operation is related to reading information about a database that is already created inside the Cosmos DB account.
It returns a record of type `Database`. We can use this result to refer to a database by it’s *resourceId* will be
useful in query operations and creating offers. You have to pass the *database ID* as a parameter for this function.

### [List All databases](admin-operations/database/list_databases.bal)
When there is a need to list down all the databases available inside a Cosmos DB account. This operation will return a
stream, each element containing a record of type `Database`.


### [Delete a database](admin-operations/database/delete_database.bal)
This operation can be used for deleting a database inside an Azure Cosmos DB account. It returns a record of type
`DeleteResponse` if the database is deleted successfully or else returns an error in case there is a problem.

## Containers
A container in Cosmos DB is schema-agnostic and it is a unit of scalability for the Cosmos DB. It is horizontally
partitioned and distributed across multiple regions. This is done according to the partition key and the items added to
the container and the provisioned throughput is distributed across a set of logical partitions.

### [Creating a container](admin-operations/container/create_container.bal)
A container can be created inside an existing database in the Cosmos DB account. As the REST API version which is used
in this implementation of the connector strictly supports the partition key, it is a necessity to provide the partition
key in the creation of a container.

Notes: <br/> Apart from this, the creation of containers allows several optional parameters to provide more specialized
characteristics to the container which is created.
- **IndexingPolicy** - This can be used in creating a container if you want to enable an Indexing policy for a specified
  set of paths. If we do not specifically give this parameter, Cosmos DB automatically indexes all the paths.
  More information about indexing can be found here: https://docs.microsoft.com/en-us/azure/cosmos-db/index-policy
- **throughputOption** - is used in the creation of a container to configure a throughputOption which is an integer value or a
  record type.

### [Get a container](admin-operations/container/get_container.bal)
This operation is related to reading information about a container that is already created inside a database. It mainly
returns a record type `Container` which contains the ID of the container, The indexing policy, and the partition key
along with the resourceId.

### [List all containers](admin-operations/container/list_containers.bal)
When there is a need to list-down all the containers available inside a database. This operation will return a
stream, each element containing a record of type `Container`.

### [Delete a container](admin-operations/container/delete_container.bal)
This operation can be used for deleting a container inside a database. It returns `DeleteResponse` if the container is
deleted successfully or else returns an error in case there is a problem.

## User Defined Functions
User-Defined Function - is a side-effect-free piece of application logic written in JavaScript. They can be used to
extend the Cosmos DB query language to support a custom application logic. They are read-only once created. You can
refer to them when writing queries. User-defined functions provide “compute-only” processing of information within a
single document in Cosmos DB without any side-effects.

### [Create a user defined function](admin-operations/user-defined-functions/create_udf.bal)
This sample shows how to create a user defined function that will compute the tax amount for a given income amount.
In this operation, you have to provide the *database ID* and the *container ID* where the user defined function is
saved in. Apart from that, a *unique ID for user defined function and a JavaScript function should be provided as
parameters.

### [Replace a user defined function](admin-operations/user-defined-functions/replace_udf.bal)
This sample shows how you can replace an existing user defined function with a new one. Here, the name of the User
Defined Function is updated to a new one. When replacing, you have to provide the *database ID* and the *container ID* where
the user defined function is saved in and you should pass the *ID of the user defined function* which will be replaced and the
JavaScript function which will replace the existing user defined function.

### [List user defined functions](admin-operations/user-defined-functions/list_udf.bal)
From this sample, you can get a list of all the user defined functions inside a container. The result will
contain a stream, each element containing a record of type  `UserDefinedFunction`. You have to provide the *database ID*
and *container ID* as parameters.

### [Delete a user defined function](admin-operations/user-defined-functions/delete_udf.bal)
This sample shows how to delete a user defined function which exists inside a container. You have to specify the
*database ID*, *container ID* where the user defined function exists and the *ID of the user defined function you want to
delete.

## Triggers
A Trigger is a piece of application logic that can be executed before (pre-triggers) and after (post-triggers). You can
use triggers to validate and/or modify data when a document is added, modified, or deleted within a container. The
triggers do not accept any parameters or do not return any result set.

### [Create a trigger](admin-operations/triggers/create_trigger.bal)
This sample shows how to create a trigger that will update a document with ID "_metadata" after the creation of a new
document in the container. For this operation, you have to provide the *database ID* and the *container ID* where the
trigger is saved in. A *unique ID* for trigger and a JavaScript function should be provided to the **trigger function**.
Apart from that, you have to provide **type of trigger operation**, and **type of trigger**  as parameters.

**Note:** <br/> When creating a trigger, there are several required parameters we have to pass as arguments.
- **triggerId** - A unique ID for the newly created trigger
- **triggerOperation** - The type of operation in which trigger will be invoked from. The acceptable values are `All`,
  `Create`, `Replace`, and `Delete`.
- **triggerType** - Specifies when the trigger will be fired, `Pre` or `Post`.
- **triggerFunction** - The function which will be fired when the trigger is executed.

### [Replace a trigger](admin-operations/triggers/replace_trigger.bal)
This sample shows how you can replace an existing trigger with a new one. Here, the name of the trigger is updated to a
new one. When replacing, you have to provide the *database ID* and the *container ID* where the trigger is saved in.
As parameters, *ID of the trigger to be replaced* and a JavaScript function should be provided to the
**trigger function**. Apart from that, you have to provide **type of trigger operation**, and **type of trigger**  as
parameters. (It is not mandatory to replace all parameters with a new value but all the values should be passed).

### [List triggers](admin-operations/triggers/list_trigger.bal)
From this sample, you can get a list of all the triggers inside a container. It will return a stream, which contains
records of type `Trigger`. You have to provide the *database ID* and *container ID* as parameters.

### [Delete a trigger](admin-operations/triggers/delete_trigger.bal)
This sample shows how to delete a trigger that exists inside a container. You have to specify the *database ID*,
*container ID* where the trigger exists and the *ID of the trigger you want to delete*.

## Users
User management operations in Cosmos DB are strictly related with the **Master Key/Primary Key** of the Cosmos DB account.
A user acts as a namespace, scoping permissions on collections, documents, attachment, stored procedures, triggers, and
user-defined functions. The User construct lives under a database resource and thus cannot cross the database boundary
it is under. The ballerina connector implementation facilitates creating a new User, replacing user ID, get, list and
delete of Users in a Cosmos DB account. More information about users can be found here:
https://docs.microsoft.com/en-us/rest/api/cosmos-db/users

### [Create a user](admin-operations/users-permissions/user/create_user.bal)
Users are stored within the context of the database in Cosmos DB. Each user has a set of unique named permissions. So in
this operation, an instance of user for a specific database is created. The things you need to create a user in Cosmos DB
are the *database ID* and a *unique ID* for the user. Here `my_database` and `my_user` are provided as parameters
respectively.

### [Replace user's ID](admin-operations/users-permissions/user/replace_user_id.bal)
From this sample, you can replace the ID of an existing user. The only replaceable property is the ID of a user created
earlier. Although the saved user can have **permissions** that are related, those will not be affected by this operation.
For this, you have to provide the *database ID* where the user is scoped into, the *user ID* you want to replace, and
the *New user ID* which the older one is to be replaced with.

### [Get a user](admin-operations/users-permissions/user/get_user.bal)
From this sample, you can get the basic information about a created user. For this, the *database ID* where the user is
scoped into and the* user ID* you want to get information about should be provided. Referring to earlier samples, the
database ID will be **my_database** and user ID will be **my_user** in this case.

### [List users](admin-operations/users-permissions/user/list_users.bal)
From this operation, you can get a list of all the users who are scoped into a given database. It will return a stream,
which contains records of type `User`. You have to provide the *database ID* which in this case `my_database` as the
argument.

### [Delete a user](admin-operations/users-permissions/user/delete_user.bal)
The Common User management operations of databases usually have the option to delete an existing user. The Cosmos DB
connector supports this operation. For deleting a user the specific *database ID* User is scoped to and the *ID of the
User to delete* must be provided.

## Permissions
Permissions are related to the Users in the Cosmos DB. The person who possesses the `Master-Token` of the Cosmos DB
account is capable of creating permissions for each user. By using this concept, a ballerina service that uses the
Cosmos DB connector can act as a token broker, which issues tokens with specific access rights to users (involves a
middle-tier service that serves as the authentication and authorization broker between a client and a back-end service).
This is granted by using `Resource-Token`.

Resource-tokens provide user-based permissions to individual resources in the Cosmos DB, including collections,
documents, attachments, stored procedures, triggers, and user-defined functions. They are auto-generated when a database
user is granted permissions to a resource and re-generated in response to a request referencing that permission.
By default, they are **valid for one hour**, with a maximum time-span of five hours. As the use of `Master-Token`
should be limited to scenarios that require full privileges to the content of an account, for more granular access,
you should use Resource Tokens. More information on token types can be found [here](https://docs.microsoft.com/en-us/azure/cosmos-db/secure-access-to-data).

### [Create a permission](admin-operations/users-permissions/permission/create_permission.bal)
Permissions in Cosmos DB have 3 primary properties:
- **permissionId** - Id for the permission.
- **permissionMode** - You only have two options here, `Read` or `All`, and like you would expect, limits the scope
  of what you can do with the data.
- **permissionResource** - ResourceLink is the meat of what this permission is allowing the user to access. In
  Cosmos DB, many things are resources such as `Databases`, `Containers`, `Documents`, and `Attachments`.
  Depending on the granularity, multiple permissions can be created and assigned to a **user** based on the data they
  should be able to have access to.
  When creating permission, you should provide values for the above properties. Apart from that, as permission is
  explicitly made referring to an existing user, *user ID* and the *database ID* also should be specified. These primary
  properties must be provided as parameters to the function. By default created token is expired in one hour.

**Note:** <br/>
The **validityPeriodInSeconds** argument can be provided as the last parameter of this method to explicitly specify a TTL
for the token you are creating. This will override the default validity period of the token. The **maximum** override value
is **18000 seconds**.

### [Replace a permission](admin-operations/users-permissions/permission/replace_permission.bal)
This operation has all the parameters similar to create permission. The only difference is that it only replaces
existing permission. Although it replaces permission, you have to specify all the primary properties. But not all
properties have to have changed. These primary properties are provided as function parameters. The *Permission ID*
should be the ID of the permission we want to replace.

### [Get a permission](admin-operations/users-permissions/permission/get_permission.bal)
From this sample, you can get the basic information about a created permission. For this, the *database ID* and the
*user ID* to which the permission belongs and the *permission ID* that, you want to get information about should be
provided.

### [List permissions](admin-operations/users-permissions/permission/list_permissions.bal)
From this operation, you can get a list of all the permissions that belong to a single user. It will return a stream,
which contains records of type `Permission`. You have to provide the *database ID* and the *user ID* the permissions
belong as parameters.

### [Delete a permission](admin-operations/users-permissions/permission/delete_permission.bal)
This Operation allows deleting a permission in the database. For deleting the permission, the specific *database ID*, 
*user ID* to which the permission belongs and the *ID of the Permission* to delete must be provided.

## [Offers](admin-operations/offers/offer_operations.bal)
Cosmos DB containers have either user-defined performance levels or pre-defined performance levels defined for each of
them. The operations on offers support replacing existing offers, listing and reading them, and querying offers.

**Note:** <br/>Operations on offers are not supported in `Serverless` accounts because they don’t specifically have a
predefined throughput level.
