//import ballerina/io;
import ballerina/test;
import ballerina/config;
import ballerina/system;
import ballerina/java;
import ballerina/log;

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

Database database = {};
DatabaseList databaseList = {};
Container container = {};
ContainerList containerList = {};

@test:Config{
    groups: ["database"]
}
function test_createDatabase(){
    log:printInfo("ACTION : createDatabase()");

    var uuid = createRandomUUID();
    string createDatabaseId = string `database-${uuid.toString()}`;
    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->createDatabase(createDatabaseId);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        database = <@untainted>result;
    }
}

@test:Config{
    groups: ["database"], 
    dependsOn: ["test_createDatabase"]
}
function test_createDatabaseIfNotExist(){
    log:printInfo("ACTION : createIfNotExist()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    string createDatabaseId = string `databasee-${uuid.toString()}`;
    var result = AzureCosmosClient->createDatabaseIfNotExist(createDatabaseId);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["database"]
}
function test_createDatabaseWithManualThroughput(){
    log:printInfo("ACTION : createDatabaseWithManualThroughput()");

    var uuid = createRandomUUID();
    string createDatabaseManualId = string `databasem-${uuid.toString()}`;
    ThroughputProperties manualThroughput = {
        throughput: 600
    };
    Client AzureCosmosClient = new(config); 
    var result = AzureCosmosClient->createDatabase(createDatabaseManualId,  manualThroughput);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["database"]
}
function test_createDBWithAutoscalingThroughput(){
    log:printInfo("ACTION : createDBWithAutoscalingThroughput()");

    Client AzureCosmosClient = new(config);

    var uuid = createRandomUUID();
    string createDatabaseAutoId = string `databasea-${uuid.toString()}`;
    ThroughputProperties tp = {
        maxThroughput: {"maxThroughput": 4000}
    };
    var result = AzureCosmosClient->createDatabase(createDatabaseAutoId,  tp);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["database"]
}
function test_createDatabaseWithBothHeaders(){
    log:printInfo("ACTION : createDatabaseWithBothHeaders()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    string createDatabaseBothId = string `database-${uuid.toString()}`;
    ThroughputProperties tp = {
        maxThroughput: {"maxThroughput" : 4000}, 
        throughput: 600
    };
    var result = AzureCosmosClient->createDatabase(createDatabaseBothId,  tp);
    if result is error {
        var output = "";
    } else {
        test:assertFail(msg = "Created database with both throughput values!!");
    }
}

@test:Config{
    groups: ["database"]
}
function test_listAllDatabases(){
    log:printInfo("ACTION : listAllDatabases()");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->getAllDatabases();
    if result is DatabaseList {
        databaseList = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config{
    groups: ["database"], 
    dependsOn: ["test_listAllDatabases"]
}
function test_listOneDatabase(){
    log:printInfo("ACTION : listOneDatabase()");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->getDatabase(databaseList.databases[0].id);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["database"], 
    dependsOn: [
        "test_createDatabase", 
        "test_getAllContainers", 
        "test_GetPartitionKeyRanges", 
        "test_createDocument", 
        "test_getDocumentList", 
        "test_GetOneDocument", 
        "test_deleteDocument", 
        "test_queryDocuments", 
        "test_createStoredProcedure", 
        "test_replaceStoredProcedure", 
        "test_getAllStoredProcedures", 
        "test_executeOneStoredProcedure", 
        "test_deleteOneStoredProcedure", 
        "test_createUDF", 
        "test_replaceUDF", 
        "test_listAllUDF", 
        "test_deleteUDF", 
        "test_createTrigger", 
        "test_replaceTrigger", 
        "test_listTriggers", 
        "test_deleteTrigger", 
        "test_createUser",  
        "test_replaceUserId",  
        "test_getUser",  
        "test_listUsers", 
        "test_createPermission", 
        "test_replacePermission", 
        "test_listPermissions", 
        "test_getPermission", 
        "test_deletePermission"
    ], 
    enable: false
}
function test_deleteDatabase(){
    log:printInfo("ACTION : deleteDatabase()");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->deleteDatabase(databaseList.databases[databaseList.databases.length()-1].id);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["container"], 
    dependsOn: ["test_createDatabase"]
}
function test_createContainer(){
    log:printInfo("ACTION : createContainer()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    @tainted ResourceProperties propertiesNewCollection = {
            databaseId: database.id, 
            containerId: string `container-${uuid.toString()}`
    };
    PartitionKey pk = {
        paths: ["/AccountNumber"], 
        kind :"Hash", 
        'version: 2
    };
    var result = AzureCosmosClient->createContainer(propertiesNewCollection, pk);
    if (result is Container) {
        container = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    } 
}

@test:Config{
    groups: ["container"], 
    dependsOn: ["test_createDatabase",  "test_createContainer"]
}
function test_getOneContainer(){
    log:printInfo("ACTION : getOneContainer()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties getCollection = {
        databaseId: database.id, 
        containerId: container.id
    };
    var result = AzureCosmosClient->getContainer(getCollection);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["container"], 
    dependsOn: ["test_createDatabase"]
}
function test_getAllContainers(){
    log:printInfo("ACTION : getAllContainers()");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->getAllContainers(database.id);
    if (result is ContainerList) {
        containerList = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config{
    groups: ["container"], 
    dependsOn: [
        "test_getAllContainers", 
        "test_GetPartitionKeyRanges", 
        "test_createDocument", 
        "test_getDocumentList", 
        "test_GetOneDocument", 
        "test_deleteDocument", 
        "test_queryDocuments", 
        "test_createStoredProcedure", 
        "test_replaceStoredProcedure", 
        "test_getAllStoredProcedures", 
        "test_executeOneStoredProcedure", 
        "test_deleteOneStoredProcedure", 
        "test_createUDF", 
        "test_replaceUDF", 
        "test_listAllUDF", 
        "test_deleteUDF", 
        "test_createTrigger", 
        "test_replaceTrigger", 
        "test_listTriggers", 
        "test_deleteTrigger"
    ], 
    enable: false
}
function test_deleteContainer(){
    log:printInfo("ACTION : deleteContainer()");

    Client AzureCosmosClient = new(config); 
    @tainted ResourceProperties deleteCollectionData = {
            databaseId: database.id, 
            containerId: container.id
    };
    var result = AzureCosmosClient->deleteContainer(deleteCollectionData);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["partitionKey"]
}
function test_GetPartitionKeyRanges(){
    log:printInfo("ACTION : GetPartitionKeyRanges()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperties = {
            databaseId: database.id, 
            containerId: container.id
    };
    var result = AzureCosmosClient->getPartitionKeyRanges(resourceProperties);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }   
}

function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}

function createRandomUUID() returns handle = @java:Method {
    name : "randomUUID", 
    'class : "java.util.UUID"
} external;