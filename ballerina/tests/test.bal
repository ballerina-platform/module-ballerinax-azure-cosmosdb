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

import ballerina/jballerina.java;
import ballerina/lang.runtime;
import ballerina/lang.'string;
import ballerina/log;
import ballerina/os;
import ballerina/regex;
import ballerina/test;

configurable string & readonly baseURL = os:getEnv("BASE_URL");
configurable string & readonly primaryKey = os:getEnv("MASTER_OR_RESOURCE_TOKEN");

ConnectionConfig config = {
    baseUrl: baseURL,
    primaryKeyOrResourceToken: primaryKey
};

ManagementClientConfig mgtClientConfig = {
    baseUrl: baseURL,
    primaryKeyOrResourceToken: primaryKey
};

DataPlaneClient azureCosmosClient = check new (config);
ManagementClient azureCosmosManagementClient = check new (mgtClientConfig);

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
Container container = {id: "", indexingPolicy: {indexingMode: NONE}, partitionKey: {}};

int AccountNumber = 1234;

@test:BeforeSuite
function testCreateDatabase() {
    log:printInfo("ACTION : createDatabase()");

    var result = azureCosmosManagementClient->createDatabase(databaseId);
    if (result is Database) {
        test:assertTrue(result.id == databaseId);
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testCreateDatabaseUsingInvalidId() {
    log:printInfo("ACTION : createDatabaseUsingInvalidId()");

    string createDatabaseId = "";
    var result = azureCosmosManagementClient->createDatabase(createDatabaseId);
    if (result is Database) {
        test:assertFail(msg = "Database created with '' id value");
    } else {
        test:assertTrue(true);
    }
}

@test:Config {
    groups: ["database"]
}
function testCreateDatabaseIfNotExist() {
    log:printInfo("ACTION : createDatabaseIfNotExist()");

    var result = azureCosmosManagementClient->createDatabaseIfNotExist(createDatabaseExistId);
    if (result is Database?) {
        test:assertTrue(result?.id == createDatabaseExistId || result is ());
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testCreateDatabaseIfExist() {
    log:printInfo("ACTION : createDatabaseIfExist()");

    var result = azureCosmosManagementClient->createDatabaseIfNotExist(databaseId);
    if (result is Database) {
        test:assertFail(msg = "Database with non unique id is created");
    } else {
        test:assertTrue(true);
    }
}

@test:Config {
    groups: ["database"],
    enable: false
}
function testCreateDatabaseWithManualThroughput() {
    log:printInfo("ACTION : createDatabaseWithManualThroughput()");
    int throughput = 1000;

    var result = azureCosmosManagementClient->createDatabase(createDatabaseManualId, throughput);
    if (result is Database) {
        test:assertTrue(result.id == createDatabaseManualId);
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"],
    enable: false
}
function testCreateDatabaseWithInvalidManualThroughput() {
    log:printInfo("ACTION : createDatabaseWithInvalidManualThroughput()");
    int throughput = 40;

    var result = azureCosmosManagementClient->createDatabase(createDatabaseManualId, throughput);
    if (result is Database) {
        test:assertFail(msg = "Database created without validating user input");
    } else {
        test:assertTrue(true);
    }
}

@test:Config {
    groups: ["database"],
    enable: false
}
function testCreateDBWithAutoscalingThroughput() {
    log:printInfo("ACTION : createDBWithAutoscalingThroughput()");
    record {|int maxThroughput;|} maxThroughput = {maxThroughput: 4000};

    var result = azureCosmosManagementClient->createDatabase(createDatabaseAutoId, maxThroughput);
    if (result is Database) {
        test:assertTrue(result.id == createDatabaseAutoId);
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testListAllDatabases() {
    log:printInfo("ACTION : listAllDatabases()");

    var result = azureCosmosManagementClient->listDatabases();
    if (result is stream<Database, error?>) {
        error? e = result.forEach(isolated function(Database queryResult) {
            log:printInfo(queryResult.toString());
        });
        if (e is error) {
            log:printInfo(msg = e.message());
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["database"]
}
function testGetOneDatabase() {
    log:printInfo("ACTION : listOneDatabase()");

    var result = azureCosmosManagementClient->getDatabase(databaseId);
    if (result is Database) {
        database = <@untainted>result;
        test:assertTrue(result.id == databaseId);
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"]
}
function testCreateContainer() {
    log:printInfo("ACTION : createContainer()");

    PartitionKey pk = {
        paths: ["/AccountNumber"],
        keyVersion: 2
    };
    var result = azureCosmosManagementClient->createContainer(databaseId, containerId, pk);
    if (result is Container) {
        test:assertTrue(result.id == containerId);
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: [testCreateContainer]
}
function testCreateCollectionWithManualThroughputAndIndexingPolicy() {
    log:printInfo("ACTION : createCollectionWithManualThroughputAndIndexingPolicy()");

    IndexingPolicy ip = {
        indexingMode: "consistent",
        automatic: true,
        includedPaths: [
            {
                path: "/*",
                indexes: [
                    {
                        dataType: STRING,
                        precision: -1,
                        kind: "Range"
                    }
                ]
            }
        ]
    };
    //int throughput = 600;
    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosManagementClient->createContainer(databaseId, containerWithOptionsId, pk, ip);
    if (result is Error) {
        test:assertFail("Container with options is not created");
    } else {
        test:assertTrue(result.id == containerWithOptionsId);
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: [testGetOneContainer]
}
function testCreateContainerIfNotExist() {
    log:printInfo("ACTION : createContainerIfNotExist()");

    PartitionKey pk = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var result = azureCosmosManagementClient->createContainerIfNotExist(databaseId, containerIfNotExistId, pk);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result?.id == containerIfNotExistId || result is ());
    }
}

@test:Config {
    groups: ["container"],
    dependsOn: [testCreateContainer]
}
function testGetOneContainer() {
    log:printInfo("ACTION : getOneContainer()");

    var result = azureCosmosManagementClient->getContainer(databaseId, containerId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        container = <@untainted>result;
        test:assertTrue(result.id == containerId);
    }
}

@test:Config {
    groups: ["container"]
}
function testGetAllContainers() {
    log:printInfo("ACTION : getAllContainers()");

    var result = azureCosmosManagementClient->listContainers(databaseId);
    if (result is stream<Container, error?>) {
        error? e = result.forEach(isolated function(Container queryResult) {
            log:printInfo(queryResult.toString());
        });
        if (e is error) {
            log:printInfo(msg = e.message());
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

// If we want to get information about offers, First we need to have any offers in the account. So enable them when
// using  a provisioned throughput account
@test:Config {
    groups: ["container"],
    dependsOn: [
        testGetOneContainer,
        testGetAllContainers,
        testGetDocumentList,
        testDeleteDocument,
        testQueryDocuments,
        testQueryDocumentsWithRequestOptions,
        testGetOneDocumentWithRequestOptions,
        testCreateDocumentWithRequestOptions,
        testGetDocumentListWithRequestOptions,
        testGetAllStoredProcedures,
        testDeleteOneStoredProcedure,
        testListAllUDF,
        testDeleteUDF,
        testDeleteTrigger,
        testCreatePermission,
        testCreatePermissionWithTTL,
        testGetPartitionKeyRanges,
        testListOffers,
        testGetOffer,
        testReplaceOfferWithOptionalParameter,
        testReplaceOffer
    ]
}
function testDeleteContainer() {
    log:printInfo("ACTION : deleteContainer()");

    var result = azureCosmosManagementClient->deleteContainer(databaseId, containerId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateContainer]
}
function testCreateDocument() returns error? {
    log:printInfo("ACTION : createDocument()");

    int valueOfPartitionKey = 1234;
    map<json> documentBody = {
        "LastName": "Thaulow",
        "Parents": [
            {
                "FamilyName": null,
                "FirstName": "Thomas"
            },
            {
                "FamilyName": null,
                "FirstName": "Mary"
            }
        ],
        "Children": [
            {
                "FamilyName": null,
                "FirstName": "Henriette",
                "Gender": "female",
                "Grade": 5,
                "Pets": [{"GivenName": "Fluffy"}]
            }
        ],
        "Address": {
            "State": "WA",
            "Country": "King",
            "City": "Seattle"
        },
        "IsRegistered": true,
        "AccountNumber": 1234
    };

    DocumentResponse response = check azureCosmosClient->createDocument(databaseId, containerId, documentId, documentBody, valueOfPartitionKey);
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["document"],
    dependsOn: [
        testGetOneDocument,
        testGetOneDocumentWithRequestOptions,
        testQueryDocuments,
        testGetDocumentList,
        testGetDocumentListWithRequestOptions
    ]
}
function testReplaceDocument() returns error? {
    log:printInfo("ACTION : replaceDocument()");

    int valueOfPartitionKey = 1234;
    map<json> documentBody = {
        "LastName": "Mark",
        "AccountNumber": 1234
    };

    DocumentResponse response = check azureCosmosClient->replaceDocument(databaseId, containerId, documentId, documentBody, valueOfPartitionKey);
    test:assertEquals(response.statusCode, 200);
}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateContainer]
}
function testReplaceDocumentID() returns error? {
    log:printInfo("ACTION : replaceDocumentID()");

    int valueOfPartitionKey = 1234;
    string documentId = string `document_${randomString.toString()}`;
    map<json> documentBody = {
        "LastName": "Einstein",
        "Parents": [
            {
                "FamilyName": null,
                "FirstName": "Hermann"
            },
            {
                "FamilyName": null,
                "FirstName": "Pauline"
            }
        ],
        "Children": [
            {
                "FamilyName": null,
                "FirstName": "Hans",
                "Gender": "male",
                "Grade": 5,
                "Pets": [{"GivenName": "Pumpkin"}]
            }
        ],
        "Address": {
            "State": "WA",
            "Country": "King",
            "City": "Seattle"
        },
        "IsRegistered": true,
        "AccountNumber": 1234
    };

    DocumentResponse createResponse = check azureCosmosClient->createDocument(databaseId, containerId, documentId, documentBody, valueOfPartitionKey);
    test:assertEquals(createResponse.statusCode, 201);

    map<json> updatedDocumentBody = {
        "LastName": "Antony",
        "AccountNumber": 1234,
        "id": "new_document_123"
    };

    DocumentResponse updateResponse = check azureCosmosClient->replaceDocument(databaseId, containerId, documentId, updatedDocumentBody, valueOfPartitionKey);
    test:assertEquals(updateResponse.statusCode, 200);
}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateContainer]
}
function testCreateDocumentWithRequestOptions() returns error? {
    log:printInfo("ACTION : createDocumentWithRequestOptions()");

    var uuid = createRandomUUIDWithoutHyphens();

    RequestOptions options = {
        indexingDirective: "Include"
    };
    int valueOfPartitionKey = 1234;
    string newDocumentId = string `document_${uuid.toString()}`;
    map<json> documentBody = {
        "LastName": "Throne",
        "Parents": [
            {
                "FamilyName": null,
                "FirstName": "Thomas"
            },
            {
                "FamilyName": null,
                "FirstName": "Mary"
            }
        ],
        "Children": [
            {
                "FamilyName": null,
                "FirstName": "Henriette",
                "Gender": "female",
                "Grade": 5,
                "Pets": [{"GivenName": "Fluffy"}]
            }
        ],
        "Address": {
            "State": "WA",
            "Country": "King",
            "City": "Seattle"
        },
        "IsRegistered": true,
        "AccountNumber": 1234
    };

    DocumentResponse response = check azureCosmosClient->createDocument(databaseId, containerId, newDocumentId, documentBody, valueOfPartitionKey, options);
    test:assertEquals(response.statusCode, 201);
}

public type Person record {
    string LastName;
    int AccountNumber;
    Children[] Children;
    record {|string State; string Country; string City;|} Address;
};

public type Children record {
    string? FamilyName?;
    string? FirstName?;
    Pet[] Pets?;
};

public type Pet record {
    string GivenName;
};

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateDocument, testCreateDocumentWithRequestOptions]
}
function testGetDocumentList() returns error? {
    log:printInfo("ACTION : getDocumentList()");
    int valueOfPartitionKey = 1234;
    stream<Person, error?> result = check azureCosmosClient->getDocumentList(databaseId, containerId,
    valueOfPartitionKey);
    check result.forEach(isolated function(Person queryResult) {
        test:assertEquals(1234, queryResult.AccountNumber);
    });
}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateDocument, testCreateDocumentWithRequestOptions]
}
function testGetDocumentListWithRequestOptions() returns error? {
    log:printInfo("ACTION : getDocumentListWithRequestOptions()");
    int valueOfPartitionKey = 1234;
    QueryOptions options = {
        consistencyLevel: EVENTUAL
    };
    stream<Person, error?> result = check azureCosmosClient->getDocumentList(databaseId, containerId,
    valueOfPartitionKey, options);
    check result.forEach(isolated function(Person queryResult) {
        test:assertEquals(1234, queryResult.AccountNumber);
    });

}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateDocument]
}
function testGetOneDocument() returns error? {
    log:printInfo("ACTION : GetOneDocument()");

    int valueOfPartitionKey = 1234;
    Person result = check azureCosmosClient->getDocument(databaseId, containerId, documentId, valueOfPartitionKey);
    test:assertEquals(AccountNumber, result.AccountNumber);
}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateDocument]
}
function testGetOneDocumentWithRequestOptions() returns error? {
    log:printInfo("ACTION : GetOneDocumentWithRequestOptions()");

    int valueOfPartitionKey = 1234;

    RequestOptions options = {
        consistancyLevel: EVENTUAL,
        sessionToken: "tag"
    };

    Person result = check azureCosmosClient->getDocument(databaseId, containerId, documentId, valueOfPartitionKey, options);
    test:assertEquals(AccountNumber, result.AccountNumber);
}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateContainer]
}
function testQueryDocuments() returns error? {
    log:printInfo("ACTION : queryDocuments()");

    string query = string `SELECT * FROM ${container.id.toString()} f WHERE f.Address.City = 'Seattle'`;

    stream<Person, error?> result = check azureCosmosClient->queryDocuments(databaseId, containerId, query);
    check result.forEach(isolated function(Person queryResult) {
        test:assertEquals("Seattle", queryResult.Address.City);
    });

}

@test:Config {
    groups: ["document"],
    dependsOn: [testCreateContainer]
}
function testQueryDocumentsWithRequestOptions() returns error? {
    log:printInfo("ACTION : queryDocumentsWithRequestOptions()");

    string query = string `SELECT * FROM ${containerId} f WHERE f.Address.City = 'Seattle'`;

    QueryOptions options = {
        indexMetricsEnabled: true
    };

    stream<Person, error?> result = check azureCosmosClient->queryDocuments(databaseId, containerId, query, options);
    check result.forEach(isolated function(Person queryResult) {
        test:assertEquals("Seattle", queryResult.Address.City);
    });
}

@test:Config {
    groups: ["document"],
    dependsOn: [
        testCreateContainer,
        testCreateDocument,
        testGetOneDocument,
        testGetOneDocumentWithRequestOptions,
        testQueryDocuments,
        testGetDocumentList,
        testGetDocumentListWithRequestOptions,
        testReplaceDocument
    ]
}
function testDeleteDocument() returns error? {
    log:printInfo("ACTION : deleteDocument()");

    DocumentResponse response = check azureCosmosClient->deleteDocument(databaseId, containerId, documentId, 1234);
    test:assertEquals(response.statusCode, 204);
}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: [testCreateContainer]
}
function testCreateStoredProcedure() returns error? {
    log:printInfo("ACTION : createStoredProcedure()");

    string createSprocBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello, World");
                                        }`;

    StoredProcedureResponse response = check azureCosmosClient->createStoredProcedure(databaseId, containerId, sprocId,
    createSprocBody);
    test:assertEquals(response.statusCode, 201);
}

@test:Config {
    groups: ["storedProcedure"]
}
function testExecuteOneStoredProcedure() returns error? {
    log:printInfo("ACTION : executeOneStoredProcedure()");

    string[] arrayofparameters = ["Sachi"];
    StoredProcedureExecuteOptions options = {
        parameters: arrayofparameters
    };
    int partitionKey = 1234;

    _ = check azureCosmosClient->executeStoredProcedure(databaseId, containerId, sprocId, partitionKey, options);

}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: [testCreateContainer]
}
function testGetAllStoredProcedures() returns error? {
    log:printInfo("ACTION : getAllStoredProcedures()");

    stream<StoredProcedure, error?> result = check azureCosmosClient->listStoredProcedures(databaseId, containerId);
    check result.forEach(isolated function(StoredProcedure queryResult) {
        log:printInfo(queryResult.id);
    });

}

@test:Config {
    groups: ["storedProcedure"],
    dependsOn: [
        testCreateStoredProcedure,
        testExecuteOneStoredProcedure
    ]
}
function testDeleteOneStoredProcedure() returns error? {
    log:printInfo("ACTION : deleteOneStoredProcedure()");

    _ = check azureCosmosClient->deleteStoredProcedure(databaseId, containerId, sprocId);

}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: [testCreateContainer]
}
function testCreateUDF() {
    log:printInfo("ACTION : createUDF()");

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
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == udfId);
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: [testCreateContainer, testCreateUDF]
}
function testReplaceUDF() {
    log:printInfo("ACTION : replaceUDF()");

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
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == udfId);
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: [testCreateContainer, testCreateUDF]
}
function testListAllUDF() {
    log:printInfo("ACTION : listAllUDF()");

    var result = azureCosmosManagementClient->listUserDefinedFunctions(databaseId, containerId);
    if (result is stream<UserDefinedFunction, error?>) {
        error? e = result.forEach(isolated function(UserDefinedFunction queryResult) {
            log:printInfo(queryResult.toString());
        });
        if (e is error) {
            log:printInfo(msg = e.message());
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["userDefinedFunction"],
    dependsOn: [testReplaceUDF, testListAllUDF]
}
function testDeleteUDF() {
    log:printInfo("ACTION : deleteUDF()");

    var result = azureCosmosManagementClient->deleteUserDefinedFunction(databaseId, containerId, udfId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }
    test:assertTrue(true);
}

@test:Config {
    groups: ["trigger"],
    dependsOn: [testCreateContainer]
}
function testCreateTrigger() {
    log:printInfo("ACTION : createTrigger()");

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
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == triggerId);
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: [testCreateTrigger]
}
function testReplaceTrigger() {
    log:printInfo("ACTION : replaceTrigger()");

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
                                            if(err) throw new error("error" + err.message);
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
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == triggerId);
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: [testCreateTrigger]
}
function testListTriggers() {
    log:printInfo("ACTION : listTriggers()");

    var result = azureCosmosManagementClient->listTriggers(databaseId, containerId);
    if (result is stream<Trigger, error?>) {
        error? e = result.forEach(isolated function(Trigger queryResult) {
            log:printInfo(queryResult.toString());
        });
        if (e is error) {
            log:printInfo(msg = e.message());
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["trigger"],
    dependsOn: [testReplaceTrigger, testListTriggers]
}
function testDeleteTrigger() {
    log:printInfo("ACTION : deleteTrigger()");

    var result = azureCosmosManagementClient->deleteTrigger(databaseId, containerId, triggerId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }
    test:assertTrue(true);
}

//------------------------------------------MANAMGEMENT_PLANE---------------------------------------------------------//

@test:Config {
    groups: ["partitionKey"],
    dependsOn: [testCreateContainer]
}
function testGetPartitionKeyRanges() {
    log:printInfo("ACTION : GetPartitionKeyRanges()");

    var result = azureCosmosManagementClient->listPartitionKeyRanges(databaseId, containerId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"]
}
function testCreateUser() {
    log:printInfo("ACTION : createUser()");

    var result = azureCosmosManagementClient->createUser(databaseId, userId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == userId);
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: [testCreateUser]
}
function testReplaceUserId() {
    log:printInfo("ACTION : replaceUserId()");
    var result = azureCosmosManagementClient->replaceUserId(databaseId, userId, newUserId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == newUserId);
    }
}

@test:Config {
    groups: ["user"],
    dependsOn: [testCreateUser, testReplaceUserId]
}
function testGetUser() {
    log:printInfo("ACTION : getUser()");

    var result = azureCosmosManagementClient->getUser(databaseId, newUserId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == newUserId);
    }
}

@test:Config {
    groups: ["user"]
}
function testListUsers() {
    log:printInfo("ACTION : listUsers()");

    var result = azureCosmosManagementClient->listUsers(databaseId);
    if (result is stream<User, error?>) {
        error? e = result.forEach(isolated function(User queryResult) {
            log:printInfo(queryResult.toString());
        });
        if (e is error) {
            log:printInfo(msg = e.message());
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["user"],
    dependsOn:
    [
        testDeletePermission,
        testReplaceUserId,
        testGetUser,
        testCreatePermission,
        testCreatePermissionWithTTL,
        testListPermissions
    ]
}
function testDeleteUser() {
    log:printInfo("ACTION : deleteUser()");

    var result = azureCosmosManagementClient->deleteUser(databaseId, newUserId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }
    test:assertTrue(true);
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        testReplaceUserId,
        testGetOneDatabase,
        testGetOneContainer
    ]
}
function testCreatePermission() {
    log:printInfo("ACTION : createPermission()");

    PermisssionMode permissionMode = "All";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}`;

    var result = azureCosmosManagementClient->createPermission(databaseId, newUserId, permissionId, permissionMode,
        permissionResource);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == permissionId);
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        testReplaceUserId,
        testGetOneDatabase,
        testGetOneContainer
    ]
}
function testCreatePermissionWithTTL() {
    log:printInfo("ACTION : createPermission()");

    var uuid = createRandomUUIDWithoutHyphens();
    string newPermissionId = string `permission_${uuid.toString()}`;
    PermisssionMode permissionMode = "Read";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}/`;
    int validityPeriod = 9000;

    var result = azureCosmosManagementClient->createPermission(databaseId, newUserId, newPermissionId, permissionMode,
        permissionResource, validityPeriod);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == newPermissionId);
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [testCreatePermission]
}
function testReplacePermission() {
    log:printInfo("ACTION : replacePermission()");

    PermisssionMode permissionMode = "Read";
    string permissionResource = string `dbs/${database.id}/colls/${container.id}`;

    var result = azureCosmosManagementClient->replacePermission(databaseId, newUserId, permissionId, permissionMode,
        permissionResource);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == permissionId);
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [testCreatePermission]
}
function testListPermissions() {
    log:printInfo("ACTION : listPermissions()");

    var result = azureCosmosManagementClient->listPermissions(databaseId, newUserId);
    if (result is stream<Permission, error?>) {
        error? e = result.forEach(isolated function(Permission queryResult) {
            log:printInfo(queryResult.toString());
        });
        if (e is error) {
            log:printInfo(msg = e.message());
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [testCreatePermission]
}
function testGetPermission() {
    log:printInfo("ACTION : getPermission()");

    var result = azureCosmosManagementClient->getPermission(databaseId, newUserId, permissionId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        test:assertTrue(result.id == permissionId);
    }
}

@test:Config {
    groups: ["permission"],
    dependsOn: [
        testReplacePermission,
        testGetPermission
    ]
}
function testDeletePermission() {
    log:printInfo("ACTION : deletePermission()");

    var result = azureCosmosManagementClient->deletePermission(databaseId, newUserId, permissionId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }
}

string? offerId = "";
string? resourceId = "";

@test:Config {
    groups: ["offer"]
}
function testListOffers() {
    log:printInfo("ACTION : listOffers()");

    var result = azureCosmosManagementClient->listOffers();
    if (result is stream<Offer, error?>) {
        record {|Offer value;|}|error? offer = result.next();
        if (offer is record {|Offer value;|}) {
            offerId = <@untainted>offer?.value?.id;
            runtime:sleep(1);
            resourceId = <@untainted>offer?.value?.resourceId;
        } else {
            log:printInfo("Empty stream");
        }
    } else {
        test:assertFail(msg = result.message());
    }
}

@test:Config {
    groups: ["offer"],
    dependsOn: [testListOffers]
}
function testGetOffer() {
    log:printInfo("ACTION : getOffer()");

    if (offerId is string && offerId != "") {
        var result = azureCosmosManagementClient->getOffer(<string>offerId);
        if (result is Error) {
            test:assertFail(msg = result.message());
        } else {
            test:assertTrue(result.id == offerId);
        }
    } else {
        test:assertFail(msg = "Offer id is invalid");
    }
}

@test:Config {
    groups: ["offer"]
}
function testReplaceOffer() {
    log:printInfo("ACTION : replaceOffer()");

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
        if (result is Error) {
            test:assertFail(msg = result.message());
        } else {
            test:assertTrue(result.id == offerId);
        }
    } else {
        test:assertFail(msg = "Offer id and resource ID are invalid");
    }
}

@test:Config {
    groups: ["offer"]
}
function testReplaceOfferWithOptionalParameter() {
    log:printInfo("ACTION : replaceOfferWithOptionalParameter()");

    if (offerId is string && offerId != "" && resourceId is string && resourceId != "") {
        string resourceSelfLink =
            string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`;
        Offer replaceOfferBody = {
            offerVersion: "V2",
            content: {"offerThroughput": 600},
            offerType: "Invalid",
            resourceSelfLink: resourceSelfLink,
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: <string>offerId,
            resourceId: <string>resourceId
        };
        var result = azureCosmosManagementClient->replaceOffer(<@untainted>replaceOfferBody);
        if (result is Error) {
            test:assertFail(msg = result.message());
        } else {
            test:assertTrue(result.id == offerId);
        }
    } else {
        test:assertFail(msg = "Offer id and resource ID are invalid");
    }
}

@test:Config {
    groups: ["offer"]
    //dependsOn: [testCreateContainer]
}
function testQueryOffer() {
    log:printInfo("ACTION : queryOffer()");
    string offerQuery =
        string `SELECT * FROM ${container.id} f WHERE (f["_self"]) = "${container?.selfReference.toString()}"`;
    var result = azureCosmosManagementClient->queryOffer(offerQuery);
    if (result is Error) {
        test:assertFail(msg = result.message());
    }

}

@test:Config {
    groups: ["permission"],
    dependsOn: [testCreatePermission, testReplacePermission],
    enable: false
}
function testGetContainerWithResourceToken() {
    log:printInfo("ACTION : createCollection_Resource_Token()");

    string permissionUserId = newUserId;
    string userPermissionId = permissionId;

    var result = azureCosmosManagementClient->getPermission(databaseId, permissionUserId, userPermissionId);
    if (result is Error) {
        test:assertFail(msg = result.message());
    } else {
        ManagementClientConfig configdb = {
            baseUrl: baseURL,
            primaryKeyOrResourceToken: result?.token.toString()
        };

        ManagementClient managementClient = checkpanic new (configdb);

        string containerId = container.id;
        var resultcontainer = managementClient->getContainer(databaseId, containerId);
        if (resultcontainer is Error) {
            test:assertFail(msg = resultcontainer.message());
        } else {
            test:assertTrue(result.id == containerId);
        }
    }
}

// The `AfterSuite` function is executed after all the test functions in this module.
@test:AfterSuite {}
function afterFunc() returns error? {
    log:printInfo("ACTION : deleteDatabases()");
    var result1 = azureCosmosManagementClient->deleteDatabase(databaseId);
    var result2 = azureCosmosManagementClient->deleteDatabase(createDatabaseExistId);
    var result3 = azureCosmosClient->close();

    if (result1 is DeleteResponse && result2 is DeleteResponse && result3 is ()) {
        log:printInfo("Success");
    } else {
        test:assertFail(msg = "Failed to delete one of the databases");
    }
}

# Create a random UUID removing the unnecessary hyphens which will interrupt querying opearations.
#
# + return - A string UUID without hyphens
function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = 'string:substring(regex:replaceAll(stringUUID, "-", ""), 1, 4);
        return stringUUID is string ? stringUUID : "";
    } else {
        return EMPTY_STRING;
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
