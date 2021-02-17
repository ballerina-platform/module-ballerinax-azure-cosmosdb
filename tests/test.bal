// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;
import ballerina/config;
import ballerina/system;
import ballerina/log;
import ballerina/runtime;
import ballerina/java;
import ballerina/stringutils;

Configuration config = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

DataPlaneClient azureCosmosClient = new(config);
ManagementClient azureCosmosManagementClient = new(config);

var randomString = createRandomUUIDWithoutHyphens();

string databaseId = string `database_${randomString.toString()}`;
string createDatabaseManualId = string `databasem_${randomString.toString()}`;
string createDatabaseAutoId = string `databasea_${randomString.toString()}`;
string createDatabaseExistId = string `databasee_${randomString.toString()}`;

string containerId = string `container_${randomString.toString()}`;
string containerWithOptionsId = string `containero_${randomString.toString()}`;
string containerIfNotExistId = string `containerx_${randomString.toString()}`;

string documentId = string `document_${randomString.toString()}`;
string sprocId = string `sproc_${randomString.toString()}`;
string udfId = string `udf_${randomString.toString()}`;
string triggerId = string `trigger_${randomString.toString()}`;

string userId = string `user_${randomString.toString()}`;
string newUserId = string `userr_${randomString.toString()}`;
string permissionId = string `permission_${randomString.toString()}`;

Database database = {id: ""};
Container container = {id: "", indexingPolicy:{ indexingMode: ""}, partitionKey: {}};

@test:BeforeSuite
function testCreateDatabase() {
    log:print("ACTION : createDatabase()");

    var result = azureCosmosManagementClient->createDatabase(databaseId);
    if (result is Database) {
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testCreateDatabaseUsingInvalidId() {
    log:print("ACTION : createDatabaseUsingInvalidId()");

    string createDatabaseId = "";
    var result = azureCosmosManagementClient->createDatabase(createDatabaseId);
    if (result is Database) {
        test:assertFail(msg = "Database created with  '' id value");
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["database"]
}
function testCreateDatabaseIfNotExist() {
    log:print("ACTION : createDatabaseIfNotExist()");

    var result = azureCosmosManagementClient->createDatabaseIfNotExist(createDatabaseExistId);
    if (result is Database?) {
  
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testCreateDatabaseIfExist() {
    log:print("ACTION : createDatabaseIfExist()");

    var result = azureCosmosManagementClient->createDatabaseIfNotExist(databaseId);
    if (result is Database) {
        test:assertFail(msg = "Database with non unique id is created");
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["database"],
    enable: false
}
function testCreateDatabaseWithManualThroughput() {
    log:print("ACTION : createDatabaseWithManualThroughput()");
    int throughput = 1000;

    var result = azureCosmosManagementClient->createDatabase(createDatabaseManualId, throughput);
    if (result is Database) {
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"],
    enable: false
}
function testCreateDatabaseWithInvalidManualThroughput() {
    log:print("ACTION : createDatabaseWithInvalidManualThroughput()");
    int throughput = 40;

    var result = azureCosmosManagementClient->createDatabase(createDatabaseManualId, throughput);
    if (result is Database) {
        test:assertFail(msg = "Database created without validating user input");
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["database"],
    enable: false
}
function testCreateDBWithAutoscalingThroughput() {
    log:print("ACTION : createDBWithAutoscalingThroughput()");
    record {|int maxThroughput;|} maxThroughput = { maxThroughput: 4000 };

    var result = azureCosmosManagementClient->createDatabase(createDatabaseAutoId, maxThroughput);
    if (result is Database) {
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testListAllDatabases() {
    log:print("ACTION : listAllDatabases()");

    var result = azureCosmosManagementClient->listDatabases(6);
    if (result is stream<Database>) {
        var databaseStream = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testListOneDatabase() {
    log:print("ACTION : listOneDatabase()");

    var result = azureCosmosManagementClient->getDatabase(databaseId);
    if (result is Database) {
        database = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"]
}
function testCreateContainer() {
    log:print("ACTION : createContainer()");

    PartitionKey pk = {
        paths: ["/AccountNumber"],
        keyVersion: 2
    };
    var result = azureCosmosManagementClient->createContainer(databaseId, containerId, pk);
    if (result is Container) {
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["testCreateContainer"]
}
function testCreateCollectionWithManualThroughputAndIndexingPolicy() {
    log:print("ACTION : createCollectionWithManualThroughputAndIndexingPolicy()");

    IndexingPolicy ip = {
        indexingMode: "consistent",
        automatic: true,
        includedPaths: [{
            path: "/*",
            indexes: [{
                dataType: STRING,
                precision: -1,
                kind: "Range"
            }]
        }]
    };
    //int throughput = 600;
    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosManagementClient->createContainer(databaseId, containerWithOptionsId, pk, ip);
    if (result is Container) {
        var output = "";
    } else {
        test:assertFail("SUccessfully created");
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["testGetOneContainer"]
}
function testCreateContainerIfNotExist() {
    log:print("ACTION : createContainerIfNotExist()");

    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosManagementClient->createContainerIfNotExist(databaseId, containerIfNotExistId, pk);
    if (result is Container?) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["testCreateContainer"]
}
function testGetOneContainer() {
    log:print("ACTION : getOneContainer()");

    var result = azureCosmosManagementClient->getContainer(databaseId, containerId);
    if (result is Container) {
        container = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"]
}
function testGetAllContainers() {
    log:print("ACTION : getAllContainers()");

    var result = azureCosmosManagementClient->listContainers(databaseId);
    if (result is stream<Container>) {
        var container = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"], 
    dependsOn: [
        "testGetOneContainer", 
        "testGetAllContainers",
        "testGetDocumentList", 
        "testDeleteDocument", 
        "testQueryDocuments", 
        "testQueryDocumentsWithRequestOptions",
        "testGetAllStoredProcedures", 
        "testDeleteOneStoredProcedure", 
        "testListAllUDF", 
        "testDeleteUDF", 
        "testDeleteTrigger", 
        "testGetOneDocumentWithRequestOptions", 
        "testCreateDocumentWithRequestOptions", 
        "testGetDocumentListWithRequestOptions",
        "testCreatePermission",
        "testCreatePermissionWithTTL",
        "testGetPartitionKeyRanges"
        // "testReplaceOfferWithOptionalParameter",
        // "testReplaceOffer",
        
    ]
}
function testDeleteContainer() {
    log:print("ACTION : deleteContainer()");

    var result = azureCosmosManagementClient->deleteContainer(databaseId, containerId);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateContainer"]
}
function testCreateDocument() {
    log:print("ACTION : createDocument()");

    int valueOfPartitionKey = 1234;
    record {|string id; json...;|} documentBody = {
        id: documentId,
        "LastName": "keeeeeee",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        "Children": [{
            "FamilyName": null,
            "FirstName": "Henriette Thaulow",
            "Gender": "female",
            "Grade": 5,
            "Pets": [{"GivenName": "Fluffy"}]
        }],
        "Address": {
            "State": "WA",
            "County": "King",
            "City": "Seattle"
        },
        "IsRegistered": true,
        "AccountNumber": 1234
    };

    var result = azureCosmosClient->createDocument(databaseId, containerId, documentBody, valueOfPartitionKey);
    if (result is Document) {

    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateContainer"]
}
function testCreateDocumentWithRequestOptions() {
    log:print("ACTION : createDocumentWithRequestOptions()");

    var uuid = createRandomUUIDWithoutHyphens();

    DocumentCreateOptions options = {
        isUpsertRequest: true,
        indexingDirective: "Include"
    };
    int valueOfPartitionKey = 1234;
    string newDocumentId = string `document_${uuid.toString()}`;
    record {|string id; json...;|} documentBody = {
        id: newDocumentId,
        "LastName": "keeeeeee",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        "Children": [{
            "FamilyName": null,
            "FirstName": "Henriette Thaulow",
            "Gender": "female",
            "Grade": 5,
            "Pets": [{"GivenName": "Fluffy"}]
        }],
        "Address": {
            "State": "WA",
            "County": "King",
            "City": "Seattle"
        },
        "IsRegistered": true,
        "AccountNumber": 1234
    };

    var result = azureCosmosClient->createDocument(databaseId, containerId, documentBody, valueOfPartitionKey, options);
    if (result is Document) {

    } else {
        test:assertFail(msg = result.message());
    }
}

// Replace document 

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateDocument"]
}
function testGetDocumentList() {
    log:print("ACTION : getDocumentList()");

    var result = azureCosmosClient->getDocumentList(databaseId, containerId);
    if (result is stream<Document>) {
        var oneElement = result.next(); 
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateDocument"]
}
function testGetDocumentListWithRequestOptions() {
    log:print("ACTION : getDocumentListWithRequestOptions()");

    DocumentListOptions options = {
        consistancyLevel: EVENTUAL,
        // changeFeedOption : "Incremental feed", 
        sessionToken: "tag",
        partitionKeyRangeId: "0"
    };
    var result = azureCosmosClient->getDocumentList(databaseId, containerId, 10, options);
    if (result is stream<Document>) {
        var singleDocument = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateDocument"]
}
function testGetOneDocument() {
    log:print("ACTION : GetOneDocument()");

    int valueOfPartitionKey = 1234;
    var result = azureCosmosClient->getDocument(databaseId, containerId, documentId, valueOfPartitionKey);
    if (result is Document) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateDocument"]
}
function testGetOneDocumentWithRequestOptions() {
    log:print("ACTION : GetOneDocumentWithRequestOptions()");

    int valueOfPartitionKey = 1234;

    ResourceReadOptions options = {
        consistancyLevel: EVENTUAL,
        sessionToken: "tag"
    };

    var result = azureCosmosClient->getDocument(databaseId, containerId, documentId, valueOfPartitionKey, options);
    if (result is Document) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateContainer"]
}
function testQueryDocuments() {
    log:print("ACTION : queryDocuments()");

    int partitionKey = 1234;
    string query = string `SELECT * FROM ${container.id.toString()} f WHERE f.Address.City = 'NY'`;

    var result = azureCosmosClient->queryDocuments(databaseId, containerId, query, 10, partitionKey);
    if (result is stream<Document>) {
        var document = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["testCreateContainer"]
}
function testQueryDocumentsWithRequestOptions() {
    log:print("ACTION : queryDocumentsWithRequestOptions()");

    string query = string `SELECT * FROM ${containerId} f WHERE f.Address.City = 'Seattle'`;

    ResourceQueryOptions options = {
        //sessionToken: "tag", 
        enableCrossPartition: true
    };

    var result = azureCosmosClient->queryDocuments(databaseId, containerId, query, (), (), options);
    if (result is stream<json>) {
        var document = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"], 
    dependsOn: [
        "testCreateContainer", 
        "testCreateDocument", 
        "testGetOneDocument", 
        "testGetOneDocumentWithRequestOptions", 
        "testQueryDocuments",
        "testGetDocumentList"
    ]
}
function testDeleteDocument() {
    log:print("ACTION : deleteDocument()");

    var result = azureCosmosClient->deleteDocument(databaseId, containerId, documentId, 1234);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["testCreateContainer"]
}
function testCreateStoredProcedure() {
    log:print("ACTION : createStoredProcedure()");

    string createSprocBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;

    var result = azureCosmosClient->createStoredProcedure(databaseId, containerId, sprocId, createSprocBody);
    if (result is StoredProcedure) {
        //storedPrcedure = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["testCreateStoredProcedure", "testGetAllStoredProcedures"]
}
function testReplaceStoredProcedure() {
    log:print("ACTION : replaceStoredProcedure()");

    string replaceSprocBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                    }`;

    var result = azureCosmosClient->replaceStoredProcedure(databaseId, containerId, sprocId, replaceSprocBody);
    if (result is StoredProcedure) {
        //storedPrcedure = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["testReplaceStoredProcedure"
]
}
function testExecuteOneStoredProcedure() {
    log:print("ACTION : executeOneStoredProcedure()");

    string[] arrayofparameters = ["Sachi"];
    StoredProcedureOptions options = {
        parameters: arrayofparameters
    };

    var result = azureCosmosClient->executeStoredProcedure(databaseId, containerId, sprocId, options);
    if (result is json) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}
@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["testCreateContainer"]
}
function testGetAllStoredProcedures() {
    log:print("ACTION : getAllStoredProcedures()");

    var result = azureCosmosClient->listStoredProcedures(databaseId, containerId);
    if (result is stream<StoredProcedure>) {
        var oneElement = result.next();
    
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: [
        "testCreateStoredProcedure", 
        "testExecuteOneStoredProcedure"    
    ]
}
function testDeleteOneStoredProcedure() {
    log:print("ACTION : deleteOneStoredProcedure()");

    var result = azureCosmosClient->deleteStoredProcedure(databaseId, containerId, sprocId);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["testCreateContainer"]
}
function testCreateUDF() {
    log:print("ACTION : createUDF()");

    string createUDFBody = string `function tax(income){

                                                if (income == undefined)
                                                    throw 'no input';

                                                if (income < 1000)
                                                    return income * 0.1;
                                                else if (income < 10000)
                                                    return income * 0.2;
                                                else
                                                    return income * 0.4;
                                            }`;

    var result = azureCosmosManagementClient->createUserDefinedFunction(databaseId, containerId, udfId, createUDFBody);
    if (result is UserDefinedFunction) {
        //udf = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["testCreateContainer", "testCreateUDF"]
}
function testReplaceUDF() {
    log:print("ACTION : replaceUDF()");

    string replace = string `function taxIncome(income){
                                                    if (income == undefined)
                                                        throw 'no input';
                                                    if (income < 1000)
                                                        return income * 0.1;
                                                    else if (income < 10000)
                                                        return income * 0.2;
                                                    else
                                                        return income * 0.4;
                                                }`;

    var result = azureCosmosManagementClient->replaceUserDefinedFunction(databaseId, containerId, udfId, replace);
    if (result is UserDefinedFunction) {
        //udf = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["testCreateContainer", "testCreateUDF"]
}
function testListAllUDF() {
    log:print("ACTION : listAllUDF()");

    var result = azureCosmosManagementClient->listUserDefinedFunctions(databaseId, containerId);
    if (result is stream<UserDefinedFunction>) {
        var userDefinedFunction = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["testReplaceUDF", "testListAllUDF"]
}
function testDeleteUDF() {
    log:print("ACTION : deleteUDF()");

    var result = azureCosmosManagementClient->deleteUserDefinedFunction(databaseId, containerId, udfId);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["testCreateContainer"]
}
function testCreateTrigger() {
    log:print("ACTION : createTrigger()");

    string createTriggerBody = string `function updateMetadata() {
                                            var context = getContext();
                                            var collection = context.getCollection();
                                            var response = context.getResponse();
                                            var createdDocument = response.getBody();

                                            // query for metadata document
                                            var filterQuery = 'SELECT * FROM root r WHERE r.id = "_metadata"';
                                            var accept = collection.queryDocuments(collection.getSelfLink(),filterQuery, 
                                                    updateMetadataCallback);
                                            if(!accept) throw "Unable to update metadata, abort";
                                        }

                                        function updateMetadataCallback(err, documents, responseOptions) {
                                            if(err) throw new Error("Error" + err.message);
                                            if(documents.length != 1) throw "Unable to find metadata document";
                                            var metadataDocument = documents[0];
                                            // update metadata
                                            metadataDocument.createdDocuments += 1;
                                            metadataDocument.createdNames += " " + createdDocument.id;
                                            var accept = collection.replaceDocument(metadataDocument._self, 
                                                    metadataDocument, function(err, docReplaced) {
                                                if(err) throw "Unable to update metadata, abort";
                                            });

                                            if(!accept) throw "Unable to update metadata, abort";
                                            return;
                                        }`;
    TriggerOperation createTriggerOperation = "All";
    TriggerType createTriggerType = "Post";

    var result = azureCosmosManagementClient->createTrigger(databaseId, containerId, triggerId, createTriggerBody, 
            createTriggerOperation, createTriggerType);
    if (result is Trigger) {
        //trigger = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["testCreateTrigger"]
}
function testReplaceTrigger() {
    log:print("ACTION : replaceTrigger()");

    string replaceTriggerBody = string `function replaceMetadata() {
                                            var context = getContext();
                                            var collection = context.getCollection();
                                            var response = context.getResponse();
                                            var createdDocument = response.getBody();

                                            // query for metadata document
                                            var filterQuery = 'SELECT * FROM root r WHERE r.id = "_metadata"';
                                            var accept = collection.queryDocuments(collection.getSelfLink(),filterQuery, 
                                                    updateMetadataCallback);
                                            if(!accept) throw "Unable to update metadata, abort";
                                        }

                                        function updateMetadataCallback(err, documents, responseOptions) {
                                            if(err) throw new Error("Error" + err.message);
                                            if(documents.length != 1) throw "Unable to find metadata document";
                                            var metadataDocument = documents[0];
                                            // update metadata
                                            metadataDocument.createdDocuments += 1;
                                            metadataDocument.createdNames += " " + createdDocument.id;
                                            var accept = collection.replaceDocument(metadataDocument._self, 
                                                    metadataDocument, function(err, docReplaced) {
                                                if(err) throw "Unable to update metadata, abort";
                                            });

                                            if(!accept) throw "Unable to update metadata, abort";
                                            return;
                                        }`;
    TriggerOperation replaceTriggerOperation = "All";
    TriggerType replaceTriggerType = "Post";

    var result = azureCosmosManagementClient->replaceTrigger(databaseId, containerId, triggerId, replaceTriggerBody, 
            replaceTriggerOperation, replaceTriggerType);
    if (result is Trigger) {
        //trigger = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["testCreateTrigger"]
}
function testListTriggers() {
    log:print("ACTION : listTriggers()");

    var result = azureCosmosManagementClient->listTriggers(databaseId, containerId);
    if (result is stream<Trigger>) {
        var doc = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["testReplaceTrigger", "testListTriggers"]
}
function testDeleteTrigger() {
    log:print("ACTION : deleteTrigger()");

    var result = azureCosmosManagementClient->deleteTrigger(databaseId, containerId, triggerId);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

//------------------------------------------MANAMGEMENT_PLANE-----------------------------------------------------------

@test:Config {
    groups: ["partitionKey"],
    dependsOn: ["testCreateContainer"]
}
function testGetPartitionKeyRanges() {
    log:print("ACTION : GetPartitionKeyRanges()");

    var result = azureCosmosManagementClient->listPartitionKeyRanges(databaseId, containerId);
    if (result is stream<PartitionKeyRange>) {
        var partitionKeyRanges = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"]
}
function testCreateUser() {
    log:print("ACTION : createUser()");

    var result = azureCosmosManagementClient->createUser(databaseId, userId);
    if (result is User) {
        //testuser = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["testCreateUser"]
}
function testReplaceUserId() {
    log:print("ACTION : replaceUserId()");
    var result = azureCosmosManagementClient->replaceUserId(databaseId, userId, newUserId);
    if (result is User) {
        //testuser = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["testCreateUser", "testReplaceUserId"]
}
function testGetUser() {
    log:print("ACTION : getUser()");

    var result = azureCosmosManagementClient->getUser(databaseId, newUserId);
    if (result is User) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"]
}
function testListUsers() {
    log:print("ACTION : listUsers()");

    var result = azureCosmosManagementClient->listUsers(databaseId);
    if (result is stream<User>) {
        var doc = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: 
    [           
        "testDeletePermission",
        "testReplaceUserId",
        "testGetUser",
        "testCreatePermission",
        "testListPermissions"
    ]
}
function testDeleteUser() {
    log:print("ACTION : deleteUser()");

    var result = azureCosmosManagementClient->deleteUser(databaseId, newUserId);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        "testListOneDatabase", 
        "testReplaceUserId"
    ]
}
function testCreatePermission() {
    log:print("ACTION : createPermission()");

    PermisssionMode permissionMode = "All";
    string permissionResource = 
            string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;

    var result = azureCosmosManagementClient->createPermission(databaseId, newUserId, permissionId, permissionMode, 
            permissionResource);
    if (result is Permission) {
        //permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        "testReplaceUserId",
        "testListOneDatabase"
    ]
}
function testCreatePermissionWithTTL() {
    log:print("ACTION : createPermission()");

    var uuid = createRandomUUIDWithoutHyphens();
    string newPermissionId = string `permission_${uuid.toString()}`;
    PermisssionMode permissionMode = "Read";
    string permissionResource = 
            string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`;
    int validityPeriod = 9000;

    var result = azureCosmosManagementClient->createPermission(databaseId, newUserId, newPermissionId, permissionMode, 
            permissionResource, validityPeriod);
    if (result is Permission) {
        //permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["testCreatePermission"]
}
function testReplacePermission() {
    log:print("ACTION : replacePermission()");

    PermisssionMode permissionMode = "All";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}`;

    var result = azureCosmosManagementClient->replacePermission(databaseId, newUserId, permissionId, permissionMode, 
            permissionResource);
    if (result is Permission) {
        //permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["testCreatePermission"]
}
function testListPermissions() {
    log:print("ACTION : listPermissions()");

    var result = azureCosmosManagementClient->listPermissions(databaseId, newUserId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
        var permission = result.next();
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["testCreatePermission"]
}
function testGetPermission() {
    log:print("ACTION : getPermission()");

    var result = azureCosmosManagementClient->getPermission(databaseId, newUserId, permissionId);
    if (result is Permission) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [  
        "testReplacePermission",
        "testGetPermission"
    ]
}
function testDeletePermission() {
    log:print("ACTION : deletePermission()");

    var result = azureCosmosManagementClient->deletePermission(databaseId, newUserId, permissionId);
    if (result is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

string? offerId = "";
string? resourceId = "";

@test:Config {
    groups: ["offer"],
    enable: false
} 
function testListOffers() {
    log:print("ACTION : listOffers()");

    var result = azureCosmosManagementClient->listOffers(3);
    if (result is stream<Offer>) {
        var offer = result.next();
        offerId = <@untainted>offer?.value?.id;
        runtime:sleep(1000);
        resourceId = offer?.value?.resourceId;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["offer"],
    dependsOn: ["testListOffers"],
    enable: false
}
function testGetOffer() {
    log:print("ACTION : getOffer()");

    if (offerId is string && offerId != "") {
        var result = azureCosmosManagementClient->getOffer(<string>offerId);
        if (result is Offer) {
            var output = "";
        } else {
            test:assertFail(msg = result.message());
        }
    } else {
        test:assertFail(msg = "Offer id is invalid");
    }
}

@test:Config {
    groups: ["offer"],
    enable: false
}
function testReplaceOffer() {
    log:print("ACTION : replaceOffer()");

    if (offerId is string && offerId != "" && resourceId is string && resourceId != "") {
        string resourceSelfLink = 
                string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`;
        Offer replaceOfferBody = {
            offerVersion: "V2",
            offerType: "Invalid",
            content: {"offerThroughput": 600},
            resourceSelfLink: resourceSelfLink,
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: <string>offerId,
            resourceId: <string>resourceId
        };
        var result = azureCosmosManagementClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result is Offer) {
            var output = "";
        } else {
            test:assertFail(msg = result.message());
        }
    } else {
        test:assertFail(msg = "Offer id  and resource ID are invalid");
    }
}

@test:Config {
    groups: ["offer"],
    enable: false
}
function testReplaceOfferWithOptionalParameter() {
    log:print("ACTION : replaceOfferWithOptionalParameter()");

    if (offerId is string && offerId != "" && resourceId is string && resourceId != "") {
        string resourceSelfLink = 
                string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`;
        Offer replaceOfferBody = {
            offerVersion: "V2",
            content: {"offerThroughput": 600},
            resourceSelfLink: resourceSelfLink,
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: <string>offerId,
            resourceId: <string>resourceId
        };
        var result = azureCosmosManagementClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result is Offer) {
            var output = "";
        } else {
            test:assertFail(msg = result.message());
        }
    } else {
        test:assertFail(msg = "Offer id  and resource ID are invalid");
    }
}

@test:Config {
    groups: ["offer"],
    dependsOn: ["testCreateContainer"],
    enable: false
}
function testQueryOffer() {
    log:print("ACTION : queryOffer()");
    string offerQuery = 
            string `SELECT * FROM ${container.id} f WHERE (f["_self"]) = "${container?.selfReference.toString()}"`;
    var result = azureCosmosManagementClient->queryOffer(offerQuery, 20);
    if (result is stream<json>) {
        var offer = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["testCreatePermission"],
    enable: false
}
function testGetCollection_Resource_Token() {
    log:print("ACTION : createCollection_Resource_Token()");

    string permissionDatabaseId = databaseId;
    string permissionUserId = newUserId;
    string userPermissionId = permissionId;

    var result = azureCosmosManagementClient->getPermission(databaseId, permissionUserId, userPermissionId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        Configuration configdb = {
            baseUrl: getConfigValue("BASE_URL"),
            masterOrResourceToken: result?.token.toString()
        };

        ManagementClient managementClient = new (configdb);

        string containerId = container.id;

        var resultdb = managementClient->getContainer(databaseId, containerId);
        if (resultdb is error) {
            test:assertFail(msg = resultdb.message());
        } else {
            var output = "";
        }
    }
}

// The `AfterSuite` function is executed after all the test functions in this module.
@test:AfterSuite {}
function afterFunc() {
    log:print("ACTION : deleteDatabases()");
    var result1 = azureCosmosManagementClient->deleteDatabase(databaseId);
    var result2 = azureCosmosManagementClient->deleteDatabase(createDatabaseExistId);

    if (result1 is DeleteResponse && result2 is DeleteResponse) {
        var output = "";
    } else {
        test:assertFail(msg = "Failed to delete one of the databases");
    }
}

isolated function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}

# Create a random UUID removing the unnecessary hyphens which will interrupt querying opearations.
# 
# + return - A string UUID without hyphens
public function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = stringutils:replace(stringUUID, "-", "");
        return stringUUID;
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
