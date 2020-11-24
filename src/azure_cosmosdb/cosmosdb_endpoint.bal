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

    function init(AzureCosmosConfiguration azureConfig){
        self.baseUrl = azureConfig.baseUrl;
        self.masterKey = azureConfig.masterKey;
        self.host = azureConfig.host;
        self.keyType = azureConfig.tokenType;
        self.tokenVersion = azureConfig.tokenVersion;
        http:ClientConfiguration httpClientConfig = {secureSocket: azureConfig.secureSocketConfig};
        self.azureCosmosClient = new (self.baseUrl,httpClientConfig);
    }

    # To create a database inside a resource
    # + properties -  id/name for the database
    # + throughputProperties - Optional throughput parameter which will set 'x-ms-offer-throughput' header 
    # + return - If successful, returns Database. Else returns error.  
    public remote function createDatabase(DatabaseProperties properties, ThroughputProperties? throughputProperties = ()) returns 
    @tainted Database|error{
        json jsonPayload;
        http:Request req = new;
        string requestPath =  prepareUrl([RESOURCE_PATH_DATABASES]);
        RequestHeaderParameters header = mapParametersToHeaderType(POST,requestPath);
        if properties.id == "" {
            return prepareError("Invalid database id: Cannot be empty");
        }
        json|error payload = properties.cloneWithType(json);
        if payload is json {
            req.setJsonPayload(payload);
        }
        req = check setHeaders(req,self.host,self.masterKey,self.keyType,self.tokenVersion,header);
        req = check setThroughputOrAutopilotHeader(req,throughputProperties);
        var response = self.azureCosmosClient->post(requestPath,req);
        [json,Headers] jsonreponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonreponse);   
    }
}