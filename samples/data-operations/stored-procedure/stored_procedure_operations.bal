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

    log:print("Creating stored procedure");
    string storedProcedureId = string `sproc_${uuid.toString()}`;
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    
    var storedProcedureCreateResult = azureCosmosClient->createStoredProcedure(databaseId, containerId, 
            storedProcedureId, storedProcedureBody); 
    if (storedProcedureCreateResult is error) {
        log:printError(storedProcedureCreateResult.message());
    }
    if (storedProcedureCreateResult is cosmosdb:StoredProcedure) {
        log:print(storedProcedureCreateResult.toString());
    }

    log:print("Replacing stored procedure");
    string newStoredProcedureBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;

    var storedProcedureReplaceResult = azureCosmosClient->replaceStoredProcedure(databaseId, containerId, 
            storedProcedureId, newStoredProcedureBody);
    if (storedProcedureReplaceResult is error) {
        log:printError(storedProcedureReplaceResult.message());
    }
    if (storedProcedureReplaceResult is cosmosdb:StoredProcedure) {
        log:print(storedProcedureReplaceResult.toString());
    }

    log:print("List stored procedures");
    var spList = azureCosmosClient->listStoredProcedures(databaseId, containerId);
    if (spList is error) {
        log:printError(spList.message());
    }
    if (spList is stream<cosmosdb:StoredProcedure>) {
        error? e = spList.forEach(function (cosmosdb:StoredProcedure procedure) {
            log:print(procedure.toString());
        });
    }

    log:print("Executing stored procedure");
    cosmosdb:StoredProcedureOptions options = {
        parameters: ["Sachi"]
    };

    var result = azureCosmosClient->executeStoredProcedure(databaseId, containerId, storedProcedureId, options); 
    if (result is error) {
        log:printError(result.message());
    }
    if (result is json) {
        log:print(result.toString());
    }

    log:print("Deleting stored procedure");
    var deletionResult = azureCosmosClient->deleteStoredProcedure(databaseId, containerId, storedProcedureId);
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
