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
    masterOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(config);

public function main() {

    string databaseId = "my_database";
    var uuid = createRandomUUIDWithoutHyphens();

    string containerId = "my_new_container";
    string containerWithIndexingId = string `containero_${uuid.toString()}`;
    string containerManualId = string `containerm_${uuid.toString()}`;
    string containerAutoscalingId = string `containera_${uuid.toString()}`;
    string containerIfnotExistId = string `containerx_${uuid.toString()}`;

    log:print("Creating container");
    cosmosdb:PartitionKey partitionKey = {
        paths: ["/id"],
        keyVersion: 2
    };
 
    var containerResult = managementClient->createContainer(databaseId, containerId, partitionKey);
    if (containerResult is error) {
        log:printError(containerResult.message());
    }
    if (containerResult is cosmosdb:Container) {
        log:print(containerResult.toString());
    }

    log:print("Creating container with indexing policy");   
    cosmosdb:IndexingPolicy indexingPolicy = {
        indexingMode: "consistent",
        automatic: true,
        includedPaths: [{
            path: "/*",
            indexes: [{
                dataType: "String",
                precision: -1,
                kind: "Range"
            }]
        }]
    };
    cosmosdb:PartitionKey partitionKeyWithIndexing = {
        paths: ["/id"],
        kind: "Hash",
        keyVersion: 2
    };

    var containerWithOptionsResult = managementClient->createContainer(databaseId, containerWithIndexingId, 
        partitionKeyWithIndexing, indexingPolicy);
    if (containerWithOptionsResult is error) {
        log:printError(containerWithOptionsResult.message());
    }   
    if (containerWithOptionsResult is cosmosdb:Container) {
        log:print(containerWithOptionsResult.toString());
    }

    log:print("Creating container with manual throughput policy");
    int throughput = 600;
    cosmosdb:PartitionKey partitionKeyManual = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    var manualPolicyContainer = managementClient->createContainer(databaseId, containerManualId, 
        partitionKeyManual, (), throughput);
    if (manualPolicyContainer is error) {
        log:printError(manualPolicyContainer.message());
    }   
    if (manualPolicyContainer is cosmosdb:Container) {
        log:print(manualPolicyContainer.toString());
    }

    log:print("Creating container with autoscaling throughput policy");
    record {|int maxThroughput;|} maxThroughput = { maxThroughput: 4000 };
    cosmosdb:PartitionKey partitionKeyAutoscaling = {
        paths: ["/id"],
        kind: "Hash",
        keyVersion: 2
    };
    containerResult = checkpanic managementClient->createContainer(databaseId, containerAutoscalingId, 
        partitionKeyAutoscaling, (), maxThroughput);

    var autoPolicyContainer = managementClient->createContainer(databaseId, containerManualId, 
        partitionKeyManual, (), throughput);
    if (autoPolicyContainer is error) {
        log:printError(autoPolicyContainer.message());
    }   
    if (autoPolicyContainer is cosmosdb:Container) {
        log:print(autoPolicyContainer.toString());
    }

    log:print("Creating container if not exist");
    cosmosdb:PartitionKey partitionKeyDefinition = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };
    var containerIfNotExistResult = managementClient->createContainer(databaseId, containerIfnotExistId, 
        partitionKeyDefinition);
    if (containerIfNotExistResult is error) {
        log:printError(containerIfNotExistResult.message());
    }   
    if (containerIfNotExistResult is cosmosdb:Container) {
        log:print(containerIfNotExistResult.toString());
    }

    string? etag;
    string? sessiontoken;     
    log:print("Reading container info");
    var existingContainer = managementClient->getContainer(databaseId, containerId);
    if (existingContainer is error) {
        log:printError(existingContainer.message());
    }
    if (existingContainer is cosmosdb:Container) {
        log:print(existingContainer.toString());
        etag = existingContainer?.eTag;
        sessiontoken = existingContainer?.sessionToken;    
    }
    
    log:print("Reading container info with request options");
    cosmosdb:ResourceReadOptions options = {
        consistancyLevel: "Bounded"
    };
    var getContainerWithOptions = managementClient->getContainer(databaseId, containerId, options);
    if (getContainerWithOptions is error) {
        log:printError(getContainerWithOptions.message());
    }
    if (getContainerWithOptions is cosmosdb:Container) {
        log:print(getContainerWithOptions.toString());
    }

    log:print("Getting list of containers");
    var containerList = managementClient->listContainers(databaseId, 2);
    if (containerList is error) {
        log:printError(containerList.message());
    }
    if (containerList is stream<cosmosdb:Container>) {
        error? e = containerList.forEach(function (cosmosdb:Container container) {
            log:print(container.toString());
        });
    }

    log:print("Deleting the container");
    var deletionResult = managementClient->deleteContainer(databaseId, containerId);
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
