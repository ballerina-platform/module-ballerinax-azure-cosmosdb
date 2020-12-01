import ballerina/io;
import ballerina/test;
import ballerina/config;
import ballerina/system;
import ballerina/java;

AzureCosmosConfiguration config = {
    baseUrl : getConfigValue("BASE_URL"),
    masterKey : getConfigValue("MASTER_KEY"),
    host : getConfigValue("HOST"),
    tokenType : getConfigValue("TOKEN_TYPE"),
    tokenVersion : getConfigValue("TOKEN_VERSION"),
    secureSocketConfig :{
                            trustStore: {
                            path: getConfigValue("b7a_home") + "/bre/security/ballerinaTruststore.p12",
                            password: getConfigValue("SSL_PASSWORD")
                            }
                        }
};

function createRandomUUID() returns handle = @java:Method {
    name : "randomUUID",
    'class : "java.util.UUID"
} external;

@tainted ResourceProperties properties = {
        databaseId: getConfigValue("TARGET_RESOURCE_DB"),
        containerId: getConfigValue("TARGET_RESOURCE_COLL")
};
var uuid = createRandomUUID();
string createDatabaseId = string `database-${uuid.toString()}`;
string createIfNotExistDatabaseId = getConfigValue("DATABASE_ID_IF_NOT_EXIST");
string createDatabaseBothId = uuid.toString();
string listOndDbId = getConfigValue("DATABASE_ID_GET"); 
string deleteDbId = getConfigValue("DATABASE_ID_DELETE");  

@test:Config{
    groups: ["database"]
}
function createDB(){
    io:println("--------------Create database------------------------\n\n");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->createDatabase(createDatabaseId);
    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

@test:Config{
    groups: ["database"]
}
function createIfNotExist(){
    io:println("--------------Create database if not exist------------------------\n\n");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->createDatabaseIfNotExist(createIfNotExistDatabaseId);
    if (result is Database?) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

string createDatabaseManualId = string `database1-${uuid.toString()}`;
ThroughputProperties manualThroughput = {
    throughput: 600
};
@test:Config{
    groups: ["database"]
}
function createDBWithManualThroughput(){
    io:println("--------------Create with manual throguput------------------------\n\n");

    Client AzureCosmosClient = new(config); 
    var result = AzureCosmosClient->createDatabase(createDatabaseManualId, manualThroughput);
    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

string createDatabaseAutoId = string `database2-${uuid.toString()}`;
ThroughputProperties tp = {
    maxThroughput: {"maxThroughput": 4000}
};
@test:Config{
    groups: ["database"]
}
function createDBWithAutoscaling(){
    io:println("--------------Create with autoscaling throguput------------------------\n\n");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->createDatabase(createDatabaseAutoId, tp);
    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

@test:Config{
    groups: ["database"]
}
function createDBWithBothHeaders(){
    io:println("--------------Create with autoscaling and throguput headers------------------------\n\n");

    Client AzureCosmosClient = new(config);
    ThroughputProperties tp = {};
    tp.maxThroughput = {"maxThroughput" : 4000};
    tp.throughput = 600; 
    var result = AzureCosmosClient->createDatabase(createDatabaseBothId, tp);
    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

@test:Config{
    groups: ["database"]
}
function listAllDB(){
    io:println("--------------List All databases------------------------\n\n");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->getAllDatabases();
    if (result is DatabaseList) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

@test:Config{
    groups: ["database"]
}
function listOneDB(){
    io:println("--------------List one database------------------------\n\n");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->getDatabase(listOndDbId);
    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

@test:Config{
    groups: ["database"]
}
function deleteDB(){
    io:println("--------------Delete one databse------------------------\n\n");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->deleteDatabase(deleteDbId);
    if (result is boolean) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}
