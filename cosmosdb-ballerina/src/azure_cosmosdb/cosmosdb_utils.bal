import ballerina/java;
import ballerina/time;
import ballerina/http;
import ballerina/stringutils;
import ballerina/lang.'string as str;

# To construct resource type  which is used to create the hashed token signature 
# + url - string parameter part of url to extract the resource type
# + return - Returns the resource type extracted from url as a string  
isolated function getResourceType(string url) returns string {
    string resourceType = EMPTY_STRING;
    string[] urlParts = stringutils:split(url,FORWARD_SLASH);
    int count = urlParts.length()-1;
    if count % 2 != 0 {
        resourceType = urlParts[count];
        if count > 1 {
            int? i = str:lastIndexOf(url,FORWARD_SLASH);
        }
    } else {
        resourceType = urlParts[count-1];
    }
    return resourceType;
}

# To construct resource id  which is used to create the hashed token signature 
# + url - string parameter part of url to extract the resource id
# + return - Returns the resource id extracted from url as a string 
isolated function getResourceId(string url) returns string {
    string resourceId = EMPTY_STRING;
    string[] urlParts = stringutils:split(url,FORWARD_SLASH);
    int count = urlParts.length()-1;
    if count % 2 != 0 {
        if count > 1 {
            int? i = str:lastIndexOf(url,FORWARD_SLASH);
            if i is int {
                resourceId = str:substring(url,1,i);
            }
        }
    } else {
        resourceId = str:substring(url,1);
    }
    return resourceId;
}

# Returns the prepared URL.
# + paths - An array of paths prefixes
# + return - The prepared URL
isolated function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;
    if (paths.length() > 0) {
        foreach var path in paths {
            if (!path.startsWith(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return <@untainted> url;
}

# To create a custom error instance
# + return - returns error.  
isolated function prepareError(string message, error? err = ()) returns error { 
    error azureError;
    if (err is error) {
        azureError = AzureError(message, err);
    } else {
        azureError = AzureError(message);
    }
    return azureError;
}

# To attach required basic headers to call REST endpoint
# + req - http:Request to add headers to
# + host - 
# + keyToken - master or resource token
# + tokenType - denotes the type of token: master or resource.
# + tokenVersion - denotes the version of the token, currently 1.0.
# + params - an object of type HeaderParamaters
# + return - If successful, returns same http:Request with newly appended headers. Else returns error.  
isolated function setHeaders(http:Request req, string host, string keyToken, string tokenType, string tokenVersion,
HeaderParameters params) returns http:Request|error {
    req.setHeader(API_VERSION_HEADER,params.apiVersion);
    req.setHeader(HOST_HEADER,host);
    req.setHeader(ACCEPT_HEADER,"*/*");
    req.setHeader(CONNECTION_HEADER,"keep-alive");

    string?|error date = getTime();
    if date is string {
        string? token = generateTokenNew(params.verb,params.resourceType,params.resourceId,keyToken,tokenType,tokenVersion);
        req.setHeader(DATE_HEADER,date);
        if token is string {
            req.setHeader(AUTHORIZATION_HEADER,token);
        } else {
            return prepareError("Authorization token is null");
        }
    } else {
        return prepareError("Date header is invalid/null");
    }
    return req;
}

# To construct the hashed token signature for a token 
# + return - If successful, returns string representing UTC date and time 
#               (in "HTTP-date" format as defined by RFC 7231 Date/Time Formats). Else returns error.  
isolated function getTime() returns string?|error {
    time:Time time1 = time:currentTime();
    var time2 = check time:toTimeZone(time1, GMT_ZONE);
    string|error timeString = time:format(time2, "EEE, dd MMM yyyy HH:mm:ss z");
    return timeString;
}

# To construct the hashed token signature for a token to set  'Authorization' header
# + verb - HTTP verb, such as GET, POST, or PUT
# + resourceType - identifies the type of resource that the request is for, Eg. "dbs", "colls", "docs"
# + resourceId -dentity property of the resource that the request is directed at
# + keyToken - master or resource token
# + tokenType - denotes the type of token: master or resource.
# + tokenVersion - denotes the version of the token, currently 1.0.
# + return - If successful, returns string which is the  hashed token signature. Else returns ().  
isolated function generateTokenNew(string verb, string resourceType, string resourceId, string keyToken, string tokenType, 
string tokenVersion) returns string? {
    var token = generateTokenJava(java:fromString(verb),java:fromString(resourceType),java:fromString(resourceId),
    java:fromString(keyToken),java:fromString(tokenType),java:fromString(tokenVersion));
    return java:toString(token);
}

isolated function setThroughputOrAutopilotHeader(http:Request req, ThroughputProperties? throughputProperties) returns 
http:Request|error {
    if throughputProperties is ThroughputProperties {
        if throughputProperties.throughput is int &&  throughputProperties.maxThroughput is () {
            req.setHeader(THROUGHPUT_HEADER, throughputProperties.maxThroughput.toString());
        } else if throughputProperties.throughput is () &&  throughputProperties.maxThroughput != () {
            req.setHeader(AUTOPILET_THROUGHPUT_HEADER, throughputProperties.maxThroughput.toString());
        } else if throughputProperties.throughput is int &&  throughputProperties.maxThroughput != () {
            return 
            prepareError("Cannot set both x-ms-offer-throughput and x-ms-cosmos-offer-autopilot-settings headers at once");
        }
    }
    return req;
}

isolated function mapResponseToTuple(http:Response|http:ClientError httpResponse) returns @tainted [json, Headers]|error {
    var responseBody = check mapResponseToJson(httpResponse);
    var responseHeaders = check mapResponseHeadersToObject(httpResponse);
    return [responseBody,responseHeaders];
}

# To handle sucess or error reponses to requests
# + httpResponse - http:Response or http:ClientError returned from an http:Request
# + return - If successful, returns json. Else returns error.  
isolated function mapResponseToJson(http:Response|http:ClientError httpResponse) returns @tainted json|error { 
    if (httpResponse is http:Response) {
        var jsonResponse = httpResponse.getJsonPayload();
        if (jsonResponse is json) {
            if (httpResponse.statusCode != http:STATUS_OK && httpResponse.statusCode != http:STATUS_CREATED) {
                return createResponseFailMessage(httpResponse,jsonResponse);
            }
            return jsonResponse;
        } else {
            return prepareError("Error occurred while accessing the JSON payload of the response");
        }
    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

# To handle the delete responses which return without a json payload
# + httpResponse - http:Response or http:ClientError returned from an http:Request
# + return - If successful, returns string. Else returns error.  
isolated function getDeleteResponse(http:Response|http:ClientError httpResponse) returns @tainted boolean|error {
    if (httpResponse is http:Response) {
        if(httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            var jsonResponse = httpResponse.getJsonPayload();
            if jsonResponse is json {
                return createResponseFailMessage(httpResponse,jsonResponse);
            }else {
                return prepareError("Error occurred while accessing the JSON payload of the response");
            }
        }
    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

isolated function createResponseFailMessage(http:Response httpResponse, json errorResponse) returns error {
    string message = errorResponse.message.toString();
    string errorMessage = httpResponse.statusCode.toString() + " " + httpResponse.reasonPhrase; 
    var stoppingIndex = message.indexOf("ActivityId");
    if stoppingIndex is int {
        errorMessage += " : " + message.substring(0,stoppingIndex);
    }
    return prepareError(errorMessage);
}

# Convert json string values to boolean
# + value - json value which has reprsents boolean value
# + return - boolean value of specified json
isolated function convertToBoolean(json|error value) returns boolean { 
    if (value is json) {
        boolean|error result = 'boolean:fromString(value.toString());
        if (result is boolean) {
            return result;
        }
    }
    return false;
}

# Convert json string values to int
# + value - json value which has reprsents int value
# + return - int value of specified json
isolated function convertToInt(json|error value) returns int {
    if (value is json) {
        int|error result = 'int:fromString(value.toString());
        if (result is int) {
            return result;
        }
    }
    return 0;
}

isolated function getHeaderIfExist(http:Response httpResponse, string headername) returns @tainted string? {
    if httpResponse.hasHeader(headername) {
        return httpResponse.getHeader(headername);
    } else {
        return ();
    }
}

isolated function generateTokenJava(handle verb, handle resourceType, handle resourceId, handle keyToken, handle tokenType, 
handle tokenVersion) returns handle = @java:Method {
    name: "generateToken",
    'class: "org.ballerinalang.cosmosdb.AuthToken"
} external;
