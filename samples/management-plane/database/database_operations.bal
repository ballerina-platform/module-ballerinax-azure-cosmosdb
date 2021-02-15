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

cosmosdb:Configuration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {

    var uuid = createRandomUUIDWithoutHyphens();
    
    string databaseId = "my_database";
    string databaseIfNotExist = string `databasex_${uuid.toString()}`;
    string databaseManualId = string `databasem_${uuid.toString()}`;
    string databaseAutoScalingId = string `databasea_${uuid.toString()}`;

    log:print("Creating database");
    cosmosdb:Database databaseResult = checkpanic managementClient->createDatabase(databaseId);

    // Create database only if it does not exist
    log:print("Creating database if it does not exist");
    cosmosdb:Database? database2 = checkpanic managementClient->createDatabaseIfNotExist(databaseIfNotExist);

    // Create database with manual throughput
    log:print("Creating database with manual throughput");
    
    int throughput = 600;
    databaseResult = checkpanic managementClient->createDatabase(databaseManualId, throughput);

    // Create database with autoscaling throughput
    log:print("Creating database with autoscaling throughput");

    json maxThroughput = {"maxThroughput": 4000};
    databaseResult = checkpanic managementClient->createDatabase(databaseAutoScalingId, maxThroughput);

    // Database read
    log:print("Reading database by id");
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    string? etag = database.eTag;
    string? sessiontoken = database.sessionToken;
  
    // Database read with session level consistancy
    log:print("Reading database with options");
    cosmosdb:ResourceReadOptions options = {
        sessionToken: sessiontoken
    };
    database = checkpanic managementClient->getDatabase(databaseId, options);

    // Makes operation conditional to only execute if the database has changed.
    // try to get the response in such situation and handle the error
    // check this
    // log:print("Reading database with options");
    // cosmosdb:ResourceReadOptions options2 = {
    //     ifNoneMatchEtag: etag
    // };
    // database = checkpanic azureCosmosClient->getDatabase(databaseId, options2);

    // Get a list of databases
    log:print("Getting list of databases");
    stream<cosmosdb:Database> databaseList = checkpanic managementClient->listDatabases(10);

    log:print("Deleting databases");
    _ = checkpanic managementClient->deleteDatabase(databaseIfNotExist);
    _ = checkpanic managementClient->deleteDatabase(databaseManualId);
    _ = checkpanic managementClient->deleteDatabase(databaseAutoScalingId);
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
