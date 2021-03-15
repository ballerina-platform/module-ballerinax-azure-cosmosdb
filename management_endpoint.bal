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

# Azure Cosmos DB Client Object for management operations.
# 
# + httpClient - the HTTP Client
public client class ManagementClient {
    private http:Client httpClient;
    private string baseUrl;
    private string primaryKeyOrResourceToken;
    private string host;

    public function init(Configuration azureConfig) returns error? {
        self.baseUrl = azureConfig.baseUrl;
        self.primaryKeyOrResourceToken = azureConfig.primaryKeyOrResourceToken;
        self.host = getHost(azureConfig.baseUrl);
        self.httpClient = check new(self.baseUrl);
    }

    # Create a database.
    # 
    # + databaseId - ID of the new database. Must be a unique value.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns `Database`. Else returns `Error`.
    remote function createDatabase(string databaseId, (int|record{|int maxThroughput;|})? throughputOption = ()) 
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
        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        // Return the json payload from the response 
        json jsonResponse = check handleResponse(response);
        // Map the reponse payload and the headers to a record type
        return mapJsonToDatabaseType(jsonResponse);
    }

    # Create a database only if the specified database ID does not exist already.
    # 
    # + databaseId - ID of the new database. Must be a unique value.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns `Database` or `nil` if database already exists. Else returns `Error`.
    remote function createDatabaseIfNotExist(string databaseId, 
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

    # Get information of a given database.
    # 
    # + databaseId - ID of the database 
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns `Database`. Else returns `Error`.
    remote function getDatabase(string databaseId, *ResourceReadOptions resourceReadOptions) returns 
                                @tainted Database|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDatabaseType(jsonResponse);
    }

    # List information of all databases.
    # 
    # + maxItemCount - Optional. Maximum number of `Database` records in one returning page.
    # + return - If successful, returns `stream<Database>`. else returns `Error`. 
    remote function listDatabases(int? maxItemCount = ()) returns @tainted stream<Database>|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);

        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Database[] initialArray = [];
        return <stream<Database>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Delete a given database.
    # 
    # + databaseId - ID of the database to delete
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    remote function deleteDatabase(string databaseId, *ResourceDeleteOptions resourceDeleteOptions) returns 
                                   @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Create a container inside the given database.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the new container. Must be a unique value.
    # + partitionKey - A record of type `PartitionKey`
    # + indexingPolicy - Optional. A record of type `IndexingPolicy`.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns `Container`. Else returns `Error`.
    remote function createContainer(string databaseId, string containerId, PartitionKey partitionKey, 
                                    IndexingPolicy? indexingPolicy = (), 
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
        request.setJsonPayload(<@untainted>jsonPayload);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Create a container only if the specified container ID does not exist already.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the new container
    # + partitionKey - A record of type `PartitionKey`
    # + indexingPolicy - Optional. A record of type `IndexingPolicy`.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns `Container` if a new container is created or `nil` if container already exists. 
    #            Else returns `Error`.
    remote function createContainerIfNotExist(string databaseId, string containerId, PartitionKey partitionKey, 
                                              IndexingPolicy? indexingPolicy = (), 
                                              (int|record{|int maxThroughput;|})? throughputOption = ()) returns 
                                              @tainted Container?|Error { 
        var result = self->createContainer(databaseId, containerId, partitionKey, indexingPolicy, throughputOption);
        if (result is error<HttpDetail>) {
            if (result.detail().status == http:STATUS_CONFLICT) {
                return;
            }
        }
        return result;
    }

    # Get information about a container.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns `Container`. Else returns `Error`.
    remote function getContainer(string databaseId, string containerId, *ResourceReadOptions resourceReadOptions) 
                                 returns @tainted Container|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # List information of all containers.
    # 
    # + databaseId - ID of the database to which the containers belongs to
    # + maxItemCount - Optional. Maximum number of container records in one returning page.
    # + return - If successful, returns `stream<Container>`. Else returns `Error`.
    remote function listContainers(string databaseId, int? maxItemCount = ()) returns @tainted stream<Container>|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Container[] initialArray = [];
        return <stream<Container>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Delete a container.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container to delete
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    remote function deleteContainer(string databaseId, string containerId, 
                                    *ResourceDeleteOptions resourceDeleteOptions) returns 
                                    @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Retrieve a list of partition key ranges for the container.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where the partition key ranges are related to
    # + return - If successful, returns `stream<PartitionKeyRange>`. Else returns `Error`.
    remote function listPartitionKeyRanges(string databaseId, string containerId) returns 
                                           @tainted stream<PartitionKeyRange>|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_PK_RANGES]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);

        PartitionKeyRange[] initialArray = [];
        return <stream<PartitionKeyRange>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Create a new user defined function. A user defined function is a side effect free piece of application logic 
    # written in JavaScript. 
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, user defined function is created
    # + userDefinedFunctionId - A unique ID for the newly created user defined function
    # + userDefinedFunction - A JavaScript function represented as a string
    # + return - If successful, returns a `UserDefinedFunction`. Else returns `Error`. 
    remote function createUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionId, 
                                              string userDefinedFunction) returns @tainted UserDefinedFunction|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);

        json payload = {
            id: userDefinedFunctionId,
            body: userDefinedFunction
        };
        request.setJsonPayload(payload); 

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserDefinedFunction(jsonResponse);
    }

    # Replace an existing user defined function.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing user defined function
    # + userDefinedFunctionId - The ID of the user defined function to replace
    # + userDefinedFunction - A JavaScript function represented as a string
    # + return - If successful, returns a `UserDefinedFunction`. Else returns `Error`. 
    remote function replaceUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionId, 
                                               string userDefinedFunction) returns @tainted UserDefinedFunction|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_UDF, userDefinedFunctionId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: userDefinedFunctionId,
            body: userDefinedFunction
        };
        request.setJsonPayload(<@untainted>payload); 

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserDefinedFunction(jsonResponse); 
    }

    # Get a list of existing user defined functions.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the user defined functions
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `stream<UserDefinedFunction>`. Else returns `Error`. 
    remote function listUserDefinedFunctions(string databaseId, string containerId, 
                                            *ResourceReadOptions resourceReadOptions) returns 
                                             @tainted stream<UserDefinedFunction>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (resourceReadOptions?.maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, resourceReadOptions?.maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        UserDefinedFunction[] initialArray = [];
        return <stream<UserDefinedFunction>> check retrieveStream(self.httpClient, requestPath, request, initialArray); 
    }

    # Delete an existing user defined function.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the user defined function
    # + userDefinedFunctionid - Id of UDF to delete
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    remote function deleteUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionid, 
                                              *ResourceDeleteOptions resourceDeleteOptions) returns 
                                              @tainted DeleteResponse|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_UDF, userDefinedFunctionid]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Create a trigger. Triggers are pieces of application logic that can be executed before (pre-triggers) and 
    # after (post-triggers) creation, deletion, and replacement of a document. Triggers are written in JavaScript.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where trigger is created
    # + triggerId - A unique ID for the newly created trigger
    # + trigger - A JavaScript function represented as a string
    # + triggerOperation - The specific operation in which trigger will be executed can be `All`, `Create`, `Replace` or 
    #                      `Delete`
    # + triggerType - The instance in which trigger will be executed `Pre` or `Post`
    # + return - If successful, returns a `Trigger`. Else returns `Error`. 
    remote function createTrigger(string databaseId, string containerId, string triggerId, string trigger, 
                                  TriggerOperation triggerOperation, TriggerType triggerType) returns 
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
        
        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToTrigger(jsonResponse);
    }

    # Replace an existing trigger.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the trigger
    # + triggerId - The ID of the trigger to be replaced
    # + trigger - A JavaScript function represented as a string
    # + triggerOperation - The specific operation in which trigger will be executed
    # + triggerType - The instance in which trigger will be executed `Pre` or `Post`
    # + return - If successful, returns a `Trigger`. Else returns `Error`. 
    remote function replaceTrigger(string databaseId, string containerId, string triggerId, string trigger, 
                                   TriggerOperation triggerOperation, TriggerType triggerType) returns 
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
        request.setJsonPayload(<@untainted>payload);
        
        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToTrigger(jsonResponse);
    }

    # List existing triggers.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the triggers
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to therequest
    # + return - If successful, returns a `stream<Trigger>`. Else returns `Error`. 
    remote function listTriggers(string databaseId, string containerId, *ResourceReadOptions resourceReadOptions) 
                                 returns @tainted stream<Trigger>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (resourceReadOptions?.maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, resourceReadOptions?.maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        Trigger[] initialArray = [];
        return <stream<Trigger>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Delete an existing trigger.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the trigger
    # + triggerId - ID of the trigger to be deleted
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    remote function deleteTrigger(string databaseId, string containerId, string triggerId, 
                                  *ResourceDeleteOptions resourceDeleteOptions) returns 
                                  @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_TRIGGER, triggerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Create a user for a given database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of the new user. Must be a unique value.
    # + return - If successful, returns a `User`. Else returns `Error`.
    remote function createUser(string databaseId, string userId) returns @tainted User|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);

        json reqBody = {id: userId};
        request.setJsonPayload(reqBody);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        return mapJsonToUserType(check handleResponse(response));
    }

    # Replace the ID of an existing user.
    # 
    # + databaseId - ID of the database to which, the existing user belongs to
    # + userId - Old ID of the user
    # + newUserId - New ID for the user
    # + return - If successful, returns a `User`. Else returns `Error`.
    remote function replaceUserId(string databaseId, string userId, string newUserId) returns @tainted User|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json reqBody = {id: newUserId};
        request.setJsonPayload(reqBody);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Get information of a user.
    # 
    # + databaseId - ID of the database to which, the user belongs to
    # + userId - ID of user
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `User`. Else returns `Error`.
    remote function getUser(string databaseId, string userId, *ResourceReadOptions resourceReadOptions) returns 
                            @tainted User|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToUserType(jsonResponse);
    }

    # List users of a specific database.
    # 
    # + databaseId - ID of the database to which, the user belongs to
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `stream<User>`. Else returns `Error`.
    remote function listUsers(string databaseId, *ResourceReadOptions resourceReadOptions) 
                              returns @tainted stream<User>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (resourceReadOptions?.maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, resourceReadOptions?.maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        User[] initialArray = [];
        return <stream<User>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Delete a user.
    # 
    # + databaseId - ID of the database to which, the user belongs to
    # + userId - ID of the user to delete
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional 
    #                           capabilities to the request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    remote function deleteUser(string databaseId, string userId, *ResourceDeleteOptions resourceDeleteOptions) 
                               returns @tainted DeleteResponse|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Create a permission for a user. 
    # 
    # + databaseId - ID of the database to which, the user belongs to
    # + userId - ID of user to which, the permission is granted. Must be a unique value.
    # + permissionId - A unique ID for the newly created permission
    # + permissionMode - The mode to which the permission is scoped
    # + resourcePath - The resource this permission is allowing the user to access
    # + validityPeriodInSeconds - Optional. Validity period of the permission in seconds.
    # + return - If successful, returns a `Permission`. Else returns `Error`.
    remote function createPermission(string databaseId, string userId, string permissionId, 
                                     PermisssionMode permissionMode, string resourcePath, 
                                     int? validityPeriodInSeconds = ()) returns @tainted Permission|Error {
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

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Replace an existing permission.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permission is granted
    # + permissionId - The ID of the permission to be replaced
    # + permissionMode - The mode to which the permission is scoped
    # + resourcePath - The resource this permission is allowing the user to access
    # + validityPeriodInSeconds - Optional. Validity period of the permission in seconds.
    # + return - If successful, returns a `Permission`. Else returns `Error`.
    remote function replacePermission(string databaseId, string userId, string permissionId, 
                                      PermisssionMode permissionMode, string resourcePath, 
                                      int? validityPeriodInSeconds = ()) returns @tainted Permission|Error { 
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
        request.setJsonPayload(<@untainted>jsonPayload);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToPermissionType(jsonResponse); 
    }

    # Get information of a permission.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permission is granted
    # + permissionId - ID of the permission
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `Permission`. Else returns `Error`.
    remote function getPermission(string databaseId, string userId, string permissionId, 
                                  *ResourceReadOptions resourceReadOptions) returns @tainted Permission|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
            RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # List permissions belong to a user.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permissions are granted
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `stream<Permission>`. Else returns `Error`.
    remote function listPermissions(string databaseId, string userId, *ResourceReadOptions resourceReadOptions) returns 
                                    @tainted stream<Permission>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
            RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (resourceReadOptions?.maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, resourceReadOptions?.maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        Permission[] initialArray = [];
        return <stream<Permission>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Deletes a permission belongs to a user.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to which, the permission is granted
    # + permissionId - ID of the permission to delete
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    remote function deletePermission(string databaseId, string userId, string permissionId, 
                                     *ResourceDeleteOptions resourceDeleteOptions) returns 
                                     @tainted DeleteResponse|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
            RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Replace an existing offer.
    # 
    # + offer - A record of type `Offer`
    # + return - If successful, returns a `Offer`. Else returns `Error`.
    remote function replaceOffer(Offer offer) returns @tainted Offer|Error {
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

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToOfferType(jsonResponse); 
    }

    # Get information about an offer.
    # 
    # + offerId - The ID of the offer
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `Offer`. Else returns `Error`.
    remote function getOffer(string offerId, *ResourceReadOptions resourceReadOptions) returns 
                             @tainted Offer|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offerId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # List information of offers. Each Azure Cosmos DB collection is provisioned with an associated performance level 
    # represented as an offer resource in the REST model. Azure Cosmos DB supports offers representing both user-defined
    # performance levels and pre-defined performance levels. 
    # 
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `stream<Offer>` Else returns `Error`.
    remote function listOffers(*ResourceReadOptions resourceReadOptions) returns 
                               @tainted stream<Offer>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, requestPath);
        if (resourceReadOptions?.maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, resourceReadOptions?.maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        Offer[] initialArray = [];
        return <stream<Offer>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Perform queries on offer resources.
    # 
    # + sqlQuery - A string value containing SQL query
    # + resourceQueryOptions - The `ResourceQueryOptions` which can be used to add additional capabilities to the 
    #                          request
    # + return - If successful, returns a `stream<json>`. Else returns `Error`.
    remote function queryOffer(string sqlQuery, *ResourceQueryOptions resourceQueryOptions) 
                               returns @tainted stream<json>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        setOptionalHeaders(request, resourceQueryOptions);
        if (resourceQueryOptions?.maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, resourceQueryOptions?.maxItemCount.toString());
        }

        request.setJsonPayload({query: sqlQuery});
        check setHeadersForQuery(request);

        return <stream<json>> check getQueryResults(self.httpClient, requestPath, request);
    }
}
