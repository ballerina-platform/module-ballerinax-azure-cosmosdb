import ballerina/http;

# Azure Cosmos DB Client object.
# + azureCosmosClient - The HTTP Client
public  client class Client {
    private string baseUrl;
    private string masterKey;
    private string host;
    private string keyType;
    private string tokenVersion;
    public http:Client azureCosmosClient;

    function init(AzureCosmosConfiguration azureConfig) {
        self.baseUrl = azureConfig.baseUrl;
        self.masterKey = azureConfig.masterKey;
        self.host = azureConfig.host;
        self.keyType = azureConfig.tokenType;
        self.tokenVersion = azureConfig.tokenVersion;
        http:ClientConfiguration httpClientConfig = {secureSocket: azureConfig.secureSocketConfig};
        self.azureCosmosClient = new (self.baseUrl,httpClientConfig);
    }

    # To create a database inside a resource
    # + databaseId -  id/name for the database
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' or 
    # 'x-ms-cosmos-offer-autopilot-settings' headers 
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabase(string databaseId, ThroughputProperties? throughputProperties = ()) returns 
    @tainted Database|error {
        json jsonPayload;
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        json body = {
            id:databaseId
        };
        request.setJsonPayload(body);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
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
        var result = self->getDatabase(databaseId);
        if result is error{
            return self->createDatabase(databaseId, throughputProperties);
        }
        return ();  
    }

    # To retrive a given database inside a resource
    # + databaseId -  id/name of the database 
    # + return - If successful, returns Database. Else returns error.  
    public remote function getDatabase(string databaseId) returns @tainted Database|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonreponse);  
    }

    # To list all databases inside a resource
    # + return - If successful, returns DatabaseList. else returns error.  
    public remote function getAllDatabases() returns @tainted DatabaseList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonresponse = check mapResponseToTuple(response);
        return mapJsonToDatabasebList(jsonresponse); 
    }

    # To delete a given database inside a resource
    # + databaseId -  id/name of the database to retrieve
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteDatabase(string databaseId) returns @tainted boolean|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

        # To create a collection inside a database
    # + properties - object of type ResourceProperties
    # + partitionKey - 
    # + indexingPolicy -
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header 
    # + return - If successful, returns Container. Else returns error.  
    public remote function createContainer(@tainted ResourceProperties properties, PartitionKey partitionKey, 
    IndexingPolicy? indexingPolicy = (), ThroughputProperties? throughputProperties = ()) returns @tainted Container|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS]);
        HeaderParameters header = mapParametersToHeaderType(POST, requestPath);
        json body = {
            "id": properties.containerId, 
            "partitionKey": <json>partitionKey.cloneWithType(json)
        };
        json finalc = check body.mergeJson(<json>indexingPolicy.cloneWithType(json));
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        request = check setThroughputOrAutopilotHeader(request, throughputProperties);
        request.setJsonPayload(<@untainted>finalc);
        var response = self.azureCosmosClient->post(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonreponse);
    }

    # To create a database inside a resource
    # + properties -  object of type ResourceProperties
    # + partitionKey - 
    # + indexingPolicy -
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header 
    # + return - If successful, returns Database. Else returns error.  
    public remote function createContainerIfNotExist(@tainted ResourceProperties properties, PartitionKey partitionKey, 
    IndexingPolicy? indexingPolicy = (), ThroughputProperties? throughputProperties = ()) returns @tainted Container?|error {
        var result = self->getContainer(properties);
        if result is error{
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

    # To list all collections inside a database
    # + databaseId -  id/name of the database where the collections are in.
    # + return - If successful, returns ContainerList. Else returns error.  
    public remote function getAllContainers(string databaseId) returns @tainted ContainerList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, databaseId, RESOURCE_PATH_COLLECTIONS]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToContainerListType(jsonreponse);
    }

    # To retrive one collection inside a database
    # + properties - object of type ResourceProperties
    # + return - If successful, returns Container. Else returns error.  
    public remote function getContainer(@tainted ResourceProperties properties) returns @tainted Container|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonreponse);
    }

    # To delete one collection inside a database
    # + properties - object of type ResourceProperties
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    public remote function deleteContainer(@tainted ResourceProperties properties) returns @tainted json|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, 
        properties.containerId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->delete(requestPath, request);
        return check getDeleteResponse(response);
    }

    # To retrieve a list of partition key ranges for the collection
    # + properties -  id/name of the database which collection is in.
    # + return - If successful, returns PartitionKeyList. Else returns error.  
    public remote function getPartitionKeyRanges(@tainted ResourceProperties properties) returns @tainted 
    PartitionKeyList|error {
        http:Request request = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES, properties.databaseId, RESOURCE_PATH_COLLECTIONS, properties.containerId, 
        RESOURCE_PATH_PK_RANGES]);
        HeaderParameters header = mapParametersToHeaderType(GET, requestPath);
        request = check setHeaders(request, self.host, self.masterKey, self.keyType, self.tokenVersion, header);
        var response = self.azureCosmosClient->get(requestPath, request);
        [json, Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToPartitionKeyType(jsonreponse);
    }
}
