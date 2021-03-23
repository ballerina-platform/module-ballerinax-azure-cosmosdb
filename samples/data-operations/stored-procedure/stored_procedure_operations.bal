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
import ballerina/log;
import ballerina/os;
import ballerina/regex;
import ballerinax/azure_cosmosdb as cosmosdb;

cosmosdb:Configuration config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:DataPlaneClient azureCosmosClient = new (config);

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
    
    cosmosdb:StoredProcedure|error storedProcedureCreateResult = azureCosmosClient->createStoredProcedure(databaseId, 
        containerId, storedProcedureId, storedProcedureBody); 

    if (storedProcedureCreateResult is cosmosdb:StoredProcedure) {
        log:print(storedProcedureCreateResult.toString());
    } else {
        log:printError(storedProcedureCreateResult.message());
    }

    log:print("Replacing stored procedure");
    string newStoredProcedureBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;

    cosmosdb:StoredProcedure|error storedProcedureReplaceResult = azureCosmosClient->replaceStoredProcedure(databaseId, 
        containerId, storedProcedureId, newStoredProcedureBody);

    if (storedProcedureReplaceResult is cosmosdb:StoredProcedure) {
        log:print(storedProcedureReplaceResult.toString());
    } else {
        log:printError(storedProcedureReplaceResult.message());
    }

    log:print("List stored procedures");
    stream<cosmosdb:StoredProcedure>|error spList = azureCosmosClient->listStoredProcedures(databaseId, containerId);

    if (spList is stream<cosmosdb:StoredProcedure>) {
        error? e = spList.forEach(function (cosmosdb:StoredProcedure procedure) {
            log:print(procedure.toString());
        });
    } else {
        log:printError(spList.message());
    }

    log:print("Executing stored procedure");
    cosmosdb:StoredProcedureOptions options = {
        parameters: ["Sachi"]
    };

    json|error result = azureCosmosClient->executeStoredProcedure(databaseId, containerId, storedProcedureId, options); 

    if (result is json) {
        log:print(result.toString());
    } else {
        log:printError(result.message());
    }

    log:print("Deleting stored procedure");
    cosmosdb:DeleteResponse|error deletionResult = azureCosmosClient->deleteStoredProcedure(databaseId, containerId, 
        storedProcedureId);

    if (deletionResult is cosmosdb:DeleteResponse) {
        log:print(deletionResult.toString());
    } else {
        log:printError(deletionResult.message());
    }
    log:print("End!");
}

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
