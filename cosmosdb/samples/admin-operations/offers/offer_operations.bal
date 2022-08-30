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

cosmosdb:ManagementClientConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = check new (config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();
    string? offerId = ();
    string? resourceId = ();

    // Get database container to get the resource ids of them.
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);

    log:printInfo("List the offers in the current cosmos db account");   
    stream<cosmosdb:Offer, error?>|error offerList = checkpanic managementClient->listOffers();

    if (offerList is stream<cosmosdb:Offer, error?>) {
        record {|cosmosdb:Offer value;|}|error? offer = offerList.next();
        if (offer is record {|cosmosdb:Offer value;|}) {
            offerId = <@untainted>offer.value.id;
            resourceId = offer?.value?.resourceId;
        }
    }

    if (offerId is string && resourceId is string) {
        log:printInfo("Get information about one offer");   
        cosmosdb:Offer result3 = checkpanic managementClient->getOffer(offerId);

        log:printInfo("Replace offer");   
        string resourceSelfLink = 
            string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}/`;
        cosmosdb:Offer replaceOfferBody = {
            offerVersion: "V2",
            offerType: "Invalid",
            content: {"offerThroughput": 1000},
            resourceSelfLink: resourceSelfLink, 
            resourceResourceId: string `${container?.resourceId.toString()}`,
            id: offerId,
            resourceId: resourceId
        };
        cosmosdb:Offer offerReplaceResult = checkpanic managementClient->replaceOffer(<@untainted>replaceOfferBody);
    }

    // Replace Offer updating optional parameters

    // Query offers
    log:printInfo("Query offers");
    string offersInContainerQuery = 
        string `SELECT * FROM ${containerId} f WHERE (f["_self"]) = "${container?.selfReference.toString()}"`;
    int maximumItemCount = 20;
    stream<cosmosdb:QueryResult, error?>|error result = checkpanic managementClient->
        queryOffer(<@untainted>offersInContainerQuery);
    log:printInfo("Success!");
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
