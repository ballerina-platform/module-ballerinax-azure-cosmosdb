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

# Azure Cosmos DB Client Object for data plane operations.
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
        self.baseUrl = checkpanic validateBaseUrl(azureConfig.baseUrl);
        self.masterOrResourceToken = azureConfig.masterOrResourceToken;
        self.host = getHost(azureConfig.baseUrl);
        self.tokenType = getTokenType(azureConfig.masterOrResourceToken);
        self.tokenVersion = TOKEN_VERSION;
        self.httpClient = new (self.baseUrl);
    }

    # Retrive information of a given database in an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the database to retrieve information. 
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function getDatabase(string databaseId, ResourceReadOptions? requestOptions = ()) returns @tainted 
            Database|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
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

        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Database[] newArray = [];
        stream<Database> databaseStream = <stream<Database>> check retriveStream(self.httpClient, requestPath, request, 
                newArray, maxItemCount);
        return databaseStream;
    }

    # Retrive information about a container in a database.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container to retrive infromation.  
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns cosmosdb:Container. Else returns error.  
    remote function getContainer(string databaseId, string containerId, ResourceReadOptions? requestOptions = ()) 
            returns @tainted Container|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
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
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Container[] newArray = [];
        stream<Container> containerStream = <stream<Container>> check retriveStream(self.httpClient, requestPath, request, 
                newArray, maxItemCount);
        return containerStream;
    }

    # Create a Document inside a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.
    # + newDocument - A cosmosdb:Document which includes the ID and the document to save in the database. 
    # + requestOptions - Optional. The DocumentCreateOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns Document. Else returns error.  
    remote function createDocument(string databaseId, string containerId, Document newDocument, any valueOfPartitionKey, 
            DocumentCreateOptions? requestOptions = ()) returns @tainted CreationResult|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, valueOfPartitionKey);

        json jsonPayload = {id: newDocument.id};
        jsonPayload = check jsonPayload.mergeJson(newDocument.documentBody);
        request.setJsonPayload(jsonPayload);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Replace a document inside a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.
    # + newDocument - A cosmosdb:Document which includes the ID and the new document to replace the existing one. 
    # + requestOptions - Optional. The DocumentCreateOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns a cosmosdb:Document. Else returns error. 
    remote function replaceDocument(string databaseId, string containerId, @tainted Document newDocument, any valueOfPartitionKey, 
            DocumentReplaceOptions? requestOptions = ()) returns @tainted CreationResult|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS, newDocument.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_PUT, requestPath);
        setPartitionKeyHeader(request, valueOfPartitionKey);

        json jsonPayload = {id: newDocument.id};
        jsonPayload = check jsonPayload.mergeJson(newDocument.documentBody); 
        request.setJsonPayload(<@untainted>jsonPayload);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Get information about one document in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.
    # + documentId - Id of the document to retrieve. 
    # + valueOfPartitionKey - Array containing the value of parition key field of the container.
    # + requestOptions - Optional. Object of type DocumentGetOptions.
    # + return - If successful, returns Document. Else returns error.  
    remote function getDocument(string databaseId, string containerId, string documentId, any valueOfPartitionKey, 
            DocumentGetOptions? requestOptions = ()) returns @tainted Document|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        setPartitionKeyHeader(request, valueOfPartitionKey);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
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
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Document[] newArray = [];
        stream<Document> documentStream = <stream<Document>> check retriveStream(self.httpClient, requestPath, request, 
                newArray, maxItemCount);
        return documentStream;
    }

    # Delete a document in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which document belongs to.    
    # + documentId - ID of the document to delete. 
    # + valueOfPartitionKey - Array containing the value of parition key  of the container.
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteDocument(string databaseId, string containerId, string documentId, any valueOfPartitionKey, 
            ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_DELETE, requestPath);
        setPartitionKeyHeader(request, valueOfPartitionKey);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }
    }

    # Query a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container to query.     
    # + sqlQuery - A cosmosdb:Query containing the SQL query and parameters.
    # + valueOfPartitionKey - Optional. An array containing the value of the partition key specified for the document.
    # + maxItemCount - Optional. Maximum number of results in the returning stream.
    # + requestOptions - Optional. The ResourceQueryOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns a stream<cosmosdb:Document>. Else returns error.
    remote function queryDocuments(string databaseId, string containerId, string sqlQuery, QueryParameter[] parameters = [],
            int? maxItemCount = (), any? valueOfPartitionKey = (), ResourceQueryOptions? requestOptions = ()) returns 
            @tainted stream<json>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, valueOfPartitionKey);

        json payload = {
            query: sqlQuery,
            parameters: check parameters.cloneWithType(json)
        };
        request.setJsonPayload(<@untainted>payload);

        setHeadersForQuery(request);
        stream<json> documentStream = <stream<json>> check getQueryResults(self.httpClient, requestPath, request, [], maxItemCount, ());
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
    remote function createStoredProcedure(string databaseId, string containerId, StoredProcedure storedProcedure) 
            returns @tainted CreationResult|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_STORED_POCEDURES]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_POST, requestPath);

        json payload = {
            id: storedProcedure.id,
            body: storedProcedure.storedProcedure
        };
        request.setJsonPayload(payload); 

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Replace a stored procedure in a container with new one.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which existing stored procedure belongs to. 
    # + storedProcedure - A cosmosdb:StoredProcedure which replaces the existing one.
    # + return - If successful, returns a cosmosdb:StoredProcedure. Else returns error. 
    remote function replaceStoredProcedure(string databaseId, string containerId, @tainted StoredProcedure storedProcedure) 
            returns @tainted CreationResult|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_STORED_POCEDURES, storedProcedure.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_PUT, requestPath);

        json payload = {
            id: storedProcedure.id,
            body: storedProcedure.storedProcedure
        };
        request.setJsonPayload(<@untainted>payload);    

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
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
        
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        StoredProcedure[] newArray = [];
        stream<StoredProcedure> storedProcedureStream = <stream<StoredProcedure>> check retriveStream(self.httpClient, 
                requestPath, request, newArray, maxItemCount);
        return storedProcedureStream;
    }

    # Delete a stored procedure in a container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container which contain the stored procedure.     
    # + storedProcedureId - ID of the stored procedure to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities 
    #       to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
            ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_DELETE, requestPath);
        
        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }
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
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, options?.valueOfPartitionKey);

        request.setTextPayload(options?.parameters.toString());

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
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
            returns @tainted CreationResult|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_POST, requestPath);
                
        json payload = {
            id: userDefinedFunction.id,
            body: userDefinedFunction.userDefinedFunction
        };
        request.setJsonPayload(payload); 

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Replace an existing user defined function in a collection.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container in which user defined function is created.    
    # + userDefinedFunction - A cosmosdb:UserDefinedFunction.
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    remote function replaceUserDefinedFunction(string databaseId, string containerId, @tainted UserDefinedFunction userDefinedFunction) 
            returns @tainted CreationResult|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF, userDefinedFunction.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_PUT, requestPath);

        json payload = {
            id: userDefinedFunction.id,
            body: userDefinedFunction.userDefinedFunction
        };
        request.setJsonPayload(<@untainted>payload); 

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Get a list of existing user defined functions inside a collection.
    # 
    # + databaseId - ID of the database which user belongs to.
    # + containerId - ID of the container which user defined functions belongs to.    
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<UserDefinedFunction>. Else returns error. 
    remote function listUserDefinedFunctions(string databaseId, string containerId, int? maxItemCount = (), 
            ResourceReadOptions? requestOptions = ()) returns @tainted stream<UserDefinedFunction>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        UserDefinedFunction[] newArray = [];
        stream<UserDefinedFunction> userDefinedFunctionStream = <stream<UserDefinedFunction>> check retriveStream(
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
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_DELETE, requestPath);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }
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
    remote function createTrigger(string databaseId, string containerId, Trigger trigger) returns @tainted 
            CreationResult|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_POST, requestPath);

        json payload = {
            id: trigger.id,
            body: trigger.triggerFunction,
            triggerOperation: trigger.triggerOperation,
            triggerType: trigger.triggerType
        };
        request.setJsonPayload(payload); 
        
        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Replace an existing trigger inside a collection.
    # 
    # + databaseId - ID of the database where container is created.
    # + containerId - ID of the container where trigger is created.     
    # + trigger - A cosmosdb:Trigger.
    # + return - If successful, returns a Trigger. Else returns error. 
    remote function replaceTrigger(string databaseId, string containerId, @tainted Trigger trigger) returns @tainted 
            CreationResult|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER, trigger.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_PUT, requestPath);

        json payload = {
            id: trigger.id,
            body: trigger.triggerFunction,
            triggerOperation: trigger.triggerOperation,
            triggerType: trigger.triggerType
        };
        request.setJsonPayload(<@untainted>payload);
        
        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # List existing triggers inside a collection.
    # 
    # + databaseId - ID of the database where the container is created.
    # + containerId - ID of the container where the triggers are created.     
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<Trigger>. Else returns error. 
    remote function listTriggers(string databaseId, string containerId, int? maxItemCount = (), 
            ResourceReadOptions? requestOptions = ()) returns @tainted stream<Trigger>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Trigger[] newArray = [];
        stream<Trigger> triggerStream = <stream<Trigger>> check retriveStream(self.httpClient, requestPath, request, 
                newArray, maxItemCount);
        return triggerStream;
    }

    # Delete an existing trigger inside a collection.
    # 
    # + databaseId - ID of the database where the container is created.
    # + containerId - ID of the container where the trigger is created. 
    # + triggerId - ID of the trigger to be deleted.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities 
    #       to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteTrigger(string databaseId, string containerId, string triggerId, 
            ResourceDeleteOptions? requestOptions = ()) returns @tainted boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER, triggerId]);        
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, self.tokenType, self.tokenVersion, 
                http:HTTP_DELETE, requestPath);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }
    }
}
