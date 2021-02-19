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

cosmosdb:Configuration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {

    var uuid = createRandomUUIDWithoutHyphens();
    
    string databaseId = "my_database";
    string databaseIfNotExistId = string `databasex_${uuid.toString()}`;
    string databaseManualId = string `databasem_${uuid.toString()}`;
    string databaseAutoScalingId = string `databasea_${uuid.toString()}`;

    log:print("Creating database");
    var databaseResult = managementClient->createDatabase(databaseId); 
    if (databaseResult is error) {
        log:printError(databaseResult.message());
    }
    if (databaseResult is cosmosdb:Database) {
        log:print(databaseResult.toString());
    }

    log:print("Creating database only if it does not exist");
    var databaseIfNotExist = managementClient->createDatabaseIfNotExist(databaseIfNotExistId); 
    if (databaseIfNotExist is error) {
        log:printError(databaseIfNotExist.message());
    }
    if (databaseIfNotExist is cosmosdb:Database) {
        log:print(databaseIfNotExist.toString());
    }

    log:print("Creating database with manual throughput");
    int throughput = 600;
    var databaseWithManualThroughput = managementClient->createDatabase(databaseManualId, throughput); 
    if (databaseWithManualThroughput is error) {
        log:printError(databaseWithManualThroughput.message());
    }
    if (databaseWithManualThroughput is cosmosdb:Database) {
        log:print(databaseWithManualThroughput.toString());
    }

    log:print("Creating database with autoscaling throughput");
    record {|int maxThroughput;|} maxThroughput = { maxThroughput: 4000 };
    var databaseWithAutoThroughput = managementClient->createDatabase(databaseAutoScalingId, maxThroughput); 
    if (databaseWithAutoThroughput is error) {
        log:printError(databaseWithAutoThroughput.message());
    }
    if (databaseWithAutoThroughput is cosmosdb:Database) {
        log:print(databaseWithAutoThroughput.toString());
    }

    string? etag;
    string? sessiontoken;
    log:print("Reading database by ID");
    var databaseInfo = managementClient->getDatabase(databaseId);
    if (databaseInfo is error) {
        log:printError(databaseInfo.message());
    }
    if (databaseInfo is cosmosdb:Database) {
        log:print(databaseInfo.toString());
        etag = databaseInfo?.eTag;
        sessiontoken = databaseInfo?.sessionToken;
    }
  
    log:print("Reading database with consistancy level option");
    cosmosdb:ResourceReadOptions options = {
        consistancyLevel: "Bounded"
    };
    var databaseInfoWithDifferentConsistancy = managementClient->getDatabase(databaseId, options);
    if (databaseInfoWithDifferentConsistancy is error) {
        log:printError(databaseInfoWithDifferentConsistancy.message());
    }
    if (databaseInfoWithDifferentConsistancy is cosmosdb:Database) {
        log:print(databaseInfoWithDifferentConsistancy.toString());
    }

    log:print("Getting list of databases");
    var databaseList = managementClient->listDatabases(10);
    if (databaseList is error) {
        log:printError(databaseList.message());
    }
    if (databaseList is stream<cosmosdb:Database>) {
        error? e = databaseList.forEach(function (cosmosdb:Database database) {
            log:print(database.toString());
        });
    }

    log:print("Deleting databases");
    _ = checkpanic managementClient->deleteDatabase(databaseIfNotExistId);
    _ = checkpanic managementClient->deleteDatabase(databaseManualId);
    _ = checkpanic managementClient->deleteDatabase(databaseAutoScalingId);
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
