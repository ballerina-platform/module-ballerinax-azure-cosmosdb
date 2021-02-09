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
import ballerina/log;
import ballerina/config;
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

    // Using UDFs, you can extend Azure Cosmos DB's query language. 
    // UDFs are a great way to express complex business logic in a query's projection.

    // ---------------------------------- USE CASE ----------------------------------------------------------
    // Create User Defined Function
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
    cosmosdb:UserDefinedFunction newUDF = {
        id: udfId,
        userDefinedFunction: userDefinedFunctionBody
    };
    cosmosdb:Result udfCreateResult = checkpanic azureCosmosClient->createUserDefinedFunction(databaseId, containerId, newUDF);
    

    // Replace User Defined Function
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
    cosmosdb:UserDefinedFunction replacementUdf = {
        id: udfId,
        userDefinedFunction: newUserDefinedFunctionBody
    };
    cosmosdb:Result udfReplaceResult = checkpanic azureCosmosClient->replaceUserDefinedFunction(databaseId, containerId, replacementUdf);


    // List all User defined Functions
    log:print("List  user defined functions");
    stream<cosmosdb:UserDefinedFunction> result5 = checkpanic azureCosmosClient->listUserDefinedFunctions(databaseId, containerId);

    // Delete User defined Functions
    log:print("Delete user defined function");
    _ = checkpanic azureCosmosClient->deleteUserDefinedFunction(databaseId, containerId, udfId);
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
