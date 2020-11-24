import ballerina/http;

isolated function mapParametersToHeaderType(string httpVerb, string url) returns RequestHeaderParameters {
    RequestHeaderParameters params = {};
    params.verb = httpVerb;
    params.resourceType = getResourceType(url);
    params.resourceId = getResourceId(url);
    return params;
}

isolated function mapResponseHeadersToObject(http:Response|http:ClientError httpResponse) returns @tainted Headers|error 
{
    Headers responseHeaders = {};
    if (httpResponse is http:Response) {
        responseHeaders.continuationHeader = getHeaderIfExist(httpResponse,"x-ms-continuation");
        responseHeaders.sessionTokenHeader = getHeaderIfExist(httpResponse,"x-ms-session-token");
        responseHeaders.requestChargeHeader = getHeaderIfExist(httpResponse,"x-ms-request-charge");
        responseHeaders.resourceUsageHeader = getHeaderIfExist(httpResponse,"x-ms-resource-usage");
        responseHeaders.itemCountHeader = getHeaderIfExist(httpResponse,"x-ms-item-count");
        responseHeaders.etagHeader = getHeaderIfExist(httpResponse,"etag");
        responseHeaders.dateHeader = getHeaderIfExist(httpResponse,"Date");
        return responseHeaders;

    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

isolated function mapJsonToDatabaseType([json, Headers] jsonPayload) returns Database {
    json payload;
    Headers headers;
    [payload,headers] = jsonPayload;
    Database db = {};
    db.id = payload.id.toString();
    db.reponseHeaders = headers;
    return db;
}