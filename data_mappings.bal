// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

// # Maps the json response returned from the request into record type of Database.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type Database.
isolated function mapJsonToDatabaseType([json, ResponseMetadata?] jsonPayload) returns Database {
    Database database = {};
    var [payload, headers] = jsonPayload;
    database.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    database.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    database.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        database.responseHeaders = headers;
    }
    return database;
}

// # Maps the json response returned from the request into record type of Container.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type Container.
isolated function mapJsonToContainerType([json, ResponseMetadata?] jsonPayload) returns @tainted Container {
    Container container = {};
    var [payload, headers] = jsonPayload;
    container.id = payload.id.toString();
    container.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    container.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    container.indexingPolicy = mapJsonToIndexingPolicy(<json>payload.indexingPolicy);
    container.partitionKey = convertJsonToPartitionKeyType(<json>payload.partitionKey);
    if (headers is ResponseMetadata) {
        container.responseHeaders = headers;
    }
    return container;
}

// # Maps the json response returned from the request into record type of Document.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type Document.
isolated function mapJsonToDocumentType([json, ResponseMetadata?] jsonPayload) returns @tainted Document {
    Document document = {};
    var [payload, headers] = jsonPayload;
    document.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    document.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    document.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    map<json>|error documentBodyJson = payload.cloneWithType(JsonMap); /// Why this does not work with map<json>??
    if (documentBodyJson is map<json>) {
        document.documentBody = mapJsonToDocumentBody(documentBodyJson);
    }
    if (headers is ResponseMetadata) {
        document.responseHeaders = headers;
    }
    return document;
}

// # Format the json response returned from the request to contain only the document. 
// #
// # + reponsePayload - A json map which contains json payload returned from the request.
// # + return - Json object which contains only the document.
isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns json {
    var deleteKeys = [JSON_KEY_ID, JSON_KEY_RESOURCE_ID, JSON_KEY_SELF_REFERENCE, JSON_KEY_ETAG, JSON_KEY_TIMESTAMP, 
    JSON_KEY_ATTACHMENTS];
    foreach var keyValue in deleteKeys {
        if (reponsePayload.hasKey(keyValue)) {
            var removedValue = reponsePayload.remove(keyValue);
        }
    }
    return reponsePayload;
}

// # Maps the json response returned from the request into record type of IndexingPolicy.
// #
// # + jsonPayload - The json object returned from request.
// # + return - An instance of record type IndexingPolicy.
isolated function mapJsonToIndexingPolicy(json jsonPayload) returns @tainted IndexingPolicy {
    IndexingPolicy indexingPolicy = {};
    indexingPolicy.indexingMode = jsonPayload.indexingMode != () ? jsonPayload.indexingMode.toString() : EMPTY_STRING;
    indexingPolicy.automatic = convertToBoolean(jsonPayload.automatic);
    indexingPolicy.includedPaths = convertToIncludedPathsArray(<json[]>jsonPayload.includedPaths);
    indexingPolicy.excludedPaths = convertToIncludedPathsArray(<json[]>jsonPayload.excludedPaths);
    return indexingPolicy;
}

// # Maps the json response returned from the request into record type of PartitionKey.
// #
// # + jsonPayload - The json object returned from request.
// # + return - An instance of record type PartitionKey.
isolated function convertJsonToPartitionKeyType(json jsonPayload) returns @tainted PartitionKey {
    PartitionKey partitionKey = {};
    partitionKey.paths = convertToStringArray(<json[]>jsonPayload.paths);
    partitionKey.keyVersion = convertToInt(jsonPayload.'version);
    return partitionKey;
}

// # Maps the json response returned from the request into record type of PartitionKeyRange.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type PartitionKeyRange.
isolated function mapJsonToPartitionKeyRange([json, ResponseMetadata?] jsonPayload) returns @tainted PartitionKeyRange {
    PartitionKeyRange partitionKeyRange = {};
    var [payload, headers] = jsonPayload;
    partitionKeyRange.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    partitionKeyRange.minInclusive = payload.minInclusive != () ? payload.minInclusive.toString() : EMPTY_STRING;
    partitionKeyRange.maxExclusive = payload.maxExclusive != () ? payload.maxExclusive.toString() : EMPTY_STRING;
    partitionKeyRange.status = payload.status != () ? payload.status.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        partitionKeyRange.responseHeaders = headers;
    }
    return partitionKeyRange;
}

// # Maps the json response returned from the request into record type of IncludedPath.
// #
// # + jsonPayload - The json object returned from request.
// # + return - An instance of record type IncludedPath.
isolated function mapJsonToIncludedPathsType(json jsonPayload) returns @tainted IncludedPath {
    IncludedPath includedPath = {};
    includedPath.path = jsonPayload.path.toString();
    if (jsonPayload.indexes is error) {
        return includedPath;
    } else {
        includedPath.indexes = convertToIndexArray(<json[]>jsonPayload.indexes);
    }
    return includedPath;
}

// # Maps the json response returned from the request into record type of Index.
// #
// # + jsonPayload - The json object returned from request.
// # + return - An instance of record type Index.
isolated function mapJsonToIndexType(json jsonPayload) returns Index {
    Index index = {};
    index.kind = jsonPayload.kind != () ? jsonPayload.kind.toString() : EMPTY_STRING;
    index.dataType = jsonPayload.dataType.toString();
    index.precision = convertToInt(jsonPayload.precision);
    return index;
}

// # Maps the json response returned from the request into record type of StoredProcedure.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type StoredProcedure.
isolated function mapJsonToStoredProcedureResponse([json, ResponseMetadata?] jsonPayload) returns @tainted StoredProcedureResponse {
    StoredProcedureResponse storedProcedureResponse = {};
    var [payload, headers] = jsonPayload;
    storedProcedureResponse.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    storedProcedureResponse.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    storedProcedureResponse.storedProcedure = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        storedProcedureResponse.responseHeaders = headers;
    }
    return storedProcedureResponse;
}

// # Maps the json response returned from the request into record type of UserDefinedFunction.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type UserDefinedFunction.
isolated function mapJsonToUserDefinedFunctionResponse([json, ResponseMetadata?] jsonPayload) returns @tainted 
UserDefinedFunctionResponse {
    UserDefinedFunctionResponse userDefinedFunctionResponse = {};
    var [payload, headers] = jsonPayload;
    userDefinedFunctionResponse.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.userDefinedFunction = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        userDefinedFunctionResponse.responseHeaders = headers;
    }
    return userDefinedFunctionResponse;
}

// # Maps the json response returned from the request into record type of Trigger.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type Trigger.
isolated function mapJsonToTriggerResponse([json, ResponseMetadata?] jsonPayload) returns @tainted TriggerResponse {
    TriggerResponse triggerResponse = {};
    var [payload, headers] = jsonPayload;
    triggerResponse.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    triggerResponse.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    triggerResponse.triggerFunction = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    triggerResponse.triggerOperation = payload.triggerOperation != () ? payload.triggerOperation.toString() : EMPTY_STRING;
    triggerResponse.triggerType = payload.triggerType != () ? payload.triggerType.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        triggerResponse.responseHeaders = headers;
    }
    return triggerResponse;
}

// # Maps the json response returned from the request into record type of User.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type User.
isolated function mapJsonToUserType([json, ResponseMetadata?] jsonPayload) returns @tainted User {
    User user = {};
    var [payload, headers] = jsonPayload;
    user.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    user.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        user.responseHeaders = headers;
    }
    return user;
}

// # Maps the json response returned from the request into record type of Permission.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type Permission.
isolated function mapJsonToPermissionType([json, ResponseMetadata?] jsonPayload) returns @tainted Permission {
    Permission permission = {};
    var [payload, headers] = jsonPayload;
    permission.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    permission.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    permission.token = payload._token != () ? payload._token.toString() : EMPTY_STRING;
    permission.permissionMode = payload.permissionMode != () ? payload.permissionMode.toString() : EMPTY_STRING;
    permission.resourcePath = payload.'resource != () ? payload.'resource.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        permission.responseHeaders = headers;
    }
    return permission;
}

// # Maps the json response returned from the request into record type of Offer.
// #
// # + jsonPayload - A tuple which contains headers and json object returned from request.
// # + return - An instance of record type Offer.
isolated function mapJsonToOfferType([json, ResponseMetadata?] jsonPayload) returns @tainted Offer {
    Offer offer = {};
    var [payload, headers] = jsonPayload;
    offer.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    offer.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    offer.offerVersion = payload.offerVersion != () ? payload.offerVersion.toString() : EMPTY_STRING;
    offer.offerType = payload.offerType != () ? payload.offerType.toString() : EMPTY_STRING;
    offer.content = payload.content != () ? payload.content.toString() : EMPTY_STRING;
    offer.resourceSelfLink = payload.'resource != () ? payload.'resource.toString() : EMPTY_STRING;
    offer.resourceResourceId = payload.offerResourceId != () ? payload.offerResourceId.toString() : EMPTY_STRING;
    if (headers is ResponseMetadata) {
        offer.responseHeaders = headers;
    }
    return offer;
}

// # Convert json array of database information in to an array of type Database.
// #
// # + databases - An existing array of type Database.
// # + sourceDatabaseArrayJsonObject - Json object which contain the array of database information.
// # + return - An array of type Database.
isolated function convertToDatabaseArray(@tainted Database[] databases, json[] sourceDatabaseArrayJsonObject) returns 
                                    @tainted Database[] {
    int i = databases.length();
    foreach json jsonDatabase in sourceDatabaseArrayJsonObject {
        databases[i] = mapJsonToDatabaseType([jsonDatabase, ()]);
        i = i + 1;
    }
    return databases;
}

// # Convert json array of container information in to an array of type Container.
// #
// # + containers - An existing array of type Container.
// # + sourceContainerArrayJsonObject - Json object which contain the array of container information.
// # + return - An array of type Container.
isolated function convertToContainerArray(@tainted Container[] containers, json[] sourceContainerArrayJsonObject) returns 
                                @tainted Container[] {
    int i = containers.length();
    foreach json jsonCollection in sourceContainerArrayJsonObject {
        containers[i] = mapJsonToContainerType([jsonCollection, ()]);
        i = i + 1;
    }
    return containers;
}

// # Convert json array of document information in to an array of type Document.
// #
// # + documents - An existing array of type Document.
// # + sourceDocumentArrayJsonObject - Json object which contain the array of document information.
// # + return - An array of type Document.
isolated function convertToDocumentArray(@tainted Document[] documents, json[] sourceDocumentArrayJsonObject) returns 
                                @tainted Document[] {
    int i = documents.length();
    foreach json document in sourceDocumentArrayJsonObject {
        documents[i] = mapJsonToDocumentType([document, ()]);
        i = i + 1;
    }
    return documents;
}

// # Convert json array of stored procedure information in to an array of type StoredProcedure.
// #
// # + storedProcedures - An existing array of type StoredProcedure.
// # + sourceStoredProcedureArrayJsonObject - Json object which contain the array of stored procedure information.
// # + return - An array of type StoredProcedure.
isolated function convertToStoredProcedureArray(@tainted StoredProcedureResponse[] storedProcedures, 
                                json[] sourceStoredProcedureArrayJsonObject) returns @tainted StoredProcedureResponse[] {
    int i = storedProcedures.length();
    foreach json storedProcedure in sourceStoredProcedureArrayJsonObject {
        storedProcedures[i] = mapJsonToStoredProcedureResponse([storedProcedure, ()]);
        i = i + 1;
    }
    return storedProcedures;
}

// # Convert json array of user defined function information in to an array of type UserDefinedFunction.
// #
// # + userDefinedFunctions - An existing array of type UserDefinedFunction.
// # + sourceUdfArrayJsonObject - Json object which contain the array of user defined function information.
// # + return - An array of type UserDefinedFunction.
isolated function convertsToUserDefinedFunctionArray(@tainted UserDefinedFunctionResponse[] userDefinedFunctions, 
                                json[] sourceUdfArrayJsonObject) returns @tainted UserDefinedFunctionResponse[] {
    int i = userDefinedFunctions.length();
    foreach json userDefinedFunction in sourceUdfArrayJsonObject {
        userDefinedFunctions[i] = mapJsonToUserDefinedFunctionResponse([userDefinedFunction, ()]);
        i = i + 1;
    }
    return userDefinedFunctions;
}

// # Convert json array of trigger information in to an array of type Trigger.
// #
// # + triggers - An existing array of type Trigger.
// # + sourceTriggerArrayJsonObject - Json object which contain the array of trigger information.
// # + return - An array of type Trigger.
isolated function convertToTriggerArray(@tainted TriggerResponse[] triggers, json[] sourceTriggerArrayJsonObject) returns 
                                @tainted TriggerResponse[] {
    int i = triggers.length();
    foreach json trigger in sourceTriggerArrayJsonObject {
        triggers[i] = mapJsonToTriggerResponse([trigger, ()]);
        i = i + 1;
    }
    return triggers;
}

// # Convert json array of user information in to an array of type User.
// #
// # + users - An existing array of type User.
// # + sourceUserArrayJsonObject - Json object which contain the array of user information.
// # + return - An array of type User.
isolated function convertToUserArray(@tainted User[] users, json[] sourceUserArrayJsonObject) returns @tainted User[] {
    int i = users.length();
    foreach json user in sourceUserArrayJsonObject {
        users[i] = mapJsonToUserType([user, ()]);
        i = i + 1;
    }
    return users;
}

// # Convert json array of permission information in to an array of type Permission.
// #
// # + permissions - An existing array of type Permission.
// # + sourcePermissionArrayJsonObject - Json object which contain the array of permission information.
// # + return - An array of type Permission.
isolated function convertToPermissionArray(@tainted Permission[] permissions, json[] sourcePermissionArrayJsonObject) 
returns @tainted Permission[] {
    int i = permissions.length();
    foreach json permission in sourcePermissionArrayJsonObject {
        permissions[i] = mapJsonToPermissionType([permission, ()]);
        i = i + 1;
    }
    return permissions;
}

// # Convert json array of offer infromation in to an array of type Offer.
// #
// # + offers - An existing array of type Offer
// # + sourceOfferArrayJsonObject - Json object which contain the array of offer information.
// # + return - An array of type Offer.
isolated function ConvertToOfferArray(@tainted Offer[] offers, json[] sourceOfferArrayJsonObject) returns 
@tainted Offer[] {
    int i = offers.length();
    foreach json offer in sourceOfferArrayJsonObject {
        offers[i] = mapJsonToOfferType([offer, ()]);
        i = i + 1;
    }
    return offers;
}

// # Convert json array of included path information in to an array of type IncludedPath.
// #
// # + sourcePathArrayJsonObject - Json object which contain the array of included path information.
// # + return - An array of type IncludedPath.
isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] {
    IncludedPath[] includedPaths = [];
    int i = 0;
    foreach json jsonPath in sourcePathArrayJsonObject {
        includedPaths[i] = <IncludedPath>mapJsonToIncludedPathsType(jsonPath);
        i = i + 1;
    }
    return includedPaths;
}

// # Convert json array of partition key ranges in to an array of type PartitionKeyRange.
// #
// # + sourcePrtitionKeyArrayJsonObject - Json object which contain the array of partition key range information.
// # + return - An array of type PartitionKeyRange.
isolated function convertToPartitionKeyRangeArray(json[] sourcePrtitionKeyArrayJsonObject) returns @tainted 
PartitionKeyRange[] {
    PartitionKeyRange[] partitionKeyRanges = [];
    int i = 0;
    foreach json jsonPartitionKey in sourcePrtitionKeyArrayJsonObject {
        partitionKeyRanges[i].id = jsonPartitionKey.id.toString();
        partitionKeyRanges[i].minInclusive = jsonPartitionKey.minInclusive.toString();
        partitionKeyRanges[i].maxExclusive = jsonPartitionKey.maxExclusive.toString();
        partitionKeyRanges[i].status = jsonPartitionKey.status.toString();
        i = i + 1;
    }
    return partitionKeyRanges;
}

// # Convert json array of indexes in to an array of type Index.
// #
// # + sourceIndexArrayJsonObject - Json object which contain the array of index information.
// # + return - An array of type Index.
isolated function convertToIndexArray(json[] sourceIndexArrayJsonObject) returns @tainted Index[] {
    Index[] indexes = [];
    int i = 0;
    foreach json index in sourceIndexArrayJsonObject {
        indexes[i] = mapJsonToIndexType(index);
        i = i + 1;
    }
    return indexes;
}

// # Convert json array with strings in to an array of type string.
// #
// # + sourceArrayJsonObject - Json object which contain the array of strings. 
// # + return - An array of type string.
isolated function convertToStringArray(json[] sourceArrayJsonObject) returns @tainted string[] {
    string[] strings = [];
    int i = 0;
    foreach json str in sourceArrayJsonObject {
        strings[i] = str.toString();
        i = i + 1;
    }
    return strings;
}
