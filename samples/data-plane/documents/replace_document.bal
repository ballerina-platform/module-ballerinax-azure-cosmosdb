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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/cosmosdb;
import ballerina/log;
import ballerina/config;

cosmosdb:Configuration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    // Assume partition key of this container is set as /gender which is an int of 0 or 1
    string containerId = "my_container";
    string documentId = "my_document";
    //We have to give the currently existing partition key of this document we can't replace that
    int partitionKeyValue = 0; 

    log:print("Replacing document");
    record {|string id; json...;|} documentBody = {
        id: documentId,
        "FirstName": "Alan",
        "FamilyName": "Turing",
        "Parents": [{
            "FamilyName": "Turing",
            "FirstName": "Julius"
        }, {
            "FamilyName": "Turing",
            "FirstName": "Ethel"
        }],
        gender: 0
    };

    cosmosdb:Document replsceResult = checkpanic azureCosmosClient->replaceDocument(databaseId, containerId, 
            newDocumentBody, partitionKeyValue);
    log:print("Success!");
}
