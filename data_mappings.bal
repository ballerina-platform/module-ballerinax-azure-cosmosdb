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

import ballerina/http;

# Maps the JSON response returned from the request into record type of `DeleteResponse`.
# 
# + response - A HTTP response object
# + return - An instance of record type `DeleteResponse`
isolated function mapHeadersToResultType(http:Response response) returns @tainted DeleteResponse {
    return {
        sessionToken: let var header = response.getHeader(SESSION_TOKEN_HEADER) in header is string ? header : 
            EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `Database`.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type `Database`
isolated function mapJsonToDatabaseType(json payload) returns Database {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `Container`.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type `Container`
isolated function mapJsonToContainerType(json payload) returns @tainted Container {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        indexingPolicy: let var indexing = 
            payload.indexingPolicy in indexing is json ? mapJsonToIndexingPolicy(indexing) : {},
        partitionKey: let var partitionKey = 
            payload.partitionKey in partitionKey is json ? convertJsonToPartitionKeyType(partitionKey) : {}
    };
}

# Maps the JSON response returned from the request into record type of `IndexingPolicy`.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type `IndexingPolicy`
isolated function mapJsonToIndexingPolicy(json payload) returns @tainted IndexingPolicy {
    return {
        indexingMode: let var mode = payload.indexingMode in mode is string ? getIndexingMode(mode) : NONE,
        includedPaths: let var inPaths = 
            payload.indexingPolicy in inPaths is json ? convertToIncludedPathsArray(<json[]>inPaths) : [],
        excludedPaths: let var exPaths = 
            payload.excludedPaths in exPaths is json ? convertToExcludedPathsArray(<json[]>exPaths) : [],
        automatic: let var automatic = payload.automatic in automatic is boolean ? automatic : true
    };
}

# Maps the JSON response returned from the request into record type of `IncludedPath`.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type `IncludedPath`
isolated function mapJsonToIncludedPathsType(json payload) returns @tainted IncludedPath {
    IncludedPath includedPath = {
        path: let var path = payload.path in path is string ? path : EMPTY_STRING
    };
    if (payload.indexes is error) {
        return includedPath;
    }
    Index[] indexArray = [];
    includedPath.indexes = let var indexes = payload.indexes in indexes is json ? convertToIndexArray(<json[]>indexes) : 
        indexArray;
    return includedPath;
}

# Maps the JSON response returned from the request into record type of `ExcludedPath`.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type `ExcludedPath`
isolated function mapJsonToExcludedPathsType(json payload) returns @tainted ExcludedPath {
    return {
        path: let var path = payload.path in path is string ? path : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `Document`.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type `Document`
isolated function mapJsonToDocumentType(json payload) returns @tainted Document {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        documentBody: let var body = <map<json>>payload in mapJsonToDocumentBody(body)
    };
}

# Format the JSON map returned from the request to contain only the document. 
# 
# + reponsePayload - A JSON map which contains JSON payload returned from the request
# + return - Map of json which contains only the document
isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns map<json> {
    final var keysToDelete = [JSON_KEY_ID, JSON_KEY_RESOURCE_ID, JSON_KEY_SELF_REFERENCE, JSON_KEY_ETAG, 
        JSON_KEY_TIMESTAMP, JSON_KEY_ATTACHMENTS];
    foreach var keyValue in keysToDelete {
        _ = reponsePayload.removeIfHasKey(keyValue);
    }
    return reponsePayload;
}

# Maps the JSON response returned from the request into record type of `PartitionKey`.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type `PartitionKey`
isolated function convertJsonToPartitionKeyType(json payload) returns @tainted PartitionKey {
    return {
        paths: let var paths = payload.paths in paths is json ? convertToStringArray(<json[]>paths) : [],
        keyVersion: let var keyVersion = payload.'version in keyVersion is int ? getPartitionKeyVersion(keyVersion) : 
            PARTITION_KEY_VERSION_1
    };
}

# Maps the JSON response returned from the request into record type of `PartitionKeyRange`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `PartitionKeyRange`
isolated function mapJsonToPartitionKeyRange(json payload) returns @tainted PartitionKeyRange {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        minInclusive: let var minInclusive = payload.minInclusive in minInclusive is string ? minInclusive : 
            EMPTY_STRING,
        maxExclusive: let var maxExclusive = payload.maxExclusive in maxExclusive is string ? maxExclusive : 
            EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `Index`.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type `Index`
isolated function mapJsonToIndexType(json payload) returns Index {
    return {
        kind: let var kind = payload.kind in kind is string ? getIndexType(kind) : HASH,
        dataType: let var dataType = payload.dataType in dataType is string ?  getIndexDataType(dataType) : STRING,
        precision: let var precision = payload.precision in precision is int ? precision : -1
    };
}

# Maps the JSON response returned from the request into record type of `StoredProcedure`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `StoredProcedure`
isolated function mapJsonToStoredProcedure(json payload) returns @tainted StoredProcedure {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        storedProcedure: let var sproc = payload.body in sproc is string ? sproc : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `UserDefinedFunction`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `UserDefinedFunction`
isolated function mapJsonToUserDefinedFunction(json payload) returns @tainted UserDefinedFunction {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        userDefinedFunction: let var udf = payload.body in udf is string ? udf : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `Trigger`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `Trigger`
isolated function mapJsonToTrigger(json payload) returns @tainted Trigger {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        triggerFunction: let var func = payload.body in func is string ? func : EMPTY_STRING,
        triggerOperation: let var oper = payload.triggerOperation in oper is string ? getTriggerOperation(oper) : ALL,
        triggerType: let var triggerType = payload.triggerType in triggerType is string ? getTriggerType(triggerType) :
            PRE
    };
}

# Maps the JSON response returned from the request into record type of `User`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `User`
isolated function mapJsonToUserType(json payload) returns @tainted User {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        permissions: let var permissions = payload._permissions in permissions is string ? permissions : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of `Permission`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `Permission`
isolated function mapJsonToPermissionType(json payload) returns @tainted Permission {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        token: let var token = payload._token in token is string? token : EMPTY_STRING,
        permissionMode: let var mode = payload.permissionMode in mode is string ? getPermisssionMode(mode) : 
            ALL_PERMISSION,
        resourcePath: let var resourcePath = payload.'resource in resourcePath is string ? resourcePath : EMPTY_STRING
    };  
}

# Maps the JSON response returned from the request into record type of `Offer`.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type `Offer`
isolated function mapJsonToOfferType(json payload) returns @tainted Offer {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        offerVersion: let var ver = payload.offerVersion in ver is string ? getOfferVersion(ver) : PRE_DEFINED,
        offerType: let var otype = payload.offerType in otype is string ? getOfferType(otype) : INVALID,
        content: let var content = payload.content in content is map<json> ? content : {},
        resourceSelfLink: let var link = payload.'resource in link is string ? link : EMPTY_STRING,
        resourceResourceId: let var resId = payload.offerResourceId in resId is string ? resId : EMPTY_STRING
    };
}

// # Convert JSON array of database information in to an array of type `Database`.
// # 
// # + databases - The initial array of database records we need to append new elements to
// # + sourceDatabaseArrayJsonObject - JSON object which contain the array of database information
// isolated function convertToDatabaseArray(Database[] databases, json[] sourceDatabaseArrayJsonObject) {
//     foreach json databaseObject in sourceDatabaseArrayJsonObject {
//         Database database = mapJsonToDatabaseType(databaseObject);
//         databases.push(database);
//     }
// }

// # Convert JSON array of container information in to an array of type `Container`.
// # 
// # + containers - The initial array of container records we need to append new elements to
// # + sourceContainerArrayJsonObject - JSON object which contain the array of container information
// isolated function convertToContainerArray(Container[] containers, json[] sourceContainerArrayJsonObject) {
//     foreach json jsonCollection in sourceContainerArrayJsonObject {
//         Container container = mapJsonToContainerType(jsonCollection);
//         containers.push(container);
//     }
// }

// # Convert JSON array of document information in to an array of type `Document`.
// # 
// # + documents - The initial array of document records we need to append new elements to
// # + sourceDocumentArrayJsonObject - JSON object which contain the array of document information
// isolated function convertToDocumentArray(Document[] documents, json[] sourceDocumentArrayJsonObject) {
//     foreach json documentObject in sourceDocumentArrayJsonObject {
//         Document document = mapJsonToDocumentType(documentObject);
//         documents.push(document);
//     }
// }

// # Convert JSON array of stored procedure information in to an array of type `StoredProcedure`.
// # 
// # + storedProcedures - The initial array of stored procedure records that we need to append new elements to to
// # + sourceStoredProcedureArrayJsonObject - JSON object which contain the array of stored procedure information
// isolated function convertToStoredProcedureArray(StoredProcedure[] storedProcedures, 
//                                                 json[] sourceStoredProcedureArrayJsonObject) {
//     foreach json storedProcedureObject in sourceStoredProcedureArrayJsonObject {
//         StoredProcedure storedProcedure = mapJsonToStoredProcedure(storedProcedureObject);
//         storedProcedures.push(storedProcedure);
//     }
// }

// # Convert JSON array of user defined function information in to an array of type `UserDefinedFunction`.
// # 
// # + userDefinedFunctions - The initial array of user defined function records that we need to append new elements to
// # + sourceUdfArrayJsonObject - JSON object which contain the array of user defined function information
// isolated function convertsToUserDefinedFunctionArray(UserDefinedFunction[] userDefinedFunctions, 
//                                                      json[] sourceUdfArrayJsonObject) {
//     foreach json userDefinedFunctionObject in sourceUdfArrayJsonObject {
//         UserDefinedFunction userDefinedFunction = mapJsonToUserDefinedFunction(userDefinedFunctionObject);
//         userDefinedFunctions.push(userDefinedFunction);
//     }
// }

// # Convert JSON array of trigger information in to an array of type `Trigger`.
// # 
// # + triggers - The initial array of trigger records that we need to append new elements to
// # + sourceTriggerArrayJsonObject - JSON object which contain the array of trigger information
// isolated function convertToTriggerArray(Trigger[] triggers, json[] sourceTriggerArrayJsonObject) {
//     foreach json triggerObject in sourceTriggerArrayJsonObject {
//         Trigger trigger = mapJsonToTrigger(triggerObject);
//         triggers.push(trigger);
//     }
// }

// # Convert JSON array of user information in to an array of type `User`.
// # 
// # + users - The initial array of users records that we need to append new elements to
// # + sourceUserArrayJsonObject - JSON object which contain the array of user information
// isolated function convertToUserArray(User[] users, json[] sourceUserArrayJsonObject) {
//     foreach json userObject in sourceUserArrayJsonObject {
//         User user = mapJsonToUserType(userObject);
//         users.push(user);
//     }
// }

// # Convert JSON array of permission information in to an array of type `Permission`.
// # 
// # + permissions - The initial array of permission records that we need to append new elements to
// # + sourcePermissionArrayJsonObject - JSON object which contain the array of permission information
// isolated function convertToPermissionArray(Permission[] permissions, json[] sourcePermissionArrayJsonObject) {
//     foreach json permissionObject in sourcePermissionArrayJsonObject {
//         Permission permission = mapJsonToPermissionType(permissionObject);
//         permissions.push(permission);
//     }
// }

// # Convert JSON array of offer infromation in to an array of type `Offer`.
// # 
// # + offers - The initial array of offer records that we need to append new elements to
// # + sourceOfferArrayJsonObject - JSON object which contain the array of offer information
// isolated function convertToOfferArray(Offer[] offers, json[] sourceOfferArrayJsonObject) {
//     foreach json offerObject in sourceOfferArrayJsonObject {
//         Offer offer = mapJsonToOfferType(offerObject);
//         offers.push(offer);
//     }
// }

// # Convert JSON array of partition key ranges in to an array of type `PartitionKeyRange`.
// # 
// # + sourcePrtitionKeyArrayJsonObject - JSON object which contain the array of partition key range information
// isolated function convertToPartitionKeyRangeArray(PartitionKeyRange[] partitionKeyRangesArray , 
//                                                   json[] sourcePrtitionKeyArrayJsonObject) {
//     foreach json jsonPartitionKey in sourcePrtitionKeyArrayJsonObject {
//         PartitionKeyRange value = {
//             id: let var id = jsonPartitionKey.id in id is string ? id : EMPTY_STRING,
//             minInclusive: let var min = jsonPartitionKey.minInclusive in min is string ? min : EMPTY_STRING,
//             maxExclusive: let var max = jsonPartitionKey.maxExclusive in max is string ? max : EMPTY_STRING
//         };
//         partitionKeyRangesArray.push(value);
//     }
// }

# Convert JSON array of included path information in to an array of type `IncludedPath`.
# 
# + sourcePathArrayJsonObject - JSON object which contain the array of included path information
# + return - An array of type `IncludedPath`
isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] {
    IncludedPath[] includedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        IncludedPath includedPath = mapJsonToIncludedPathsType(jsonPathObject);
        includedPaths.push(includedPath);
    }
    return includedPaths;
}

# Convert JSON array of excluded path information in to an array of type `ExcludedPath`.
# 
# + sourcePathArrayJsonObject - JSON object which contain the array of excluded path information
# + return - An array of type `ExcludedPath`
isolated function convertToExcludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted ExcludedPath[] {
    ExcludedPath[] excludedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        ExcludedPath excludedPath = mapJsonToExcludedPathsType(jsonPathObject);
        excludedPaths.push(excludedPath);
    }
    return excludedPaths;
}

# Convert JSON array of indexes in to an array of type `Index`.
# 
# + sourceIndexArrayJsonObject - JSON object which contain the array of index information
# + return - An array of type `Index`
isolated function convertToIndexArray(json[] sourceIndexArrayJsonObject) returns @tainted Index[] {
    Index[] indexes = [];
    foreach json indexObject in sourceIndexArrayJsonObject {
        Index index = mapJsonToIndexType(indexObject);
        indexes.push(index);
    }
    return indexes;
}

# Convert JSON array with strings in to an array of type string.
# 
# + sourceArrayJsonObject - JSON object which contain the array of strings 
# + return - An array of type string
isolated function convertToStringArray(json[] sourceArrayJsonObject) returns @tainted string[] {
    string[] strings = [];
    foreach json stringObject in sourceArrayJsonObject {
        strings.push(stringObject.toString());
    }
    return strings;
}
