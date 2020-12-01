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

isolated function mapJsonToDbList([json, Headers] jsonPayload) returns @tainted DatabaseList {
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    DatabaseList dbl = {};
    dbl._rid = payload._rid != ()? payload._rid.toString() : EMPTY_STRING;
    dbl.Databases =  convertToDatabaseArray(<json[]>payload.Databases);
    dbl.reponseHeaders = headers;
    return dbl;
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
