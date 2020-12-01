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
        http:Request req = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(POST,requestPath);
        json body = {
            id:databaseId
        };
        req.setJsonPayload(body);
        req = check setHeaders(req,self.host,self.masterKey,self.keyType,self.tokenVersion,header);
        req = check setThroughputOrAutopilotHeader(req,throughputProperties);
        var response = self.azureCosmosClient->post(requestPath,req);
        [json,Headers] jsonreponse = check mapResponseToTuple(response);
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
            return self->createDatabase(databaseId,throughputProperties);
        }
        return ();  
    }

    # To retrive a given database inside a resource
    # + databaseId -  id/name of the database to retrieve
    # + return - If successful, returns Database. Else returns error.  
    public remote function getDatabase(string databaseId) returns @tainted Database|error {
        http:Request req = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES,databaseId]);
        HeaderParameters header = mapParametersToHeaderType(GET,requestPath);
        req = check setHeaders(req,self.host,self.masterKey,self.keyType,self.tokenVersion,header);
        var response = self.azureCosmosClient->get(requestPath,req);
        [json,Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonreponse);  
    }

    # To list all databases inside a resource
    # + return - If successful, returns DatabaseList. else returns error.  
    public remote function getAllDatabases() returns @tainted DatabaseList|error {
        http:Request req = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES]);
        HeaderParameters header = mapParametersToHeaderType(GET,requestPath);

        req = check setHeaders(req,self.host,self.masterKey,self.keyType,self.tokenVersion,header);
        var response = self.azureCosmosClient->get(requestPath,req);
        [json,Headers] jsonresponse = check mapResponseToTuple(response);
        return mapJsonToDbList(jsonresponse); 
    }

    # To delete a given database inside a resource
    # + databaseId -  id/name of the database to retrieve
    # + return - If successful, returns DeleteResponse specifying delete is sucessfull. Else returns error.  
    public remote function deleteDatabase(string databaseId) returns @tainted boolean|error {
        http:Request req = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES,databaseId]);
        HeaderParameters header = mapParametersToHeaderType(DELETE,requestPath);
        req = check setHeaders(req,self.host,self.masterKey,self.keyType,self.tokenVersion,header);
        var response = self.azureCosmosClient->delete(requestPath,req);
        return check getDeleteResponse(response);
    }
}
