// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerinax/'client.config;

# This is the Azure Cosmos DB SQL API, a fast NoSQL database servic offers rich querying over diverse data, helps 
# deliver configurable and reliable performance, is globally distributed, and enables rapid development. 
# 
# + httpClient - the HTTP Client
@display {label: "Azure Cosmos DB Management Client", iconPath: "resources/azure_cosmosdb.svg"} 
public isolated client class ManagementClient {
    final http:Client httpClient;
    final string baseUrl;
    final string primaryKeyOrResourceToken;
    final string host;

    # Gets invoked to initialize the `connector`.
    # The HTTP client initialization requires setting the API credentials. 
    # Create an [Azure Cosmos DB account](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account) 
    # and obtain tokens following [this guide](https://docs.microsoft.com/en-us/azure/cosmos-db/database-security#primary-keys).
    #
    # + cosmosdbConfig - Configurations required to initialize the `Client` endpoint
    # + httpClientConfig - HTTP configuration
    # + return -  Error at failure of client initialization
    public isolated function init(ManagementClientConfig config) returns error? {
        self.baseUrl = config.baseUrl;
        self.primaryKeyOrResourceToken = config.primaryKeyOrResourceToken;
        self.host = getHost(config.baseUrl);
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        self.httpClient = check new (self.baseUrl, httpClientConfig);
    }

    # Creates a database.
    # 
    # + databaseId - ID of the new database. Must be a unique value.
    # + throughputOption - Throughput parameter of type int or json.
    # + return - If successful, returns `cosmos_db:Database`. Else returns `cosmos_db:Error`.
    @display {label: "Create Database"} 
    remote isolated function createDatabase(@display {label: "Database ID"} string databaseId, 
                                            @display {label: "Maximum Throughput (optional)"} 
                                            (int|record{|int maxThroughput;|})? throughputOption = ()) 
                                            returns @tainted Database|Error {
        // Creating a new request
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);
        // Setting mandatory headers for the request
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        // Setting optional headers
        check setThroughputOrAutopilotHeader(request, throughputOption);
        // Setting a request payload
        json jsonPayload = {id: databaseId};
        request.setJsonPayload(jsonPayload);
        // Get the response
        http:Response response = check self.httpClient->post(requestPath, request);
        // Return the json payload from the response 
        json jsonResponse = check handleResponse(response);
        // Map the response payload and the headers to a record type
        return mapJsonToDatabaseType(jsonResponse);
    }

    # Creates a database only if the specified database ID does not exist already.
    # 
    # + databaseId - ID of the new database. Must be a unique value.
    # + throughputOption - Throughput parameter of type int or json.
    # + return - If successful, returns `cosmos_db:Database` or `()` if database already exists. Else returns `cosmos_db:Error`.
    @display {label: "Create Database If Not Exist"} 
    remote isolated function createDatabaseIfNotExist(@display {label: "Database ID"} string databaseId, 
                                                      @display {label: "Maximum Throughput (optional)"} 
                                                      (int|record{|int maxThroughput;|})? throughputOption = ()) returns 
                                                      @tainted Database?|Error {
        var result = self->createDatabase(databaseId, throughputOption);
        if (result is error<HttpDetail>) {
            if (result.detail().status == http:STATUS_CONFLICT) {
                return;
            }
        }
        return result;
    }

    # Gets information of a given database.
    # 
    # + databaseId - ID of the database 
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns `cosmos_db:Database`. Else returns `cosmos_db:Error`.
    @display {label: "Get Database"} 
    remote isolated function getDatabase(@display {label: "Database ID"} string databaseId, 
                                         @display {label: "Optional Header Parameters"} ResourceReadOptions? 
                                         resourceReadOptions = ()) 
                                         returns @tainted Database|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, 
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        http:Response response = check self.httpClient->get(requestPath, headerMap);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDatabaseType(jsonResponse);
    }

    # Lists information of all databases.
    # 
    # + return - If successful, returns `stream<cosmos_db:Database, error>`. else returns `cosmos_db:Error`.
    @display {label: "Get Databases"}
    remote isolated function listDatabases() returns
                                          @tainted @display {label: "Stream of Databases"}
                                          stream<Database, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);

        DatabaseStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Database, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes a given database.
    #
    # + databaseId - ID of the database to delete
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
    @display {label: "Delete Database"}
    remote isolated function deleteDatabase(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Optional Header Parameters"} ResourceDeleteOptions?
                                            resourceDeleteOptions = ()) returns @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response);
    }

    # Creates a container inside the given database.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the new container. Must be a unique value.
    # + partitionKey - A record `cosmos_db:PartitionKey`
    # + indexingPolicy - A record `cosmos_db:IndexingPolicy`.
    # + throughputOption - Throughput parameter of type int or json.
    # + return - If successful, returns `cosmos_db:Container`. Else returns `cosmos_db:Error`.
    @display {label: "Create Container"}
    remote isolated function createContainer(@display {label: "Database ID"} string databaseId,
                                             @display {label: "Container ID"} string containerId,
                                             @display {label: "Partition Key Definition"} PartitionKey partitionKey,
                                             @display {label: "Indexing Policy (optional)"} IndexingPolicy?
                                             indexingPolicy = (),
                                             @display {label: "Maximum Throughput (optional)"}
                                             (int|record{|int maxThroughput;|})? throughputOption = ()) returns
                                             @tainted Container|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        check setThroughputOrAutopilotHeader(request, throughputOption);

        json jsonPayload = {
            id: containerId,
            partitionKey: {
                paths: check partitionKey.paths.cloneWithType(json),
                kind: partitionKey.kind,
                Version: partitionKey?.keyVersion
            }
        };
        if (indexingPolicy != ()) {
            jsonPayload = check jsonPayload.mergeJson({indexingPolicy: check indexingPolicy.cloneWithType(json)});
        }
        request.setJsonPayload(jsonPayload);

        http:Response response = check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Creates a container only if the specified container ID does not exist already.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the new container
    # + partitionKey - A record of `cosmos_db:PartitionKey`
    # + indexingPolicy - A record of `cosmos_db:IndexingPolicy`.
    # + throughputOption - Throughput parameter of type int or json.
    # + return - If successful, returns `cosmos_db:Container` if a new container is created or `()` if container already 
    #           exists. Else returns `cosmos_db:Error`.
    @display {label: "Create Container If Not Exist"}
    remote isolated function createContainerIfNotExist(@display {label: "Database ID"} string databaseId,
                                                       @display {label: "Container ID"} string containerId,
                                                       @display {label: "Partition Key Definition"} PartitionKey
                                                       partitionKey,
                                                       @display {label: "Indexing Policy (optional)"} IndexingPolicy?
                                                       indexingPolicy = (),
                                                       @display {label: "Maximum Throughput (optional)"}
                                                       (int|record{|int maxThroughput;|})? throughputOption = ())
                                                       returns @tainted Container?|Error {
        var result = self->createContainer(databaseId, containerId, partitionKey, indexingPolicy, throughputOption);
        if (result is error<HttpDetail>) {
            if (result.detail().status == http:STATUS_CONFLICT) {
                return;
            }
        }
        return result;
    }

    # Gets information about a container.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns `cosmos_db:Container`. Else returns `cosmos_db:Error`.
    @display {label: "Get Container"}
    remote isolated function getContainer(@display {label: "Database ID"} string databaseId,
                                          @display {label: "Container ID"} string containerId,
                                          @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                          resourceReadOptions = ())
                                          returns @tainted Container|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        http:Response response = check self.httpClient->get(requestPath, headerMap);
        json jsonResponse = check handleResponse(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Lists information of all containers.
    #
    # + databaseId - ID of the database to which the containers belongs to
    # + return - If successful, returns `stream<cosmos_db:Container, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get Containers"}
    remote isolated function listContainers(@display {label: "Database ID"} string databaseId)
                                            returns @tainted @display {label: "Stream of Containers"}
                                            stream<Container, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);

        ContainerStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Container, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes a container.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container to delete
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
    @display {label: "Delete Container"}
    remote isolated function deleteContainer(@display {label: "Database ID"} string databaseId,
                                             @display {label: "Container ID"} string containerId,
                                             @display {label: "Optional Header Parameters"} ResourceDeleteOptions?
                                             resourceDeleteOptions = ()) returns
                                             @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response);
    }

    # Retrieves a list of partition key ranges for the container.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where the partition key ranges are related to
    # + return - If successful, returns `stream<cosmos_db:PartitionKeyRange, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get Partition Key Ranges"}
    remote isolated function listPartitionKeyRanges(@display {label: "Database ID"} string databaseId,
                                                    @display {label: "Container ID"} string containerId) returns
                                                    @tainted @display {label: "Stream of Partition Key Ranges"}
                                                    stream<PartitionKeyRange, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_PK_RANGES]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);

        PartitionKeyRangeStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<PartitionKeyRange, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Creates a new User Defined Function.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, User Defined Function is created
    # + userDefinedFunctionId - A unique ID for the newly created User Defined Function
    # + userDefinedFunction - A JavaScript function represented as a string
    # + return - If successful, returns a `cosmos_db:UserDefinedFunction`. Else returns `cosmos_db:Error`.
    @display {label: "Create User Defined Function"}
    remote isolated function createUserDefinedFunction(@display {label: "Database ID"} string databaseId,
                                                       @display {label: "Container ID"} string containerId,
                                                       @display {label: "User Defined Function ID"} string
                                                       userDefinedFunctionId,
                                                       @display {label: "User Defined Function"} string
                                                       userDefinedFunction) returns
                                                       @tainted  UserDefinedFunction|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);

        json payload = {
            id: userDefinedFunctionId,
            body: userDefinedFunction
        };
        request.setJsonPayload(payload);

        http:Response response = check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserDefinedFunction(jsonResponse);
    }

    # Replaces an existing User Defined Function.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing User Defined Function
    # + userDefinedFunctionId - The ID of the User Defined Function to replace
    # + userDefinedFunction - A JavaScript function represented as a string
    # + return - If successful, returns a `cosmos_db:UserDefinedFunction`. Else returns `cosmos_db:Error`.
    @display {label: "Replace User Defined Function"}
    remote isolated function replaceUserDefinedFunction(@display {label: "Database ID"} string databaseId,
                                                        @display {label: "Container ID"} string containerId,
                                                        @display {label: "User Defined Function ID"} string
                                                        userDefinedFunctionId,
                                                        @display {label: "User Defined Function"} string
                                                        userDefinedFunction) returns
                                                        @tainted UserDefinedFunction|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_UDF, userDefinedFunctionId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: userDefinedFunctionId,
            body: userDefinedFunction
        };
        request.setJsonPayload(payload);

        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserDefinedFunction(jsonResponse);
    }

    # Gets a list of existing user defined functions.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the user defined functions
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `stream<cosmos_db:UserDefinedFunction, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get User Defined Functions"}
    remote isolated function listUserDefinedFunctions(@display {label: "Database ID"} string databaseId,
                                                      @display {label: "Container ID"} string containerId,
                                                      @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                                      resourceReadOptions = ()) returns
                                                      @tainted @display {label: "Stream of User Defined Fucntions"}
                                                      stream<UserDefinedFunction, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_UDF]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        UserDefiinedFunctionStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<UserDefinedFunction, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes an existing User Defined Function.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the User Defined Function
    # + userDefinedFunctionid - ID of UDF to delete
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
    @display {label: "Delete User Defined Function"}
    remote isolated function deleteUserDefinedFunction(@display {label: "Database ID"} string databaseId,
                                                       @display {label: "Container ID"} string containerId,
                                                       @display {label: "User Defined Function ID"} string
                                                       userDefinedFunctionid,
                                                       @display {label: "Optional Header Parameters"}
                                                       ResourceDeleteOptions? resourceDeleteOptions =()) returns
                                                       @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_UDF, userDefinedFunctionid]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response);
    }

    # Creates a trigger.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where trigger is created
    # + triggerId - A unique ID for the newly created trigger
    # + trigger - A JavaScript function represented as a string
    # + triggerOperation - The specific operation in which trigger will be executed can be `All`, `Create`, `Replace` or
    #                      `Delete`
    # + triggerType - The instance in which trigger will be executed `Pre` or `Post`
    # + return - If successful, returns a `cosmos_db:Trigger`. Else returns `cosmos_db:Error`.
    @display {label: "Create Trigger"}
    remote isolated function createTrigger(@display {label: "Database ID"} string databaseId,
                                           @display {label: "Container ID"} string containerId,
                                           @display {label: "Trigger ID"} string triggerId,
                                           @display {label: "Trigger"} string trigger,
                                           @display {label: "Triggering Operation"} TriggerOperation triggerOperation,
                                           @display {label: "Trigger Type"} TriggerType triggerType) returns
                                           @tainted Trigger|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);

        json payload = {
            id: triggerId,
            body: trigger,
            triggerOperation: triggerOperation,
            triggerType: triggerType
        };
        request.setJsonPayload(payload);

        http:Response response = check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToTrigger(jsonResponse);
    }

    # Replaces an existing trigger.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the trigger
    # + triggerId - The ID of the trigger to be replaced
    # + trigger - A JavaScript function represented as a string
    # + triggerOperation - The specific operation in which trigger will be executed
    # + triggerType - The instance in which trigger will be executed `Pre` or `Post`
    # + return - If successful, returns a `cosmos_db:Trigger`. Else returns `cosmos_db:Error`.
    @display {label: "Replace Trigger"}
    remote isolated function replaceTrigger(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "Trigger ID"} string triggerId,
                                            @display {label: "Trigger"} string trigger,
                                            @display {label: "Triggering Operation"} TriggerOperation triggerOperation,
                                            @display {label: "Trigger Type"} TriggerType triggerType) returns
                                            @tainted Trigger|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_TRIGGER, triggerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: triggerId,
            body: trigger,
            triggerOperation: triggerOperation,
            triggerType: triggerType
        };
        request.setJsonPayload(payload);

        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToTrigger(jsonResponse);
    }

    # Lists existing triggers.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the triggers
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `stream<cosmos_db:Trigger, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get Triggers"}
    remote isolated function listTriggers(@display {label: "Database ID"} string databaseId,
                                          @display {label: "Container ID"} string containerId,
                                          @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                          resourceReadOptions = ()) returns
                                          @tainted @display {label: "Stream of Triggers"} stream<Trigger, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_TRIGGER]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        TriggerStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Trigger, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes an existing trigger.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the trigger
    # + triggerId - ID of the trigger to be deleted
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
    @display {label: "Delete Trigger"}
    remote isolated function deleteTrigger(@display {label: "Database ID"} string databaseId,
                                           @display {label: "Container ID"} string containerId,
                                           @display {label: "Trigger ID"} string triggerId,
                                           @display {label: "Optional Header Parameters"} ResourceDeleteOptions?
                                           resourceDeleteOptions = ()) returns @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_TRIGGER, triggerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response);
    }

    # Creates a user for a given database.
    #
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of the new user. Must be a unique value.
    # + return - If successful, returns a `cosmos_db:User`. Else returns `cosmos_db:Error`.
    @display {label: "Create User"}
    remote isolated function createUser(@display {label: "Database ID"} string databaseId,
                                        @display {label: "User ID"} string userId) returns @tainted User|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);

        json reqBody = {id: userId};
        request.setJsonPayload(reqBody);

        http:Response response = check self.httpClient->post(requestPath, request);
        return mapJsonToUserType(check handleResponse(response));
    }

    # Replaces the ID of an existing user.
    #
    # + databaseId - ID of the database to which, the existing user belongs to
    # + userId - Old ID of the user
    # + newUserId - New ID for the user
    # + return - If successful, returns a `cosmos_db:User`. Else returns `cosmos_db:Error`.
    @display {label: "Replace User ID"}
    remote isolated function replaceUserId(@display {label: "Database ID"} string databaseId,
                                           @display {label: "Old User ID"} string userId,
                                           @display {label: "New User ID"} string newUserId) returns
                                           @tainted User|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json reqBody = {id: newUserId};
        request.setJsonPayload(reqBody);

        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Gets information of a user.
    #
    # + databaseId - ID of the database to which, the user belongs to
    # + userId - ID of user
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `cosmos_db:User`. Else returns `cosmos_db:Error`.
    @display {label: "Get User"}
    remote isolated function getUser(@display {label: "Database ID"} string databaseId,
                                     @display {label: "User ID"} string userId,
                                     @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                     resourceReadOptions = ()) returns @tainted User|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        http:Response response = check self.httpClient->get(requestPath, headerMap);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Lists users of a specific database.
    #
    # + databaseId - ID of the database to which, the user belongs to
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to
    #                         the request
    # + return - If successful, returns a `stream<cosmos_db:User, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get Users"}
    remote isolated function listUsers(@display {label: "Database ID"} string databaseId,
                                       @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                       resourceReadOptions = ()) returns @tainted @display {label: "Stream of Users"}
                                       stream<User, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        UserStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<User, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes a user.
    #
    # + databaseId - ID of the database to which, the user belongs to
    # + userId - ID of the user to delete
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional
    #                           capabilities to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
    @display {label: "Delete User"}
    remote isolated function deleteUser(@display {label: "Database ID"} string databaseId,
                                        @display {label: "User ID"} string userId,
                                        @display {label: "Optional Header Parameters"} ResourceDeleteOptions?
                                        resourceDeleteOptions = ()) returns @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response);
    }

    # Creates a permission for a user.
    #
    # + databaseId - ID of the database to which, the user belongs to
    # + userId - ID of user to which, the permission is granted. Must be a unique value.
    # + permissionId - A unique ID for the newly created permission
    # + permissionMode - The mode to which the permission is scoped
    # + resourcePath - The resource this permission is allowing the user to access
    # + validityPeriodInSeconds - Validity period of the permission in seconds.
    # + return - If successful, returns a `cosmos_db:Permission`. Else returns `cosmos_db:Error`.
    @display {label: "Create Permission"}
    remote isolated function createPermission(@display {label: "Database ID"} string databaseId,
                                              @display {label: "User ID"} string userId,
                                              @display {label: "Permission ID"} string permissionId,
                                              @display {label: "Permission Mode"} PermisssionMode permissionMode,
                                              @display {label: "Resource Path"} string resourcePath,
                                              @display {label: "Validity Period in Seconds (optional)"} int?
                                              validityPeriodInSeconds = ()) returns @tainted Permission|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId,
            RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        if (validityPeriodInSeconds is int) {
            check setExpiryHeader(request, validityPeriodInSeconds);
        }

        json jsonPayload = {
            id: permissionId,
            permissionMode: permissionMode,
            'resource: resourcePath
        };
        request.setJsonPayload(jsonPayload);

        http:Response response = check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Replaces an existing permission.
    #
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permission is granted
    # + permissionId - The ID of the permission to be replaced
    # + permissionMode - The mode to which the permission is scoped
    # + resourcePath - The resource this permission is allowing the user to access
    # + validityPeriodInSeconds - Validity period of the permission in seconds.
    # + return - If successful, returns a `cosmos_db:Permission`. Else returns `cosmos_db:Error`.
    @display {label: "Replace Permission"}
    remote isolated function replacePermission(@display {label: "Database ID"} string databaseId,
                                               @display {label: "User ID"} string userId,
                                               @display {label: "Permission ID"} string permissionId,
                                               @display {label: "Permission Mode"} PermisssionMode permissionMode,
                                               @display {label: "Resource Path"} string resourcePath,
                                               @display {label: "Validity Period in Seconds (optional)"} int?
                                               validityPeriodInSeconds = ()) returns @tainted Permission|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId,
            RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);
        if (validityPeriodInSeconds is int) {
            check setExpiryHeader(request, validityPeriodInSeconds);
        }

        json jsonPayload = {
            id: permissionId,
            permissionMode: permissionMode,
            'resource: resourcePath
        };
        request.setJsonPayload(jsonPayload);

        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Gets information of a permission.
    #
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permission is granted
    # + permissionId - ID of the permission
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `cosmos_db:Permission`. Else returns `cosmos_db:Error`.
    @display {label: "Get Permission"}
    remote isolated function getPermission(@display {label: "Database ID"} string databaseId,
                                           @display {label: "User ID"} string userId,
                                           @display {label: "Permission ID"} string permissionId,
                                           @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                           resourceReadOptions = ()) returns @tainted Permission|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId,
            RESOURCE_TYPE_PERMISSION, permissionId]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        http:Response response = check self.httpClient->get(requestPath, headerMap);
        json jsonResponse = check handleResponse(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists permissions belong to a user.
    #
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permissions are granted
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `stream<cosmos_db:Permission, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get Permissions"}
    remote isolated function listPermissions(@display {label: "Database ID"} string databaseId,
                                             @display {label: "User ID"} string userId,
                                             @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                             resourceReadOptions = ()) returns
                                             @tainted @display {label: "Stream of Permissions"}
                                             stream<Permission, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId,
            RESOURCE_TYPE_PERMISSION]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        PermissionStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Permission, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes a permission belongs to a user.
    #
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permission is granted
    # + permissionId - ID of the permission to delete
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
    @display {label: "Delete Permission"}
    remote isolated function deletePermission(@display {label: "Database ID"} string databaseId,
                                              @display {label: "User ID"} string userId,
                                              @display {label: "Permission ID"} string permissionId,
                                              @display {label: " Optional Header Parameters"} ResourceDeleteOptions?
                                              resourceDeleteOptions = ()) returns @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId,
            RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response);
    }

    # Replaces an existing offer.
    #
    # + offer - A record `cosmos_db:Offer`
    # + return - If successful, returns a `cosmos_db:Offer`. Else returns `cosmos_db:Error`.
    @display {label: "Replace Offer"}
    remote isolated function replaceOffer(@display {label: "Offer ID"} Offer offer) returns @tainted Offer|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offer.id]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json jsonPaylod = {
            offerVersion: offer.offerVersion,
            content: offer.content,
            offerType: offer.offerType,
            'resource: offer.resourceSelfLink,
            offerResourceId: offer.resourceResourceId,
            id: offer.id,
            _rid: offer?.resourceId
        };
        request.setJsonPayload(jsonPaylod);

        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Gets information about an offer.
    #
    # + offerId - The ID of the offer
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `cosmos_db:Offer`. Else returns `cosmos_db:Error`.
    @display {label: "Get Offer"}
    remote isolated function getOffer(@display {label: "Offer ID"} string offerId,
                                      @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                      resourceReadOptions = ()) returns @tainted Offer|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offerId]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        http:Response response = check self.httpClient->get(requestPath, headerMap);
        json jsonResponse = check handleResponse(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Lists information of offers.
    #
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `stream<cosmos_db:Offer, error>` Else returns `cosmos_db:Error`.
    @display {label: "Get Offers"}
    remote isolated function listOffers(@display {label: " Optional Header Parameters"} ResourceReadOptions?
                                        resourceReadOptions = ()) returns @tainted @display {label: "Stream of Offers"}
                                        stream<Offer, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        OfferStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Offer, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Performs queries on offer resources.
    #
    # + sqlQuery - A string value containing SQL query
    # + resourceQueryOptions - The `cosmos_db:ResourceQueryOptions` which can be used to add additional capabilities to 
    #                          the request
    # + return - If successful, returns a `stream<cosmos_db:Offer, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Query Offers"}
    remote isolated function queryOffer(@display {label: "SQL Query"} string sqlQuery,
                                        @display {label: "Optional Header Parameters"} ResourceQueryOptions?
                                        resourceQueryOptions = ()) returns
                                        @tainted @display {label: "Stream of Query Results"}
                                        stream<Offer, error?>|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        setOptionalHeaders(request, resourceQueryOptions);

        request.setJsonPayload({query: sqlQuery});
        check setHeadersForQuery(request);

        OfferQueryResultStream objectInstance = check new (self.httpClient, requestPath, request);
        stream<Offer, error?> finalStream = new (objectInstance);
        return finalStream;
    }
}
