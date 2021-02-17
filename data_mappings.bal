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
import ballerina/http;

# Maps the JSON response returned from the request into record type of DeleteResponse.
# 
# + response - A HTTP response object
# + return - An instance of record type DeleteResponse
isolated function mapHeadersToResultType(http:Response response) returns @tainted DeleteResponse {
    return {
        sessionToken: response.getHeader(SESSION_TOKEN_HEADER)
    };
}

# Maps the JSON response returned from the request into record type of Database.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type Database
isolated function mapJsonToDatabaseType(json payload) returns Database {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of Container.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type Container
isolated function mapJsonToContainerType(json payload) returns @tainted Container {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        indexingPolicy: let var indexingP = <json>payload.indexingPolicy in mapJsonToIndexingPolicy(indexingP),
        partitionKey: let var partitionKey = <json>payload.partitionKey in convertJsonToPartitionKeyType(partitionKey)
    };
}

# Maps the JSON response returned from the request into record type of IndexingPolicy.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type IndexingPolicy
isolated function mapJsonToIndexingPolicy(json payload) returns @tainted IndexingPolicy {
    return {
        indexingMode: let var mode = payload.indexingMode in mode is string ? mode : EMPTY_STRING,
        automatic: let var automatic = <json>payload.automatic in convertToBoolean(automatic),
        includedPaths: let var inPaths = <json[]>payload.includedPaths in convertToIncludedPathsArray(inPaths),
        excludedPaths: let var exPaths = <json[]>payload.excludedPaths in convertToExcludedPathsArray(exPaths)
    };
}

# Maps the JSON response returned from the request into record type of IncludedPath.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type IncludedPath
isolated function mapJsonToIncludedPathsType(json payload) returns @tainted IncludedPath {
    IncludedPath includedPath = {
        path: let var path = payload.path in path is string ? path : EMPTY_STRING
    };
    if (payload.indexes is error) {
        return includedPath;
    }
    includedPath.indexes = let var indexes = <json[]>payload.indexes in convertToIndexArray(indexes);
    return includedPath;
}

# Maps the JSON response returned from the request into record type of ExcludedPath.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type ExcludedPath
isolated function mapJsonToExcludedPathsType(json payload) returns @tainted ExcludedPath {
    return {
        path: let var path = payload.path in path is string ? path : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of Document.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type Document
isolated function mapJsonToDocumentType(json payload) returns @tainted Document {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        documentBody: let var body = <map<json>>payload in mapJsonToDocumentBody(body)
    };
}

# Format the JSON map returned from the request to contain only the document. 
# 
# + reponsePayload - A JSON map which contains JSON payload returned from the request
# + return - JSON object which contains only the document
isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns map<json> {
    final var keysToDelete = [JSON_KEY_ID, JSON_KEY_RESOURCE_ID, JSON_KEY_SELF_REFERENCE, JSON_KEY_ETAG, 
            JSON_KEY_TIMESTAMP, JSON_KEY_ATTACHMENTS];
    foreach var keyValue in keysToDelete {
        _ = reponsePayload.removeIfHasKey(keyValue);
    }
    return reponsePayload;
}

# Maps the JSON response returned from the request into record type of PartitionKey.
# 
# + payload - The JSON object returned from request
# + return - An instance of record type PartitionKey
isolated function convertJsonToPartitionKeyType(json payload) returns @tainted PartitionKey {
    return {
        paths: let var paths = <json[]>payload.paths in convertToStringArray(paths),
        keyVersion: let var keyVersion = <json>payload.'version in convertToInt(keyVersion)
    };
}

# Maps the JSON response returned from the request into record type of PartitionKeyRange.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type PartitionKeyRange
isolated function mapJsonToPartitionKeyRange(json payload) returns @tainted PartitionKeyRange {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        minInclusive: let var minInclusive = payload.minInclusive in minInclusive is string ? minInclusive : 
                EMPTY_STRING,
        maxExclusive: let var maxExclusive = payload.maxExclusive in maxExclusive is string ? maxExclusive : 
                EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of Index.
# 
# + payload - A JSON object returned from request
# + return - An instance of record type Index
isolated function mapJsonToIndexType(json payload) returns Index {
    return {
        kind: let var kind = <string>payload.kind in getIndexType(kind),
        dataType: let var dataType = <string>payload.dataType in getIndexDataType(dataType),
        precision: let var precision = <string>payload.precision in convertToInt(precision)
    };
}

# Maps the JSON response returned from the request into record type of StoredProcedure.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type StoredProcedure
isolated function mapJsonToStoredProcedure(json payload) returns @tainted StoredProcedure {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        storedProcedure: let var sproc = payload.body in sproc is string ? sproc : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of UserDefinedFunction.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type UserDefinedFunction
isolated function mapJsonToUserDefinedFunction(json payload) returns @tainted UserDefinedFunction {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        userDefinedFunction: let var udf = payload.body in udf is string ? udf : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of Trigger.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type Trigger
isolated function mapJsonToTrigger(json payload) returns @tainted Trigger {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        triggerFunction: let var func = payload.body in func is string ? func : EMPTY_STRING,
        triggerOperation: let var oper = <string>payload.triggerOperation in getTriggerOperation(oper),
        triggerType: let var triggerType = <string>payload.triggerType in getTriggerType(triggerType)
    };
}

# Maps the JSON response returned from the request into record type of User.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type User
isolated function mapJsonToUserType(json payload) returns @tainted User {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        permissions: let var permissions = payload._permissions in permissions is string ? permissions : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of Permission.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type Permission
isolated function mapJsonToPermissionType(json payload) returns @tainted Permission {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        token: let var token = payload._token in token is string? token : EMPTY_STRING,
        permissionMode: let var mode = <string>payload.permissionMode in getPermisssionMode(mode),
        resourcePath: let var resourcePath = payload.'resource in resourcePath is string ? resourcePath : EMPTY_STRING
    };
}

# Maps the JSON response returned from the request into record type of Offer.
# 
# + payload - A tuple which contains headers and JSON object returned from request
# + return - An instance of record type Offer.
isolated function mapJsonToOfferType(json payload) returns @tainted Offer {
    return {
        id: let var id = payload.id in id is string ? id : EMPTY_STRING,
        resourceId: let var resourceId = payload._rid in resourceId is string ? resourceId : EMPTY_STRING,
        selfReference: let var selfReference = payload._self in selfReference is string ? selfReference : EMPTY_STRING,
        eTag: let var eTag = payload._etag in eTag is string ? eTag : EMPTY_STRING,
        //sessionToken: let var session = headers?.sessionToken in session is string ? session : EMPTY_STRING,
        offerVersion: let var offVersion = <string>payload.offerVersion in getOfferVersion(offVersion),
        offerType: let var offType = <string>payload.offerType in getOfferVersion(offType),
        content: let var content = payload.content in content is string ? content : EMPTY_STRING,
        resourceSelfLink: let var link = payload.'resource in link is string ? link : EMPTY_STRING,
        resourceResourceId: let var resId = payload.offerResourceId in resId is string ? resId : EMPTY_STRING
    };
}

# Convert JSON array of database information in to an array of type Database.
# 
# + sourceDatabaseArrayJsonObject - JSON object which contain the array of database information
# + return - An array of type Database
isolated function convertToDatabaseArray(json[] sourceDatabaseArrayJsonObject) returns Database[] {
    Database[] databases = [];
    foreach json databaseObject in sourceDatabaseArrayJsonObject {
        Database database = mapJsonToDatabaseType(databaseObject);
        array:push(databases, database);
    }
    return databases;
}

# Convert JSON array of container information in to an array of type Container.
# 
# + sourceContainerArrayJsonObject - JSON object which contain the array of container information
# + return - An array of type Container
isolated function convertToContainerArray(json[] sourceContainerArrayJsonObject) returns Container[] {
    Container[] containers = [];
    foreach json jsonCollection in sourceContainerArrayJsonObject {
        Container container = mapJsonToContainerType(jsonCollection);
        array:push(containers, container);
    }
    return containers;
}

# Convert JSON array of document information in to an array of type Document.
# 
# + sourceDocumentArrayJsonObject - JSON object which contain the array of document information
# + return - An array of type Document
isolated function convertToDocumentArray(json[] sourceDocumentArrayJsonObject) returns Document[] {
    Document[] documents = [];
    foreach json documentObject in sourceDocumentArrayJsonObject {
        Document document = mapJsonToDocumentType(documentObject);
        array:push(documents, document);
    }
    return documents;
}

# Convert JSON array of stored procedure information in to an array of type StoredProcedure.
# 
# + sourceStoredProcedureArrayJsonObject - JSON object which contain the array of stored procedure information
# + return - An array of type StoredProcedure
isolated function convertToStoredProcedureArray(json[] sourceStoredProcedureArrayJsonObject) returns StoredProcedure[] {
    StoredProcedure[] storedProcedures = [];
    foreach json storedProcedureObject in sourceStoredProcedureArrayJsonObject {
        StoredProcedure storedProcedure = mapJsonToStoredProcedure(storedProcedureObject);
        array:push(storedProcedures, storedProcedure);
    }
    return storedProcedures;
}

# Convert JSON array of user defined function information in to an array of type UserDefinedFunction.
# 
# + sourceUdfArrayJsonObject - JSON object which contain the array of user defined function information
# + return - An array of type UserDefinedFunction
isolated function convertsToUserDefinedFunctionArray(json[] sourceUdfArrayJsonObject) returns UserDefinedFunction[] {
    UserDefinedFunction[] userDefinedFunctions = [];
    foreach json userDefinedFunctionObject in sourceUdfArrayJsonObject {
        UserDefinedFunction userDefinedFunction = mapJsonToUserDefinedFunction(userDefinedFunctionObject);
        array:push(userDefinedFunctions, userDefinedFunction);
    }
    return userDefinedFunctions;
}

# Convert JSON array of trigger information in to an array of type Trigger.
# 
# + sourceTriggerArrayJsonObject - JSON object which contain the array of trigger information
# + return - An array of type Trigger
isolated function convertToTriggerArray(json[] sourceTriggerArrayJsonObject) returns Trigger[] {
    Trigger[] triggers = [];
    foreach json triggerObject in sourceTriggerArrayJsonObject {
        Trigger trigger = mapJsonToTrigger(triggerObject);
        array:push(triggers, trigger);
    }
    return triggers;
}

# Convert JSON array of user information in to an array of type User.
# 
# + sourceUserArrayJsonObject - JSON object which contain the array of user information
# + return - An array of type User
isolated function convertToUserArray(json[] sourceUserArrayJsonObject) returns User[] {
    User[] users = [];
    foreach json userObject in sourceUserArrayJsonObject {
        User user = mapJsonToUserType(userObject);
        array:push(users, user);
    }
    return users;
}

# Convert JSON array of permission information in to an array of type Permission.
# 
# + sourcePermissionArrayJsonObject - JSON object which contain the array of permission information
# + return - An array of type Permission
isolated function convertToPermissionArray(json[] sourcePermissionArrayJsonObject) returns Permission[] {
    Permission[] permissions = [];
    foreach json permissionObject in sourcePermissionArrayJsonObject {
        Permission permission = mapJsonToPermissionType(permissionObject);
        array:push(permissions, permission);
    }
    return permissions;
}

# Convert JSON array of offer infromation in to an array of type Offer.
# 
# + sourceOfferArrayJsonObject - JSON object which contain the array of offer information
# + return - An array of type Offer
isolated function convertToOfferArray(json[] sourceOfferArrayJsonObject) returns Offer[] {
    Offer[] offers = [];
    foreach json offerObject in sourceOfferArrayJsonObject {
        Offer offer = mapJsonToOfferType(offerObject);
        array:push(offers, offer);
    }
    return offers;
}

# Convert JSON array of included path information in to an array of type IncludedPath.
# 
# + sourcePathArrayJsonObject - JSON object which contain the array of included path information
# + return - An array of type IncludedPath
isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] {
    IncludedPath[] includedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        IncludedPath includedPath = mapJsonToIncludedPathsType(jsonPathObject);
        array:push(includedPaths, includedPath);
    }
    return includedPaths;
}

# Convert JSON array of excluded path information in to an array of type ExcludedPath.
# 
# + sourcePathArrayJsonObject - JSON object which contain the array of excluded path information
# + return - An array of type ExcludedPath.
isolated function convertToExcludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted ExcludedPath[] {
    ExcludedPath[] excludedPaths = [];
    foreach json jsonPathObject in sourcePathArrayJsonObject {
        ExcludedPath excludedPath = mapJsonToExcludedPathsType(jsonPathObject);
        array:push(excludedPaths, excludedPath);
    }
    return excludedPaths;
}

# Convert JSON array of partition key ranges in to an array of type PartitionKeyRange.
# 
# + sourcePrtitionKeyArrayJsonObject - JSON object which contain the array of partition key range information
# + return - An array of type PartitionKeyRange
isolated function convertToPartitionKeyRangeArray(json[] sourcePrtitionKeyArrayJsonObject) returns @tainted 
        PartitionKeyRange[] {
    PartitionKeyRange[] partitionKeyRangesArray = [];
    foreach json jsonPartitionKey in sourcePrtitionKeyArrayJsonObject {
        PartitionKeyRange value = {
            id: let var id = jsonPartitionKey.id in id is string ? id : EMPTY_STRING,
            minInclusive: let var min = jsonPartitionKey.minInclusive in min is string ? min : EMPTY_STRING,
            maxExclusive: let var max = jsonPartitionKey.maxExclusive in max is string ? max : EMPTY_STRING
        };
        array:push(partitionKeyRangesArray, value);
    }
    return partitionKeyRangesArray;
}

# Convert JSON array of indexes in to an array of type Index.
# 
# + sourceIndexArrayJsonObject - JSON object which contain the array of index information
# + return - An array of type Index
isolated function convertToIndexArray(json[] sourceIndexArrayJsonObject) returns @tainted Index[] {
    Index[] indexes = [];
    foreach json indexObject in sourceIndexArrayJsonObject {
        Index index = mapJsonToIndexType(indexObject);
        array:push(indexes, index);
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
        array:push(strings, stringObject.toString());
    }
    return strings;
}
