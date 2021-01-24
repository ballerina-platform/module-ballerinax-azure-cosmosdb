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
# + httpClient - the HTTP Client
public client class CoreClient {
    private http:Client httpClient;
    private string baseUrl;
    private string masterOrResourceToken;
    private string host;
    private string tokenType;
    private string tokenVersion;

    public function init(AzureCosmosConfiguration azureConfig) {
        self.baseUrl = azureConfig.baseUrl;
        self.masterOrResourceToken = azureConfig.masterOrResourceToken;
        self.host = getHost(azureConfig.baseUrl);
        self.tokenType = getTokenType(azureConfig.masterOrResourceToken);
        self.tokenVersion = TOKEN_VERSION;
        self.httpClient = new (self.baseUrl);
    }

    # Create a database inside an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the new database. Must be unique.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function createDatabase(string databaseId, (int|json)? throughputOption = ()) 
                                    returns @tainted Database|error {
        // Creating a new request
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);
        // Setting mandatory headers for the request
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);
        // Setting optional headers
        check setThroughputOrAutopilotHeader(request, throughputOption);

        // Setting a request payload
        json jsonPayload = {id: databaseId};
        request.setJsonPayload(jsonPayload);

        // Get the response
        var response = self.httpClient->post(requestPath, request);
        // Map the payload and headers, of the request to a tuple 
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        // Map the reponse payload and the headers to a record type
        return mapJsonToDatabaseType(jsonResponse);
    }

    # Create a database inside an Azure Cosmos DB account only if the specified database ID does not exist already.
    # 
    # + databaseId - ID of the new database.
    # + throughputOption - Optional. Throughput parameter of type int OR json.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function createDatabaseIfNotExist(string databaseId, (int|json)? throughputOption = ()) returns @tainted 
                                    Database?|error {
        var result = self->getDatabase(databaseId);
        if (result is error) {
            string status = result.detail()[STATUS].toString();
            if (status == STATUS_NOT_FOUND_STRING) {
                return self->createDatabase(databaseId, throughputOption);
            }
        }
    }

    # Retrive information of a given database in an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the database to retrieve information. 
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function getDatabase(string databaseId, ResourceReadOptions? requestOptions = ()) 
                                    returns @tainted Database|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        var response = self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonResponse);
    }

    # List information of all databases in an Azure Cosmos DB account.
    # 
    # + maxItemCount - Optional. Maximum number of Databases in the returning stream.
    # + return - If successful, returns stream<cosmosdb:Database>. else returns error. 
    remote function listDatabases(int? maxItemCount = ()) returns @tainted stream<Database>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        Database[] newArray = [];
        stream<Database>|error databaseStream = <stream<Database>|error>retriveStream(self.httpClient, requestPath, 
        request, newArray, maxItemCount);
        return databaseStream;
    }

    # Delete a given database in an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the database to delete.
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteDatabase(string databaseId, ResourceDeleteOptions? requestOptions = ()) 
                                    returns @tainted boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);

    }

    # Create a container in the given database.
    # 
    # + databaseId - ID of the database the container belongs to.
    # + containerId - ID of the new container container.
    # + partitionKey - A cosmosdb:PartitionKey.
    # + indexingPolicy - Optional. A cosmosdb:IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Container. Else returns error.  
    remote function createContainer(string databaseId, string containerId, PartitionKey partitionKey, 
                                    IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) returns @tainted Container|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, 
                                        RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);
        check setThroughputOrAutopilotHeader(request, throughputOption);

        json jsonPayload = {
            id: containerId,
            partitionKey: {
                paths: <json>partitionKey.paths.cloneWithType(json),
                kind: partitionKey.kind,
                Version: partitionKey?.keyVersion
            }
        };
        if (indexingPolicy != ()) {
            jsonPayload = check jsonPayload.mergeJson({indexingPolicy: <json>indexingPolicy.cloneWithType(json)});
        }
        request.setJsonPayload(<@untainted>jsonPayload);

        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Create a container in the database only if the specified container ID does not exist already.
    # 
    # + databaseId - ID of the database the container belongs to.
    # + containerId - ID of the new container.    
    # + partitionKey - A cosmosdb:PartitionKey.
    # + indexingPolicy - Optional. A cosmosdb:IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns Container if a new container is created or () if container already exists. Else returns error.  
    remote function createContainerIfNotExist(string databaseId, string containerId, PartitionKey partitionKey, 
                                    IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) returns @tainted Container?|error { 
        var result = self->getContainer(databaseId, containerId);
        if result is error {
            string status = result.detail()[STATUS].toString();
            if (status == STATUS_NOT_FOUND_STRING) {
                return self->createContainer(databaseId, containerId, partitionKey, indexingPolicy, throughputOption);
            }
        }
    }

    # Retrive information about a container in a database.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container to retrive infromation.  
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns cosmosdb:Container. Else returns error.  
    remote function getContainer(string databaseId, string containerId, ResourceReadOptions? requestOptions = ()) returns @tainted 
                                    Container|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        var response = self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # List information of all containers in a database
    # 
    # + databaseId - ID of the database where the containers belong to.
    # + maxItemCount - Optional. Maximum number of Containers to in the returning stream.
    # + return - If successful, returns stream<cosmosdb:Container>. Else returns error.  
    remote function listContainers(string databaseId, int? maxItemCount = ()) returns @tainted stream<Container>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Container[] newArray = [];
        stream<Container>|error containerStream = <stream<Container>|error>retriveStream(self.httpClient, requestPath, 
        request, newArray, maxItemCount);
        return containerStream;
    }

    # Delete a given container in a database.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container to delete.
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteContainer(string databaseId, string containerId, ResourceDeleteOptions? requestOptions = ()) 
                                    returns @tainted boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);
    }

    # Create a Document inside a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.
    # + document - A cosmosdb:Document which includes the ID and the document to save in the database. 
    # + requestOptions - Optional. The DocumentCreateOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns Document. Else returns error.  
    remote function createDocument(string databaseId, string containerId, Document document, any[] partitionKey,
                                    DocumentCreateOptions? requestOptions = ()) returns @tainted Document|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);
        setPartitionKeyHeader(request, partitionKey);

        json jsonPayload = {id: document.id};
        jsonPayload = check jsonPayload.mergeJson(document.documentBody);
        request.setJsonPayload(jsonPayload);

        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # Replace a document inside a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.
    # + document - A cosmosdb:Document which includes the ID and the new document to replace the existing one. 
    # + requestOptions - Optional. The DocumentCreateOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a cosmosdb:Document. Else returns error. 
    remote function replaceDocument(string databaseId, string containerId, @tainted Document document, any[] partitionKey, 
                                    DocumentReplaceOptions? requestOptions = ()) returns @tainted Document|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_DOCUMENTS, document.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);
        setPartitionKeyHeader(request, partitionKey);

        json jsonPayload = {id: document.id};
        jsonPayload = check jsonPayload.mergeJson(document.documentBody);
        request.setJsonPayload(<@untainted>jsonPayload);

        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # Get information about one document in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.
    # + documentId - Id of the document to retrieve. 
    # + partitionKey - Array containing the value of parition key field of the container.
    # + requestOptions - Optional. Object of type DocumentGetOptions.
    # + return - If successful, returns Document. Else returns error.  
    remote function getDocument(string databaseId, string containerId, string documentId, any[] partitionKey, 
                                    DocumentGetOptions? requestOptions = ()) returns @tainted Document|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        setPartitionKeyHeader(request, partitionKey);

        var response = self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # List information of all the documents in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which documents belongs to.
    # + maxItemCount - Optional. Maximum number of documents in the returning stream.
    # + requestOptions - Optional. The DocumentListOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns stream<Document> Else, returns error. 
    remote function getDocumentList(string databaseId, string containerId, int? maxItemCount = (), 
                                    DocumentListOptions? requestOptions = ()) returns @tainted stream<Document>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Document[] newArray = [];
        stream<Document>|error documentStream = <stream<Document>|error>retriveStream(self.httpClient, requestPath, 
        request, newArray, maxItemCount);
        return documentStream;
    }

    # Delete a document in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.    
    # + documentId - ID of the document to delete. 
    # + partitionKey - Array containing the value of parition key  of the container.
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteDocument(string databaseId, string containerId, string documentId, any[] partitionKey, 
                                    ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);
        setPartitionKeyHeader(request, partitionKey);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);
    }

    # Query a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container to query.     
    # + sqlQuery - A cosmosdb:Query containing the SQL query and parameters.
    # + partitionKey - Optional. An array containing the value of the partition key specified for the document.
    # + maxItemCount - Optional. Maximum number of results in the returning stream.
    # + requestOptions - Optional. The ResourceQueryOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<cosmosdb:Document>. Else returns error.
    remote function queryDocuments(string databaseId, string containerId, string sqlQuery, QueryParameter[] parameters = [], int? maxItemCount = (), 
                                    any[]? partitionKey = (), ResourceQueryOptions? requestOptions = ()) returns @tainted stream<json>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);
        setPartitionKeyHeader(request, partitionKey);

        json payload = {
            query: sqlQuery,
            parameters: checkpanic parameters.cloneWithType(json)
        };
        request.setJsonPayload(<@untainted>payload);

        setHeadersForQuery(request);
        stream<json>|error documentStream = <stream<json>|error>getQueryResults(self.httpClient, requestPath, request, [], maxItemCount, ());
        return documentStream;
    }

    # Create a new stored procedure inside a container.
    # 
    # A stored procedure is a piece of application logic written in JavaScript that is registered and executed against a 
    # collection as a single transaction.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which stored procedure will be created.     
    # + storedProcedure - A cosmosdb:StoredProcedure.
    # + return - If successful, returns a cosmosdb:StoredProcedure. Else returns error. 
    remote function createStoredProcedure(string databaseId, string containerId, StoredProcedure storedProcedure) returns @tainted 
                                    StoredProcedure|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_STORED_POCEDURES]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);

        json payload = checkpanic storedProcedure.cloneWithType(json);
        request.setJsonPayload(<@untainted>payload);
        
        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureType(jsonResponse);
    }

    # Replace a stored procedure in a container with new one.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which existing stored procedure belongs to. 
    # + storedProcedure - A cosmosdb:StoredProcedure which replaces the existing one.
    # + return - If successful, returns a cosmosdb:StoredProcedure. Else returns error. 
    remote function replaceStoredProcedure(string databaseId, string containerId, @tainted StoredProcedure storedProcedure) 
                                    returns @tainted StoredProcedure|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_STORED_POCEDURES, storedProcedure.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);

        json payload = checkpanic storedProcedure.cloneWithType(json);
        request.setJsonPayload(<@untainted>payload);
        
        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureType(jsonResponse);
    }

    # List information of all stored procedures in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which contain the stored procedures.    
    # + maxItemCount - Optional. Maximum number of results in the returning stream.
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<cosmosdb:StoredProcedure>. Else returns error. 
    remote function listStoredProcedures(string databaseId, string containerId, int? maxItemCount = (), 
                                    ResourceReadOptions? requestOptions = ()) returns @tainted stream<StoredProcedure>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_STORED_POCEDURES]);
        
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        StoredProcedure[] newArray = [];
        stream<StoredProcedure>|error storedProcedureStream = <stream<StoredProcedure>|error>retriveStream(self.httpClient, 
        requestPath, request, newArray, maxItemCount);
        return storedProcedureStream;
    }

    # Delete a stored procedure in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which contain the stored procedure.     
    # + storedProcedureId - ID of the stored procedure to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                                    ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);
    }

    # Execute a stored procedure in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which contain the stored procedure.        
    # + storedProcedureId - ID of the stored procedure to execute.
    # + options - Optional. A record of type StoredProcedureOptions to specify the additional parameters.
    # + return - If successful, returns json with the output from the executed funxtion. Else returns error. 
    remote function executeStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                                    StoredProcedureOptions? options = ()) returns @tainted json|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);
        setPartitionKeyHeader(request, options?.valueOfPartitionKey);

        request.setTextPayload(options?.parameters.toString());

        var response = self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return jsonResponse;
    }

    # Create a new user defined function inside a collection.
    # 
    # A user-defined function (UDF) is a side effect free piece of application logic written in JavaScript. 
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which user defined will be created.  
    # + userDefinedFunction - A cosmosdb:UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    remote function createUserDefinedFunction(string databaseId, string containerId, UserDefinedFunction userDefinedFunction) 
                                    returns @tainted UserDefinedFunction|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);

        json|error payload = userDefinedFunction.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }

        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionType(jsonResponse);
    }

    # Replace an existing user defined function in a collection.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container in which user defined function is created.    
    # + userDefinedFunction - A cosmosdb:UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    remote function replaceUserDefinedFunction(string databaseId, string containerId, @tainted UserDefinedFunction userDefinedFunction) 
                                    returns @tainted UserDefinedFunction|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_UDF, userDefinedFunction.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);

        json|error payload = userDefinedFunction.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }

        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionType(jsonResponse);
    }

    # Get a list of existing user defined functions inside a collection.
    # 
    # + databaseId - ID of the database which user belongs to.
    # + containerId - ID of the container which user defined functions belongs to.    
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<UserDefinedFunction>. Else returns error. 
    remote function listUserDefinedFunctions(string databaseId, string containerId, int? maxItemCount = (), 
                                    ResourceReadOptions? requestOptions = ()) returns @tainted stream<UserDefinedFunction>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        UserDefinedFunction[] newArray = [];
        stream<UserDefinedFunction>|error userDefinedFunctionStream = <stream<UserDefinedFunction>|error>retriveStream(
        self.httpClient, requestPath, request, newArray, maxItemCount);
        return userDefinedFunctionStream;
    }

    # Delete an existing user defined function inside a collection.
    # 
    # + databaseId - ID of the database which container is created.
    # + containerId - ID of the container which user defined function is created.    
    # + userDefinedFunctionid - Id of UDF to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionid, 
                                    ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_UDF, userDefinedFunctionid]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);
    }

    # Create a trigger inside a collection.
    # 
    # Triggers are pieces of application logic that can be executed before (pre-triggers) and after (post-triggers) 
    # creation, deletion, and replacement of a document. Triggers are written in JavaScript.
    #  
    # + databaseId - ID of the database where container is created.
    # + containerId - ID of the container where trigger is created.    
    # + trigger - A cosmosdb:Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    remote function createTrigger(string databaseId, string containerId, Trigger trigger) returns @tainted Trigger|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);

        json|error payload = trigger.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }

        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerType(jsonResponse);
    }

    # Replace an existing trigger inside a collection.
    # 
    # + databaseId - ID of the database where container is created.
    # + containerId - ID of the container where trigger is created.     
    # + trigger - A cosmosdb:Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    remote function replaceTrigger(string databaseId, string containerId, @tainted Trigger trigger) returns @tainted 
                                    Trigger|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_TRIGGER, trigger.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);

        json|error payload = trigger.cloneWithType(json);
        if (payload is json) {
            request.setJsonPayload(<@untainted>payload);
        } else {
            return prepareError(PAYLOAD_IS_NOT_JSON_ERROR);
        }

        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerType(jsonResponse);
    }

    # List existing triggers inside a collection.
    # 
    # + databaseId - ID of the database where the container is created.
    # + containerId - ID of the container where the triggers are created.     
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<Trigger>. Else returns error. 
    remote function listTriggers(string databaseId, string containerId, int? maxItemCount = (), 
                                    ResourceReadOptions? requestOptions = ()) returns @tainted stream<Trigger>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Trigger[] newArray = [];
        stream<Trigger>|error triggerStream = <stream<Trigger>|error>retriveStream(self.httpClient, requestPath, request, 
        newArray, maxItemCount);
        return triggerStream;
    }

    # Delete an existing trigger inside a collection.
    # 
    # + databaseId - ID of the database where the container is created.
    # + containerId - ID of the container where the trigger is created. 
    # + triggerId - ID of the trigger to be deleted.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteTrigger(string databaseId, string containerId, string triggerId, 
                                    ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_TRIGGER, triggerId]);        
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response); 
    }

// ------------------------------------------MANAGEMENT PLANE-----------------------------------------------------------
    # Retrieve a list of partition key ranges for the container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container where the partition key ranges are related to.    
    # + return - If successful, returns stream<cosmosdb:PartitionKeyRange>. Else returns error.  
    remote function listPartitionKeyRanges(string databaseId, string containerId) returns @tainted 
                                    stream<PartitionKeyRange>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                                        RESOURCE_TYPE_PK_RANGES]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        PartitionKeyRange[] newArray = [];
        stream<PartitionKeyRange>|error partitionKeyStream = <stream<PartitionKeyRange>|error>retriveStream(self.
        httpClient, requestPath, request, newArray);
        return partitionKeyStream;
    }

    # Create a user in a database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of the new user.
    # + return - If successful, returns a User. Else returns error.
    remote function createUser(string databaseId, string userId) returns @tainted User|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);

        json reqBody = {id: userId};
        request.setJsonPayload(reqBody);

        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Replace the id of an existing user for a database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - Old ID of the user.
    # + newUserId - New ID for the user.
    # + return - If successful, returns a User. Else returns error.
    remote function replaceUserId(string databaseId, string userId, string newUserId) returns @tainted User|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);

        json reqBody = {id: newUserId};
        request.setJsonPayload(reqBody);

        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);
    }

    # To get information of a user from a database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user to get.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a User. Else returns error.
    remote function getUser(string databaseId, string userId, ResourceReadOptions? requestOptions = ()) returns @tainted 
                                    User|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        var response = self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Lists users in a database account.
    # 
    # + databaseId - ID of the database where users is created.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<User>. Else returns error.
    remote function listUsers(string databaseId, int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) 
                                    returns @tainted stream<User>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        User[] newArray = [];
        stream<User>|error userStream = <stream<User>|error>retriveStream(self.httpClient, requestPath, request, 
        newArray, maxItemCount);
        return userStream;
    }

    # Delete a user from a database account.
    # 
    # + databaseId - ID of the database where user is created.
    # + userId - ID of user to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteUser(string databaseId, string userId, ResourceDeleteOptions? requestOptions = ()) 
                                    returns @tainted boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);
    }

    # Create a permission for a user. 
    # 
    # + databaseId - ID of the database where user is created.
    # + userId - ID of user to which the permission belongs.
    # + permission - A cosmosdb:Permission.
    # + validityPeriod - Optional. Validity period of the permission.
    # + return - If successful, returns a Permission. Else returns error.
    remote function createPermission(string databaseId, string userId, Permission permission, int? validityPeriod = ()) 
                                    returns @tainted Permission|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                                        RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);
        if (validityPeriod is int) {
            setExpiryHeader(request, validityPeriod);
        }

        json jsonPayload = {
            id: permission.id,
            permissionMode: permission.permissionMode,
            'resource: permission.resourcePath
        };
        request.setJsonPayload(jsonPayload);

        var response = self.httpClient->post(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Replace an existing permission.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user where the the permission is created.
    # + permission - A cosmosdb:Permission.
    # + validityPeriod - Optional. Validity period of the permission
    # + return - If successful, returns a Permission. Else returns error.
    remote function replacePermission(string databaseId, string userId, @tainted Permission permission, 
                                    int? validityPeriod = ()) returns @tainted Permission|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                                        RESOURCE_TYPE_PERMISSION, permission.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);
        if (validityPeriod is int) {
            setExpiryHeader(request, validityPeriod);
        }

        json jsonPayload = {
            id: permission.id,
            permissionMode: permission.permissionMode,
            'resource: permission.resourcePath
        };
        request.setJsonPayload(<@untainted>jsonPayload);

        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # To get information of a permission belongs to a user.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user where the the permission belongs to.
    # + permissionId - ID of the permission to get information.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a Permission. Else returns error.
    remote function getPermission(string databaseId, string userId, string permissionId, ResourceReadOptions? requestOptions = ()) 
                                    returns @tainted Permission|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                                        RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        var response = self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists permissions belong to a user.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user where the the permissions is created.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<Permission>. Else returns error.
    remote function listPermissions(string databaseId, string userId, int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) 
                                    returns @tainted stream<Permission>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                                        RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Permission[] newArray = [];
        stream<Permission>|error permissionStream = <stream<Permission>|error>retriveStream(self.httpClient, requestPath, 
        request, newArray, maxItemCount);
        return permissionStream;
    }

    # Deletes a permission belongs to a user.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user which the permission belongs to.
    # + permissionId - ID of the permission to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deletePermission(string databaseId, string userId, string permissionId, ResourceDeleteOptions? requestOptions = ()) 
                                    returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                                        RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        var response = self.httpClient->delete(requestPath, request);
        return <boolean>check handleResponse(response);
    }

    # Replace an existing offer.
    # 
    # + offer - A cosmosdb:Offer.
    # + offerType - Optional. Type of the offer.
    # + return - If successful, returns a Offer. Else returns error.
    remote function replaceOffer(Offer offer, string? offerType = ()) returns @tainted Offer|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offer.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, PUT, requestPath);

        json jsonPaylod = {
            offerVersion: offer.offerVersion,
            content: offer.content,
            'resource: offer.resourceSelfLink,
            offerResourceId: offer.resourceResourceId,
            id: offer.id,
            _rid: offer?.resourceId
        };
        if (offerType is string && offer.offerVersion == OFFER_VERSION_1) {
            json selectedType = {offerType: offerType};
            jsonPaylod = check jsonPaylod.mergeJson(selectedType);
        }
        request.setJsonPayload(jsonPaylod);

        var response = self.httpClient->put(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Get information about an offer.
    # 
    # + offerId - The ID of the offer.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a Offer. Else returns error.
    remote function getOffer(string offerId, ResourceReadOptions? requestOptions = ()) returns @tainted Offer|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);

        var response = self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Gets information of offers inside database account.
    # 
    # Each Azure Cosmos DB collection is provisioned with an associated performance level represented as an 
    # Offer resource in the REST model. Azure Cosmos DB supports offers representing both user-defined performance 
    # levels and pre-defined performance levels. 
    # 
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<Offer> Else returns error.
    remote function listOffers(int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) returns @tainted 
                                    stream<Offer>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Offer[] newArray = [];
        stream<Offer>|error offerStream = <stream<Offer>|error>retriveStream(self.httpClient, requestPath, request, 
        newArray, maxItemCount);
        return offerStream;
    }

    # Perform queries on Offer resources.
    # 
    # + sqlQuery - SQL query.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceQueryOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<Offer>. Else returns error.
    remote function queryOffer(Query sqlQuery, int? maxItemCount = (), ResourceQueryOptions? requestOptions = ()) 
                                    returns @tainted stream<Offer>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, POST, requestPath);

        request.setJsonPayload(<json>sqlQuery.cloneWithType(json));
        setHeadersForQuery(request);

        Offer[] newArray = [];
        stream<Offer>|error offerStream = <stream<Offer>|error>retriveStream(self.httpClient, requestPath, request, 
        newArray, maxItemCount, (), true);
        return offerStream;
    }
}
