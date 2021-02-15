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

import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;
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

    // Create trigger
    log:print("Creating a trigger");
    string triggerId = string `trigger_${uuid.toString()}`;
    string createTriggerBody = 
    string `function updateMetadata() {
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
    cosmosdb:TriggerOperation createTriggerOperationType = "All";
    cosmosdb:TriggerType createTriggerType = "Post";
    cosmosdb:Trigger triggerCreationResult = checkpanic azureCosmosClient->createTrigger(databaseId, containerId, 
            triggerId, createTriggerBody, createTriggerOperationType, createTriggerType);

    // Replace trigger
    log:print("Replacing a trigger");
    string replaceTriggerBody = 
    string `function replaceMetadata() {
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
    cosmosdb:TriggerOperation replaceTriggerOperation = "All";
    cosmosdb:TriggerType replaceTriggerType = "Post";

    cosmosdb:Result triggerReplaceResult = checkpanic azureCosmosClient->replaceTrigger(databaseId, containerId, 
            triggerId, replaceTriggerBody, replaceTriggerOperation, replaceTriggerType);

    // List triggers
    log:print("List available triggers");
    stream<cosmosdb:Trigger> result5 = checkpanic azureCosmosClient->listTriggers(databaseId, containerId);

    // Delete trigger
    log:print("Deleting trigger");
    _ = checkpanic azureCosmosClient->deleteTrigger(databaseId, containerId, triggerId);
    log:print("Success!");
}

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
