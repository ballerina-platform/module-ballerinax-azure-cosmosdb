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
    masterOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Using UDFs, you can extend Azure Cosmos DB's query language. 
    // UDFs are a great way to express complex business logic in a query's projection.

    log:print("Creating a user defined function");
    string udfId = string `udf_${uuid.toString()}`;
    string userDefinedFunctionBody = string `function tax(income){
                                                if (income == undefined)
                                                    throw 'no input';

                                                if (income < 1000)
                                                    return income * 0.1;
                                                else if (income < 10000)
                                                    return income * 0.2;
                                                else
                                                    return income * 0.4;
                                            }`;

    cosmosdb:UserDefinedFunction|error udfCreateResult = managementClient->createUserDefinedFunction(databaseId, 
        containerId, udfId, userDefinedFunctionBody);

    if (udfCreateResult is cosmosdb:UserDefinedFunction) {
        log:print(udfCreateResult.toString());
    } else {
        log:printError(udfCreateResult.message());
    }

    log:print("Replacing a user defined function");
    string newUserDefinedFunctionBody = string `function taxIncome(income){
                                                    if (income == undefined)
                                                        throw 'no input';
                                                    if (income < 1000)
                                                        return income * 0.1;
                                                    else if (income < 10000)
                                                        return income * 0.2;
                                                    else
                                                        return income * 0.4;
                                                }`;
    cosmosdb:UserDefinedFunction|error udfReplaceResult = managementClient->replaceUserDefinedFunction(databaseId, 
        containerId, udfId, newUserDefinedFunctionBody);

    if (udfReplaceResult is cosmosdb:UserDefinedFunction) {
        log:print(udfReplaceResult.toString());
    } else {
        log:printError(udfReplaceResult.message());
    }

    log:print("List  user defined functions(udf)s");
    stream<cosmosdb:UserDefinedFunction>|error udfList = managementClient->listUserDefinedFunctions(databaseId, 
        containerId);

    if (udfList is stream<cosmosdb:UserDefinedFunction>) {
        error? e = udfList.forEach(function (cosmosdb:UserDefinedFunction udf) {
            log:print(udf.toString());
        });
    } else {
        log:printError(udfList.message());
    }

    log:print("Delete user defined function");
    cosmosdb:DeleteResponse|error deletionResult = managementClient->deleteUserDefinedFunction(databaseId, containerId, 
        udfId);

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
