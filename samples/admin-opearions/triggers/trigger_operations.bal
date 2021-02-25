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
import ballerina/jballerina.java;
import ballerina/regex;
import ballerina/os;

cosmosdb:Configuration config = {
    baseUrl: os:getEnv("BASE_URL"),
    masterOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

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

    var triggerCreationResult = managementClient->createTrigger(databaseId, containerId, triggerId, createTriggerBody, 
        createTriggerOperationType, createTriggerType); 
    if (triggerCreationResult is error) {
        log:printError(triggerCreationResult.message());
    }
    if (triggerCreationResult is cosmosdb:Trigger) {
        log:print(triggerCreationResult.toString());
    }

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

    var triggerReplaceResult = managementClient->replaceTrigger(databaseId, containerId, triggerId, replaceTriggerBody, 
        replaceTriggerOperation, replaceTriggerType); 
    if (triggerReplaceResult is error) {
        log:printError(triggerReplaceResult.message());
    }
    if (triggerReplaceResult is cosmosdb:Trigger) {
        log:print(triggerReplaceResult.toString());
    }

    log:print("List available triggers");
    var triggerList = managementClient->listTriggers(databaseId, containerId);
    if (triggerList is error) {
        log:printError(triggerList.message());
    }
    if (triggerList is stream<cosmosdb:Trigger>) {
        error? e = triggerList.forEach(function (cosmosdb:Trigger trigger) {
            log:print(trigger.toString());
        });
    }

    log:print("Deleting trigger");
    var deletionResult = managementClient->deleteTrigger(databaseId, containerId, triggerId);
    if (deletionResult is error) {
        log:printError(deletionResult.message());
    }
    if (deletionResult is cosmosdb:DeleteResponse) {
        log:print(deletionResult.toString());
    }
    log:print("End!");
}

public function createRandomUUIDWithoutHyphens() returns string {
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
