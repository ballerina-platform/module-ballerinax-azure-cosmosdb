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

import ballerina/lang.array as array;

// Maps the JSON response and response headers returned from the request into record type of Result.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Result
isolated function mapTupleToResultType([boolean, ResponseHeaders] jsonPayload) returns @tainted Result {
    var [status, headers] = jsonPayload;
    Result result = {
        eTag: <string>headers.eTag,
        sessionToken: <string>headers.sessionToken
    };
    return result;
}

// Maps the JSON response and response headers returned from the request into record type of Database.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Database
isolated function mapJsonToDatabaseType([json, ResponseHeaders?] jsonPayload) returns Database {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING
    };
}

// Maps the JSON response and response headers returned from the request into record type of Container.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Container
isolated function mapJsonToContainerType([json, ResponseHeaders?] jsonPayload) returns @tainted Container {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        indexingPolicy: let var indexingPolicy = <json>payload.indexingPolicy in mapJsonToIndexingPolicy(indexingPolicy),
        partitionKey: let var partitionKey = <json>payload.partitionKey in convertJsonToPartitionKeyType(partitionKey)
    };
}

// Maps the JSON response returned from the request into record type of IndexingPolicy.
// 
// + jsonPayload - The JSON object returned from request
// + return - An instance of record type IndexingPolicy
isolated function mapJsonToIndexingPolicy(json jsonPayload) returns @tainted IndexingPolicy {
    return {
        indexingMode: let var indexingMode = jsonPayload.indexingMode in indexingMode is string ? indexingMode : 
                EMPTY_STRING,
        automatic: let var automatic = <json>jsonPayload.automatic in convertToBoolean(automatic),
        includedPaths: let var includedPaths = <json[]>jsonPayload.includedPaths in convertToIncludedPathsArray(includedPaths),
        excludedPaths: let var excludedPaths = <json[]>jsonPayload.excludedPaths in convertToExcludedPathsArray(excludedPaths)
    };
}

// Maps the JSON response returned from the request into record type of IncludedPath.
// 
// + jsonPayload - The JSON object returned from request
// + return - An instance of record type IncludedPath
isolated function mapJsonToIncludedPathsType(json jsonPayload) returns @tainted IncludedPath {
    IncludedPath includedPath = {
        path: let var path = jsonPayload.path in path is string ? path : EMPTY_STRING
    };
    if (jsonPayload.indexes is error) {
        return includedPath;
    }
    includedPath.indexes = let var indexes = jsonPayload.indexes in indexes is json[] ? convertToIndexArray(indexes) :[];
    return includedPath;
}

// Maps the JSON response returned from the request into record type of ExcludedPath.
// 
// + jsonPayload - The JSON object returned from request
// + return - An instance of record type ExcludedPath
isolated function mapJsonToExcludedPathsType(json jsonPayload) returns @tainted ExcludedPath {
    return {
        path: let var path = jsonPayload.path in path is string ? path : EMPTY_STRING
    };
}

// Maps the JSON response and response headers returned from the request into record type of Document.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Document
isolated function mapJsonToDocumentType([json, ResponseHeaders?] jsonPayload) returns @tainted Document {
    var [payload, headers] = jsonPayload;
    Document document = {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING
    };
    map<json>|error documentBodyJson = payload.cloneWithType(JsonMap);
    if (documentBodyJson is map<json>) {
        document.documentBody = mapJsonToDocumentBody(documentBodyJson);
    }
    return document;
}

// Format the JSON map returned from the request to contain only the document. 
// 
// + reponsePayload - A JSON map which contains JSON payload returned from the request
// + return - JSON object which contains only the document
isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns json {
    final var keysToDelete = [JSON_KEY_ID, JSON_KEY_RESOURCE_ID, JSON_KEY_SELF_REFERENCE, JSON_KEY_ETAG, JSON_KEY_TIMESTAMP, 
            JSON_KEY_ATTACHMENTS];
    foreach var keyValue in keysToDelete {
        if (reponsePayload.hasKey(keyValue)) {
            var removedValue = reponsePayload.remove(keyValue);
        }
    }
    return reponsePayload;
}

// Maps the JSON response returned from the request into record type of PartitionKey.
// 
// + jsonPayload - The JSON object returned from request
// + return - An instance of record type PartitionKey
isolated function convertJsonToPartitionKeyType(json jsonPayload) returns @tainted PartitionKey {
    return {
        paths: let var paths = <json[]>jsonPayload.paths in convertToStringArray(paths),
        keyVersion: let var keyVersion = <json>jsonPayload.'version in convertToInt(keyVersion)
    };
}

// Maps the JSON response and response headers returned from the request into record type of PartitionKeyRange.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type PartitionKeyRange
isolated function mapJsonToPartitionKeyRange([json, ResponseHeaders?] jsonPayload) returns @tainted PartitionKeyRange {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        minInclusive: let var minInclusive = payload.minInclusive in minInclusive is string ? minInclusive : EMPTY_STRING,
        maxExclusive: let var maxExclusive = payload.maxExclusive in maxExclusive is string ? maxExclusive : EMPTY_STRING
    };
}

// Maps the JSON response returned from the request into record type of Index.
// 
// + jsonPayload - A JSON object returned from request
// + return - An instance of record type Index
isolated function mapJsonToIndexType(json jsonPayload) returns Index {
    return {
        kind: let var kind = <string>jsonPayload.kind in getIndexType(kind),
        dataType: let var dataType = <string>jsonPayload.dataType in getIndexDataType(dataType),
        precision: let var precision = <string>jsonPayload.precision in convertToInt(precision)
    };
}

// Maps the JSON response and response headers returned from the request into record type of StoredProcedure.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type StoredProcedure
isolated function mapJsonToStoredProcedure([json, ResponseHeaders?] jsonPayload) returns @tainted StoredProcedure {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        storedProcedure: let var sproc = payload.body in sproc is string ? sproc : EMPTY_STRING
    };
}

// Maps the JSON response and response headers returned from the request into record type of UserDefinedFunction.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type UserDefinedFunction
isolated function mapJsonToUserDefinedFunction([json, ResponseHeaders?] jsonPayload) returns @tainted 
        UserDefinedFunction {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        userDefinedFunction: let var udf = payload.body in udf is string ? udf : EMPTY_STRING
    };
}

// Maps the JSON response and response headers returned from the request into record type of Trigger.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Trigger
isolated function mapJsonToTrigger([json, ResponseHeaders?] jsonPayload) returns @tainted Trigger {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        triggerFunction: let var func = payload.body in func is string ? func : EMPTY_STRING,
        triggerOperation: let var oper = <string>payload.triggerOperation in getTriggerOperation(oper),
        triggerType: let var triggerType = <string>payload.triggerType in getTriggerType(triggerType)
    };
}

// Maps the JSON response and response headers returned from the request into record type of User.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type User
isolated function mapJsonToUserType([json, ResponseHeaders?] jsonPayload) returns @tainted User {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        permissions: let var permissions = payload._permissions in permissions is string ? permissions : EMPTY_STRING
    };
}

// Maps the JSON response and response headers returned from the request into record type of Permission.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Permission
isolated function mapJsonToPermissionType([json, ResponseHeaders?] jsonPayload) returns @tainted Permission {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        token: payload._token != () ? payload._token.toString() : EMPTY_STRING,
        permissionMode: let var mode = <string>payload.permissionMode in getPermisssionMode(mode),
        resourcePath: let var resourcePath = payload.'resource in resourcePath is string ? resourcePath : EMPTY_STRING
    };
}

// Maps the JSON response and response headers returned from the request into record type of Offer.
// 
// + jsonPayload - A tuple which contains headers and JSON object returned from request
// + return - An instance of record type Offer.
isolated function mapJsonToOfferType([json, ResponseHeaders?] jsonPayload) returns @tainted Offer {
    var [payload, headers] = jsonPayload;
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        offerVersion: let var offVersion = <string>payload.offerVersion in getOfferVersion(offVersion),
        offerType: let var offType = <string>payload.offerType in getOfferVersion(offType),
        content: let var content = payload.content in content is string ? content : EMPTY_STRING,
        resourceSelfLink: let var link = payload.'resource in link is string ? link : EMPTY_STRING,
        resourceResourceId: let var resId = payload.offerResourceId in resId is string ? resId : EMPTY_STRING
    };
}

// Convert JSON array of database information in to an array of type Database.
// 
// + sourceDatabaseArrayJsonObject - JSON object which contain the array of database information
// + return - An array of type Database
isolated function convertToDatabaseArray(json[] sourceDatabaseArrayJsonObject) returns Database[] {
    Database[] databases = [];
    foreach json databaseObject in sourceDatabaseArrayJsonObject {
        Database database = mapJsonToDatabaseType([databaseObject, ()]);
        array:push(databases, database);
    }
    return databases;
}

// Convert JSON array of container information in to an array of type Container.
// 
// + sourceContainerArrayJsonObject - JSON object which contain the array of container information
// + return - An array of type Container
isolated function convertToContainerArray(json[] sourceContainerArrayJsonObject) returns Container[] {
    Container[] containers = [];
    foreach json jsonCollection in sourceContainerArrayJsonObject {
        Container container = mapJsonToContainerType([jsonCollection, ()]);
        array:push(containers, container);
    }
    return containers;
}

// Convert JSON array of document information in to an array of type Document.
// 
// + sourceDocumentArrayJsonObject - JSON object which contain the array of document information
// + return - An array of type Document
isolated function convertToDocumentArray(json[] sourceDocumentArrayJsonObject) returns Document[] {
    Document[] documents = [];
    foreach json documentObject in sourceDocumentArrayJsonObject {
        Document document = mapJsonToDocumentType([documentObject, ()]);
        array:push(documents, document);
    }
    return documents;
}

// Convert JSON array of stored procedure information in to an array of type StoredProcedure.
// 
// + sourceStoredProcedureArrayJsonObject - JSON object which contain the array of stored procedure information
// + return - An array of type StoredProcedure
isolated function convertToStoredProcedureArray(json[] sourceStoredProcedureArrayJsonObject) returns StoredProcedure[] {
    StoredProcedure[] storedProcedures = [];
    foreach json storedProcedureObject in sourceStoredProcedureArrayJsonObject {
        StoredProcedure storedProcedure = mapJsonToStoredProcedure([storedProcedureObject, ()]);
        array:push(storedProcedures, storedProcedure);
    }
    return storedProcedures;
}

// Convert JSON array of user defined function information in to an array of type UserDefinedFunction.
// 
// + sourceUdfArrayJsonObject - JSON object which contain the array of user defined function information
// + return - An array of type UserDefinedFunction
isolated function convertsToUserDefinedFunctionArray(json[] sourceUdfArrayJsonObject) returns UserDefinedFunction[] {
    UserDefinedFunction[] userDefinedFunctions = [];
    foreach json userDefinedFunctionObject in sourceUdfArrayJsonObject {
        UserDefinedFunction userDefinedFunction = mapJsonToUserDefinedFunction([userDefinedFunctionObject, ()]);
        array:push(userDefinedFunctions, userDefinedFunction);
    }
    return userDefinedFunctions;
}

// Convert JSON array of trigger information in to an array of type Trigger.
// 
// + sourceTriggerArrayJsonObject - JSON object which contain the array of trigger information
// + return - An array of type Trigger
isolated function convertToTriggerArray(json[] sourceTriggerArrayJsonObject) returns Trigger[] {
    Trigger[] triggers = [];
    foreach json triggerObject in sourceTriggerArrayJsonObject {
        Trigger trigger = mapJsonToTrigger([triggerObject, ()]);
        array:push(triggers, trigger);
    }
    return triggers;
}

// Convert JSON array of user information in to an array of type User.
// 
// + sourceUserArrayJsonObject - JSON object which contain the array of user information
// + return - An array of type User
isolated function convertToUserArray(json[] sourceUserArrayJsonObject) returns User[] {
    User[] users = [];
    foreach json userObject in sourceUserArrayJsonObject {
        User user = mapJsonToUserType([userObject, ()]);
        array:push(users, user);
    }
    return users;
}

// Convert JSON array of permission information in to an array of type Permission.
// 
// + sourcePermissionArrayJsonObject - JSON object which contain the array of permission information
// + return - An array of type Permission
isolated function convertToPermissionArray(json[] sourcePermissionArrayJsonObject) returns Permission[] {
    Permission[] permissions = [];
    foreach json permissionObject in sourcePermissionArrayJsonObject {
        Permission permission = mapJsonToPermissionType([permissionObject, ()]);
        array:push(permissions, permission);
    }
    return permissions;
}

// Convert JSON array of offer infromation in to an array of type Offer.
// 
// + sourceOfferArrayJsonObject - JSON object which contain the array of offer information
// + return - An array of type Offer
isolated function convertToOfferArray(json[] sourceOfferArrayJsonObject) returns Offer[] {
    Offer[] offers = [];
    foreach json offerObject in sourceOfferArrayJsonObject {
        Offer offer = mapJsonToOfferType([offerObject, ()]);
        array:push(offers, offer);
    }
    return offers;
}

// Convert JSON array of included path information in to an array of type IncludedPath.
// 
// + sourcePathArrayJsonObject - JSON object which contain the array of included path information
// + return - An array of type IncludedPath
isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] {
    IncludedPath[] includedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        IncludedPath includedPath = mapJsonToIncludedPathsType(jsonPathObject);
        array:push(includedPaths, includedPath);
    }
    return includedPaths;
}

// Convert JSON array of excluded path information in to an array of type ExcludedPath.
// 
// + sourcePathArrayJsonObject - JSON object which contain the array of excluded path information
// + return - An array of type ExcludedPath.
isolated function convertToExcludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted ExcludedPath[] {
    ExcludedPath[] excludedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        ExcludedPath excludedPath = mapJsonToExcludedPathsType(jsonPathObject);
        array:push(excludedPaths, excludedPath);
    }
    return excludedPaths;
}

// Convert JSON array of partition key ranges in to an array of type PartitionKeyRange.
// 
// + sourcePrtitionKeyArrayJsonObject - JSON object which contain the array of partition key range information
// + return - An array of type PartitionKeyRange
isolated function convertToPartitionKeyRangeArray(json[] sourcePrtitionKeyArrayJsonObject) returns @tainted 
PartitionKeyRange[] {
    PartitionKeyRange[] partitionKeyRanges = [];
    int i = 0;
    foreach json jsonPartitionKey in sourcePrtitionKeyArrayJsonObject {
        partitionKeyRanges[i].id = jsonPartitionKey.id.toString();
        partitionKeyRanges[i].minInclusive = jsonPartitionKey.minInclusive.toString();
        partitionKeyRanges[i].maxExclusive = jsonPartitionKey.maxExclusive.toString();
        i = i + 1;
    }
    return partitionKeyRanges;
}

// Convert JSON array of indexes in to an array of type Index.
// 
// + sourceIndexArrayJsonObject - JSON object which contain the array of index information
// + return - An array of type Index
isolated function convertToIndexArray(json[] sourceIndexArrayJsonObject) returns @tainted Index[] {
    Index[] indexes = [];
    foreach json indexObject in sourceIndexArrayJsonObject {
        Index index = mapJsonToIndexType([indexObject, ()]);
        array:push(indexes, index);
    }
    return indexes;
}

// Convert JSON array with strings in to an array of type string.
// 
// + sourceArrayJsonObject - JSON object which contain the array of strings 
// + return - An array of type string
isolated function convertToStringArray(json[] sourceArrayJsonObject) returns @tainted string[] {
    string[] strings = [];
    foreach json stringObject in sourceArrayJsonObject {
        array:push(strings, stringObject.toString());
    }
    return strings;
}
