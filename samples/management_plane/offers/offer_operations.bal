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

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Get database container to get the resource ids of them.
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);

    log:print("List the offers in the current cosmos db account");   
    stream<cosmosdb:Offer> offerList = checkpanic managementClient->listOffers(10);
    var offer = offerList.next();
    string? offerId = <@untainted>offer?.value?.id;
    string? resourceId = offer?.value?.resourceId;

    if (offerId is string && resourceId is string) {
        log:print("Get information about one offer");   
        cosmosdb:Offer result3 = checkpanic managementClient->getOffer(offerId);

        log:print("Replace offer");   
        cosmosdb:Offer replaceOfferBody = {
            offerVersion: "V2",
            offerType: "Invalid",
            content: {"offerThroughput": 1000},
            resourceSelfLink: string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`, /// not found in the result
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: offerId,
            resourceId: resourceId
        };
        cosmosdb:Result offerReplaceResult = checkpanic managementClient->replaceOffer(<@untainted>replaceOfferBody);
    }

    // Replace Offer updating optional parameters

    // Query offers
    log:print("Query offers");
    string offersInContainerQuery = string `SELECT * FROM ${containerId} f WHERE (f["_self"]) = "${container?.selfReference.toString()}"`;
    int maximumItemCount = 20;
    cosmosdb:Query offerQuery = {
        query: offersInContainerQuery
    };
    stream<json> result6 = checkpanic managementClient->queryOffer(<@untainted>offerQuery, maximumItemCount);
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
