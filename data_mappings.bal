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

import ballerina/lang.array as array;

//  Maps the json response returned from the request into record type of Document.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Document.
isolated function mapTupleToResultType([boolean, ResponseHeaders] jsonPayload) returns @tainted Result {
    Result result = {};
    var [status, headers] = jsonPayload;
    result.success = status ? true : false;
    result.eTag = headers.eTag.toString();
    result.sessionToken = headers.sessionToken.toString();
    return result;
}

//  Maps the json response returned from the request into record type of Database.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Database.
isolated function mapJsonToDatabaseType([json, ResponseHeaders?] jsonPayload) returns Database {
    Database database = {};
    var [payload, headers] = jsonPayload;
    database.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    database.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    database.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    database.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    database.sessionToken = headers?.sessionToken.toString();
    return database;
}

//  Maps the json response returned from the request into record type of Container.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Container.
isolated function mapJsonToContainerType([json, ResponseHeaders?] jsonPayload) returns @tainted Container {
    Container container = {};
    var [payload, headers] = jsonPayload;
    container.id = payload.id.toString();
    container.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    container.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    container.indexingPolicy = mapJsonToIndexingPolicy(<json>payload.indexingPolicy);
    container.partitionKey = convertJsonToPartitionKeyType(<json>payload.partitionKey);
    container.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    container.sessionToken = headers?.sessionToken.toString();
    return container;
}

//  Maps the json response returned from the request into record type of Document.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Document.
isolated function mapJsonToDocumentType([json, ResponseHeaders?] jsonPayload) returns @tainted Document {
    Document document = {};
    var [payload, headers] = jsonPayload;
    document.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    document.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    document.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    map<json>|error documentBodyJson = payload.cloneWithType(JsonMap); /// Why this does not work with map<json>??
    if (documentBodyJson is map<json>) {
        document.documentBody = mapJsonToDocumentBody(documentBodyJson);
    }
    document.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    document.sessionToken = headers?.sessionToken.toString();
    return document;
}

//  Format the json response returned from the request to contain only the document. 
// 
//  + reponsePayload - A json map which contains json payload returned from the request.
//  + return - Json object which contains only the document.
isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns json {
    var keysToDelete = [JSON_KEY_ID, JSON_KEY_RESOURCE_ID, JSON_KEY_SELF_REFERENCE, JSON_KEY_ETAG, JSON_KEY_TIMESTAMP, 
    JSON_KEY_ATTACHMENTS];
    foreach var keyValue in keysToDelete {
        if (reponsePayload.hasKey(keyValue)) {
            var removedValue = reponsePayload.remove(keyValue);
        }
    }
    return reponsePayload;
}

//  Maps the json response returned from the request into record type of IndexingPolicy.
// 
//  + jsonPayload - The json object returned from request.
//  + return - An instance of record type IndexingPolicy.
isolated function mapJsonToIndexingPolicy(json jsonPayload) returns @tainted IndexingPolicy {
    IndexingPolicy indexingPolicy = {};
    indexingPolicy.indexingMode = jsonPayload.indexingMode != () ? jsonPayload.indexingMode.toString() : EMPTY_STRING;
    indexingPolicy.automatic = convertToBoolean(jsonPayload.automatic);
    indexingPolicy.includedPaths = convertToIncludedPathsArray(<json[]>jsonPayload.includedPaths);
    indexingPolicy.excludedPaths = convertToExcludedPathsArray(<json[]>jsonPayload.excludedPaths);
    return indexingPolicy;
}

//  Maps the json response returned from the request into record type of PartitionKey.
// 
//  + jsonPayload - The json object returned from request.
//  + return - An instance of record type PartitionKey.
isolated function convertJsonToPartitionKeyType(json jsonPayload) returns @tainted PartitionKey {
    PartitionKey partitionKey = {};
    partitionKey.paths = convertToStringArray(<json[]>jsonPayload.paths);
    partitionKey.keyVersion = convertToInt(jsonPayload.'version);
    return partitionKey;
}

//  Maps the json response returned from the request into record type of PartitionKeyRange.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type PartitionKeyRange.
isolated function mapJsonToPartitionKeyRange([json, ResponseHeaders?] jsonPayload) returns @tainted PartitionKeyRange {
    PartitionKeyRange partitionKeyRange = {};
    var [payload, headers] = jsonPayload;
    partitionKeyRange.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    partitionKeyRange.minInclusive = payload.minInclusive != () ? payload.minInclusive.toString() : EMPTY_STRING;
    partitionKeyRange.maxExclusive = payload.maxExclusive != () ? payload.maxExclusive.toString() : EMPTY_STRING;
    partitionKeyRange.status = payload.status != () ? payload.status.toString() : EMPTY_STRING;
    partitionKeyRange.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    partitionKeyRange.sessionToken = headers?.sessionToken.toString();
    return partitionKeyRange;
}

//  Maps the json response returned from the request into record type of IncludedPath.
// 
//  + jsonPayload - The json object returned from request.
//  + return - An instance of record type IncludedPath.
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

//  Maps the json response returned from the request into record type of ExcludedPath.
// 
//  + jsonPayload - The json object returned from request.
//  + return - An instance of record type IncludedPath.
isolated function mapJsonToExcludedPathsType(json jsonPayload) returns @tainted ExcludedPath {
    ExcludedPath excludedPath = {};
    excludedPath.path = jsonPayload.path.toString();
    return excludedPath;
}

//  Maps the json response returned from the request into record type of Index.
// 
//  + jsonPayload - The json object returned from request.
//  + return - An instance of record type Index.
isolated function mapJsonToIndexType(json jsonPayload) returns Index {
    Index index = {};
    //index.kind = jsonPayload.kind != () ? jsonPayload.kind.toString() : EMPTY_STRING;
    index.dataType = jsonPayload.dataType.toString();
    index.precision = convertToInt(jsonPayload.precision);
    return index;
}

//  Maps the json response returned from the request into record type of StoredProcedure.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type StoredProcedure.
isolated function mapJsonToStoredProcedure([json, ResponseHeaders?] jsonPayload) returns @tainted StoredProcedure {
    StoredProcedure storedProcedureResponse = {};
    var [payload, headers] = jsonPayload;
    storedProcedureResponse.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    storedProcedureResponse.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    storedProcedureResponse.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    storedProcedureResponse.storedProcedure = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    storedProcedureResponse.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    storedProcedureResponse.sessionToken = headers?.sessionToken.toString();
    return storedProcedureResponse;
}

//  Maps the json response returned from the request into record type of UserDefinedFunction.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type UserDefinedFunction.
isolated function mapJsonToUserDefinedFunction([json, ResponseHeaders?] jsonPayload) returns @tainted 
UserDefinedFunction {
    UserDefinedFunction userDefinedFunctionResponse = {};
    var [payload, headers] = jsonPayload;
    userDefinedFunctionResponse.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.userDefinedFunction = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    userDefinedFunctionResponse.sessionToken = headers?.sessionToken.toString();
    return userDefinedFunctionResponse;
}

//  Maps the json response returned from the request into record type of Trigger.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Trigger.
isolated function mapJsonToTrigger([json, ResponseHeaders?] jsonPayload) returns @tainted Trigger {
    Trigger triggerResponse = {};
    var [payload, headers] = jsonPayload;
    triggerResponse.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    triggerResponse.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    triggerResponse.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    triggerResponse.triggerFunction = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    triggerResponse.triggerOperation = payload.triggerOperation != () ? payload.triggerOperation.toString() : EMPTY_STRING;
    triggerResponse.triggerType = payload.triggerType != () ? payload.triggerType.toString() : EMPTY_STRING;
    triggerResponse.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    triggerResponse.sessionToken = headers?.sessionToken.toString();
    return triggerResponse;
}

//  Maps the json response returned from the request into record type of User.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type User.
isolated function mapJsonToUserType([json, ResponseHeaders?] jsonPayload) returns @tainted User {
    User user = {};
    var [payload, headers] = jsonPayload;
    user.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    user.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    user.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    user.selfReference = payload._permissions != () ? payload._permissions.toString() : EMPTY_STRING;
    user.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    user.sessionToken = headers?.sessionToken.toString();
    return user;
}

//  Maps the json response returned from the request into record type of Permission.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Permission.
isolated function mapJsonToPermissionType([json, ResponseHeaders?] jsonPayload) returns @tainted Permission {
    Permission permission = {};
    var [payload, headers] = jsonPayload;
    permission.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    permission.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    permission.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    permission.token = payload._token != () ? payload._token.toString() : EMPTY_STRING;
    permission.permissionMode = payload.permissionMode != () ? payload.permissionMode.toString() : EMPTY_STRING;
    permission.resourcePath = payload.'resource != () ? payload.'resource.toString() : EMPTY_STRING;
    permission.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    permission.sessionToken = headers?.sessionToken.toString();
    return permission;
}

//  Maps the json response returned from the request into record type of Offer.
// 
//  + jsonPayload - A tuple which contains headers and json object returned from request.
//  + return - An instance of record type Offer.
isolated function mapJsonToOfferType([json, ResponseHeaders?] jsonPayload) returns @tainted Offer {
    Offer offer = {};
    var [payload, headers] = jsonPayload;
    offer.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    offer.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    offer.selfReference = payload._self != () ? payload._self.toString() : EMPTY_STRING;
    offer.offerVersion = payload.offerVersion != () ? payload.offerVersion.toString() : EMPTY_STRING;
    offer.offerType = payload.offerType != () ? payload.offerType.toString() : EMPTY_STRING;
    offer.content = payload.content != () ? payload.content.toString() : EMPTY_STRING;
    offer.resourceSelfLink = payload.'resource != () ? payload.'resource.toString() : EMPTY_STRING;
    offer.resourceResourceId = payload.offerResourceId != () ? payload.offerResourceId.toString() : EMPTY_STRING;
    offer.eTag = payload._etag != () ? payload._etag.toString() : EMPTY_STRING;
    offer.sessionToken = headers?.sessionToken.toString();
    return offer;
}

//  Convert json array of database information in to an array of type Database.
// 
//  + databases - An existing array of type Database.
//  + sourceDatabaseArrayJsonObject - Json object which contain the array of database information.
//  + return - An array of type Database.
isolated function convertToDatabaseArray(json[] sourceDatabaseArrayJsonObject) returns Database[] {
    Database[] databases = [];
    foreach json databaseObject in sourceDatabaseArrayJsonObject {
        Database database = mapJsonToDatabaseType([databaseObject, ()]);
        array:push(databases, database);
    }
    return databases;
}

//  Convert json array of container information in to an array of type Container.
// 
//  + containers - An existing array of type Container.
//  + sourceContainerArrayJsonObject - Json object which contain the array of container information.
//  + return - An array of type Container.
isolated function convertToContainerArray(json[] sourceContainerArrayJsonObject) returns Container[] {
    Container[] containers = [];  
    foreach json jsonCollection in sourceContainerArrayJsonObject {
        Container container = mapJsonToContainerType([jsonCollection, ()]);
        array:push(containers, container);
    }
    return containers;
}

//  Convert json array of document information in to an array of type Document.
// 
//  + documents - An existing array of type Document.
//  + sourceDocumentArrayJsonObject - Json object which contain the array of document information.
//  + return - An array of type Document.
isolated function convertToDocumentArray(json[] sourceDocumentArrayJsonObject) returns Document[] {
    Document[] documents = [];
    foreach json documentObject in sourceDocumentArrayJsonObject {
        Document document = mapJsonToDocumentType([documentObject, ()]);
        array:push(documents, document);
    }
    return documents;
}

//  Convert json array of stored procedure information in to an array of type StoredProcedure.
// 
//  + storedProcedures - An existing array of type StoredProcedure.
//  + sourceStoredProcedureArrayJsonObject - Json object which contain the array of stored procedure information.
//  + return - An array of type StoredProcedure.
isolated function convertToStoredProcedureArray(json[] sourceStoredProcedureArrayJsonObject) returns StoredProcedure[] {
    StoredProcedure[] storedProcedures = [];
    foreach json storedProcedureObject in sourceStoredProcedureArrayJsonObject {
        StoredProcedure storedProcedure = mapJsonToStoredProcedure([storedProcedureObject, ()]);
        array:push(storedProcedures, storedProcedure);
    }
    return storedProcedures;
}

//  Convert json array of user defined function information in to an array of type UserDefinedFunction.
// 
//  + userDefinedFunctions - An existing array of type UserDefinedFunction.
//  + sourceUdfArrayJsonObject - Json object which contain the array of user defined function information.
//  + return - An array of type UserDefinedFunction.
isolated function convertsToUserDefinedFunctionArray(json[] sourceUdfArrayJsonObject) returns UserDefinedFunction[] {
    UserDefinedFunction[] userDefinedFunctions = [];
    foreach json userDefinedFunctionObject in sourceUdfArrayJsonObject {
        UserDefinedFunction userDefinedFunction = mapJsonToUserDefinedFunction([userDefinedFunctionObject, ()]);
        array:push(userDefinedFunctions, userDefinedFunction);
    }
    return userDefinedFunctions;
}

//  Convert json array of trigger information in to an array of type Trigger.
// 
//  + triggers - An existing array of type Trigger.
//  + sourceTriggerArrayJsonObject - Json object which contain the array of trigger information.
//  + return - An array of type Trigger.
isolated function convertToTriggerArray(json[] sourceTriggerArrayJsonObject) returns Trigger[] {
    Trigger[] triggers = [];
    foreach json triggerObject in sourceTriggerArrayJsonObject {
        Trigger trigger = mapJsonToTrigger([triggerObject, ()]);
        array:push(triggers, trigger);
    }
    return triggers;
}

//  Convert json array of user information in to an array of type User.
// 
//  + users - An existing array of type User.
//  + sourceUserArrayJsonObject - Json object which contain the array of user information.
//  + return - An array of type User.
isolated function convertToUserArray(json[] sourceUserArrayJsonObject) returns User[] {
    User[] users = [];
    foreach json userObject in sourceUserArrayJsonObject {
        User user = mapJsonToUserType([userObject, ()]);
        array:push(users, user);
    }
    return users;
}

//  Convert json array of permission information in to an array of type Permission.
// 
//  + permissions - An existing array of type Permission.
//  + sourcePermissionArrayJsonObject - Json object which contain the array of permission information.
//  + return - An array of type Permission.
isolated function convertToPermissionArray(json[] sourcePermissionArrayJsonObject) returns Permission[] {
    Permission[] permissions = [];
    foreach json permissionObject in sourcePermissionArrayJsonObject {
        Permission permission = mapJsonToPermissionType([permissionObject, ()]);
        array:push(permissions, permission);
    }
    return permissions;
}

//  Convert json array of offer infromation in to an array of type Offer.
// 
//  + offers - An existing array of type Offer
//  + sourceOfferArrayJsonObject - Json object which contain the array of offer information.
//  + return - An array of type Offer.
isolated function convertToOfferArray(json[] sourceOfferArrayJsonObject) returns Offer[] {
    Offer[] offers = [];
    foreach json offerObject in sourceOfferArrayJsonObject {
        Offer offer = mapJsonToOfferType([offerObject, ()]);
        array:push(offers, offer);
    }
    return offers;
}

//  Convert json array of included path information in to an array of type IncludedPath.
// 
//  + sourcePathArrayJsonObject - Json object which contain the array of included path information.
//  + return - An array of type IncludedPath.
isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] {
    IncludedPath[] includedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        IncludedPath includedPath = mapJsonToIncludedPathsType([jsonPathObject, ()]);
        array:push(includedPaths, includedPath);
    }
    return includedPaths;
}

//  Convert json array of included path information in to an array of type IncludedPath.
// 
//  + sourcePathArrayJsonObject - Json object which contain the array of included path information.
//  + return - An array of type IncludedPath.
isolated function convertToExcludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted ExcludedPath[] {
    ExcludedPath[] excludedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        ExcludedPath excludedPath = mapJsonToExcludedPathsType([jsonPathObject, ()]);
        array:push(excludedPaths, excludedPath);
    }
    return excludedPaths;
}

//  Convert json array of partition key ranges in to an array of type PartitionKeyRange.
// 
//  + sourcePrtitionKeyArrayJsonObject - Json object which contain the array of partition key range information.
//  + return - An array of type PartitionKeyRange.
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

//  Convert json array of indexes in to an array of type Index.
// 
//  + sourceIndexArrayJsonObject - Json object which contain the array of index information.
//  + return - An array of type Index.
isolated function convertToIndexArray(json[] sourceIndexArrayJsonObject) returns @tainted Index[] {
    Index[] indexes = [];
    foreach json indexObject in sourceIndexArrayJsonObject {
        Index index = mapJsonToIndexType([indexObject, ()]);
        array:push(indexes, index);
    }
    return indexes;
}

//  Convert json array with strings in to an array of type string.
// 
//  + sourceArrayJsonObject - Json object which contain the array of strings. 
//  + return - An array of type string.
isolated function convertToStringArray(json[] sourceArrayJsonObject) returns @tainted string[] {
    string[] strings = [];
    foreach json stringObject in sourceArrayJsonObject {
        array:push(strings, stringObject.toString());
    }
    return strings;
}
