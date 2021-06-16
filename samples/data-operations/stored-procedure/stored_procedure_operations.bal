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

cosmosdb:DataPlaneClient azureCosmosClient = check new (config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    log:printInfo("Creating stored procedure");
    string storedProcedureId = string `sproc_${uuid.toString()}`;
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    
    cosmosdb:StoredProcedure|error storedProcedureCreateResult = azureCosmosClient->createStoredProcedure(databaseId, 
        containerId, storedProcedureId, storedProcedureBody); 

    if (storedProcedureCreateResult is cosmosdb:StoredProcedure) {
        log:printInfo(storedProcedureCreateResult.toString());
    } else {
        log:printError(storedProcedureCreateResult.message());
    }

    log:printInfo("Replacing stored procedure");
    string newStoredProcedureBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;

    cosmosdb:StoredProcedure|error storedProcedureReplaceResult = azureCosmosClient->replaceStoredProcedure(databaseId, 
        containerId, storedProcedureId, newStoredProcedureBody);

    if (storedProcedureReplaceResult is cosmosdb:StoredProcedure) {
        log:printInfo(storedProcedureReplaceResult.toString());
    } else {
        log:printError(storedProcedureReplaceResult.message());
    }

    log:printInfo("List stored procedures");
    stream<cosmosdb:StoredProcedure, error>|error spList = azureCosmosClient->listStoredProcedures(databaseId, containerId);
    if (spList is stream<cosmosdb:StoredProcedure, error>) {
        error? e = spList.forEach(function (cosmosdb:StoredProcedure storedPrcedure) {
            log:printInfo(storedPrcedure.toString());
        });
        log:printInfo("Success!");
    } else {
        log:printError(spList.message());
    }

    log:printInfo("Executing stored procedure");
    cosmosdb:StoredProcedureExecuteOptions options = {
        parameters: ["Sachi"]
    };

    json|error result = azureCosmosClient->executeStoredProcedure(databaseId, containerId, storedProcedureId, options); 

    if (result is json) {
        log:printInfo(result.toString());
    } else {
        log:printError(result.message());
    }

    log:printInfo("Deleting stored procedure");
    cosmosdb:DeleteResponse|error deletionResult = azureCosmosClient->deleteStoredProcedure(databaseId, containerId, 
        storedProcedureId);

    if (deletionResult is cosmosdb:DeleteResponse) {
        log:printInfo(deletionResult.toString());
    } else {
        log:printError(deletionResult.message());
    }
    log:printInfo("End!");
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
