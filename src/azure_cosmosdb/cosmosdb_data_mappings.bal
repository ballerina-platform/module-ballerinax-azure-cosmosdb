import ballerina/http;

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

isolated function mapResponseHeadersToObject(http:Response|http:ClientError httpResponse) returns @tainted Headers|error 
{
    Headers responseHeaders = {};
    if(httpResponse is http:Response) {
        responseHeaders.continuationHeader = getHeaderIfExist(httpResponse, CONTINUATION_HEADER);
        responseHeaders.sessionTokenHeader = getHeaderIfExist(httpResponse, SESSION_TOKEN_HEADER);
        responseHeaders.requestChargeHeader = getHeaderIfExist(httpResponse, REQUEST_CHARGE_HEADER);
        responseHeaders.resourceUsageHeader = getHeaderIfExist(httpResponse, RESOURCE_USAGE_HEADER);
        responseHeaders.itemCountHeader = getHeaderIfExist(httpResponse, ITEM_COUNT_HEADER);
        responseHeaders.etagHeader = getHeaderIfExist(httpResponse, ETAG_HEADER);
        responseHeaders.dateHeader = getHeaderIfExist(httpResponse, RESPONSE_DATE_HEADER);
        return responseHeaders;
    } else {
        return prepareError(REST_API_INVOKING_ERROR);
    }
}

isolated function mapJsonToDatabaseType([json, Headers?] jsonPayload) returns Database {
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    Database database = {};
    database.id = payload.id != ()? payload.id.toString() : EMPTY_STRING;
    database.resourceId = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    database.selfReference = payload._self != ()? payload._self.toString() : EMPTY_STRING;
    if(headers is Headers) {
        database[RESPONSE_HEADERS] = headers;
    }    
    return database;
}

function mapJsonToDatabaseIteratorType([json, Headers] jsonPayload) returns @tainted DatabaseIterator {
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    stream<Database> databaseStream = convertToDatabaseStream(<json[]>payload.Databases);
    int count = convertToInt(payload._count);
    DatabaseIterator iterator = new(databaseStream, count, headers);
    return iterator;
}

isolated function mapJsonToContainerType([json, Headers?] jsonPayload) returns @tainted Container {
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    Container container = {};
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

isolated function mapJsonToContainerListType([json, Headers] jsonPayload) returns @tainted ContainerList {
    ContainerList containerList = {};
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    containerList._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    containerList._count = convertToInt(payload._count);
    containerList.containers = convertToContainerArray(<json[]>payload.DocumentCollections);
    containerList.reponseHeaders = headers;
    return containerList;
}

isolated function mapJsonToDocumentType([json, Headers?] jsonPayload) returns @tainted Document {  
    Document document = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
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
    var deleteKeys = ["id", "_rid", "_self", "_etag", "_ts", "_attachments"];
    foreach var 'key in deleteKeys {
        if(reponsePayload.hasKey('key)) {
            var removedValue = reponsePayload.remove('key);
        }
    }
    return reponsePayload;
}

isolated function mapJsonToDocumentListType([json, Headers] jsonPayload) returns @tainted DocumentList|error {
    DocumentList documentlist = {};
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    documentlist._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    documentlist._count = convertToInt(payload._count);
    documentlist.documents = check convertToDocumentArray(<json[]>payload.Documents);
    documentlist.reponseHeaders = headers;
    return documentlist;
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
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    //partitionKeyList.resourceId = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    //partitionKeyList.partitionKeyRanges = convertToPartitionKeyRangeArray(<json[]>payload.PartitionKeyRanges);
    partitionKeyList.reponseHeaders = headers;
    partitionKeyList._count = convertToInt(payload._count);
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
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    storedProcedure.resourceId = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    storedProcedure.id = payload.id != () ? payload.id.toString(): EMPTY_STRING;
    storedProcedure.body = payload.body !=() ? payload.body.toString(): EMPTY_STRING;
    if(headers is Headers) {
        storedProcedure[RESPONSE_HEADERS] = headers;
    }
    return storedProcedure;
}

isolated function mapJsonToStoredProcedureListType([json, Headers] jsonPayload) returns @tainted StoredProcedureList {
    StoredProcedureList storedProcedureList = {};
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    storedProcedureList._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    storedProcedureList.storedProcedures = convertToStoredProcedureArray(<json[]>payload.StoredProcedures);
    storedProcedureList._count = convertToInt(payload._count);
    storedProcedureList[RESPONSE_HEADERS] = headers;
    return storedProcedureList;
}

isolated function mapJsonToUserDefinedFunctionType([json, Headers?] jsonPayload) returns @tainted UserDefinedFunction {
    UserDefinedFunction userDefinedFunction = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    userDefinedFunction.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    userDefinedFunction.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    userDefinedFunction.body = payload.body != () ? payload.body.toString() : EMPTY_STRING;
    if(headers is Headers) {
        userDefinedFunction[RESPONSE_HEADERS] = headers;
    }
    return userDefinedFunction;
}

isolated function mapJsonToUserDefinedFunctionListType([json, Headers] jsonPayload) returns @tainted UserDefinedFunctionList|error {
    UserDefinedFunctionList userDefinedFunctionList = {};
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    userDefinedFunctionList._rid = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    userDefinedFunctionList.UserDefinedFunctions = userDefinedFunctionArray(<json[]>payload.UserDefinedFunctions);
    userDefinedFunctionList._count = convertToInt(payload._count);
    userDefinedFunctionList[RESPONSE_HEADERS] = headers;
    return userDefinedFunctionList;
}

isolated function mapJsonToTriggerType([json, Headers?] jsonPayload) returns @tainted Trigger {
    Trigger trigger = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
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

isolated function mapJsonToTriggerListType([json, Headers] jsonPayload) returns @tainted TriggerList|error {
    TriggerList triggerList = {};
    json payload;
    Headers headers;
    [payload, headers] = jsonPayload;
    triggerList._rid = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    triggerList.triggers = ConvertToTriggerArray(<json[]>payload.Triggers);
    triggerList._count = convertToInt(payload._count);
    triggerList[RESPONSE_HEADERS] = headers;
    return triggerList;
}

isolated function mapJsonToUserType([json, Headers?] jsonPayload) returns @tainted User {
    User user = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    user.resourceId = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    user.id = payload.id != () ? payload.id.toString() : EMPTY_STRING;
    if(headers is Headers) {
        user[RESPONSE_HEADERS] = headers;
    }
    return user;
}

isolated function mapJsonToUserListType([json, Headers?] jsonPayload) returns @tainted UserList {
    UserList userList = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    userList._rid = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    userList.users = ConvertToUserArray(<json[]>payload.Users);
    userList._count = convertToInt(payload._count);
    userList[RESPONSE_HEADERS] = headers;
    return userList;
}

isolated function mapJsonToPermissionType([json, Headers?] jsonPayload) returns @tainted Permission {
    Permission permission = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
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

isolated function mapJsonToPermissionListType([json, Headers?] jsonPayload) returns @tainted PermissionList {
    PermissionList permissionList = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    permissionList._rid = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    permissionList.permissions = ConvertToPermissionArray(<json[]>payload.Permissions);
    permissionList._count = convertToInt(payload._count);
    permissionList[RESPONSE_HEADERS] = headers;
    return permissionList;
}

isolated function mapJsonToOfferType([json, Headers?] jsonPayload) returns @tainted Offer {
    Offer offer = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
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

isolated function mapJsonToOfferListType([json, Headers?] jsonPayload) returns @tainted OfferList {
    OfferList offerList = {};
    json payload;
    Headers? headers;
    [payload, headers] = jsonPayload;
    offerList._rid = payload._rid != () ? payload._rid.toString() : EMPTY_STRING;
    offerList.offers = ConvertToOfferArray(<json[]>payload.Offers);
    offerList._count = convertToInt(payload._count);
    offerList[RESPONSE_HEADERS] = headers;
    return offerList;
}

function convertToDatabaseStream(json[] sourceDatabaseArrayJsonObject) returns @tainted stream<Database> {
    Database[] databases = [];
    int i = 0;
    foreach json jsonDatabase in sourceDatabaseArrayJsonObject {
        databases[i] = mapJsonToDatabaseType([jsonDatabase,()]);
        i = i + 1;
    }
    stream<Database> db = databases.toStream();
    return db;
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

isolated function convertToContainerArray(json[] sourceCollectionArrayJsonObject) returns @tainted Container[] {
    Container[] collections = [];
    int i = 0;
    foreach json jsonCollection in sourceCollectionArrayJsonObject {
        collections[i] = mapJsonToContainerType([jsonCollection, ()]);
        i = i + 1;
    }
    return collections;
}

isolated function convertToDocumentArray(json[] sourceDocumentArrayJsonObject) returns @tainted Document[]|error { 
    Document[] documents = [];
    int i = 0;
    foreach json document in sourceDocumentArrayJsonObject { 
        documents[i] = mapJsonToDocumentType([document, ()]);
        i = i + 1;
    }
    return documents;
}

isolated function convertToStoredProcedureArray(json[] sourceSprocArrayJsonObject) returns @tainted StoredProcedure[] { 
    StoredProcedure[] storedProcedures = [];
    int i = 0;
    foreach json storedProcedure in sourceSprocArrayJsonObject { 
        storedProcedures[i] = mapJsonToStoredProcedureType([storedProcedure, ()]);
        i = i + 1;
    }
    return storedProcedures;
}

isolated function userDefinedFunctionArray(json[] sourceUdfArrayJsonObject) returns @tainted UserDefinedFunction[] { 
    UserDefinedFunction[] userDefinedFunctions = [];
    int i = 0;
    foreach json userDefinedFunction in sourceUdfArrayJsonObject { 
        userDefinedFunctions[i] = mapJsonToUserDefinedFunctionType([userDefinedFunction, ()]);
        i = i + 1;
    }
    return userDefinedFunctions;
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

isolated function ConvertToTriggerArray(json[] sourceTriggerArrayJsonObject) returns @tainted Trigger[] { 
    Trigger[] triggers = [];
    int i = 0;
    foreach json trigger in sourceTriggerArrayJsonObject { 
        triggers[i] = mapJsonToTriggerType([trigger, ()]);
        i = i + 1;
    }
    return triggers;
}

isolated function ConvertToUserArray(json[] sourceTriggerArrayJsonObject) returns @tainted User[] { 
    User[] users = [];
    int i = 0;
    foreach json user in sourceTriggerArrayJsonObject { 
        users[i] = mapJsonToUserType([user, ()]);
        i = i + 1;
    }
    return users;
}

isolated function ConvertToPermissionArray(json[] sourcePermissionArrayJsonObject) returns @tainted Permission[] { 
    Permission[] permissions = [];
    int i = 0;
    foreach json permission in sourcePermissionArrayJsonObject { 
        permissions[i] = mapJsonToPermissionType([permission, ()]);
        i = i + 1;
    }
    return permissions;
}

isolated function ConvertToOfferArray(json[] sourceOfferArrayJsonObject) returns @tainted Offer[] { 
    Offer[] offers = [];
    int i = 0;
    foreach json offer in sourceOfferArrayJsonObject { 
        offers[i] = mapJsonToOfferType([offer, ()]);
        i = i + 1;
    }
    return offers;
}
