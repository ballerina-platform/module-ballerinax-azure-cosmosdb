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

import ballerina/io;
import ballerina/jballerina.java;
import ballerina/log;
import ballerina/os;
import ballerina/regex;
import ballerinax/azure_cosmosdb as cosmosdb;

cosmosdb:Configuration config = {
    baseUrl: os:getEnv("BASE_URL"),
    masterOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:DataPlaneClient azureCosmosClient = new (config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();
    
    log:print("Create a new document");
    string documentId = string `document_${uuid.toString()}`;
    record {|string id; json...;|} documentBody = {
        id: documentId,
        "LastName": "Sam",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        "gender": 0
    };
    int partitionKeyValue = 0;

    cosmosdb:Document|error documentResult = azureCosmosClient->createDocument(databaseId, containerId, documentBody, 
        partitionKeyValue); 

    if (documentResult is cosmosdb:Document) {
        log:print(documentResult.toString());
    } else {
        log:printError(documentResult.message());
    }

    log:print("Creating a new document allowing to include it in the indexing.");
    record {|string id; json...;|} documentWithIndexing = {
        id: string `documenti_${uuid.toString()}`,
        "LastName": "Tom",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        "gender": 1
    };
    partitionKeyValue = 1;

    cosmosdb:DocumentCreateOptions indexingOptions = {
        indexingDirective: "Include"
    };

    cosmosdb:Document|error documentCreateResult = azureCosmosClient->createDocument(databaseId, containerId, 
        documentWithIndexing, partitionKeyValue, indexingOptions);

    if (documentCreateResult is cosmosdb:Document) {
        log:print(documentCreateResult.toString());
    } else {
        log:printError(documentCreateResult.message());
    }

    cosmosdb:Document|error  documentResultWithIndexing = azureCosmosClient->createDocument(databaseId, containerId, 
        documentWithIndexing, partitionKeyValue, indexingOptions); 

    if (documentResultWithIndexing is cosmosdb:Document) {
        log:print(documentResultWithIndexing.toString());
    } else {
        log:printError(documentResultWithIndexing.message());
    }

    // Create the document which already existing id and specify that it is an upsert request. If not this will show an 
    // error.
    log:print("Upserting the document");
    record {|string id; json...;|} upsertDocument = {
        id: string `documentu_${uuid.toString()}`,
        "LastName": "Tim",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        "gender": 0
    };
    partitionKeyValue = 0;

    cosmosdb:DocumentCreateOptions upsertOptions = {
        isUpsertRequest: true
    };
    
    cosmosdb:Document|error documentUpsertResult = azureCosmosClient->createDocument(databaseId, containerId, 
        upsertDocument, partitionKeyValue, upsertOptions); 

    if (documentUpsertResult is cosmosdb:Document) {
        log:print(documentUpsertResult.toString());
    } else {
        log:printError(documentUpsertResult.message());
    }

    log:print("Replacing document");
    record {|string id; json...;|} newDocumentBody = {
        id: documentId,
        "LastName": "Helena",
        "Parents": [{
            "FamilyName": null,
            "FirstName": "Thomas"
        }, {
            "FamilyName": null,
            "FirstName": "Mary Kay"
        }],
        "gender": 0
    };
    partitionKeyValue = 0;

    cosmosdb:Document|error replaceResult = azureCosmosClient->replaceDocument(databaseId, containerId, newDocumentBody, 
        partitionKeyValue); 

    if (replaceResult is cosmosdb:Document) {
        log:print(replaceResult.toString());
    } else {
        log:printError(replaceResult.message());
    }

    log:print("Read the document by id");
    cosmosdb:Document|error returnedDocument = azureCosmosClient->getDocument(databaseId, containerId, documentId, 
        partitionKeyValue);

    if (returnedDocument is cosmosdb:Document) {
        log:print(returnedDocument.toString());
    }else {
        log:printError(returnedDocument.message());
    }

    log:print("Read the document with request options");
    cosmosdb:ResourceReadOptions options = {
        consistancyLevel: "Eventual"
    };
    cosmosdb:Document|error returnedDocumentWithOptions = azureCosmosClient->getDocument(databaseId, 
        containerId, documentId, partitionKeyValue, options);

    if (returnedDocumentWithOptions is cosmosdb:Document) {
        log:print(returnedDocumentWithOptions.toString());
    } else {
        log:printError(returnedDocumentWithOptions.message());
    }

    log:print("Getting list of documents");
    stream<cosmosdb:Document>|error documentList = azureCosmosClient->getDocumentList(databaseId, containerId);

    if (documentList is stream<cosmosdb:Document>) {
        error? e = documentList.forEach(function (cosmosdb:Document document) {
            log:print(document.toString());
        });
    } else {
        log:printError(documentList.message());
    }

    log:print("Deleting the document");
    cosmosdb:DeleteResponse|error deletionResult = azureCosmosClient->deleteDocument(databaseId, containerId, 
        documentId, partitionKeyValue);

    if (deletionResult is cosmosdb:DeleteResponse) {
        log:print(deletionResult.toString());
    } else {
        log:printError(deletionResult.message());
    }

    log:print("End!");
}

function read(string path) returns @tainted json|error {
    io:ReadableByteChannel rbc = check io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = rch.readJson();
    closeRc(rch);
    return result;
}

function closeRc(io:ReadableCharacterChannel rc) {
    var result = rc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream ", err = result);
    }
}

# Create a random UUID removing the unnecessary hyphens which will interrupt querying opearations.
# 
# + return - A string UUID without hyphens
function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = 'string:substring(regex:replaceAll(stringUUID, "-", ""), 1, 4);
        return stringUUID;
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
