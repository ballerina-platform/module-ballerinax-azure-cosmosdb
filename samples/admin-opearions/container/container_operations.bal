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
 
    cosmosdb:Container|error containerResult = managementClient->createContainer(databaseId, containerId, partitionKey);
    if (containerResult is cosmosdb:Container) {
        log:print(containerResult.toString());
    } else {
        log:printError(containerResult.message());
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

    cosmosdb:Container|error containerWithOptionsResult = managementClient->createContainer(databaseId, 
        containerWithIndexingId, partitionKeyWithIndexing, indexingPolicy);
  
    if (containerWithOptionsResult is cosmosdb:Container) {
        log:print(containerWithOptionsResult.toString());
    } else {
        log:printError(containerWithOptionsResult.message());
    } 

    log:print("Creating container with manual throughput policy");
    int throughput = 600;
    cosmosdb:PartitionKey partitionKeyManual = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };

    cosmosdb:Container|error manualPolicyContainer = managementClient->createContainer(databaseId, containerManualId, 
        partitionKeyManual, (), throughput); 
    if (manualPolicyContainer is cosmosdb:Container) {
        log:print(manualPolicyContainer.toString());
    } else {
        log:printError(manualPolicyContainer.message());
    }  

    log:print("Creating container with autoscaling throughput policy");
    record {|int maxThroughput;|} maxThroughput = { maxThroughput: 4000 };
    cosmosdb:PartitionKey partitionKeyAutoscaling = {
        paths: ["/id"],
        kind: "Hash",
        keyVersion: 2
    };

    cosmosdb:Container|error autoPolicyContainer = managementClient->createContainer(databaseId, containerManualId, 
        partitionKeyManual, (), maxThroughput);  
    if (autoPolicyContainer is cosmosdb:Container) {
        log:print(autoPolicyContainer.toString());
    } else {
        log:printError(autoPolicyContainer.message());
    } 

    log:print("Creating container if not exist");
    cosmosdb:PartitionKey partitionKeyDefinition = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };
    cosmosdb:Container?|error containerIfNotExistResult = managementClient->createContainer(databaseId, 
        containerIfnotExistId, partitionKeyDefinition);
    if (containerIfNotExistResult is cosmosdb:Container?) {
        log:print(containerIfNotExistResult.toString());
    } else {
        log:printError(containerIfNotExistResult.message());
    } 

    string? etag;
    string? sessiontoken;     
    log:print("Reading container info");
    cosmosdb:Container|error existingContainer = managementClient->getContainer(databaseId, containerId);

    if (existingContainer is cosmosdb:Container) {
        log:print(existingContainer.toString());
        etag = existingContainer?.eTag;
        sessiontoken = existingContainer?.sessionToken;    
    } else {
        log:printError(existingContainer.message());
    }
    
    log:print("Reading container info with request options");
    cosmosdb:ResourceReadOptions options = {
        consistancyLevel: "Bounded"
    };
    cosmosdb:Container|error getContainerWithOptions = managementClient->getContainer(databaseId, containerId, options);

    if (getContainerWithOptions is cosmosdb:Container) {
        log:print(getContainerWithOptions.toString());
    } else {
        log:printError(getContainerWithOptions.message());
    }

    log:print("Getting list of containers");
    stream<cosmosdb:Container>|error containerList = managementClient->listContainers(databaseId, 2);

    if (containerList is stream<cosmosdb:Container>) {
        error? e = containerList.forEach(function (cosmosdb:Container container) {
            log:print(container.toString());
        });
    } else {
        log:printError(containerList.message());
    }

    log:print("Deleting the container");
    cosmosdb:DeleteResponse|error deletionResult = managementClient->deleteContainer(databaseId, containerId);

    if (deletionResult is cosmosdb:DeleteResponse) {
        log:print(deletionResult.toString());
    } else{
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
