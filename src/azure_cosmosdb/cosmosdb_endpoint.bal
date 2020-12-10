import ballerina/http;

# Azure Cosmos DB Client object.
public  client class Client {
    private string baseUrl;
    private string keyOrResourceToken;
    private string host;
    private string keyType;
    private string tokenVersion;
    private http:Client azureCosmosClient;

    function init(AzureCosmosConfiguration azureConfig) {
        self.baseUrl = azureConfig.baseUrl;
        self.keyOrResourceToken = azureConfig.keyOrResourceToken;
        self.host = azureConfig.host;
        self.keyType = azureConfig.tokenType;
        self.tokenVersion = azureConfig.tokenVersion;
        http:ClientConfiguration httpClientConfig = {secureSocket: azureConfig.secureSocketConfig};
        self.azureCosmosClient = new (self.baseUrl, httpClientConfig);
    }

    # To create a database inside a resource
    # + databaseId -  id/name for the database
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' or 
    # 'x-ms-cosmos-offer-autopilot-settings' headers 
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabase(string databaseId, ThroughputProperties? throughputProperties = ()) returns 
    @tainted Database|error {
        if(self.keyType == TOKEN_TYPE_RESOURCE) {
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
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonreponse);   
    }

    # To create a database inside a resource
    # + databaseId -  id/name for the database
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' or 
    # 'x-ms-cosmos-offer-autopilot-settings' headers
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabaseIfNotExist(string databaseId, ThroughputProperties? throughputProperties = ()) 
    returns @tainted Database?|error {
        if(self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        var result = self->getDatabase(databaseId);
        if(result is error) {
            return self->createDatabase(databaseId, throughputProperties);
        }
        return ();  
    }

    # To retrive a given database inside a resource
    # + databaseId -  id/name of the database 
    # + return - If successful, returns Database. Else returns error.  
    public remote function getDatabase(string databaseId) returns @tainted Database|error {
        if(self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonreponse);  
    }


    # List all databases inside a resource
    # + return - If successful, returns DatabaseList. else returns error.  
    public remote function getAllDatabases() returns @tainted DatabaseList|error {
        if self.keyType == TOKEN_TYPE_RESOURCE {
            return prepareError("Enter a valid master key and token type should be master key");
        }
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonresponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseListType(jsonresponse); 
    }

    # Delete a given database inside a resource
    # + databaseId -  id/name of the database to retrieve
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteDatabase(string databaseId) returns @tainted boolean|error {
        if(self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, databaseId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Create a collection inside a database
    # + properties - object of type ResourceProperties
    # + partitionKey - required object of type PartitionKey
    # + indexingPolicy - optional object of type IndexingPolicy
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header 
    # + return - If successful, returns Container. Else returns error.  
    public remote function createContainer(@tainted ResourceProperties properties, PartitionKey partitionKey, 
    IndexingPolicy? indexingPolicy = (), ThroughputProperties? throughputProperties = ()) returns @tainted Container|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        json jsonPayload = {
            "id": properties.containerId, 
            "partitionKey": {
                paths: <json>partitionKey.paths.cloneWithType(json), 
                kind : partitionKey.kind, 
                Version: partitionKey?.keyVersion
            }
        };
        if(indexingPolicy != ()) {
            jsonPayload = check jsonPayload.mergeJson({"indexingPolicy": <json>indexingPolicy.cloneWithType(json)});
        }
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setThroughputOrAutopilotHeader(request, throughputProperties);
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonreponse);
    }

    # Create a database inside a resource
    # + properties -  object of type ResourceProperties
    # + partitionKey - 
    # + indexingPolicy -
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header 
    # + return - If successful, returns Database. Else returns error.  
    public remote function createContainerIfNotExist(@tainted ResourceProperties properties, PartitionKey partitionKey, 
    IndexingPolicy? indexingPolicy = (), ThroughputProperties? throughputProperties = ()) returns @tainted Container?|error {
        var result = self->getContainer(properties);
        if result is error {
            return self->createContainer(properties, partitionKey);
        } else {
            return prepareError("The collection with specific id alrady exist");
        }
    }

    // # To create a collection inside a database
    // # + properties - object of type ContainerProperties
    // # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header 
    // # + return - If successful, returns Container. Else returns error. 
    // public remote function replaceProvisionedThroughput(@tainted ContainerProperties properties, ThroughputProperties 
    // throughputProperties) returns @tainted Container|error {
    //     return self->createContainer(properties, throughputProperties);
    // }

    # List all collections inside a database
    # + databaseId -  id/name of the database where the collections are in.
    # + return - If successful, returns ContainerList. Else returns error.  
    public remote function getAllContainers(string databaseId) returns @tainted ContainerList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToContainerListType(jsonreponse);
    }

    # Retrive one collection inside a database
    # + properties - object of type ResourceProperties
    # + return - If successful, returns Container. Else returns error.  
    public remote function getContainer(@tainted ResourceProperties properties) returns @tainted Container|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonreponse);
    }

    # Delete one collection inside a database
    # + properties - object of type ResourceProperties
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteContainer(@tainted ResourceProperties properties) returns @tainted json|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Retrieve a list of partition key ranges for the collection
    # + properties -  id/name of the database which collection is in.
    # + return - If successful, returns PartitionKeyList. Else returns error.  
    public remote function getPartitionKeyRanges(@tainted ResourceProperties properties) returns @tainted 
    PartitionKeyList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_PK_RANGES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToPartitionKeyListType(jsonreponse);
    }

    # Create a Document inside a collection
    # + properties - object of type ResourceProperties
    # + document - object of type Document 
    # + requestOptions - object of type RequestHeaderOptions
    # + return - If successful, returns Document. Else returns error.  
    public remote function createDocument(@tainted ResourceProperties properties, Document document, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted Document|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, document.partitionKey);
        if(requestOptions is RequestHeaderOptions) {
            request = check setRequestOptions(request, requestOptions);
        }
        json jsonPayload = {
            id: document.id
        };  
        jsonPayload = check jsonPayload.mergeJson(document.documentBody);     
        request.setJsonPayload(jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonreponse);
    }

    # List one document inside a collection
    # + properties - object of type ResourceProperties
    # + documentId - id of  Document, 
    # + partitionKey - array containing value of parition key field.
    # + requestOptions - object of type RequestHeaderOptions
    # + return - If successful, returns Document. Else returns error.  
    public remote function getDocument(@tainted ResourceProperties properties, string documentId, any[] partitionKey, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted Document|error {
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
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonreponse);
    }

    # List all the documents inside a collection
    # + properties - object of type ResourceProperties
    # + requestOptions - object of type RequestHeaderOptions
    # + return - If successful, returns DocumentList. Else returns error. 
    public remote function getDocumentList(@tainted ResourceProperties properties, RequestHeaderOptions? requestOptions = ()) 
    returns @tainted DocumentList|error { 
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if requestOptions is RequestHeaderOptions {
            request = check setRequestOptions(request, requestOptions);
        }
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        DocumentList list =  check mapJsonToDocumentListType(jsonreponse); 
        return list;    
    }

    # Replace a document inside a collection
    # + properties - object of type ResourceProperties
    # + document - object of type Document 
    # + requestOptions - object of type RequestHeaderOptions
    # set x-ms-documentdb-partitionkey header
    # + return - If successful, returns a Document. Else returns error. 
    public remote function replaceDocument(@tainted ResourceProperties properties, @tainted Document document, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted Document|error {         
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS, document.id]);
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, document.partitionKey);
        if(requestOptions is RequestHeaderOptions) {
            request = check setRequestOptions(request, requestOptions);
        }
        json jsonPayload = {
            id: document.id
        };  
        jsonPayload = check jsonPayload.mergeJson(document.documentBody); 
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonreponse);
    }

    # Delete a document inside a collection
    # + properties - object of type ResourceProperties
    # + documentId - id of the Document 
    # + partitionKey - array containing value of parition key field.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteDocument(@tainted ResourceProperties properties, string documentId, any[] partitionKey) 
    returns @tainted boolean|error {  
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS, documentId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, partitionKey);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Query documents inside a collection
    # + properties - object of type ResourceProperties
    # + sqlQuery - json object of type Query containing the CQL query
    # + requestOptions - object of type RequestOptions
    # + partitionKey - the value provided for the partition key specified in the document
    # + return - If successful, returns a json. Else returns error. 
    public remote function queryDocuments(@tainted ResourceProperties properties, any[] partitionKey, Query sqlQuery, 
    RequestHeaderOptions? requestOptions = ()) returns @tainted stream<json>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_DOCUMENTS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request = check setPartitionKeyHeader(request, partitionKey);
        request.setPayload(<json>sqlQuery.cloneWithType(json));
        request = check setHeadersForQuery(request);
        var response = self.azureCosmosClient->post(requestPath, request);
        stream<json> jsonresponse = check mapResponseToJsonStream(response);
        return jsonresponse;
    }

    # Create a new stored procedure inside a collection
    # A stored procedure is a piece of application logic written in JavaScript that 
    # is registered and executed against a collection as a single transaction.
    # + properties - object of type ResourceProperties
    # + storedProcedure - object of type StoredProcedure
    # + return - If successful, returns a StoredProcedure. Else returns error. 
    public remote function createStoredProcedure(@tainted ResourceProperties properties, StoredProcedure 
    storedProcedure) returns @tainted StoredProcedure|error {
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

    # Replace a stored procedure with new one inside a collection
    # + properties - object of type ResourceProperties
    # + storedProcedure - object of type StoredProcedure
    # + return - If successful, returns a StoredProcedure. Else returns error. 
    public remote function replaceStoredProcedure(@tainted ResourceProperties properties, @tainted StoredProcedure 
    storedProcedure) returns @tainted StoredProcedure|error {
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

    # List all stored procedures inside a collection
    # + properties - object of type ResourceProperties
    # + return - If successful, returns a StoredProcedureList. Else returns error. 
    public remote function listStoredProcedures(@tainted ResourceProperties properties) returns @tainted 
    StoredProcedureList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedureListType(jsonResponse);  
    }

    # Delete a stored procedure inside a collection
    # + properties - object of type ResourceProperties
    # + storedProcedureId - id of the stored procedure to delete
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteStoredProcedure(@tainted ResourceProperties properties, string storedProcedureId) returns 
    @tainted boolean|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedureId]);        
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Execute a stored procedure inside a collection
    # ***********function only works correctly for string parameters************
    # + properties - object of type ResourceProperties
    # + storedProcedureId - id of the stored procedure to execute
    # + parameters - The list of function paramaters to pass to javascript function as an array.
    # + return - If successful, returns json with the output from the executed funxtion. Else returns error. 
    public remote function executeStoredProcedure(@tainted ResourceProperties properties, string storedProcedureId, 
    any[]? parameters) returns @tainted json|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_STORED_POCEDURES, storedProcedureId]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setTextPayload(parameters.toString());
        var response = self.azureCosmosClient->post(requestPath, request);
        json jsonreponse = check mapResponseToJson(response);
        return jsonreponse;   
    }

    # Create a new user defined function inside a collection
    # A user-defined function (UDF) is a side effect free piece of application logic written in JavaScript. 
    # + properties - object of type ResourceProperties
    # + userDefinedFunction - object of type UserDefinedFunction
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    public remote function createUserDefinedFunction(@tainted ResourceProperties properties, 
    UserDefinedFunction userDefinedFunction) returns @tainted UserDefinedFunction|error {
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

    # Replace an existing user defined function inside a collection
    # + properties - object of type ResourceProperties
    # + userDefinedFunction - object of type UserDefinedFunction
    # + return - If successful, returns a UserDefinedFunction. Else returns error. 
    public remote function replaceUserDefinedFunction(@tainted ResourceProperties properties, 
    @tainted UserDefinedFunction userDefinedFunction) returns @tainted UserDefinedFunction|error {
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

    # Get a list of existing user defined functions inside a collection
    # + properties - object of type ResourceProperties
    # + return - If successful, returns a UserDefinedFunctionList. Else returns error. 
    public remote function listUserDefinedFunctions(@tainted ResourceProperties properties) returns @tainted 
    UserDefinedFunctionList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_UDF]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunctionListType(jsonResponse);      
    }

    # Delete an existing user defined function inside a collection
    # + properties - object of type ResourceProperties
    # + userDefinedFunctionid - id of UDF to delete
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteUserDefinedFunction(@tainted ResourceProperties properties, string userDefinedFunctionid) 
    returns @tainted boolean|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_UDF, userDefinedFunctionid]);        
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Create a trigger inside a collection
    # Triggers are pieces of application logic that can be executed before (pre-triggers) and after (post-triggers) 
    # creation, deletion, and replacement of a document. Triggers are written in JavaScript. 
    # + properties - object of type ResourceProperties
    # + trigger - object of type Trigger
    # + return - If successful, returns a Trigger. Else returns error. 
    public remote function createTrigger(@tainted ResourceProperties properties, Trigger trigger) returns @tainted 
    Trigger|error {
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
    
    # Replace an existing trigger inside a collection
    # + properties - object of type ResourceProperties
    # + trigger - object of type Trigger
    # + return - If successful, returns a Trigger. Else returns error. 
    public remote function replaceTrigger(@tainted ResourceProperties properties, @tainted Trigger trigger) returns 
    @tainted Trigger|error {
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

    # List existing triggers inside a collection
    # + properties - object of type ResourceProperties
    # + return - If successful, returns a TriggerList. Else returns error. 
    public remote function listTriggers(@tainted ResourceProperties properties) returns @tainted TriggerList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_TRIGGER]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTriggerListType(jsonResponse);      
    }

    # Delete an existing trigger inside a collection
    # + properties - object of type ResourceProperties
    # + triggerId - id of the trigger to be deleted
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteTrigger(@tainted ResourceProperties properties, string triggerId) returns @tainted 
    boolean|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId, RESOURCE_PATH_TRIGGER, triggerId]);       
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Create a user in a database
    # + properties - object of type ResourceProperties
    # + userId - the id which should be given to the new user
    # + return - If successful, returns a User. Else returns error.
    public remote function createUser(@tainted ResourceProperties properties, string userId) returns @tainted 
    User|error {
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
    
    # Replace the id of an existing user for a database
    # + properties - object of type ResourceProperties
    # + userId - the id which should be given to the new user
    # + newUserId - the new id for the user
    # + return - If successful, returns a User. Else returns error.
    public remote function replaceUserId(@tainted ResourceProperties properties, string userId, string newUserId) returns 
    @tainted User|error {
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

    # To get information of a user from a database
    # + properties - object of type ResourceProperties
    # + userId - the id of user to get information
    # + return - If successful, returns a User. Else returns error.
    public remote function getUser(@tainted ResourceProperties properties, string userId) returns @tainted User|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);      
    }

    # Lists users in a database account
    # + properties - object of type ResourceProperties
    # + return - If successful, returns a UserList. Else returns error.
    public remote function listUsers(@tainted ResourceProperties properties) returns @tainted UserList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserListType(jsonResponse);     
    }

    # Delete a user from a database account
    # + properties - object of type ResourceProperties
    # + userId - the id of user to delete
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteUser(@tainted ResourceProperties properties, string userId) returns @tainted 
    boolean|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId]);       
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Create a permission for a user 
    # + properties - object of type ResourceProperties
    # + userId - the id of user to which the permission belongs
    # + permission - object of type Permission
    # + validityPeriod - optional validity period parameter which specify  ttl
    # + return - If successful, returns a Permission. Else returns error.
    public remote function createPermission(@tainted ResourceProperties properties, string userId, Permission permission, 
    int? validityPeriod = ()) returns @tainted Permission|error {
        if(self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION]);       
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if(validityPeriod is int) {
            request = check setExpiryHeader(request, validityPeriod);
        }
        json jsonPayload = {
            "id" : permission.id, 
            "permissionMode" : permission.permissionMode, 
            "resource": permission.resourcePath
        };
        request.setJsonPayload(jsonPayload);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Replace an existing permission
    # + properties - object of type ResourceProperties
    # + userId - the id of user to which the permission belongs
    # + permission - object of type Permission
    # + validityPeriod - optional validity period parameter which specify  ttl
    # + return - If successful, returns a Permission. Else returns error.
    public remote function replacePermission(@tainted ResourceProperties properties, string userId, @tainted 
    Permission permission, int? validityPeriod = ()) returns @tainted Permission|error {
        if(self.keyType == TOKEN_TYPE_RESOURCE) {
            return prepareError(MASTER_KEY_ERROR);
        }
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permission.id]);       
        HeaderParameters header = mapParametersToHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        if(validityPeriod is int) {
            request = check setExpiryHeader(request, validityPeriod);
        }
        json jsonPayload = {
            "id" : permission.id, 
            "permissionMode" : permission.permissionMode, 
            "resource": permission.resourcePath
        };
        request.setJsonPayload(<@untainted>jsonPayload);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists permissions belong to a user
    # + properties - object of type ResourceProperties
    # + userId - the id of user to the permissions belong
    # + return - If successful, returns a PermissionList. Else returns error.
    public remote function listPermissions(@tainted ResourceProperties properties, string userId) returns @tainted 
    PermissionList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION]);       
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionListType(jsonResponse);
    }

    # To get information of a permission belongs to a user
    # + properties - object of type ResourceProperties
    # + userId - the id of user to the permission belongs
    # + permissionId - object of type Permission
    # + return - If successful, returns a Permission. Else returns error.
    public remote function getPermission(@tainted ResourceProperties properties, string userId, string permissionId)
    returns @tainted Permission|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permissionId]);       
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Deletes a permission belongs to a user
    # + properties - object of type ResourceProperties
    # + userId - the id of user to the permission belongs
    # + permissionId - id of the permission to delete
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deletePermission(@tainted ResourceProperties properties, string userId, string permissionId) 
    returns @tainted boolean|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_USER, userId, 
        RESOURCE_PATH_PERMISSION, permissionId]);       
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # Gets information of offers inside database account
    # Each Azure Cosmos DB collection is provisioned with an associated performance level represented as an 
    # Offer resource in the REST model. Azure Cosmos DB supports offers representing both user-defined performance 
    # levels and pre-defined performance levels. 
    # + return - If successful, returns a OfferList. Else returns error.
    public remote function listOffers() returns @tainted OfferList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_OFFER]);       
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferListType(jsonResponse);
    }

    # Get information of an offer
    # + offerId - the id of offer
    # + return - If successful, returns a Offer. Else returns error.
    public remote function getOffer(string offerId) returns @tainted Offer|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_OFFER, offerId]);       
        HeaderParameters header = mapOfferHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Replace an existing offer
    # + offer - an object of type Offer
    # + offerType - 
    # + return - If successful, returns a Offer. Else returns error.
    public remote function replaceOffer(Offer offer, string? offerType = ()) returns @tainted Offer|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_OFFER, offer.id]);       
        HeaderParameters header = mapOfferHeaderType(PUT, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        json jsonPaylod = {
            "offerVersion": offer.offerVersion, 
            "content": offer.content, 
            "resource": offer.resourceSelfLink, 
            "offerResourceId": offer.offerResourceId, 
            "id": offer.id, 
            "_rid": offer?.resourceId
        };
        if(offerType is string && offer.offerVersion == "V1") {
            json selectedType = {
                "offerType": offerType
            };
            jsonPaylod = check jsonPaylod.mergeJson(selectedType);
        }
        request.setJsonPayload(jsonPaylod);
        var response = self.azureCosmosClient->put(requestPath, request);
        [json, Headers] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Perform queries on Offer resources
    # + sqlQuery - the CQL query to execute
    # + return - If successful, returns a json. Else returns error.
    public remote function queryOffer(Query sqlQuery) returns @tainted stream<json>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_PATH_OFFER]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        request = check setHeaders(request, self.host, self.keyOrResourceToken, self.keyType, self.tokenVersion, header);
        request.setJsonPayload(<json>sqlQuery.cloneWithType(json));
        request = check setHeadersForQuery(request);
        var response = self.azureCosmosClient->post(requestPath, request);
        stream<json> jsonresponse = check mapResponseToJsonStream(response);
        return (jsonresponse);
    }
}
