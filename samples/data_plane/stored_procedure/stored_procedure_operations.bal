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

cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:CoreClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Create a stored procedure
    log:print("Creating stored procedure");
    string storedProcedureId = string `sproc_${uuid.toString()}`;
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    
    cosmosdb:Result storedProcedureCreateResult = checkpanic azureCosmosClient->createStoredProcedure(databaseId, 
            containerId, storedProcedureId, storedProcedureBody);

    // Replace stored procedure
    log:print("Replacing stored procedure");
    string newStoredProcedureBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;

    cosmosdb:Result storedProcedureReplaceResult = checkpanic azureCosmosClient->replaceStoredProcedure(databaseId, 
            containerId, storedProcedureId, newStoredProcedureBody);

    // Get a list of stored procedures
    log:print("List stored procedure");
    stream<cosmosdb:StoredProcedure> result5 = checkpanic azureCosmosClient->listStoredProcedures(databaseId, containerId);

    // Execute stored procedure
    log:print("Executing stored procedure");
    cosmosdb:StoredProcedureOptions options = {
        parameters: ["Sachi"]
    };

    json result = checkpanic azureCosmosClient->executeStoredProcedure(databaseId, containerId, storedProcedureId, 
            options);

    // Delete Stored procedure
    log:print("Deleting stored procedure");
    _ = checkpanic azureCosmosClient->deleteStoredProcedure(databaseId, containerId, storedProcedureId);
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
