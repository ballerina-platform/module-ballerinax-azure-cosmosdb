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
import ballerina/io;

AzureCosmosConfiguration config = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
    // tokenType: config:getAsString("TOKEN_TYPE"),
    // tokenVersion: config:getAsString("TOKEN_VERSION")
};

Client azureCosmosClient = new (config);

Database database = {};
Database manual = {};
Database auto = {};
Database ifexist = {};
Container container = {};
Document document = {};
StoredProcedure storedPrcedure = {};
UserDefinedFunction udf = {};
Trigger trigger = {};
User test_user = {};
Permission permission = {};

@test:Config {
    groups: ["database"]
}
function test_createDatabase() {
    log:print("ACTION : createDatabase()");

    var uuid = createRandomUUIDBallerina();
    string createDatabaseId = string `database_${uuid.toString()}`;

    var result = azureCosmosClient->createDatabase(createDatabaseId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        database = <@untainted>result;
    }
}

@test:Config {
    groups: ["database"]
}
function test_createDatabaseUsingInvalidId() {
    log:print("ACTION : createDatabaseUsingInvalidId()");

    string createDatabaseId = "";

    var result = azureCosmosClient->createDatabase(createDatabaseId);
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

    var uuid = createRandomUUIDBallerina();
    string createDatabaseId = string `databasee_${uuid.toString()}`;

    var result = azureCosmosClient->createDatabaseIfNotExist(createDatabaseId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        ifexist = <@untainted><Database>result;
    }
}

@test:Config {
    groups: ["database"],
    dependsOn: ["test_createDatabase"]
}
function test_createDatabaseIfExist() {
    log:print("ACTION : createDatabaseIfExist()");

    var uuid = createRandomUUIDBallerina();
    string createDatabaseId = database.id;

    var result = azureCosmosClient->createDatabaseIfNotExist(createDatabaseId);
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
function test_createDatabaseWithManualThroughput() {
    log:print("ACTION : createDatabaseWithManualThroughput()");

    var uuid = createRandomUUIDBallerina();
    string createDatabaseManualId = string `databasem_${uuid.toString()}`;
    int throughput = 1000;

    var result = azureCosmosClient->createDatabase(createDatabaseManualId, throughput);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        manual = <@untainted>result;
    }
}

@test:Config {
    groups: ["database"]
}
function test_createDatabaseWithInvalidManualThroughput() {
    log:print("ACTION : createDatabaseWithInvalidManualThroughput()");

    var uuid = createRandomUUIDBallerina();
    string createDatabaseManualId = string `databasem_${uuid.toString()}`;
    int throughput = 40;

    var result = azureCosmosClient->createDatabase(createDatabaseManualId, throughput);
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
function test_createDBWithAutoscalingThroughput() {
    log:print("ACTION : createDBWithAutoscalingThroughput()");

    var uuid = createRandomUUIDBallerina();
    string createDatabaseAutoId = string `databasea_${uuid.toString()}`;
    json maxThroughput = {"maxThroughput": 4000};

    var result = azureCosmosClient->createDatabase(createDatabaseAutoId, maxThroughput);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        auto = <@untainted>result;
    }
}

@test:Config {
    groups: ["database"]
}
function test_listAllDatabases() {
    log:print("ACTION : listAllDatabases()");

    var result = azureCosmosClient->listDatabases(6);
    if (result is stream<Database>) {
        var database = result.next();
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

    var result = azureCosmosClient->getDatabase(database.id);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["database"], 
    dependsOn: [
        "test_createDatabase", 
        "test_createDatabaseIfNotExist", 
        "test_listOneDatabase", 
        "test_createDatabase", 
        "test_getAllContainers", 
        "test_getDocumentListWithRequestOptions", 
        "test_createDocumentWithRequestOptions", 
        "test_getDocumentList", 
        "test_createCollectionWithManualThroughputAndIndexingPolicy", 
        "test_deleteDocument", 
        "test_deleteOneStoredProcedure", 
        "test_getAllStoredProcedures", 
        "test_listUsers", 
        "test_deleteUDF", 
        "test_deleteTrigger", 
        "test_deleteUser", 
        "test_createContainerIfNotExist", 
        "test_deleteContainer", 
        "test_createPermissionWithTTL",
        "test_getCollection_Resource_Token"
    ]
}
function test_deleteDatabase() {
    log:print("ACTION : deleteDatabase()");

    var result1 = azureCosmosClient->deleteDatabase(database.id);
    var result2 = azureCosmosClient->deleteDatabase(manual.id);
    var result3 = azureCosmosClient->deleteDatabase(auto.id);
    var result4 = azureCosmosClient->deleteDatabase(ifexist.id);
    if (result1 is error) {
        test:assertFail(msg = result1.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createDatabase"]
}
function test_createContainer() {
    log:print("ACTION : createContainer()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = string `container_${uuid.toString()}`;
    PartitionKey pk = {
        paths: ["/AccountNumber"],
        keyVersion: 2
    };
    var result = azureCosmosClient->createContainer(databaseId, containerId, pk);
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

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
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

    var result = azureCosmosClient->createContainer(databaseId, containerId, pk, ip, throughput);
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

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = string `container_${uuid.toString()}`;
    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosClient->createContainerIfNotExist(databaseId, containerId, pk);
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

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->getContainer(databaseId, containerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: ["test_createDatabase"]
}
function test_getAllContainers() {
    log:print("ACTION : getAllContainers()");

    var result = azureCosmosClient->listContainers(database.id);
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
        "test_getAllContainers",
        "test_getCollection_Resource_Token"
        //"test_replaceOfferWithOptionalParameter",
        //"test_replaceOffer"
    ]
}
function test_deleteContainer() {
    log:print("ACTION : deleteContainer()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->deleteContainer(databaseId, containerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["partitionKey"],
    dependsOn: ["test_createContainer"],
    enable: false
}
function test_GetPartitionKeyRanges() {
    log:print("ACTION : GetPartitionKeyRanges()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->listPartitionKeyRanges(databaseId, containerId);
    if (result is stream<PartitionKeyRange>) {
        var partitionKeyRanges = result.next();
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

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = container.id;
    int[] valueOfPartitionKey = [1234];
    Document createDoc = {
        id: string `document_${uuid.toString()}`,
        documentBody: {
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
        }
    };

    var result = azureCosmosClient->createDocument(databaseId, containerId, createDoc, valueOfPartitionKey);
    if (result is Document) {
        document = <@untainted>result;
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

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = container.id;
    DocumentCreateOptions options = {
        isUpsertRequest: true,
        indexingDirective: "Include"
    };
    int[] valueOfPartitionKey = [1234];
    Document createDoc = {
        id: string `document_${uuid.toString()}`,
        documentBody: {
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
        }
    };
    var result = azureCosmosClient->createDocument(databaseId, containerId, createDoc, valueOfPartitionKey, options);
    if (result is Document) {
        document = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createDocument"]
}
function test_getDocumentList() {
    log:print("ACTION : getDocumentList()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->getDocumentList(databaseId, containerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var singleDocument = result.next();
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createDocument"]
}
function test_getDocumentListWithRequestOptions() {
    log:print("ACTION : getDocumentListWithRequestOptions()");

    string databaseId = database.id;
    string containerId = container.id;

    DocumentListOptions options = {
        consistancyLevel: "Eventual",
        // changeFeedOption : "Incremental feed", 
        sessionToken: "tag",
        ifNoneMatchEtag: "hhh",
        partitionKeyRangeId: "0"
    };
    var result = azureCosmosClient->getDocumentList(databaseId, containerId, 10, options);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createDocument"]
}
function test_GetOneDocument() {
    log:print("ACTION : GetOneDocument()");

    string databaseId = database.id;
    string containerId = container.id;
    int[] valueOfPartitionKey = [1234];

    var result = azureCosmosClient->getDocument(databaseId, containerId, document.id, valueOfPartitionKey);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createDocument"]
}
function test_GetOneDocumentWithRequestOptions() {
    log:print("ACTION : GetOneDocumentWithRequestOptions()");

    string databaseId = database.id;
    string containerId = container.id;
    Document getDoc = {
        id: document.id
    };
    int[] valueOfPartitionKey = [1234];

    DocumentGetOptions options = {
        consistancyLevel: "Eventual",
        sessionToken: "tag",
        ifNoneMatchEtag: "hhh"
    };

    var result = azureCosmosClient->getDocument(databaseId, containerId, document.id, valueOfPartitionKey, options);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createContainer"]
}
function test_queryDocuments() {
    log:print("ACTION : queryDocuments()");

    string databaseId = database.id;
    string containerId = container.id;
    int[] partitionKey = [1234];
    string query = string `SELECT * FROM ${container.id.toString()} f WHERE f.Address.City = 'NY'`;

    var result = azureCosmosClient->queryDocuments(databaseId, containerId, query, [], 10, [1234]);
    if (result is stream<json>) {
        var document = result.next();
        io:println(document);
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
        "test_queryDocuments"
    ]
}
function test_deleteDocument() {
    log:print("ACTION : deleteDocument()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->deleteDocument(databaseId, containerId, document.id, [1234]);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: ["test_createContainer"]
}
function test_queryDocumentsWithRequestOptions() {
    log:print("ACTION : queryDocumentsWithRequestOptions()");

    string databaseId = database.id;
    string containerId = container.id;
    int[] partitionKey = [1234];
    string query = string `SELECT * FROM ${container.id.toString()} f WHERE f.Address.City = 'Seattle'`;

    ResourceQueryOptions options = {
        //sessionToken: "tag", 
        enableCrossPartition: true};

    var result = azureCosmosClient->queryDocuments(databaseId, containerId, query, [],10, (), options);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
        var document = result.next();
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_createContainer"]
}
function test_createStoredProcedure() {
    log:print("ACTION : createStoredProcedure()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = container.id;
    string createSprocBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    StoredProcedure sp = {
        id: string `sproc_${uuid.toString()}`,
        body: createSprocBody
    };

    var result = azureCosmosClient->createStoredProcedure(databaseId, containerId, sp);
    if (result is StoredProcedure) {
        storedPrcedure = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_createStoredProcedure"]
}
function test_replaceStoredProcedure() {
    log:print("ACTION : replaceStoredProcedure()");

    string databaseId = database.id;
    string containerId = container.id;

    string replaceSprocBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;
    StoredProcedure sp = {
        id: storedPrcedure.id,
        body: replaceSprocBody
    };
    var result = azureCosmosClient->replaceStoredProcedure(databaseId, containerId, sp);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_createContainer"]
}
function test_getAllStoredProcedures() {
    log:print("ACTION : getAllStoredProcedures()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->listStoredProcedures(databaseId, containerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
        var storedProcedure = result.next();
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_replaceStoredProcedure"]
}
function test_executeOneStoredProcedure() {
    log:print("ACTION : executeOneStoredProcedure()");

    string databaseId = database.id;
    string containerId = container.id;
    string executeSprocId = storedPrcedure.id;
    string[] arrayofparameters = ["Sachi"];
    StoredProcedureOptions options = {
        parameters: arrayofparameters
    };

    var result = azureCosmosClient->executeStoredProcedure(databaseId, containerId, executeSprocId, options);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: ["test_createStoredProcedure", "test_executeOneStoredProcedure", "test_getAllStoredProcedures"]
}
function test_deleteOneStoredProcedure() {
    log:print("ACTION : deleteOneStoredProcedure()");

    string databaseId = database.id;
    string containerId = container.id;
    string deleteSprocId = storedPrcedure.id;

    var result = azureCosmosClient->deleteStoredProcedure(databaseId, containerId, deleteSprocId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_createContainer"]
}
function test_createUDF() {
    log:print("ACTION : createUDF()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = container.id;
    string udfId = string `udf_${uuid.toString()}`;
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
        body: createUDFBody
    };

    var result = azureCosmosClient->createUserDefinedFunction(databaseId, containerId, createUdf);
    if (result is UserDefinedFunction) {
        udf = <@untainted>result;
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

    string databaseId = database.id;
    string containerId = container.id;
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
        id: udf.id,
        body: replaceUDFBody
    };

    var result = azureCosmosClient->replaceUserDefinedFunction(databaseId, containerId, replacementUdf);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_createContainer", "test_createUDF"]
}
function test_listAllUDF() {
    log:print("ACTION : listAllUDF()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->listUserDefinedFunctions(databaseId, containerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
        var userDefinedFunction = result.next();
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: ["test_replaceUDF", "test_listAllUDF"]
}
function test_deleteUDF() {
    log:print("ACTION : deleteUDF()");

    string deleteUDFId = udf.id;
    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->deleteUserDefinedFunction(databaseId, containerId, deleteUDFId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_createContainer"]
}
function test_createTrigger() {
    log:print("ACTION : createTrigger()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string containerId = container.id;
    string triggerId = string `trigger_${uuid.toString()}`;
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
        body: createTriggerBody,
        triggerOperation: createTriggerOperation,
        triggerType: createTriggerType
    };

    var result = azureCosmosClient->createTrigger(databaseId, containerId, createTrigger);
    if (result is Trigger) {
        trigger = <@untainted>result;
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

    string databaseId = database.id;
    string containerId = container.id;
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
        id: trigger.id,
        body: replaceTriggerBody,
        triggerOperation: replaceTriggerOperation,
        triggerType: replaceTriggerType
    };

    var result = azureCosmosClient->replaceTrigger(databaseId, containerId, replaceTrigger);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_createTrigger"]
}
function test_listTriggers() {
    log:print("ACTION : listTriggers()");

    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->listTriggers(databaseId, containerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
        var doc = result.next();
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: ["test_replaceTrigger", "test_listTriggers"]
}
function test_deleteTrigger() {
    log:print("ACTION : deleteTrigger()");

    string deleteTriggerId = trigger.id;
    string databaseId = database.id;
    string containerId = container.id;

    var result = azureCosmosClient->deleteTrigger(databaseId, containerId, deleteTriggerId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createDatabase"]
}
function test_createUser() {
    log:print("ACTION : createUser()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string userId = string `user_${uuid.toString()}`;

    var result = azureCosmosClient->createUser(databaseId, userId);
    if (result is User) {
        test_user = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createUser", "test_getUser"]
}
function test_replaceUserId() {
    log:print("ACTION : replaceUserId()");

    var uuid = createRandomUUIDBallerina();
    string newReplaceId = string `user_${uuid.toString()}`;
    string databaseId = database.id;
    string replaceUser = test_user.id;

    var result = azureCosmosClient->replaceUserId(databaseId, replaceUser, newReplaceId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        test_user = <@untainted>result;
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createUser"]
}
function test_getUser() {
    log:print("ACTION : getUser()");

    Client azureCosmosClient = new (config);
    string databaseId = database.id;
    string getUserId = test_user.id;

    var result = azureCosmosClient->getUser(databaseId, getUserId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: ["test_createUser"]
}
function test_listUsers() {
    log:print("ACTION : listUsers()");

    string databaseId = database.id;

    var result = azureCosmosClient->listUsers(databaseId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
        var doc = result.next();
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: 
    ["test_replaceUserId", "test_deletePermission", "test_createPermissionWithTTL", "test_getCollection_Resource_Token"]
}
function test_deleteUser() {
    log:print("ACTION : deleteUser()");

    string deleteUserId = test_user.id;
    string databaseId = database.id;

    var result = azureCosmosClient->deleteUser(databaseId, deleteUserId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_createDatabase", "test_createUser"]
}
function test_createPermission() {
    log:print("ACTION : createPermission()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string permissionUserId = test_user.id;
    string permissionId = string `permission_${uuid.toString()}`;
    string permissionMode = "All";
    string permissionResource = string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;
    Permission createPermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };

    var result = azureCosmosClient->createPermission(databaseId, permissionUserId, createPermission);
    if (result is Permission) {
        permission = <@untainted>result;
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_createDatabase", "test_createUser"]
}
function test_createPermissionWithTTL() {
    log:print("ACTION : createPermission()");

    var uuid = createRandomUUIDBallerina();
    string databaseId = database.id;
    string permissionUserId = test_user.id;
    string permissionId = string `permission_${uuid.toString()}`;
    string permissionMode = "All";
    string permissionResource = string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;
    int validityPeriod = 9000;
    Permission createPermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };

    var result = azureCosmosClient->createPermission(databaseId, permissionUserId, createPermission, validityPeriod);
    if (result is Permission) {
        permission = <@untainted>result;
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

    string databaseId = database.id;
    string permissionUserId = test_user.id;
    string permissionId = permission.id;
    string permissionMode = "All";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}`;
    Permission replacePermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };

    var result = azureCosmosClient->replacePermission(databaseId, permissionUserId, replacePermission);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_createPermission"]
}
function test_listPermissions() {
    log:print("ACTION : listPermissions()");

    string databaseId = database.id;
    string permissionUserId = test_user.id;

    var result = azureCosmosClient->listPermissions(databaseId, permissionUserId);
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

    string databaseId = database.id;
    string permissionUserId = test_user.id;
    string permissionId = permission.id;

    var result = azureCosmosClient->getPermission(databaseId, permissionUserId, permissionId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_getPermission", "test_listPermissions", "test_replacePermission", "test_getCollection_Resource_Token"]
}
function test_deletePermission() {
    log:print("ACTION : deletePermission()");

    string databaseId = database.id;
    string permissionUserId = test_user.id;
    string permissionId = permission.id;

    var result = azureCosmosClient->deletePermission(databaseId, permissionUserId, permissionId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        var output = "";
    }
}

string? offerId = "";
string? resourceId = "";

@test:Config {
    groups: ["offer"]
} 
function test_listOffers() {
    log:print("ACTION : listOffers()");

    var result = azureCosmosClient->listOffers(10);
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
        var result2 = azureCosmosClient->getOffer(<string>offerId);
        if (result2 is error) {
            test:assertFail(msg = result2.message());
        } else {
            var output = "";
        }
    } else {
        test:assertFail(msg = "Offer id is invalid");
    }
}

@test:Config {
    groups: ["offer"]
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
        var result2 = azureCosmosClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result2 is error) {
            test:assertFail(msg = result2.message());
        } else {
            var output = "";
        }
    } else {
        test:assertFail(msg = "Offer id  and resource ID are invalid");
    }
}

@test:Config {
    groups: ["offer"]
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
        var result2 = azureCosmosClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result2 is error) {
            test:assertFail(msg = result2.message());
        } else {
            var output = "";
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
    var result = azureCosmosClient->queryOffer(offerQuery, 20);
    if (result is stream<Offer>) {
        var offer = result.next();
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: ["test_createPermission"]
}
function test_getCollection_Resource_Token() {
    log:print("ACTION : createCollection_Resource_Token()");

    string databaseId = database.id;
    string permissionUserId = test_user.id;
    string permissionId = permission.id;

    var result = azureCosmosClient->getPermission(databaseId, permissionUserId, permissionId);
    if (result is error) {
        test:assertFail(msg = result.message());
    } else {
        if (result?.token is string) {
            AzureCosmosConfiguration configdb = {
                baseUrl: getConfigValue("BASE_URL"),
                masterOrResourceToken: result?.token.toString()
            };

            Client azureCosmosClientDatabase = new (configdb);

            string containerId = container.id;

            var resultdb = azureCosmosClientDatabase->getContainer(databaseId, containerId);
            if (resultdb is error) {
                test:assertFail(msg = resultdb.message());
            } else {
                var output = "";
            }
        }
    }
}

isolated function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}
