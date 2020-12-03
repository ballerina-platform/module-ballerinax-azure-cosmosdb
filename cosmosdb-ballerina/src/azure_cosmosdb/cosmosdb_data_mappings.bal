import ballerina/http;

isolated function mapParametersToHeaderType(string httpVerb, string url) returns HeaderParameters {
    HeaderParameters params = {};
    params.verb = httpVerb;
    params.resourceType = getResourceType(url);
    params.resourceId = getResourceId(url);
    return params;
}

isolated function mapResponseHeadersToObject(http:Response|http:ClientError httpResponse) returns @tainted Headers|error 
{
    Headers responseHeaders = {};
    if (httpResponse is http:Response) {
        responseHeaders.continuationHeader = getHeaderIfExist(httpResponse,CONTINUATION_HEADER);
        responseHeaders.sessionTokenHeader = getHeaderIfExist(httpResponse,SESSION_TOKEN_HEADER);
        responseHeaders.requestChargeHeader = getHeaderIfExist(httpResponse,REQUEST_CHARGE_HEADER);
        responseHeaders.resourceUsageHeader = getHeaderIfExist(httpResponse,RESOURCE_USAGE_HEADER);
        responseHeaders.itemCountHeader = getHeaderIfExist(httpResponse,ITEM_COUNT_HEADER);
        responseHeaders.etagHeader = getHeaderIfExist(httpResponse,ETAG_HEADER);
        responseHeaders.dateHeader = getHeaderIfExist(httpResponse,RESPONSE_DATE_HEADER);
        return responseHeaders;
    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

isolated function mapJsonToDatabaseType([json, Headers?] jsonPayload) returns Database {
    json payload;
    Headers? headers;
    [payload,headers] = jsonPayload;
    Database db = {};
    db.id = payload.id != ()? payload.id.toString() : EMPTY_STRING;
    db._rid = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    db._self = payload._self != ()? payload._self.toString() : EMPTY_STRING;
    if headers is Headers {
        db["reponseHeaders"] = headers;
    }    
    return db;
}

isolated function mapJsonToDatabasebList([json, Headers] jsonPayload) returns @tainted DatabaseList {
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    DatabaseList dbl = {};
    dbl._rid = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    dbl.databases =  convertToDatabaseArray(<json[]>payload.Databases);
    dbl.reponseHeaders = headers;
    return dbl;
}

isolated function mapJsonToContainerType([json, Headers?] jsonPayload) returns @tainted Container {
    json payload;
    Headers? headers;
    [payload,headers] = jsonPayload;
    Container coll = {};
    coll.id = payload.id.toString();
    coll._rid = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    coll._self = payload._self != ()? payload._self.toString() : EMPTY_STRING;
    coll.allowMaterializedViews = convertToBoolean(payload.allowMaterializedViews);
    coll.indexingPolicy = mapJsonToIndexingPolicy(<json>payload.indexingPolicy);
    coll.partitionKey = convertJsonToPartitionKey(<json>payload.partitionKey);
    if headers is Headers {
        coll["reponseHeaders"] = headers;
    }
    return coll;
}

isolated function mapJsonToContainerListType([json, Headers] jsonPayload) returns @tainted ContainerList {
    ContainerList cll = {};
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    cll._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    cll._count = convertToInt(payload._count);
    cll.containers = convertToContainerArray(<json[]>payload.DocumentCollections);
    cll.reponseHeaders = headers;
    return cll;
}

isolated function mapJsonToDocumentType([json, Headers?] jsonPayload) returns @tainted Document {  
    Document doc = {};
    json payload;
    Headers? headers;
    [payload,headers] = jsonPayload;
    doc.id = payload.id != () ? payload.id.toString(): EMPTY_STRING;
    doc._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    doc._self = payload._self != () ? payload._self.toString(): EMPTY_STRING;
    JsonMap|error document = payload.cloneWithType(JsonMap);
    if document is JsonMap {
        doc.documentBody = mapJsonToDocumentBody(document);
    }
    if headers is Headers {
        doc["reponseHeaders"] = headers;
    }
    return doc;
}

isolated function mapJsonToDocumentBody(map<json> reponsePayload) returns json {
    var deleteKeys = ["id","_rid","_self","_etag","_ts","_attachments"];
    foreach var 'key in deleteKeys {
        if reponsePayload.hasKey('key) {
            var removedValue = reponsePayload.remove('key);
        }
    }
    return reponsePayload;
}

isolated function mapJsonToDocumentListType([json, Headers] jsonPayload) returns @tainted DocumentList|error {
    DocumentList documentlist = {};
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    documentlist._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    documentlist._count = convertToInt(payload._count);
    documentlist.documents = check convertToDocumentArray(<json[]>payload.Documents);
    documentlist.reponseHeaders = headers;
    return documentlist;
} 

isolated function mapJsonToIndexingPolicy(json jsonPayload) returns @tainted IndexingPolicy {
    IndexingPolicy indp = {};
    indp.indexingMode = jsonPayload.indexingMode != ()? jsonPayload.indexingMode.toString() : EMPTY_STRING;
    indp.automatic = convertToBoolean(jsonPayload.automatic);
    indp.includedPaths =  convertToIncludedPathsArray(<json[]>jsonPayload.includedPaths);
    indp.excludedPaths =  convertToIncludedPathsArray(<json[]>jsonPayload.excludedPaths);
    return indp;
}

isolated function convertJsonToPartitionKey(json jsonPayload) returns @tainted PartitionKey {
    PartitionKey pk = {};
    pk.paths = convertToStringArray(<json[]>jsonPayload.paths);
    pk.kind = jsonPayload.kind != () ? jsonPayload.kind.toString(): EMPTY_STRING;
    pk.'version = convertToInt(jsonPayload.'version);
    return pk;
}

isolated function mapJsonToPartitionKeyType([json, Headers] jsonPayload) returns @tainted PartitionKeyList {
    PartitionKeyList pkl = {};
    PartitionKeyRange pkr = {};
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    pkl._rid = payload._rid != () ? payload._rid.toString(): EMPTY_STRING;
    pkl.PartitionKeyRanges = convertToPartitionKeyRangeArray(<json[]>payload.PartitionKeyRanges);
    pkl.reponseHeaders = headers;
    pkl._count = convertToInt(payload._count);
    return pkl;
}

isolated function mapJsonToIncludedPathsType(json jsonPayload) returns @tainted IncludedPath {
    IncludedPath ip = {};
    ip.path = jsonPayload.path.toString();
    if jsonPayload.indexes is error {
        return ip;
    } else {
        ip.indexes = convertToIndexArray(<json[]>jsonPayload.indexes);
    }
    return ip;
}

isolated function mapJsonToIndexType(json jsonPayload) returns Index {
    Index ind = {};
    ind.kind = jsonPayload.kind != () ? jsonPayload.kind.toString(): EMPTY_STRING;
    ind.dataType = jsonPayload.dataType.toString();
    ind.precision = convertToInt(jsonPayload.precision);
    return ind; 
}

isolated function convertToDatabaseArray(json[] sourceDatabaseArrayJsonObject) returns @tainted Database[] {
    Database[] databases = [];
    int i = 0;
    foreach json jsonDatabase in sourceDatabaseArrayJsonObject {
        databases[i] = mapJsonToDatabaseType([jsonDatabase,()]);
        i = i + 1;
    }
    return databases;
}

isolated function convertToIncludedPathsArray(json[] sourcePathArrayJsonObject) returns @tainted IncludedPath[] { 
    IncludedPath[] includedpaths = [];
    int i = 0;
    foreach json jsonPath in sourcePathArrayJsonObject {
        includedpaths[i] = <IncludedPath>mapJsonToIncludedPathsType(jsonPath);
        i = i + 1;
    }
    return includedpaths;
}

isolated function convertToPartitionKeyRangeArray(json[] sourcePrtitionKeyArrayJsonObject) returns @tainted PartitionKeyRange[] { 
    PartitionKeyRange[] pkranges = [];
    int i = 0;
    foreach json jsonPartitionKey in sourcePrtitionKeyArrayJsonObject {
        pkranges[i].id = jsonPartitionKey.id.toString();
        pkranges[i].minInclusive = jsonPartitionKey.minInclusive.toString();
        pkranges[i].maxExclusive = jsonPartitionKey.maxExclusive.toString();
        pkranges[i].status = jsonPartitionKey.status.toString();
        i = i + 1;
    }
    return pkranges;
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
        collections[i] = mapJsonToContainerType([jsonCollection,()]);
        i = i + 1;
    }
    return collections;
}

isolated function convertToDocumentArray(json[] sourceDocumentArrayJsonObject) returns @tainted Document[]|error { 
    Document[] documents = [];
    int i = 0;
    foreach json document in sourceDocumentArrayJsonObject { 
        documents[i] = mapJsonToDocumentType([document,()]);
        i = i + 1;
    }
    return documents;
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
