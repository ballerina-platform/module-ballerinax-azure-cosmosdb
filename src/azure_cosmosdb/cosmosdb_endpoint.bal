// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Azure Cosmos DB Client Object.
# 
# + azureCosmosClient - the HTTP Client
public  client class Client {
    private http:Client azureCosmosClient;
    private string baseUrl;
    private string keyOrResourceToken;
    private string host;
    private string keyType;
    private string tokenVersion;

    function init(AzureCosmosConfiguration azureConfig) {
        self.baseUrl = azureConfig.baseUrl;
        self.keyOrResourceToken = azureConfig.keyOrResourceToken;
        self.host = azureConfig.host;
        self.keyType = azureConfig.tokenType;
        self.tokenVersion = azureConfig.tokenVersion;
        http:ClientConfiguration httpClientConfig = {secureSocket: azureConfig.secureSocketConfig};
        self.azureCosmosClient = new (self.baseUrl, httpClientConfig);
    }

    # Create a database inside a resource.
    # 
    # + databaseId - Id for the database
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' or 
    # 'x-ms-cosmos-offer-autopilot-settings' headers.
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabase(string databaseId, ThroughputProperties? throughputProperties = ()) returns 
    @tainted Database | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        json jsonPayload = {
            id:databaseId
        };
        request.setJsonPayload(jsonPayload);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setThroughputOrAutopilotHeader(request, throughputProperties);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonResponse);   
    }

    # Create a database inside a resource.
    # 
    # + databaseId - Id for the database.
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' or 
    # 'x-ms-cosmos-offer-autopilot-settings' headers.
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabaseIfNotExist(string databaseId, ThroughputProperties? throughputProperties = ()) 
    returns @tainted Database? | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        var result = self->getDatabase(databaseId);
        if (result is error) {
            string status = result.detail()[STATUS].toString();
            if (status == STATUS_NOT_FOUND_STRING) {
                return self->createDatabase(databaseId, throughputProperties);
            } else {
                return prepareError(AZURE_ERROR + string `${result.message()}`);
            }
        }
        return ();  
    }

    # Retrive a given database inside a resource.
    # 
    # + databaseId - Id of the database. 
    # + return - If successful, returns Database. Else returns error.  
    public remote function getDatabase(string databaseId) returns @tainted Database | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId]);
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToDatabaseType(jsonResponse);  
    }

    # List all databases inside a resource.
    # 
    # + maxItemCount - The maximum number of elements to retrieve.
    # + return - If successful, returns stream<Database>. else returns error. 
    public remote function listDatabases(int? maxItemCount = ()) returns @tainted stream<Database> | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        Database[] newArray = [];
        stream<Database> | error databaseStream = <stream<Database> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return databaseStream;
    }

    # Delete a given database inside a resource.
    # 
    # + databaseId - Id of the database to retrieve.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteDatabase(string databaseId) returns @tainted boolean | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId]);
        return self.deleteRecord(requestPath);
    }

    # Create a collection inside a database.
    # 
    # + properties - Object of type ResourceProperties.
    # + partitionKey - Required Object of type PartitionKey.
    # + indexingPolicy - Optional Object of type IndexingPolicy.
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header. 
    # + return - If successful, returns Container. Else returns error.  
    public remote function createContainer(@tainted ResourceProperties properties, PartitionKey partitionKey, 
    IndexingPolicy? indexingPolicy = (), ThroughputProperties? throughputProperties = ()) returns @tainted Container | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        json jsonPayload = {
            id: properties.containerId, 
            partitionKey: {
                paths: <json>partitionKey.paths.cloneWithType(json), 
                kind : partitionKey.kind, 
                Version: partitionKey?.keyVersion
            }
        };
        if (indexingPolicy != ()) {
            jsonPayload = check jsonPayload.mergeJson({indexingPolicy: <json>indexingPolicy.cloneWithType(json)});
        }
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setThroughputOrAutopilotHeader(request, throughputProperties);
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Create a database inside a resource.
    # 
    # + properties - Object of type ResourceProperties.
    # + partitionKey - Object of type PartitionKey.
    # + indexingPolicy - Optional Object of type IndexingPolicy.
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header. 
    # + return - If successful, returns Database. Else returns error.  
    public remote function createContainerIfNotExist(@tainted ResourceProperties properties, PartitionKey partitionKey, 
    IndexingPolicy? indexingPolicy = (), ThroughputProperties? throughputProperties = ()) returns @tainted Container? | error {
        var result = self->getContainer(properties);
        if result is error {
            string status = result.detail()[STATUS].toString();
            if (status == STATUS_NOT_FOUND_STRING) {
                return self->createContainer(properties, partitionKey);
            } else {
                return prepareError(AZURE_ERROR + string `${result.message()}`);
            }
        }
        return ();
    }

    # Retrive one collection inside a database.
    # 
    # + properties - Object of type ResourceProperties.
    # + return - If successful, returns Container. Else returns error.  
    public remote function getContainer(@tainted ResourceProperties properties) returns @tainted Container | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId]);
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToContainerType(jsonResponse);
    }
    
    # List all collections inside a database
    # 
    # + databaseId - Id of the database where the collections are in.
    # + maxItemCount - The maximum number of elements to retrieve.
    # + return - If successful, returns stream<Container>. Else returns error.  
    public remote function listContainers(string databaseId, int? maxItemCount = ()) returns @tainted stream<Container> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        Container[] newArray = [];
        stream<Container> | error containerStream = <stream<Container> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return containerStream;
    }

    # Delete one collection inside a database.
    # 
    # + properties - Object of type ResourceProperties.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteContainer(@tainted ResourceProperties properties) returns @tainted json | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId]);
        return self.deleteRecord(requestPath);
    }

    # Retrieve a list of partition key ranges for the collection.
    # 
    # + properties - Id of the database which collection is in.
    # + return - If successful, returns PartitionKeyList. Else returns error.  
    public remote function getPartitionKeyRanges(@tainted ResourceProperties properties) returns @tainted 
    PartitionKeyList | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_PK_RANGES]);
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToPartitionKeyListType(jsonResponse);
    }

    # Create a Document inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + document - Object of type Document. 
    # + requestOptions - Object of type RequestHeaderOptions.
    # + return - If successful, returns Document. Else returns error.  
    public remote function createDocument(@tainted ResourceProperties properties, Document document, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted Document | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, document.partitionKey);
        if (requestOptions is RequestHeaderOptions) {
            request = check setRequestOptions(request, requestOptions);
        }
        json jsonPayload = {
            id: document.id
        };  
        jsonPayload = check jsonPayload.mergeJson(document.documentBody);     
        request.setJsonPayload(jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # Replace a document inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + document - Object of type Document. 
    # + requestOptions - Object of type RequestHeaderOptions.
    # + return - If successful, returns a Document. Else returns error. 
    public remote function replaceDocument(@tainted ResourceProperties properties, @tainted Document document, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted Document | error {         
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS, document.id]);
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, document.partitionKey);
        if (requestOptions is RequestHeaderOptions) {
            request = check setRequestOptions(request, requestOptions);
        }
        json jsonPayload = {
            id: document.id
        };  
        jsonPayload = check jsonPayload.mergeJson(document.documentBody); 
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # List one document inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + documentId - Id of the document. 
    # + partitionKey - Array containing value of parition key field.
    # + requestOptions - Object of type RequestHeaderOptions.
    # + return - If successful, returns Document. Else returns error.  
    public remote function getDocument(@tainted ResourceProperties properties, string documentId, any[] partitionKey, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted Document | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS, documentId]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, partitionKey);
        if requestOptions is RequestHeaderOptions {
            request = check setRequestOptions(request, requestOptions);
        }
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # List all the documents inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + requestOptions - Object of type RequestHeaderOptions.
    # + maxItemCount - Maximum number of elements to retrieve.
    # + return - If successful, returns stream<Document> Else, returns error. 
    public remote function getDocumentList(@tainted ResourceProperties properties, RequestHeaderOptions? requestOptions = (), 
    int? maxItemCount = ()) returns @tainted stream<Document> | error { 
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if requestOptions is RequestHeaderOptions {
            request = check setRequestOptions(request, requestOptions);
        }
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        Document[] newArray = [];
        stream<Document> | error documentStream =  <stream<Document> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return documentStream; 
    }

    # Delete a document inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + documentId - Id of the document. 
    # + partitionKey - Array containing value of parition key field.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteDocument(@tainted ResourceProperties properties, string documentId, any[] partitionKey) 
    returns @tainted boolean | error {  
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS, documentId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, partitionKey);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Query documents inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + sqlQuery - Json Object of type Query containing the SQL query.
    # + requestOptions - Object of type RequestOptions.
    # + partitionKey - The value provided for the partition key specified in the document.
    # + return - If successful, returns a stream<json>. Else returns error. 
    public remote function queryDocuments(@tainted ResourceProperties properties, any[] partitionKey, Query sqlQuery, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted stream<json> | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, partitionKey);
        request.setPayload(<json>sqlQuery.cloneWithType(json));
        request = check setHeadersForQuery(request);
        var response = self.azureCosmosClient->post(requestPath, request);
        stream<json> jsonResponse = check mapResponseToJsonStream(response);
        return jsonResponse;
    }

    # Create a new stored procedure inside a collection.
    # 
    # A stored procedure is a piece of application logic written in JavaScript that 
    # is registered and executed against a collection as a single transaction.
    # + properties - Object of type ResourceProperties.
    # + storedProcedure - Object of type StoredProcedure.
    # + return - If successful, returns a StoredProcedure. Else returns error. 
    public remote function createStoredProcedure(@tainted ResourceProperties properties, StoredProcedure storedProcedure) 
    returns @tainted StoredProcedure | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<json>storedProcedure.cloneWithType(json));
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureType(jsonResponse);    
    }

    # Replace a stored procedure with new one inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + storedProcedure - Object of type StoredProcedure.
    # + return - If successful, returns a StoredProcedure. Else returns error. 
    public remote function replaceStoredProcedure(@tainted ResourceProperties properties, @tainted StoredProcedure 
    storedProcedure) returns @tainted StoredProcedure | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedure.id]);
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<@untainted><json>storedProcedure.cloneWithType(json));
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureType(jsonResponse);  
    }

    # List all stored procedures inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + maxItemCount - Maximum number of elements to retrieve.
    # + return - If successful, returns a stream<StoredProcedure>. Else returns error. 
    public remote function listStoredProcedures(@tainted ResourceProperties properties, int? maxItemCount = ()) returns 
    @tainted stream<StoredProcedure> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        StoredProcedure[] newArray = [];
        stream<StoredProcedure> | error storedProcedureStream =  <stream<StoredProcedure> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return storedProcedureStream;        
    }

    # Delete a stored procedure inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + storedProcedureId - Id of the stored procedure to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteStoredProcedure(@tainted ResourceProperties properties, string storedProcedureId) returns 
    @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedureId]);        
        return self.deleteRecord(requestPath);
    }

    # Execute a stored procedure inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + storedProcedureId - Id of the stored procedure to execute.
    # + parameters - The list of function paramaters to pass to javascript function as an array.
    # + return - If successful, returns json with the output from the executed funxtion. Else returns error. 
    public remote function executeStoredProcedure(@tainted ResourceProperties properties, string storedProcedureId, 
    any[]? parameters) returns @tainted json | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedureId]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setTextPayload(parameters.toString());
        var response = self.azureCosmosClient->post(requestPath, request);
        json jsonResponse = check mapResponseToJson(response);
        return jsonResponse;   
    }

    # Create a new user defined function inside a collection.
    # 
    # A user-defined function (UDF) is a side effect free piece of application logic written in JavaScript. 
    # + properties - Object of type ResourceProperties.
    # + userDefinedFunction - Object of type UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    public remote function createUserDefinedFunction(@tainted ResourceProperties properties, 
    UserDefinedFunction userDefinedFunction) returns @tainted UserDefinedFunction | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_UDF]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<json>userDefinedFunction.cloneWithType(json));
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionType(jsonResponse);      
    }

    # Replace an existing user defined function inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + userDefinedFunction - Object of type UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    public remote function replaceUserDefinedFunction(@tainted ResourceProperties properties, 
    @tainted UserDefinedFunction userDefinedFunction) returns @tainted UserDefinedFunction | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_UDF, userDefinedFunction.id]);      
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<@untainted><json>userDefinedFunction.cloneWithType(json));
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionType(jsonResponse);      
    }

    # Get a list of existing user defined functions inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + maxItemCount - Maximum number of elements to retrieve.
    # + return - If successful, returns a stream<UserDefinedFunction>. Else returns error. 
    public remote function listUserDefinedFunctions(@tainted ResourceProperties properties, int? maxItemCount = ()) returns 
    @tainted stream<UserDefinedFunction> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_UDF]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        UserDefinedFunction[] newArray = [];
        stream<UserDefinedFunction> | error userDefinedFunctionStream =  <stream<UserDefinedFunction> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return userDefinedFunctionStream;   
    }

    # Delete an existing user defined function inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + userDefinedFunctionid - Id of UDF to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteUserDefinedFunction(@tainted ResourceProperties properties, string userDefinedFunctionid) 
    returns @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_UDF, userDefinedFunctionid]);        
        return self.deleteRecord(requestPath);
    }

    # Create a trigger inside a collection.
    # 
    # Triggers are pieces of application logic that can be executed before (pre-triggers) and after (post-triggers) 
    # creation, deletion, and replacement of a document. Triggers are written in JavaScript. 
    # + properties - Object of type ResourceProperties.
    # + trigger - Object of type Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    public remote function createTrigger(@tainted ResourceProperties properties, Trigger trigger) returns @tainted 
    Trigger | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_TRIGGER]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<json>trigger.cloneWithType(json));
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerType(jsonResponse);      
    }
    
    # Replace an existing trigger inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + trigger - Object of type Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    public remote function replaceTrigger(@tainted ResourceProperties properties, @tainted Trigger trigger) returns 
    @tainted Trigger | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_TRIGGER, trigger.id]);       
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<@untainted><json>trigger.cloneWithType(json));
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerType(jsonResponse); 
    }

    # List existing triggers inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + maxItemCount - Maximum number of elements to retrieve.
    # + return - If successful, returns a stream<Trigger>. Else returns error. 
    public remote function listTriggers(@tainted ResourceProperties properties, int? maxItemCount = ()) returns @tainted 
    stream<Trigger> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_TRIGGER]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        } 
        Trigger[] newArray = [];
        stream<Trigger> | error triggerStream =  <stream<Trigger> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return triggerStream;       
    }

    # Delete an existing trigger inside a collection.
    # 
    # + properties - Object of type ResourceProperties.
    # + triggerId - Id of the trigger to be deleted.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteTrigger(@tainted ResourceProperties properties, string triggerId) returns @tainted 
    boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_TRIGGER, triggerId]);       
        return self.deleteRecord(requestPath);
    }

    # Create a user in a database.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id which should be given to the new user.
    # + return - If successful, returns a User. Else returns error.
    public remote function createUser(@tainted ResourceProperties properties, string userId) returns @tainted User | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        json reqBody = {
            id:userId
        };
        request.setJsonPayload(reqBody);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);     
    }
    
    # Replace the id of an existing user for a database.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id which should be given to the new user.
    # + newUserId - The new id for the user.
    # + return - If successful, returns a User. Else returns error.
    public remote function replaceUserId(@tainted ResourceProperties properties, string userId, string newUserId) returns 
    @tainted User | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId]);       
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        json reqBody = {
            id:newUserId
        };
        request.setJsonPayload(reqBody);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse); 
    }

    # To get information of a user from a database.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to get information.
    # + return - If successful, returns a User. Else returns error.
    public remote function getUser(@tainted ResourceProperties properties, string userId) returns @tainted User | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId]);
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToUserType(jsonResponse);      
    }

    # Lists users in a database account.
    # 
    # + properties - Object of type ResourceProperties.
    # + maxItemCount - The maximum number of elements to retrieve.
    # + return - If successful, returns a stream<User>. Else returns error.
    public remote function listUsers(@tainted ResourceProperties properties, int? maxItemCount = ()) returns @tainted stream<User> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }  
        User[] newArray = [];
        stream<User> | error userStream = <stream<User> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return userStream;    
    }

    # Delete a user from a database account.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteUser(@tainted ResourceProperties properties, string userId) returns @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId]);       
        return self.deleteRecord(requestPath);
    }

    # Create a permission for a user. 
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to which the permission belongs.
    # + permission - Object of type Permission.
    # + validityPeriod - Optional validity period parameter which specify  time to live.
    # + return - If successful, returns a Permission. Else returns error.
    public remote function createPermission(@tainted ResourceProperties properties, string userId, Permission permission, 
    int? validityPeriod = ()) returns @tainted Permission | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (validityPeriod is int) {
            request = check setExpiryHeader(request, validityPeriod);
        }
        json jsonPayload = {
            id : permission.id, 
            permissionMode : permission.permissionMode, 
            'resource: permission.resourcePath
        };
        request.setJsonPayload(jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Replace an existing permission.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to which the permission belongs.
    # + permission - Object of type Permission.
    # + validityPeriod - Optional validity period parameter which specify  time to live.
    # + return - If successful, returns a Permission. Else returns error.
    public remote function replacePermission(@tainted ResourceProperties properties, string userId, @tainted 
    Permission permission, int? validityPeriod = ()) returns @tainted Permission | error {
        http:Request request = new;
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permission.id]);       
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (validityPeriod is int) {
            request = check setExpiryHeader(request, validityPeriod);
        }
        json jsonPayload = {
            id : permission.id, 
            permissionMode : permission.permissionMode, 
            'resource: permission.resourcePath
        };
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # To get information of a permission belongs to a user.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to the permission belongs.
    # + permissionId - Object of type Permission.
    # + return - If successful, returns a Permission. Else returns error.
    public remote function getPermission(@tainted ResourceProperties properties, string userId, string permissionId)
    returns @tainted Permission | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permissionId]);       
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists permissions belong to a user.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to the permissions belong.
    # + maxItemCount - The maximum number of elements to retrieve.
    # + return - If successful, returns a stream<Permission>. Else returns error.
    public remote function listPermissions(@tainted ResourceProperties properties, string userId, int? maxItemCount = ()) 
    returns @tainted stream<Permission> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION]);       
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        Permission[] newArray = [];
        stream<Permission> | error permissionStream = <stream<Permission> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return permissionStream;
    }

    # Deletes a permission belongs to a user.
    # 
    # + properties - Object of type ResourceProperties.
    # + userId - The id of user to the permission belongs.
    # + permissionId - Id of the permission to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deletePermission(@tainted ResourceProperties properties, string userId, string permissionId) 
    returns @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permissionId]);       
        return self.deleteRecord(requestPath);
    }

    # Replace an existing offer.
    # 
    # + offer - Object of type Offer.
    # + offerType - Type of the offer.
    # + return - If successful, returns a Offer. Else returns error.
    public remote function replaceOffer(Offer offer, string? offerType = ()) returns @tainted Offer | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_OFFER, offer.id]);       
        HeaderParameters header = mapOfferHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        json jsonPaylod = {
            offerVersion: offer.offerVersion, 
            content: offer.content, 
            'resource: offer.resourceSelfLink, 
            offerResourceId: offer.offerResourceId, 
            id: offer.id, 
            _rid: offer?.resourceId
        };
        if (offerType is string && offer.offerVersion == OFFER_VERSION_1) {
            json selectedType = {
                offerType: offerType
            };
            jsonPaylod = check jsonPaylod.mergeJson(selectedType);
        }
        request.setJsonPayload(jsonPaylod);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Get information of an offer.
    # 
    # + offerId - The id of the offer.
    # + return - If successful, returns a Offer. Else returns error.
    public remote function getOffer(string offerId) returns @tainted Offer | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_OFFER, offerId]);       
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToOfferType(jsonResponse);
    }

    # Gets information of offers inside database account.
    # 
    # Each Azure Cosmos DB collection is provisioned with an associated performance level represented as an 
    # Offer resource in the REST model. Azure Cosmos DB supports offers representing both user-defined performance 
    # levels and pre-defined performance levels. 
    # + maxItemCount - The maximum number of elements to retrieve.
    # + return - If successful, returns a stream<Offer> | . Else returns error.
    public remote function listOffers(int? maxItemCount = ()) returns @tainted stream<Offer> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_OFFER]);       
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString()); 
        }
        Offer[] newArray = [];
        stream<Offer> | error offerStream = <stream<Offer> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount);
        return offerStream;
    }

    # Perform queries on Offer resources.
    # 
    # + sqlQuery - the SQL query to execute
    # + return - If successful, returns a stream<json>. Else returns error.
    public remote function queryOffer(Query sqlQuery) returns @tainted stream<json> | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_OFFER]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<json>sqlQuery.cloneWithType(json));
        request = check setHeadersForQuery(request);
        var response = self.azureCosmosClient->post(requestPath, request);
        stream<json> jsonResponse = check mapResponseToJsonStream(response);
        return (jsonResponse);
    }

    function getRecord(string requestPath) returns @tainted [json, Headers] | error {
        http:Request request = new;
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return jsonResponse;
    }

    function deleteRecord(string requestPath) returns @tainted boolean | error {
        http:Request request = new;
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

}
