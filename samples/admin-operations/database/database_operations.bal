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
import ballerina/jballerina.java;
import ballerina/log;
import ballerina/os;
import ballerina/regex;

cosmosdb:Configuration config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = check new (config);

public function main() {

    var uuid = createRandomUUIDWithoutHyphens();
    
    string databaseId = "my_database";
    string databaseIfNotExistId = string `databasex_${uuid.toString()}`;
    string databaseManualId = string `databasem_${uuid.toString()}`;
    string databaseAutoScalingId = string `databasea_${uuid.toString()}`;

    log:printInfo("Creating database");
    cosmosdb:Database|error databaseResult = managementClient->createDatabase(databaseId); 

    if (databaseResult is cosmosdb:Database) {
        log:printInfo(databaseResult.toString());
    } else {
        log:printError(databaseResult.message());
    }

    log:printInfo("Creating database only if it does not exist");
    cosmosdb:Database?|error databaseIfNotExist = managementClient->createDatabaseIfNotExist(databaseIfNotExistId); 

    if (databaseIfNotExist is cosmosdb:Database?) {
        log:printInfo(databaseIfNotExist.toString());
    } else {
        log:printError(databaseIfNotExist.message());
    }

    log:printInfo("Creating database with manual throughput");
    int throughput = 600;
    cosmosdb:Database|error databaseWithManualThroughput = managementClient->createDatabase(databaseManualId, 
        throughput); 

    if (databaseWithManualThroughput is cosmosdb:Database) {
        log:printInfo(databaseWithManualThroughput.toString());
    } else {
        log:printError(databaseWithManualThroughput.message());
    }

    log:printInfo("Creating database with autoscaling throughput");
    record {|int maxThroughput;|} maxThroughput = { maxThroughput: 4000 };
    cosmosdb:Database|error databaseWithAutoThroughput = managementClient->createDatabase(databaseAutoScalingId, 
        maxThroughput); 

    if (databaseWithAutoThroughput is cosmosdb:Database) {
        log:printInfo(databaseWithAutoThroughput.toString());
    } else{
        log:printError(databaseWithAutoThroughput.message());
    }

    string? etag;
    string? sessiontoken;
    log:printInfo("Reading database by ID");
    cosmosdb:Database|error databaseInfo = managementClient->getDatabase(databaseId);

    if (databaseInfo is cosmosdb:Database) {
        log:printInfo(databaseInfo.toString());
        etag = databaseInfo?.eTag;
        sessiontoken = databaseInfo?.sessionToken;
    } else {
        log:printError(databaseInfo.message());
    }
  
    log:printInfo("Reading database with consistancy level option");
    cosmosdb:ResourceReadOptions options = {
        consistancyLevel: "Bounded"
    };
    cosmosdb:Database|error databaseInfoWithDifferentConsistancy = managementClient->getDatabase(databaseId, options);

    if (databaseInfoWithDifferentConsistancy is cosmosdb:Database) {
        log:printInfo(databaseInfoWithDifferentConsistancy.toString());
    } else{
        log:printError(databaseInfoWithDifferentConsistancy.message());
    }

    log:printInfo("Getting list of databases");
    stream<cosmosdb:Data,error>|error databaseList = managementClient->listDatabases();

    if (databaseList is stream<cosmosdb:Data,error>) {
        error? e = databaseList.forEach(function (cosmosdb:Data database) {
            log:printInfo(database.toString());
        });
    } else {
        log:printError(databaseList.message());
    }

    log:printInfo("Deleting databases");
    _ = checkpanic managementClient->deleteDatabase(databaseIfNotExistId);
    _ = checkpanic managementClient->deleteDatabase(databaseManualId);
    _ = checkpanic managementClient->deleteDatabase(databaseAutoScalingId);
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
