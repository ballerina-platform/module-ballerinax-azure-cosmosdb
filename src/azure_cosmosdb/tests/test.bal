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
Document document = {};
StoredProcedure storedPrcedure = {};
UserDefinedFunction udf = {};
User user = {};
Permission permission = {};
OfferList offerList = {};

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

@test:Config{
    groups: ["document"], 
    dependsOn: ["test_createDatabase",  "test_createContainer"]
}
function test_createDocument(){
    log:printInfo("ACTION : createDocument()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    Document createDoc = {
        id: string `document-${uuid.toString()}`, 
        documentBody :{
            "LastName": "keeeeeee",  
        "Parents": [  
            {  
            "FamilyName": null,  
            "FirstName": "Thomas"  
            },  
            {  
            "FamilyName": null,  
            "FirstName": "Mary Kay"  
            }  
        ],  
        "Children": [  
            {  
            "FamilyName": null,  
            "FirstName": "Henriette Thaulow",  
            "Gender": "female",  
            "Grade": 5,  
            "Pets": [  
                {  
                "GivenName": "Fluffy"  
                }  
            ]  
            }  
        ],  
        "Address": {  
            "State": "WA",  
            "County": "King",  
            "City": "Seattle"  
        },  
        "IsRegistered": true, 
        "AccountNumber": 1234
        }, 
        partitionKey : 1234  
    };
    RequestHeaderOptions options = {
        isUpsertRequest: true
    };
    var result = AzureCosmosClient->createDocument(resourceProperty,  createDoc,  options);
    if result is Document {
        document = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }   
}

@test:Config{
    groups: ["document"], 
    dependsOn: ["test_createDatabase",  "test_createContainer",  "test_createDocument"]
}
function test_getDocumentList(){
    log:printInfo("ACTION : getDocumentList()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    var result = AzureCosmosClient->getDocumentList(resourceProperty);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["document"], 
    dependsOn: ["test_createDatabase",  "test_createContainer",  "test_createDocument"]
}
function test_GetOneDocument(){
    log:printInfo("ACTION : GetOneDocument()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    @tainted Document getDoc =  {
        id: document.id, 
        partitionKey : 1234  
    };
    var result = AzureCosmosClient->getDocument(resourceProperty, getDoc);
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["document"], 
    dependsOn: ["test_createDatabase", "test_createContainer", "test_GetOneDocument"]
}
function test_deleteDocument(){
    log:printInfo("ACTION : deleteDocument()");
    
    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    @tainted Document deleteDoc =  {
        id: document.id, 
        partitionKey : 1234  
    };
    var result = AzureCosmosClient->deleteDocument(resourceProperty, deleteDoc);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["document"], 
    dependsOn: ["test_createDatabase", "test_createContainer"],
    enable: false
}
function test_queryDocuments(){
    log:printInfo("ACTION : queryDocuments()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    int partitionKey = 1234;//get the pk from endpoint
    Query sqlQuery = {
        query: string `SELECT * FROM ${container.id.toString()} f WHERE f.Address.City = 'Seattle'`, 
        parameters: []
    };
    //QueryParameter[] params = [{name: "@id",  value: "46c25391-e11d-4327-b7c5-28f44bcf3f2f"}];
    var result = AzureCosmosClient->queryDocuments(resourceProperty, partitionKey, sqlQuery);   
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }   
}

@test:Config{
    groups: ["storedProcedure"], 
    dependsOn: ["test_createDatabase", "test_createContainer"]
}
function test_createStoredProcedure(){
    log:printInfo("ACTION : createStoredProcedure()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    string createSprocBody = "function () {\r\n    var context = getContext();\r\n    var response = context.getResponse();\r\n\r\n    response.setBody(\"Hello,  World\");\r\n}"; 
    StoredProcedure sp = {
        id: string `sproc-${uuid.toString()}`, 
        body:createSprocBody
    };
    var result = AzureCosmosClient->createStoredProcedure(resourceProperty, sp);  
    if result is StoredProcedure {
        storedPrcedure = <@untainted> result;
    } else {
        test:assertFail(msg = result.message());
    }   
}

@test:Config{
    groups: ["storedProcedure"], 
    dependsOn: ["test_createStoredProcedure"]
}
function test_replaceStoredProcedure(){
    log:printInfo("ACTION : replaceStoredProcedure()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    string replaceSprocBody = "function heloo(personToGreet) {\r\n    var context = getContext();\r\n    var response = context.getResponse();\r\n\r\n    response.setBody(\"Hello,  \" + personToGreet);\r\n}";
    StoredProcedure sp = {
        id: storedPrcedure.id, 
        body: replaceSprocBody
    }; 
    var result = AzureCosmosClient->replaceStoredProcedure(resourceProperty, sp);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }   
}

@test:Config{
    groups: ["storedProcedure"], 
    dependsOn: ["test_createDatabase", "test_createContainer"]
}
function test_getAllStoredProcedures(){
    log:printInfo("ACTION : replaceStoredProcedure()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    var result = AzureCosmosClient->listStoredProcedures(resourceProperty);   
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["storedProcedure"], 
    dependsOn: ["test_createStoredProcedure", "test_replaceStoredProcedure"]
}
function test_executeOneStoredProcedure(){
    log:printInfo("ACTION : executeOneStoredProcedure()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    string executeSprocId = storedPrcedure.id;
    string[] arrayofparameters = ["Sachi"];
    var result = AzureCosmosClient->executeStoredProcedure(resourceProperty, executeSprocId, arrayofparameters);   
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }        
}

@test:Config{
    groups: ["storedProcedure"], 
    dependsOn: ["test_createStoredProcedure", "test_replaceStoredProcedure", "test_executeOneStoredProcedure"]
}
function test_deleteOneStoredProcedure(){
    log:printInfo("ACTION : deleteOneStoredProcedure()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    string deleteSprocId = storedPrcedure.id;
    var result = AzureCosmosClient->deleteStoredProcedure(resourceProperty, deleteSprocId);   
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }   
}

@test:Config{
    groups: ["userDefinedFunction"], 
    dependsOn: ["test_createDatabase", "test_createContainer"]
}
function test_createUDF(){
    log:printInfo("ACTION : createUDF()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    string udfId = string `udf-${uuid.toString()}`;
    string createUDFBody = "function tax(income) {\r\n    if(income == undefined) \r\n        throw 'no input';\r\n    if (income < 1000) \r\n        return income * 0.1;\r\n    else if (income < 10000) \r\n        return income * 0.2;\r\n    else\r\n        return income * 0.4;\r\n}"; 
    UserDefinedFunction createUdf = {
        id: udfId, 
        body: createUDFBody
    };
    var result = AzureCosmosClient->createUserDefinedFunction(resourceProperty, createUdf);  
    if result is UserDefinedFunction {
        udf = <@untainted> result;
    } else {
        test:assertFail(msg = result.message());
    }   
}

@test:Config{
    groups: ["userDefinedFunction"], 
    dependsOn: ["test_createDatabase", "test_createContainer", "test_createUDF"]
}
function test_replaceUDF(){
    log:printInfo("ACTION : replaceUDF()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    string replaceUDFBody = "function taxIncome(income) {\r\n if(income == undefined) \r\n throw 'no input';\r\n if (income < 1000) \r\n return income * 0.1;\r\n else if (income < 10000) \r\n return income * 0.2;\r\n else\r\n return income * 0.4;\r\n}"; 
    UserDefinedFunction replacementUdf = {
        id: udf.id, 
        body:replaceUDFBody
    };
    var result = AzureCosmosClient->replaceUserDefinedFunction(resourceProperty, replacementUdf);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }   
}

@test:Config{
    groups: ["userDefinedFunction"], 
    dependsOn: ["test_createDatabase",  "test_createContainer",  "test_createUDF"]
}
function test_listAllUDF(){
    log:printInfo("ACTION : listAllUDF()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    var result = AzureCosmosClient->listUserDefinedFunctions(resourceProperty);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["userDefinedFunction"], 
    dependsOn: ["test_createUDF",  "test_replaceUDF", "test_listAllUDF"]
}
function test_deleteUDF(){
    log:printInfo("ACTION : deleteUDF()");

    Client AzureCosmosClient = new(config);
    string deleteUDFId = udf.id;
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id, 
        containerId: container.id
    };
    var result = AzureCosmosClient->deleteUserDefinedFunction(resourceProperty, deleteUDFId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["user"], 
    dependsOn: ["test_createDatabase"]
}
function test_createUser(){
    log:printInfo("ACTION : createUser()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string userId = string `user-${uuid.toString()}`;
    var result = AzureCosmosClient->createUser(resourceProperty, userId);  
    if result is User {
        user = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }   
}

@test:Config{
    groups: ["user"], 
    dependsOn: [
        "test_createUser",
        "test_getUser",
        "test_createPermission", 
        "test_replacePermission", 
        "test_listPermissions", 
        "test_getPermission", 
        "test_deletePermission"
        ]
}
function test_replaceUserId(){
    log:printInfo("ACTION : replaceUserId()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    string newReplaceId = string `user-${uuid.toString()}`;
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string replaceUser = user.id;
    var result = AzureCosmosClient->replaceUserId(resourceProperty, replaceUser, newReplaceId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["user"], 
    dependsOn: ["test_createUser"]
}
function test_getUser(){
    log:printInfo("ACTION : getUser()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string getUserId = user.id;
    var result = AzureCosmosClient->getUser(resourceProperty, getUserId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["user"], 
    dependsOn: ["test_createUser"]
}
function test_listUsers(){
    log:printInfo("ACTION : listUsers()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    var result = AzureCosmosClient->listUsers(resourceProperty);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    } 
}

@test:Config{
    groups: ["user"], 
    dependsOn: [
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
function test_deleteUser(){
    log:printInfo("ACTION : deleteUser()");

    Client AzureCosmosClient = new(config);
    string deleteUserId = user.id;
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    var result = AzureCosmosClient->deleteUser(resourceProperty, deleteUserId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    } 
}

@test:Config{
    groups: ["permission"], 
    dependsOn: ["test_createDatabase", "test_createUser",  "test_createContainer"]
}
function test_createPermission(){
    log:printInfo("ACTION : createPermission()");

    Client AzureCosmosClient = new(config);
    var uuid = createRandomUUID();
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string permissionUserId = user.id;
    string permissionId = string `permission-${uuid.toString()}`;
    string permissionMode = "Read";
    string permissionResource = string `dbs/${database._rid.toString()}/colls/${container._rid.toString()}`;
    Permission createPermission = {
        id: permissionId, 
        permissionMode: permissionMode, 
        'resource: permissionResource
    };

    var result = AzureCosmosClient->createPermission(resourceProperty, permissionUserId, createPermission);  
    if result is Permission {
        permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }   
}

@test:Config{
    groups: ["permission"], 
    dependsOn: ["test_createPermission"]
}
function test_replacePermission(){
    log:printInfo("ACTION : replacePermission()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string permissionUserId = user.id;
    string permissionId = permission.id;
    string permissionMode = "All";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}`;
    Permission replacePermission = {
        id:permissionId, 
        permissionMode:permissionMode, 
        'resource:permissionResource
    };
    var result = AzureCosmosClient->replacePermission(resourceProperty, permissionUserId, replacePermission);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["permission"], 
    dependsOn: ["test_createPermission"]
}
function test_listPermissions(){
    log:printInfo("ACTION : listPermissions()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string permissionUserId = user.id;
    var result = AzureCosmosClient->listPermissions(resourceProperty, permissionUserId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    } 
}

@test:Config{
    groups: ["permission"], 
    dependsOn: ["test_createPermission"]
}
function test_getPermission(){
    log:printInfo("ACTION : getPermission()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string permissionUserId = user.id;
    string permissionId = permission.id;
    var result = AzureCosmosClient->getPermission(resourceProperty, permissionUserId, permissionId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config{
    groups: ["permission"], 
    dependsOn: ["test_createPermission", "test_getPermission", "test_listPermissions", "test_replacePermission"]
}
function test_deletePermission(){
    log:printInfo("ACTION : deletePermission()");

    Client AzureCosmosClient = new(config);
    @tainted ResourceProperties resourceProperty = {
        databaseId: database.id
    };
    string permissionUserId = user.id;
    string permissionId = permission.id;
    var result = AzureCosmosClient->deletePermission(resourceProperty, permissionUserId, permissionId);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    } 
}

@test:Config{
    groups: ["offer"]
}
function test_listOffers(){
    log:printInfo("ACTION : listOffers()");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->listOffers();  
    if result is OfferList {
        offerList = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }   
}

@test:Config{
    groups: ["offer"], 
    dependsOn: ["test_listOffers"]
}
function test_getOffer(){
    log:printInfo("ACTION : getOffer()");

    Client AzureCosmosClient = new(config);
    var result = AzureCosmosClient->getOffer(offerList.offers[0].id);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }  
}

@test:Config{
    groups: ["offer"]
}
function test_replaceOffer(){
    log:printInfo("ACTION : replaceOffer()");

    Client AzureCosmosClient = new(config);
    Offer replaceOfferBody = {
        offerVersion: "V2", 
        offerType: "Invalid",    
        content: {  
            "offerThroughput": 600
        },  
        'resource: string `dbs/${database._rid.toString()}/colls/${container._rid.toString()}/`,  
        offerResourceId: string `${container._rid.toString()}`, 
        id: offerList.offers[0].id, 
        _rid: offerList.offers[0]._rid 
    };
    var result = AzureCosmosClient->replaceOffer(replaceOfferBody);  
    if result is error {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    } 
}

@test:Config{
    groups: ["offer"], 
    dependsOn: ["test_createDatabase",  "test_createContainer"],
    enable: false
}
function test_queryOffer(){
    log:printInfo("ACTION : queryOffer()");

    Client AzureCosmosClient = new(config);
    Query offerQuery = {
    query: string `SELECT * FROM ${container.id} WHERE (${container.id}["_self"]) = ${container._self.toString()} "`
    };
    var result = AzureCosmosClient->queryOffer(offerQuery);   
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
