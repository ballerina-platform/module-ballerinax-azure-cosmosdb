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

import ballerina/log;
import ballerina/os;
import ballerinax/azure_cosmosdb as cosmosdb;

cosmosdb:ConnectionConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:DataPlaneClient azureCosmosClient = check new (config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";

    log:printInfo("Query1 - Select all from the container where gender 0");
    string selectAllQuery = string `SELECT * FROM ${containerId.toString()} f WHERE f.gender = ${0}`;

    cosmosdb:ResourceQueryOptions options = {partitionKey : 0, enableCrossPartition: false};
    stream<cosmosdb:Document, error?>|error result = azureCosmosClient->queryDocuments(databaseId, containerId,
        selectAllQuery, options);

    if (result is stream<cosmosdb:Document, error?>) {
        error? e = result.forEach(function (cosmosdb:Document queryResult) {
            log:printInfo(queryResult.toString());
        });
        log:printInfo("Success!");
    } else {
        log:printError(result.message());
    }
}
