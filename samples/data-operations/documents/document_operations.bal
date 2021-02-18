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

import ballerinax/azure_cosmosdb as cosmosdb;
import ballerina/log;
import ballerina/config;
import ballerina/io;
import ballerina/java;
import ballerina/stringutils;

cosmosdb:Configuration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

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

    cosmosdb:Document documentResult = checkpanic azureCosmosClient->createDocument(databaseId, containerId, 
            documentBody, partitionKeyValue); 

    log:print("Creating a new document allowing to include it in the indexing.");
    record {|string id; json...;|} documentIndexing = {
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

    cosmosdb:Document documentCreateResult = checkpanic azureCosmosClient->createDocument(databaseId, containerId, 
            documentIndexing, partitionKeyValue, indexingOptions);

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
    
    cosmosdb:Document documentUpsertResult = checkpanic azureCosmosClient->createDocument(databaseId, containerId, 
            upsertDocument, partitionKeyValue, upsertOptions);

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

    cosmosdb:Document replaceResult = checkpanic azureCosmosClient->replaceDocument(databaseId, containerId, 
            newDocumentBody, partitionKeyValue);

    log:print("Read the document by id");
    cosmosdb:Document returnedDocument = checkpanic azureCosmosClient->getDocument(databaseId, containerId, documentId, 
            partitionKeyValue);

    log:print("Read the document with request options");
    cosmosdb:ResourceReadOptions options = {
        consistancyLevel: "Eventual"
    };
    cosmosdb:Document document3 = checkpanic azureCosmosClient->getDocument(databaseId, containerId, documentId, 
            partitionKeyValue, options);

    log:print("Deleting the document");
    _ = checkpanic azureCosmosClient->deleteDocument(databaseId, containerId, documentId, partitionKeyValue);

    log:print("Getting list of documents");
    stream<cosmosdb:Document> documentList = checkpanic azureCosmosClient->getDocumentList(databaseId, containerId);
    log:print("Success!");
}

public function read(string path) returns @tainted json|error {
    io:ReadableByteChannel rbc = check io:openReadableFile(path);
    io:ReadableCharacterChannel rch = new (rbc, "UTF8");
    var result = rch.readJson();
    closeRc(rch);
    return result;
}

public function closeRc(io:ReadableCharacterChannel rc) {
    var result = rc.close();
    if (result is error) {
        log:printError("Error occurred while closing character stream ", err = result);
    }
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
