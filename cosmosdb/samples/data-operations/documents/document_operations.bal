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

cosmosdb:ConnectionConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:DataPlaneClient azureCosmosClient = check new (config);

public function main() returns error? {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();
    
    log:printInfo("Create a new document");
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

    cosmosdb:DocumentResponse documentResponse = check azureCosmosClient->createDocument(databaseId, containerId, 
    documentId, documentBody, partitionKeyValue);

    log:printInfo("Creating a new document allowing to include it in the indexing.");
    string id = string `documenti_${uuid.toString()}`;
    record {} documentWithIndexing = {
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

    cosmosdb:RequestOptions indexingOptions = {
        indexingDirective: "Include"
    };

    cosmosdb:DocumentResponse documentResponseResult = check azureCosmosClient->createDocument(databaseId, containerId, 
    id, documentWithIndexing, partitionKeyValue, 
    indexingOptions);

    // Create the document which already existing id and specify that it is an upsert request. If not this will show an 
    // error.
    log:printInfo("Upserting the document");
    record {} upsertDocument = {
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

    cosmosdb:RequestOptions upsertOptions = {
        isUpsertRequest: true
    };
    
    cosmosdb:DocumentResponse documentResponseOut = check azureCosmosClient->createDocument(databaseId, containerId, id,
    upsertDocument, partitionKeyValue, upsertOptions); 

    log:printInfo("Replacing document");
    record {} newDocumentBody = {
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

    cosmosdb:DocumentResponse documentResponseValue = check azureCosmosClient->replaceDocument(databaseId, containerId, 
    documentId, newDocumentBody, partitionKeyValue); 

    log:printInfo("Read the document by id");
    cosmosdb:Document returnedDocument = check azureCosmosClient->getDocument(databaseId, containerId, documentId, 
        partitionKeyValue);

    log:printInfo(returnedDocument.toString());

    log:printInfo("Read the document with request options");
    cosmosdb:RequestOptions options = {
        consistancyLevel: "Eventual"
    };
    cosmosdb:Document returnedDocumentWithOptions = check azureCosmosClient->getDocument(databaseId, 
        containerId, documentId, partitionKeyValue, options);

    log:printInfo(returnedDocumentWithOptions.toString());

    log:printInfo("Getting list of documents");
    stream<record {}, error?> documentList = check azureCosmosClient->getDocumentList(databaseId, containerId, 
    partitionKeyValue);

    error? e = documentList.forEach(function (record{} document) {
        log:printInfo(document.toString());
    });
    log:printInfo("Success!");
   

    log:printInfo("Deleting the document");
    cosmosdb:DocumentResponse b = check azureCosmosClient->deleteDocument(databaseId, containerId, documentId, 
    partitionKeyValue);

    log:printInfo("End!");
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
        log:printError("Error occurred while closing character stream ");
    }
}

# Create a random UUID removing the unnecessary hyphens which will interrupt querying opearations.
#
# + return - A string UUID without hyphens
function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = 'string:substring(regex:replaceAll(stringUUID, "-", ""), 1, 4);
        if (stringUUID is string) {
            return stringUUID;
        }
        return "";
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
