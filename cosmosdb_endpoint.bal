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
        self.host = getHost(azureConfig.baseUrl);
        self.keyType = azureConfig.tokenType;
        self.tokenVersion = azureConfig.tokenVersion;
        http:ClientConfiguration httpClientConfig = {secureSocket: azureConfig.secureSocketConfig};
        self.azureCosmosClient = new (self.baseUrl, httpClientConfig);
    }

    # Create a database inside a resource.
    # 
    # + databaseId - ID for the database.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabase(string databaseId, (int|json)? throughputOption = ()) returns 
                            @tainted Database | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);
        request = check setThroughputOrAutopilotHeader(request, throughputOption);

        json jsonPayload = {
            id:databaseId
        };
        request.setJsonPayload(jsonPayload);
        
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonResponse);   
    }

    # Create a database inside a resource.
    # 
    # + databaseId - ID for the database.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabaseIfNotExist(string databaseId, (int|json)? throughputOption = ()) 
                            returns @tainted Database? | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        var result = self->getDatabase(databaseId);
        if (result is error) {
            string status = result.detail()[STATUS].toString();
            if (status == STATUS_NOT_FOUND_STRING) {
                return self->createDatabase(databaseId, throughputOption);
            } else {
                return prepareError(AZURE_ERROR + string `${result.message()}`);
            }
        }
        return ();  
    }

    # Retrive a given database inside a resource.
    # 
    # + databaseId - ID of the database. 
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
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns stream<Database>. else returns error. 
    public remote function listDatabases(int? maxItemCount = ()) returns @tainted stream<Database> | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }

        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
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
    # + databaseId - ID of the database to delete.
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container.
    # + partitionKey - Object of type PartitionKey.
    # + indexingPolicy - Optional. Object of type IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns Container. Else returns error.  
    public remote function createContainer(string databaseId, string containerId, PartitionKey partitionKey, 
                            IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) 
                            returns @tainted Container | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);
        request = check setThroughputOrAutopilotHeader(request, throughputOption);

        json jsonPayload = {
            id: containerId, 
            partitionKey: {
                paths: <json>partitionKey.paths.cloneWithType(json), 
                kind : partitionKey.kind, 
                Version: partitionKey?.keyVersion
            }
        };
        if (indexingPolicy != ()) {
            jsonPayload = check jsonPayload.mergeJson({indexingPolicy: <json>indexingPolicy.cloneWithType(json)});
        }
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Create a database inside a resource.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container.    
    # + partitionKey - Object of type PartitionKey.
    # + indexingPolicy - Optional. Object of type IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns Database. Else returns error.  
    public remote function createContainerIfNotExist(string databaseId, string containerId, PartitionKey partitionKey, 
                            IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) 
                            returns @tainted Container? | error {
        var result = self->getContainer(databaseId, containerId);
        if result is error {
            string status = result.detail()[STATUS].toString();
            if (status == STATUS_NOT_FOUND_STRING) {
                return self->createContainer(databaseId, containerId, partitionKey, indexingPolicy, throughputOption);
            } else {
                return prepareError(AZURE_ERROR + string `${result.message()}`);
            }
        }
        return ();
    }

    # Retrive one collection inside a database.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container.    
    # + return - If successful, returns Container. Else returns error.  
    public remote function getContainer(string databaseId, string containerId) returns @tainted Container | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId]);
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToContainerType(jsonResponse);
    }
    
    # List all collections inside a database
    # 
    # + databaseId - ID of the database where the collections are in.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns stream<Container>. Else returns error.  
    public remote function listContainers(string databaseId, int? maxItemCount = ()) returns @tainted stream<Container> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteContainer(string databaseId, string containerId) returns @tainted json | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId]);
        return self.deleteRecord(requestPath);
    }

    # Retrieve a list of partition key ranges for the collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container.    
    # + return - If successful, returns PartitionKeyList. Else returns error.  
    public remote function listPartitionKeyRanges(string databaseId, string containerId) returns @tainted stream<PartitionKeyRange> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_PK_RANGES]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
        
        PartitionKeyRange[] newArray = [];
        stream<PartitionKeyRange> | error partitionKeyStream = <stream<PartitionKeyRange> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray);
        return partitionKeyStream;
    }

    # Create a Document inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which document is created.
    # + document - Object of type Document. 
    # + requestOptions - Object of type RequestHeaderOptions.
    # + return - If successful, returns Document. Else returns error.  
    public remote function createDocument(string databaseId, string containerId, Document document, 
                            RequestHeaderOptions? requestOptions = ()) returns @tainted Document | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_DOCUMENTS]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which document is created.
    # + document - Object of type Document. 
    # + requestOptions - Optional. Object of type RequestHeaderOptions.
    # + return - If successful, returns a Document. Else returns error. 
    public remote function replaceDocument(string databaseId, string containerId, @tainted Document document, 
                            RequestHeaderOptions? requestOptions = ()) returns @tainted Document | error {         
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_DOCUMENTS, document.id]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which document is created.
    # + documentId - Id of the document. 
    # + partitionKey - Array containing value of parition key field.
    # + requestOptions - Optional. Object of type RequestHeaderOptions.
    # + return - If successful, returns Document. Else returns error.  
    public remote function getDocument(string databaseId, string containerId, string documentId, any[] partitionKey, 
                            RequestHeaderOptions? requestOptions = ()) returns @tainted Document | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_DOCUMENTS, documentId]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which documents are created.
    # + requestOptions - Object of type RequestHeaderOptions.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns stream<Document> Else, returns error. 
    public remote function getDocumentList(string databaseId, string containerId, RequestHeaderOptions? requestOptions = (), 
                            int? maxItemCount = ()) returns @tainted stream<Document> | error { 
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_DOCUMENTS]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which document is created.    
    # + documentId - ID of the document to delete. 
    # + partitionKey - Array containing value of parition key field.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteDocument(string databaseId, string containerId, string documentId, any[] partitionKey) 
                            returns @tainted boolean | error {  
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_DOCUMENTS, documentId]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, DELETE, requestPath);
        request = check setPartitionKeyHeader(request, partitionKey);

        var response = self.azureCosmosClient->delete(requestPath, request);
        json | boolean  booleanResponse = check handleResponse(response);
        if (booleanResponse is boolean) {
            return booleanResponse;
        } else  {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        } 
    }

    # Query documents inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container to query.     
    # + sqlQuery - Object of type Query containing the SQL query.
    # + requestOptions - Object of type RequestOptions.
    # + partitionKey - Value of the partition key specified for the document.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<Document>. Else returns error. 
    public remote function queryDocuments(string databaseId, string containerId, any[] partitionKey, Query sqlQuery, 
                            RequestHeaderOptions? requestOptions = (), int? maxItemCount = ()) 
                            returns @tainted stream<Document> | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_DOCUMENTS]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);
        request = check setPartitionKeyHeader(request, partitionKey);

        json | error payload = sqlQuery.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }
        request = check setHeadersForQuery(request);
        Document[] newArray = [];
        stream<Document> | error documentStream =  <stream<Document> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount, (), true);
        return documentStream; 
    }

    # Create a new stored procedure inside a collection.
    # 
    # A stored procedure is a piece of application logic written in JavaScript that 
    # is registered and executed against a collection as a single transaction.
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which stored procedure is created.     
    # + storedProcedure - Object of type StoredProcedure.
    # + return - If successful, returns a StoredProcedure. Else returns error. 
    public remote function createStoredProcedure(string databaseId, string containerId, StoredProcedure storedProcedure) 
                            returns @tainted StoredProcedure | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_STORED_POCEDURES]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);

        json | error payload = storedProcedure.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted><json>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureType(jsonResponse);    
    }

    # Replace a stored procedure with new one inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which stored procedure is created. 
    # + storedProcedure - Object of type StoredProcedure.
    # + return - If successful, returns a StoredProcedure. Else returns error. 
    public remote function replaceStoredProcedure(string databaseId, string containerId, 
                            @tainted StoredProcedure storedProcedure) returns @tainted StoredProcedure | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedure.id]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);

        json | error payload = storedProcedure.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureType(jsonResponse);  
    }

    # List all stored procedures inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which contain the stored procedures.    
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<StoredProcedure>. Else returns error. 
    public remote function listStoredProcedures(string databaseId, string containerId, int? maxItemCount = ()) returns 
                            @tainted stream<StoredProcedure> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_STORED_POCEDURES]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
        
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which stored procedure is created.     
    # + storedProcedureId - ID of the stored procedure to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteStoredProcedure(string databaseId, string containerId, string storedProcedureId) returns 
                            @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedureId]);        
        return self.deleteRecord(requestPath);
    }

    # Execute a stored procedure inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which stored procedure is created.     
    # + storedProcedureId - ID of the stored procedure to execute.
    # + parameters - Optional. Array of function paramaters to pass to javascript function as an array.
    # + return - If successful, returns json with the output from the executed funxtion. Else returns error. 
    public remote function executeStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                            any[]? parameters) returns @tainted json | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedureId]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);

        request.setTextPayload(parameters.toString());
        var response = self.azureCosmosClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return jsonResponse;   
    }

    # Create a new user defined function inside a collection.
    # 
    # A user-defined function (UDF) is a side effect free piece of application logic written in JavaScript. 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which user defined function is created.     
    # + userDefinedFunction - Object of type UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    public remote function createUserDefinedFunction(string databaseId, string containerId, 
                            UserDefinedFunction userDefinedFunction) returns @tainted UserDefinedFunction | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_UDF]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);

        json | error payload = userDefinedFunction.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }        
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionType(jsonResponse);      
    }

    # Replace an existing user defined function inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which user defined function is created.    
    # + userDefinedFunction - Object of type UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    public remote function replaceUserDefinedFunction(string databaseId, string containerId, 
                            @tainted UserDefinedFunction userDefinedFunction) returns @tainted UserDefinedFunction | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_UDF, userDefinedFunction.id]);      
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);

        json | error payload = userDefinedFunction.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionType(jsonResponse);      
    }

    # Get a list of existing user defined functions inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which user defined functions are created.    
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<UserDefinedFunction>. Else returns error. 
    public remote function listUserDefinedFunctions(string databaseId, string containerId, int? maxItemCount = ()) returns 
                            @tainted stream<UserDefinedFunction> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_UDF]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
        
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which user defined function is created.    
    # + userDefinedFunctionid - Id of UDF to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionid) 
                            returns @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_UDF, userDefinedFunctionid]);        
        return self.deleteRecord(requestPath);
    }

    # Create a trigger inside a collection.
    # 
    # Triggers are pieces of application logic that can be executed before (pre-triggers) and after (post-triggers) 
    # creation, deletion, and replacement of a document. Triggers are written in JavaScript. 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which trigger is created.    
    # + trigger - Object of type Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    public remote function createTrigger(string databaseId, string containerId, Trigger trigger) returns @tainted 
                            Trigger | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_TRIGGER]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);

        json | error payload = trigger.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }        
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerType(jsonResponse);      
    }
    
    # Replace an existing trigger inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which trigger is created.     
    # + trigger - Object of type Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    public remote function replaceTrigger(string databaseId, string containerId, @tainted Trigger trigger) returns 
                            @tainted Trigger | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_TRIGGER, trigger.id]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);

        json | error payload = trigger.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerType(jsonResponse); 
    }

    # List existing triggers inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which triggers are created.     
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<Trigger>. Else returns error. 
    public remote function listTriggers(string databaseId, string containerId, int? maxItemCount = ()) returns @tainted 
                            stream<Trigger> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_TRIGGER]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
        
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
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which trigger is created. 
    # + triggerId - ID of the trigger to be deleted.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteTrigger(string databaseId, string containerId, string triggerId) returns @tainted 
                            boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS, 
        containerId, RESOURCE_PATH_TRIGGER, triggerId]);       
        return self.deleteRecord(requestPath);
    }

    # Create a user in a database.
    # 
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID which should be given to the new user.
    # + return - If successful, returns a User. Else returns error.
    public remote function createUser(string databaseId, string userId) returns @tainted User | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);

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
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of the user.
    # + newUserId - New ID for the user.
    # + return - If successful, returns a User. Else returns error.
    public remote function replaceUserId(string databaseId, string userId, string newUserId) returns 
                            @tainted User | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);

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
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to get.
    # + return - If successful, returns a User. Else returns error.
    public remote function getUser(string databaseId, string userId) returns @tainted User | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId]);
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToUserType(jsonResponse);      
    }

    # Lists users in a database account.
    # 
    # + databaseId - ID of the database to which users belongs.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<User>. Else returns error.
    public remote function listUsers(string databaseId, int? maxItemCount = ()) returns @tainted stream<User> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
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
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteUser(string databaseId, string userId) returns @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId]);       
        return self.deleteRecord(requestPath);
    }

    # Create a permission for a user. 
    # 
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to which the permission belongs.
    # + permission - Object of type Permission.
    # + validityPeriod - Optional. Validity period of the permission
    # + return - If successful, returns a Permission. Else returns error.
    public remote function createPermission(string databaseId, string userId, Permission permission, 
                            int? validityPeriod = ()) returns @tainted Permission | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }

        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);
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
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to which the permission belongs.
    # + permission - Object of type Permission.
    # + validityPeriod - Optional. Validity period of the permission
    # + return - If successful, returns a Permission. Else returns error.
    public remote function replacePermission(string databaseId, string userId, @tainted 
                            Permission permission, int? validityPeriod = ()) returns @tainted Permission | error {
        if (self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permission.id]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);
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
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to which the permission belongs.
    # + permissionId - ID of the permission to get.
    # + return - If successful, returns a Permission. Else returns error.
    public remote function getPermission(string databaseId, string userId, string permissionId)
                            returns @tainted Permission | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permissionId]);       
        [json, Headers] jsonResponse = check self.getRecord(requestPath);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists permissions belong to a user.
    # 
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to which the permissions belongs.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<Permission>. Else returns error.
    public remote function listPermissions(string databaseId, string userId, int? maxItemCount = ()) 
                            returns @tainted stream<Permission> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
        
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
    # + databaseId - ID of the database to which user belongs.
    # + userId - ID of user to the permission belongs.
    # + permissionId - ID of the permission to delete.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deletePermission(string databaseId, string userId, string permissionId) 
                            returns @tainted boolean | error {
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permissionId]);       
        return self.deleteRecord(requestPath);
    }

    # Replace an existing offer.
    # 
    # + offer - Object of type Offer.
    # + offerType - Optional. Type of the offer.
    # + return - If successful, returns a Offer. Else returns error.
    public remote function replaceOffer(Offer offer, string? offerType = ()) returns @tainted Offer | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_OFFER, offer.id]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, PUT, requestPath);

        json jsonPaylod = {
            offerVersion: offer.offerVersion, 
            content: offer.content, 
            'resource: offer.resourceSelfLink, 
            offerResourceId: offer.resourceResourceId, 
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
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<Offer> Else returns error.
    public remote function listOffers(int? maxItemCount = ()) returns @tainted stream<Offer> | error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_OFFER]);       
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);
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
    # + sqlQuery - SQL query to execute.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + return - If successful, returns a stream<Offer>. Else returns error.
    public remote function queryOffer(Query sqlQuery, int? maxItemCount = ()) returns @tainted stream<Offer> | error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_OFFER]);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, POST, requestPath);

        request.setJsonPayload(<json>sqlQuery.cloneWithType(json));
        request = check setHeadersForQuery(request);
        Offer[] newArray = [];
        stream<Offer> | error offerStream = <stream<Offer> | error>
            retriveStream(self.azureCosmosClient, requestPath, request, newArray, maxItemCount, (), true);
        return offerStream;
    }

    function getRecord(string requestPath) returns @tainted [json, Headers] | error {
        http:Request request = new;
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, GET, requestPath);

        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return jsonResponse;
    }

    function deleteRecord(string requestPath) returns @tainted boolean | error {
        http:Request request = new;
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, DELETE, requestPath);

        var response = self.azureCosmosClient->delete(requestPath, request);
        json | boolean  booleanResponse = check handleResponse(response);
        if (booleanResponse is boolean) {
            return booleanResponse;
        } else  {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }    
    }
}
