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
import ballerina/test;
import ballerina/config;
import ballerina/system;
import ballerina/log;
import ballerina/runtime;

AzureCosmosConfiguration clientConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

AzureCosmosManagementConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterToken: config:getAsString("MASTER_TOKEN")
};

CoreClient azureCosmosClient = new(clientConfig);
CoreManagementClient azureCosmosManagementClient = new(managementConfig);

var randomString = createRandomUUIDWithoutHyphens();

Database database = {};
string databaseId = string `database_${randomString.toString()}`;

Database manual = {};
Database auto = {};
Database ifExist = {};
Container container = {};
string containerId = string `container_${randomString.toString()}`;

Document document = {};
string documentId = string `document_${randomString.toString()}`;

string sprocId = string `sproc_${randomString.toString()}`;

string udfId = string `udf_${randomString.toString()}`;

string triggerId = string `trigger_${randomString.toString()}`;

string userId = string `user_${randomString.toString()}`;
string newUserId = string `userr_${randomString.toString()}`;

string permissionId = string `permission_${randomString.toString()}`;

@test:Config {
    groups: ["database"]
}
function test_createDatabase() {
    log:print("ACTION : createDatabase()");

    var result = azureCosmosManagementClient->createDatabase(databaseId);
    if (result is Database) {
        //database = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function test_createDatabaseUsingInvalidId() {
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
    groups: ["database"],
    dependsOn: ["test_createDatabase"]
}
function test_createDatabaseIfNotExist() {
    log:print("ACTION : createDatabaseIfNotExist()");

    var uuid = createRandomUUIDWithoutHyphens();
    string createDatabaseId = string `databasee_${uuid.toString()}`;

    var result = azureCosmosManagementClient->createDatabaseIfNotExist(createDatabaseId);
    if (result is Database?) {
        if (result is Database) {
            ifExist = <@untainted>result;
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"],
    dependsOn: ["test_createDatabase"]
}
function test_createDatabaseIfExist() {
    log:print("ACTION : createDatabaseIfExist()");

    var result = azureCosmosManagementClient->createDatabaseIfNotExist(databaseId);
    if (result is Database) {
        test:assertFail(msg = "Database with non unique id is created");
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["database"]
}
function test_createDatabaseWithManualThroughput() {
    log:print("ACTION : createDatabaseWithManualThroughput()");

    var uuid = createRandomUUIDWithoutHyphens();
    string createDatabaseManualId = string `databasem_${uuid.toString()}`;
    int throughput = 1000;

    var result = azureCosmosManagementClient->createDatabase(createDatabaseManualId, throughput);
    if (result is Database) {
        manual = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function test_createDatabaseWithInvalidManualThroughput() {
    log:print("ACTION : createDatabaseWithInvalidManualThroughput()");

    var uuid = createRandomUUIDWithoutHyphens();
    string createDatabaseManualId = string `databasem_${uuid.toString()}`;
    int throughput = 40;

    var result = azureCosmosManagementClient->createDatabase(createDatabaseManualId, throughput);
    if (result is Database) {
        test:assertFail(msg = "Database created without validating user input");
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["database"]
}
function test_createDBWithAutoscalingThroughput() {
    log:print("ACTION : createDBWithAutoscalingThroughput()");

    var uuid = createRandomUUIDWithoutHyphens();
    string createDatabaseAutoId = string `databasea_${uuid.toString()}`;
    json maxThroughput = {"maxThroughput": 4000};

    var result = azureCosmosManagementClient->createDatabase(createDatabaseAutoId, maxThroughput);
    if (result is Database) {
        auto = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function test_listAllDatabases() {
    log:print("ACTION : listAllDatabases()");

    var result = azureCosmosClient->listDatabases(6);
    if (result is stream<Database>) {
        var databaseStream = result.next();
        //io:println(databaseStream);
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"],
    dependsOn: ["test_createDatabase"]
}
function test_listOneDatabase() {
    log:print("ACTION : listOneDatabase()");

    var result = azureCosmosClient->getDatabase(databaseId);
    if (result is Database) {
        database = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"], 
    dependsOn: [
        "test_createDatabase", 
        "test_listOneDatabase", 
        "test_createDatabase", 
        "test_listAllDatabases",
        "test_getAllContainers", 
        "test_deleteContainer",
        "test_createCollectionWithManualThroughputAndIndexingPolicy",
        "test_getDocumentListWithRequestOptions", 
        "test_createDocumentWithRequestOptions", 
        "test_getDocumentList", 
        "test_deleteDocument", 
        "test_deleteOneStoredProcedure", 
        "test_getAllStoredProcedures", 
        "test_listUsers", 
        "test_deleteUDF", 
        "test_deleteTrigger", 
        "test_deleteUser",
        "test_createPermission",
        "test_createPermissionWithTTL",
        "test_createContainerIfNotExist",
        "test_deletePermission"
    ]
}
function test_deleteDatabase() {
    log:print("ACTION : deleteDatabase()");

    var result1 = azureCosmosManagementClient->deleteDatabase(databaseId);
    var result2 = azureCosmosManagementClient->deleteDatabase(manual.id);
    var result3 = azureCosmosManagementClient->deleteDatabase(auto.id);
    if (result1 is boolean && result2 is boolean && result3 is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = "Failed to delete one of the databases");
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createDatabase"]
}
function test_createContainer() {
    log:print("ACTION : createContainer()");

    PartitionKey pk = {
        paths: ["/AccountNumber"],
        keyVersion: 2
    };
    var result = azureCosmosManagementClient->createContainer(databaseId, containerId, pk);
    if (result is Container) {
        container = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createContainer"]
}
function test_createCollectionWithManualThroughputAndIndexingPolicy() {
    log:print("ACTION : createCollectionWithManualThroughputAndIndexingPolicy()");

    var uuid = createRandomUUIDWithoutHyphens();
    string containerId = string `container_${uuid.toString()}`;
    IndexingPolicy ip = {
        indexingMode: "consistent",
        automatic: true,
        includedPaths: [{
            path: "/*",
            indexes: [{
                dataType: "String",
                precision: -1,
                kind: "Range"
            }]
        }]
    };
    int throughput = 600;
    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosManagementClient->createContainer(databaseId, containerId, pk, ip, throughput);
    if (result is Container) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createDatabase", "test_getOneContainer"]
}
function test_createContainerIfNotExist() {
    log:print("ACTION : createContainerIfNotExist()");

    var uuid = createRandomUUIDWithoutHyphens();
    string containerId = string `container_${uuid.toString()}`;
    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosManagementClient->createContainerIfNotExist(databaseId, containerId, pk);
    if (result is Container?) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createContainer"]
}
function test_getOneContainer() {
    log:print("ACTION : getOneContainer()");

    var result = azureCosmosClient->getContainer(databaseId, containerId);
    if (result is Container) {
        container = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createDatabase"]
}
function test_getAllContainers() {
    log:print("ACTION : getAllContainers()");

    var result = azureCosmosClient->listContainers(databaseId);
    if (result is stream<Container>) {
        var container = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"], 
    dependsOn: [
        "test_getOneContainer", 
        "test_getAllContainers",
        "test_getDocumentList", 
        "test_deleteDocument", 
        "test_queryDocuments", 
        "test_queryDocumentsWithRequestOptions", 
        "test_getAllStoredProcedures", 
        "test_deleteOneStoredProcedure", 
        "test_listAllUDF", 
        "test_deleteUDF", 
        "test_deleteTrigger", 
        "test_GetOneDocumentWithRequestOptions", 
        "test_createDocumentWithRequestOptions", 
        "test_getDocumentListWithRequestOptions",
        "test_createPermission",
        "test_createPermissionWithTTL"
        // "test_replaceOfferWithOptionalParameter",
        // "test_replaceOffer"
    ]
}
function test_deleteContainer() {
    log:print("ACTION : deleteContainer()");

    var result = azureCosmosManagementClient->deleteContainer(databaseId, containerId);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createContainer"]
}
function test_createDocument() {
    log:print("ACTION : createDocument()");

    int[] valueOfPartitionKey = [1234];
    json documentBody = {
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

    Document newDocument = {
        id: documentId,
        documentBody: documentBody
    };

    var result = azureCosmosClient->createDocument(databaseId, containerId, newDocument, valueOfPartitionKey);
    if (result is CreationResult) {

    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createContainer"]
}
function test_createDocumentWithRequestOptions() {
    log:print("ACTION : createDocumentWithRequestOptions()");

    var uuid = createRandomUUIDWithoutHyphens();

    DocumentCreateOptions options = {
        isUpsertRequest: true,
        indexingDirective: "Include"
    };
    int[] valueOfPartitionKey = [1234];
    string id = string `document_${uuid.toString()}`;

    json documentBody = {
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
    Document newDocument = {
        id: id,
        documentBody: documentBody
    };

    var result = azureCosmosClient->createDocument(databaseId, containerId, newDocument, valueOfPartitionKey, options);
    if (result is CreationResult) {

    } else {
        test:assertFail(msg = result.message());
    }
}

// Replace document 

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createDocument"]
}
function test_getDocumentList() {
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
    dependsOn: ["test_createDocument"]
}
function test_getDocumentListWithRequestOptions() {
    log:print("ACTION : getDocumentListWithRequestOptions()");

    DocumentListOptions options = {
        consistancyLevel: "Eventual",
        // changeFeedOption : "Incremental feed", 
        sessionToken: "tag",
        ifNoneMatchEtag: "hhh",
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
    dependsOn: ["test_createDocument"]
}
function test_GetOneDocument() {
    log:print("ACTION : GetOneDocument()");

    int[] valueOfPartitionKey = [1234];
    var result = azureCosmosClient->getDocument(databaseId, containerId, documentId, valueOfPartitionKey);
    if (result is Document) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createDocument"]
}
function test_GetOneDocumentWithRequestOptions() {
    log:print("ACTION : GetOneDocumentWithRequestOptions()");

    int[] valueOfPartitionKey = [1234];

    DocumentGetOptions options = {
        consistancyLevel: "Eventual",
        sessionToken: "tag",
        ifNoneMatchEtag: "hhh"
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
    dependsOn: ["test_createContainer"]
}
function test_queryDocuments() {
    log:print("ACTION : queryDocuments()");

    int[] partitionKey = [1234];
    string query = string `SELECT * FROM ${container.id.toString()} f WHERE f.Address.City = 'NY'`;

    var result = azureCosmosClient->queryDocuments(databaseId, containerId, query, [], 10, [1234]);
    if (result is stream<json>) {
        var document = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createContainer"]
}
function test_queryDocumentsWithRequestOptions() {
    log:print("ACTION : queryDocumentsWithRequestOptions()");

    int[] partitionKey = [1234];
    string query = string `SELECT * FROM ${containerId} f WHERE f.Address.City = 'Seattle'`;

    ResourceQueryOptions options = {
        //sessionToken: "tag", 
        enableCrossPartition: true};

    var result = azureCosmosClient->queryDocuments(databaseId, containerId, query, [],10, (), options);
    if (result is stream<json>) {
        var document = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"], 
    dependsOn: [
        "test_createContainer", 
        "test_createDocument", 
        "test_GetOneDocument", 
        "test_GetOneDocumentWithRequestOptions", 
        "test_queryDocuments",
        "test_getDocumentList"
    ]
}
function test_deleteDocument() {
    log:print("ACTION : deleteDocument()");

    var result = azureCosmosClient->deleteDocument(databaseId, containerId, documentId, [1234]);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_createContainer"]
}
function test_createStoredProcedure() {
    log:print("ACTION : createStoredProcedure()");

    string createSprocBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    StoredProcedure sp = {
        id: sprocId,
        storedProcedure: createSprocBody
    };

    var result = azureCosmosClient->createStoredProcedure(databaseId, containerId, sp);
    if (result is CreationResult) {
        //storedPrcedure = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_createStoredProcedure", "test_getAllStoredProcedures"]
}
function test_replaceStoredProcedure() {
    log:print("ACTION : replaceStoredProcedure()");

    string replaceSprocBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                    }`;
    StoredProcedure sp = {
        id: sprocId,
        storedProcedure: replaceSprocBody
    };
    var result = azureCosmosClient->replaceStoredProcedure(databaseId, containerId, sp);
    if (result is CreationResult) {
        //storedPrcedure = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_replaceStoredProcedure"
]
}
function test_executeOneStoredProcedure() {
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
    dependsOn: ["test_createContainer"]
}
function test_getAllStoredProcedures() {
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
        "test_createStoredProcedure", 
        "test_executeOneStoredProcedure"    
    ]
}
function test_deleteOneStoredProcedure() {
    log:print("ACTION : deleteOneStoredProcedure()");

    var result = azureCosmosClient->deleteStoredProcedure(databaseId, containerId, sprocId);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_createContainer"]
}
function test_createUDF() {
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
    UserDefinedFunction createUdf = {
        id: udfId,
        userDefinedFunction: createUDFBody
    };

    var result = azureCosmosClient->createUserDefinedFunction(databaseId, containerId, createUdf);
    if (result is CreationResult) {
        //udf = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_createContainer", "test_createUDF"]
}
function test_replaceUDF() {
    log:print("ACTION : replaceUDF()");

    string replaceUDFBody = string `function taxIncome(income){
                                                    if (income == undefined)
                                                        throw 'no input';
                                                    if (income < 1000)
                                                        return income * 0.1;
                                                    else if (income < 10000)
                                                        return income * 0.2;
                                                    else
                                                        return income * 0.4;
                                                }`;
    UserDefinedFunction replacementUdf = {
        id: udfId,
        userDefinedFunction: replaceUDFBody
    };

    var result = azureCosmosClient->replaceUserDefinedFunction(databaseId, containerId, replacementUdf);
    if (result is CreationResult) {
        //udf = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_createContainer", "test_createUDF"]
}
function test_listAllUDF() {
    log:print("ACTION : listAllUDF()");

    var result = azureCosmosClient->listUserDefinedFunctions(databaseId, containerId);
    if (result is stream<UserDefinedFunction>) {
        var userDefinedFunction = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_replaceUDF", "test_listAllUDF"]
}
function test_deleteUDF() {
    log:print("ACTION : deleteUDF()");

    var result = azureCosmosClient->deleteUserDefinedFunction(databaseId, containerId, udfId);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_createContainer"]
}
function test_createTrigger() {
    log:print("ACTION : createTrigger()");

    string createTriggerBody = string `function updateMetadata() {
                                            var context = getContext();
                                            var collection = context.getCollection();
                                            var response = context.getResponse();
                                            var createdDocument = response.getBody();

                                            // query for metadata document
                                            var filterQuery = 'SELECT * FROM root r WHERE r.id = "_metadata"';
                                            var accept = collection.queryDocuments(collection.getSelfLink(), filterQuery, updateMetadataCallback);
                                            if(!accept) throw "Unable to update metadata, abort";
                                        }

                                        function updateMetadataCallback(err, documents, responseOptions) {
                                            if(err) throw new Error("Error" + err.message);
                                            if(documents.length != 1) throw "Unable to find metadata document";
                                            var metadataDocument = documents[0];
                                            // update metadata
                                            metadataDocument.createdDocuments += 1;
                                            metadataDocument.createdNames += " " + createdDocument.id;
                                            var accept = collection.replaceDocument(metadataDocument._self, metadataDocument, function(err, docReplaced) {
                                                if(err) throw "Unable to update metadata, abort";
                                            });

                                            if(!accept) throw "Unable to update metadata, abort";
                                            return;
                                        }`;
    string createTriggerOperation = "All";
    string createTriggerType = "Post";
    Trigger createTrigger = {
        id: triggerId,
        triggerFunction: createTriggerBody,
        triggerOperation: createTriggerOperation,
        triggerType: createTriggerType
    };

    var result = azureCosmosClient->createTrigger(databaseId, containerId, createTrigger);
    if (result is CreationResult) {
        //trigger = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_createTrigger"]
}
function test_replaceTrigger() {
    log:print("ACTION : replaceTrigger()");

    string replaceTriggerBody = string `function replaceMetadata() {
                                            var context = getContext();
                                            var collection = context.getCollection();
                                            var response = context.getResponse();
                                            var createdDocument = response.getBody();

                                            // query for metadata document
                                            var filterQuery = 'SELECT * FROM root r WHERE r.id = "_metadata"';
                                            var accept = collection.queryDocuments(collection.getSelfLink(), filterQuery, updateMetadataCallback);
                                            if(!accept) throw "Unable to update metadata, abort";
                                        }

                                        function updateMetadataCallback(err, documents, responseOptions) {
                                            if(err) throw new Error("Error" + err.message);
                                            if(documents.length != 1) throw "Unable to find metadata document";
                                            var metadataDocument = documents[0];
                                            // update metadata
                                            metadataDocument.createdDocuments += 1;
                                            metadataDocument.createdNames += " " + createdDocument.id;
                                            var accept = collection.replaceDocument(metadataDocument._self, metadataDocument, function(err, docReplaced) {
                                                if(err) throw "Unable to update metadata, abort";
                                            });

                                            if(!accept) throw "Unable to update metadata, abort";
                                            return;
                                        }`;
    string replaceTriggerOperation = "All";
    string replaceTriggerType = "Post";
    Trigger replaceTrigger = {
        id: triggerId,
        triggerFunction: replaceTriggerBody,
        triggerOperation: replaceTriggerOperation,
        triggerType: replaceTriggerType
    };

    var result = azureCosmosClient->replaceTrigger(databaseId, containerId, replaceTrigger);
    if (result is CreationResult) {
        //trigger = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_createTrigger"]
}
function test_listTriggers() {
    log:print("ACTION : listTriggers()");

    var result = azureCosmosClient->listTriggers(databaseId, containerId);
    if (result is stream<Trigger>) {
        var doc = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_replaceTrigger", "test_listTriggers"]
}
function test_deleteTrigger() {
    log:print("ACTION : deleteTrigger()");

    var result = azureCosmosClient->deleteTrigger(databaseId, containerId, triggerId);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

//------------------------------------------MANAMGEMENT_PLANE-----------------------------------------------------------

@test:Config {
    groups: ["partitionKey"],
    dependsOn: ["test_createContainer"],
    enable: false
}
function test_GetPartitionKeyRanges() {
    log:print("ACTION : GetPartitionKeyRanges()");

    var result = azureCosmosManagementClient->listPartitionKeyRanges(databaseId, containerId);
    if (result is stream<PartitionKeyRange>) {
        var partitionKeyRanges = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createDatabase"]
}
function test_createUser() {
    log:print("ACTION : createUser()");

    var result = azureCosmosManagementClient->createUser(databaseId, userId);
    if (result is CreationResult) {
        //test_user = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createUser"]
}
function test_replaceUserId() {
    log:print("ACTION : replaceUserId()");
    var result = azureCosmosManagementClient->replaceUserId(databaseId, userId, newUserId);
    if (result is CreationResult) {
        //test_user = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createUser", "test_replaceUserId"]
}
function test_getUser() {
    log:print("ACTION : getUser()");

    var result = azureCosmosManagementClient->getUser(databaseId, newUserId);
    if (result is User) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createDatabase"]
}
function test_listUsers() {
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
        "test_deletePermission",
        "test_replaceUserId",
        "test_getUser",
        "test_createPermission",
        "test_listPermissions"
    ]
}
function test_deleteUser() {
    log:print("ACTION : deleteUser()");

    var result = azureCosmosManagementClient->deleteUser(databaseId, newUserId);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        "test_createDatabase",
        "test_listOneDatabase", 
        "test_replaceUserId"
    ]
}
function test_createPermission() {
    log:print("ACTION : createPermission()");

    string permissionMode = "All";
    string permissionResource = string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;
    Permission createPermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };

    var result = azureCosmosManagementClient->createPermission(databaseId, newUserId, createPermission);
    if (result is CreationResult) {
        //permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        "test_createDatabase", 
        "test_replaceUserId",
        "test_listOneDatabase"
    ]
}
function test_createPermissionWithTTL() {
    log:print("ACTION : createPermission()");

    var uuid = createRandomUUIDWithoutHyphens();
    string newPermissionId = string `permission_${uuid.toString()}`;
    string permissionMode = "Read";
    string permissionResource = string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`;
    int validityPeriod = 9000;
    Permission createPermission = {
        id: newPermissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };

    var result = azureCosmosManagementClient->createPermission(databaseId, newUserId, createPermission, validityPeriod);
    if (result is CreationResult) {
        //permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_createPermission"]
}
function test_replacePermission() {
    log:print("ACTION : replacePermission()");

    string permissionMode = "All";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}`;
    Permission replacePermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };

    var result = azureCosmosManagementClient->replacePermission(databaseId, newUserId, replacePermission);
    if (result is CreationResult) {
        //permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_createPermission"]
}
function test_listPermissions() {
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
    dependsOn: ["test_createPermission"]
}
function test_getPermission() {
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
        "test_replacePermission",
        "test_getPermission"
    ]
}
function test_deletePermission() {
    log:print("ACTION : deletePermission()");

    var result = azureCosmosManagementClient->deletePermission(databaseId, newUserId, permissionId);
    if (result is boolean) {
        var output = "";
    } else {
        test:assertFail(msg = result.message());
    }
}

string? offerId = "";
string? resourceId = "";

@test:Config {
    groups: ["offer"]
} 
function test_listOffers() {
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
    dependsOn: ["test_listOffers"]
}
function test_getOffer() {
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
function test_replaceOffer() {
    log:print("ACTION : replaceOffer()");

    if (offerId is string && offerId != "" && resourceId is string && resourceId != "") {
        Offer replaceOfferBody = {
            offerVersion: "V2",
            offerType: "Invalid",
            content: {"offerThroughput": 600},
            resourceSelfLink: string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`,
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: <string>offerId,
            resourceId: <string>resourceId
        };
        var result = azureCosmosManagementClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result is CreationResult) {
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
function test_replaceOfferWithOptionalParameter() {
    log:print("ACTION : replaceOfferWithOptionalParameter()");

    if (offerId is string && offerId != "" && resourceId is string && resourceId != "") {
        Offer replaceOfferBody = {
            offerVersion: "V2",
            content: {"offerThroughput": 600},
            resourceSelfLink: string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`,
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: <string>offerId,
            resourceId: <string>resourceId
        };
        var result = azureCosmosManagementClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result is CreationResult) {
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
    dependsOn: ["test_createDatabase", "test_createContainer"]
}
function test_queryOffer() {
    log:print("ACTION : queryOffer()");
    Query offerQuery = {query: string `SELECT * FROM ${container.id} f WHERE (f["_self"]) = "${container?.selfReference.
        toString()}"`};
    var result = azureCosmosManagementClient->queryOffer(offerQuery, 20);
    if (result is stream<json>) {
        var offer = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

// @test:Config {
//     groups: ["permission"],
//     dependsOn: ["test_createPermission"]
// }
// function test_getCollection_Resource_Token() {
//     log:print("ACTION : createCollection_Resource_Token()");

//     string databaseId = database.id;
//     string permissionUserId = test_user.id;
//     string permissionId = permission.id;

//     var result = azureCosmosManagementClient->getPermission(databaseId, permissionUserId, permissionId);
//     if (result is error) {
//         test:assertFail(msg = result.message());
//     } else {
//         if (result?.token is string) {
//             AzureCosmosConfiguration configdb = {
//                 baseUrl: getConfigValue("BASE_URL"),
//                 masterOrResourceToken: result?.token.toString()
//             };

//             CoreClient azureCosmosClientDatabase = new (configdb);

//             string containerId = container.id;

//             var resultdb = azureCosmosClientDatabase->getContainer(databaseId, containerId);
//             if (resultdb is error) {
//                 test:assertFail(msg = resultdb.message());
//             } else {
//                 var output = "";
//             }
//         }
//     }
// }

isolated function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}
