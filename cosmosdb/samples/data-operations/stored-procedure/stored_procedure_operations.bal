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
import ballerinax/azure.cosmosdb;

cosmosdb:ConnectionConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:DataPlaneClient azureCosmosClient = check new (config);

public function main() returns error? {
    string databaseId = "my_database";
    string containerId = "my_container";
    string primaryKey = "key";
    var uuid = createRandomUUIDWithoutHyphens();

    log:printInfo("Creating stored procedure");
    string storedProcedureId = string `sproc_${uuid.toString()}`;
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;

    cosmosdb:StoredProcedureResponse storedProcedureCreateResult = check azureCosmosClient->createStoredProcedure(
        databaseId, containerId, storedProcedureId, storedProcedureBody);

    log:printInfo(storedProcedureCreateResult.toString());

    log:printInfo("List stored procedures");
    stream<cosmosdb:StoredProcedure, error?> spList = check azureCosmosClient->listStoredProcedures(databaseId, 
    containerId);
    error? e = spList.forEach(function(cosmosdb:StoredProcedure storedPrcedure) {
        log:printInfo(storedPrcedure.toString());
    });
    log:printInfo("Success!");

    log:printInfo("Executing stored procedure");
    cosmosdb:StoredProcedureExecuteOptions options = {
        parameters: ["Sachi"]
    };

    cosmosdb:StoredProcedureResponse result = check azureCosmosClient->executeStoredProcedure(databaseId, containerId, 
    storedProcedureId, primaryKey, options);

    log:printInfo(result.toString());

    log:printInfo("Deleting stored procedure");
    cosmosdb:StoredProcedureResponse deletionResult = check azureCosmosClient->deleteStoredProcedure(databaseId, 
    containerId, storedProcedureId);

    log:printInfo(deletionResult.toString());
  
    log:printInfo("End!");
}

function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = 'string:substring(regex:replaceAll(stringUUID, "-", ""), 1, 4);
        return <string> stringUUID;
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
