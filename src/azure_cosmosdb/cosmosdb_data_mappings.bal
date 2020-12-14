isolated function mapParametersToHeaderType(string httpVerb, string url) returns HeaderParameters {
    HeaderParameters params = {};
    params.verb = httpVerb;
    params.resourceType = getResourceType(url);
    params.resourceId = getResourceId(url);
    return params;
}

isolated function mapOfferHeaderType(string httpVerb, string url) returns HeaderParameters {
    HeaderParameters params = {};
    params.verb = httpVerb;
    params.resourceType = getResourceType(url);
    params.resourceId = getResourceIdForOffer(url);
    return params;
}

isolated function mapJsonToDatabaseType([json, Headers?] jsonPayload) returns Database {
    Database database = {};
    var [payload, headers] = jsonPayload;
    database.id = payload.id != ()? payload.id.toString() : EMPTY_STRING;
    database.resourceId = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    database.selfReference = payload._self != ()? payload._self.toString() : EMPTY_STRING;
    if(headers is Headers) {
        database[RESPONSE_HEADERS] = headers;
    }    
    return database;
}

isolated function mapJsonToContainerType([json, Headers?] jsonPayload) returns @tainted Container {
    Container container = {};
    var [payload, headers] = jsonPayload;
    container.id = payload.id.toString();
    container.resourceId = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    container.selfReference = payload._self != ()? payload._self.toString() : EMPTY_STRING;
    container.allowMaterializedViews = convertToBoolean(payload.allowMaterializedViews);
    container.indexingPolicy = mapJsonToIndexingPolicy(<json>payload.indexingPolicy);
    container.partitionKey = convertJsonToPartitionKeyType(<json>payload.partitionKey);
    if(headers is Headers) {
        container[RESPONSE_HEADERS] = headers;
    }
    return container;
}

isolated function mapJsonToDocumentType([json, Headers?] jsonPayload) returns @tainted Document {  
    Document document = {};
    var [payload, headers] = jsonPayload;
    document.id = payload.id != () ? payload.id.toString(): EMPTY_STRING;
    document.resourceId = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    document.selfReference = payload._self != () ? payload._self.toString(): EMPTY_STRING;
    JsonMap|error documentBodyJson = payload.cloneWithType(JsonMap);
    if(documentBodyJson is JsonMap) {
        document.documentBody = mapJsonToDocumentBody(documentBodyJson);
    }
    if(headers is Headers) {
        document[RESPONSE_HEADERS] = headers;
    }
    return document;
}

isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns json {
    var deleteKeys = [JSON_KEY_ID, JSON_KEY_RESOURCE_ID, JSON_KEY_SELF_REFERENCE, JSON_KEY_ETAG, JSON_KEY_TIMESTAMP, 
    JSON_KEY_ATTACHMENTS];
    foreach var keyValue in deleteKeys {
        if(reponsePayload.hasKey(keyValue)) {
            var removedValue = reponsePayload.remove(keyValue);
        }
    }
    return reponsePayload;
}

isolated function mapJsonToIndexingPolicy(json jsonPayload) returns @tainted IndexingPolicy {
    IndexingPolicy indexingPolicy = {};
    indexingPolicy.indexingMode = jsonPayload.indexingMode != ()? jsonPayload.indexingMode.toString() : EMPTY_STRING;
    indexingPolicy.automatic = convertToBoolean(jsonPayload.automatic);
    indexingPolicy.includedPaths = convertToIncludedPathsArray(<json[]>jsonPayload.includedPaths);
    indexingPolicy.excludedPaths = convertToIncludedPathsArray(<json[]>jsonPayload.excludedPaths);
    return indexingPolicy;
}

isolated function convertJsonToPartitionKeyType(json jsonPayload) returns @tainted PartitionKey {
    PartitionKey partitionKey = {};
    partitionKey.paths = convertToStringArray(<json[]>jsonPayload.paths);
    partitionKey.kind = jsonPayload.kind != () ? jsonPayload.kind.toString(): EMPTY_STRING;
    partitionKey.keyVersion = convertToInt(jsonPayload.'version);
    return partitionKey;
}

isolated function mapJsonToPartitionKeyListType([json, Headers] jsonPayload) returns @tainted PartitionKeyList {
    PartitionKeyList partitionKeyList = {};
    PartitionKeyRange pkr = {};
    var [payload, headers] = jsonPayload;
    //partitionKeyList.resourceId = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    //partitionKeyList.partitionKeyRanges = convertToPartitionKeyRangeArray(<json[]>payload.PartitionKeyRanges);
    partitionKeyList.reponseHeaders = headers;
    partitionKeyList.count = convertToInt(payload._count);
    return partitionKeyList;
}

isolated function mapJsonToPartitionKeyRange([json, Headers] jsonPayload) returns @tainted PartitionKeyRange {
    PartitionKeyRange partitionKeyRange = {};
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    partitionKeyRange.id = payload.id.toString();
    partitionKeyRange.minInclusive = payload.minInclusive.toString();
    partitionKeyRange.maxExclusive = payload.maxExclusive.toString();
    partitionKeyRange.status = payload.status.toString();
    partitionKeyRange.reponseHeaders = headers;
    return partitionKeyRange;
}

isolated function mapJsonToIncludedPathsType(json jsonPayload) returns @tainted IncludedPath {
    IncludedPath includedPath = {};
    includedPath.path = jsonPayload.path.toString();
    if(jsonPayload.indexes is error) {
        return includedPath;
    } else {
        includedPath.indexes = convertToIndexArray(<json[]>jsonPayload.indexes);
    }
    return includedPath;
}

isolated function mapJsonToIndexType(json jsonPayload) returns Index {
    Index index = {};
    index.kind = jsonPayload.kind != () ? jsonPayload.kind.toString(): EMPTY_STRING;
    index.dataType = jsonPayload.dataType.toString();
    index.precision = convertToInt(jsonPayload.precision);
    return index; 
}

isolated function mapJsonToStoredProcedureType([json, Headers?] jsonPayload) returns @tainted StoredProcedure {
    StoredProcedure storedProcedure = {};
    var [payload, headers] = jsonPayload;
    storedProcedure.resourceId = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    storedProcedure.id = payload.id != () ? payload.id.toString(): EMPTY_STRING;
    storedProcedure.body = payload.body !=() ? payload.body.toString(): EMPTY_STRING;
    if(headers is Headers) {
        storedProcedure[RESPONSE_HEADERS] = headers;
    }
    return storedProcedure;
}

isolated function mapJsonToUserDefinedFunctionType([json, Headers?] jsonPayload) returns @tainted UserDefinedFunction {
    UserDefinedFunction userDefinedFunction = {};
    var [payload, headers] = jsonPayload;
    userDefinedFunction.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    userDefinedFunction.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    userDefinedFunction.body = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    if(headers is Headers) {
        userDefinedFunction[RESPONSE_HEADERS] = headers;
    }
    return userDefinedFunction;
}

isolated function mapJsonToTriggerType([json, Headers?] jsonPayload) returns @tainted Trigger {
    Trigger trigger = {};
    var [payload, headers] = jsonPayload;
    trigger.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    trigger.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    trigger.body = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    trigger.triggerOperation = payload.triggerOperation != () ? payload.triggerOperation.toString() : EMPTY_STRING;
    trigger.triggerType = payload.triggerType != () ? payload.triggerType.toString() : EMPTY_STRING;
    if(headers is Headers) {
        trigger[RESPONSE_HEADERS] = headers;
    }
    return trigger;
}

isolated function mapJsonToUserType([json, Headers?] jsonPayload) returns @tainted User {
    User user = {};
    var [payload, headers] = jsonPayload;
    user.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    user.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    if(headers is Headers) {
        user[RESPONSE_HEADERS] = headers;
    }
    return user;
}

isolated function mapJsonToPermissionType([json, Headers?] jsonPayload) returns @tainted Permission {
    Permission permission = {};
    var [payload, headers] = jsonPayload;
    permission.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    permission.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    permission.token = payload._token != () ? payload._token.toString() : EMPTY_STRING;
    permission.permissionMode = payload.permissionMode != () ? payload.permissionMode.toString() : EMPTY_STRING;
    permission.resourcePath = payload.'resource != () ? payload.'resource.toString() : EMPTY_STRING;
    if(headers is Headers) {
        permission[RESPONSE_HEADERS] = headers;
    }
    return permission;
}

isolated function mapJsonToOfferType([json, Headers?] jsonPayload) returns @tainted Offer {
    Offer offer = {};
    var [payload, headers] = jsonPayload;
    offer.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    offer.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    offer.offerVersion = payload.offerVersion != () ? payload.offerVersion.toString() : EMPTY_STRING;
    offer.offerType = payload.offerType != () ? payload.offerType.toString() : EMPTY_STRING;
    offer.content = payload.content != () ? payload.content.toString() : EMPTY_STRING;
    offer.resourceSelfLink = payload.'resource != () ? payload.'resource.toString() : EMPTY_STRING;
    offer.offerResourceId = payload.offerResourceId != () ? payload.offerResourceId.toString() : EMPTY_STRING;
    if(headers is Headers) {
        offer[RESPONSE_HEADERS] = headers;
    }
    return offer;
}

isolated function convertToDatabaseArray(@tainted Database[] databases, json[] sourceDatabaseArrayJsonObject) 
returns @tainted  Database[] {
    int length = databases.length();
    int i = length;
    foreach json jsonDatabase in sourceDatabaseArrayJsonObject {
        databases[i] = mapJsonToDatabaseType([jsonDatabase,()]);
        i = i + 1;
    }
    return databases;
}

isolated function convertToContainerArray(@tainted Container[] containers, json[] sourceCollectionArrayJsonObject) 
returns @tainted Container[] {
    int length = containers.length();
    int i = length;   
    foreach json jsonCollection in sourceCollectionArrayJsonObject {
        containers[i] = mapJsonToContainerType([jsonCollection, ()]);
        i = i + 1;
    }
    return containers;
}

isolated function convertToDocumentArray(@tainted Document[] documents,json[] sourceDocumentArrayJsonObject) returns 
@tainted Document[] { 
    int length = documents.length();
    int i = length;
    foreach json document in sourceDocumentArrayJsonObject { 
        documents[i] = mapJsonToDocumentType([document, ()]);
        i = i + 1;
    }
    return documents;
}

isolated function convertToStoredProcedureArray(@tainted StoredProcedure[] storedProcedures, json[] sourceSprocArrayJsonObject) 
returns @tainted StoredProcedure[] { 
    int length = storedProcedures.length();
    int i = length;    
    foreach json storedProcedure in sourceSprocArrayJsonObject { 
        storedProcedures[i] = mapJsonToStoredProcedureType([storedProcedure, ()]);
        i = i + 1;
    }
    return storedProcedures;
}

isolated function convertsToUserDefinedFunctionArray(@tainted UserDefinedFunction[] userDefinedFunctions, json[] sourceUdfArrayJsonObject) 
returns @tainted UserDefinedFunction[] { 
    int length = userDefinedFunctions.length();
    int i = length;
    foreach json userDefinedFunction in sourceUdfArrayJsonObject { 
        userDefinedFunctions[i] = mapJsonToUserDefinedFunctionType([userDefinedFunction, ()]);
        i = i + 1;
    }
    return userDefinedFunctions;
}

isolated function convertToTriggerArray(@tainted Trigger[] triggers, json[] sourceTriggerArrayJsonObject) returns @tainted Trigger[] { 
    int length = triggers.length();
    int i = length; 
    foreach json trigger in sourceTriggerArrayJsonObject { 
        triggers[i] = mapJsonToTriggerType([trigger, ()]);
        i = i + 1;
    }
    return triggers;
} 

isolated function convertToUserArray(@tainted User[] users, json[] sourceTriggerArrayJsonObject) returns @tainted User[] { 
    int length = users.length();
    int i = length;
    foreach json user in sourceTriggerArrayJsonObject { 
        users[i] = mapJsonToUserType([user, ()]);
        i = i + 1;
    }
    return users;
}

isolated function convertToPermissionArray(@tainted Permission[] permissions, json[] sourcePermissionArrayJsonObject) 
returns @tainted Permission[] { 
    int length = permissions.length();
    int i = length;
    foreach json permission in sourcePermissionArrayJsonObject { 
        permissions[i] = mapJsonToPermissionType([permission, ()]);
        i = i + 1;
    }
    return permissions;
}

isolated function ConvertToOfferArray(@tainted Offer[] offers, json[] sourceOfferArrayJsonObject) returns @tainted Offer[] { 
    int length = offers.length();
    int i = length;
    foreach json offer in sourceOfferArrayJsonObject { 
        offers[i] = mapJsonToOfferType([offer, ()]);
        i = i + 1;
    }
    return offers;
}

isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] { 
    IncludedPath[] includedPaths = [];
    int i = 0;
    foreach json jsonPath in sourcePathArrayJsonObject {
        includedPaths[i] = <IncludedPath>mapJsonToIncludedPathsType(jsonPath);
        i = i + 1;
    }
    return includedPaths;
}

isolated function convertToPartitionKeyRangeArray(json[] sourcePrtitionKeyArrayJsonObject) returns @tainted PartitionKeyRange[] { 
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

isolated function convertToIndexArray(json[] sourcePathArrayJsonObject) returns @tainted Index[] {
    Index[] indexes = [];
    int i = 0;
    foreach json index in sourcePathArrayJsonObject {
        indexes[i] = mapJsonToIndexType(index);
        i = i + 1;
    }
    return indexes;
}

isolated function convertToStringArray(json[] sourceArrayJsonObject) returns @tainted string[] {
    string[] strings = [];
    int i = 0;
    foreach json str in sourceArrayJsonObject {
        strings[i] = str.toString();
        i = i + 1;
    }
    return strings;
}
