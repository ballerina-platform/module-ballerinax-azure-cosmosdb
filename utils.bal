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

import ballerina/time;
import ballerina/http;
import ballerina/crypto;
import ballerina/encoding;
import ballerina/stringutils;
import ballerina/lang.'string as str;
import ballerina/lang.array as array;

//  Extract the type of token used for accessing the Cosmos DB.
// 
//  + token - the token provided by the user to access Cosmos DB.
//
function getTokenType(string token) returns string {
    boolean ifContain = stringutils:contains(token, TOKEN_TYPE_RESOURCE);
    if (ifContain) {
        return TOKEN_TYPE_RESOURCE;
    } else {
        return TOKEN_TYPE_MASTER;
    }
}

//  Extract the host of the cosmos db from the base url.
// 
//  + url - the Base URL given by the user from which we want to extract host.
//  + return - string representing the resource id.
//
isolated function getHost(string url) returns string {
    string replacedString = stringutils:replaceFirst(url, HTTPS_REGEX, EMPTY_STRING);
    int? lastIndex = str:lastIndexOf(replacedString, FORWARD_SLASH);
    if (lastIndex is int) {
        replacedString = replacedString.substring(0, lastIndex);
    }
    return replacedString;
}

//  Extract the resource type related to cosmos db from a given url
// 
//  + url - the URL from which we want to extract resource type
//  + return - string representing the resource type
//
isolated function getResourceType(string url) returns string {
    string resourceType = EMPTY_STRING;
    string[] urlParts = stringutils:split(url, FORWARD_SLASH);
    int count = urlParts.length() - 1;
    if (count % 2 != 0) {
        resourceType = urlParts[count];
        if (count > 1) {
            int? lastIndex = str:lastIndexOf(url, FORWARD_SLASH);
        }
    } else {
        resourceType = urlParts[count - 1];
    }
    return resourceType;
}

//  Extract the resource type related to cosmos db from a given url
// 
//  + url - the URL from which we want to extract resource type
//  + return - string representing the resource id
//
isolated function getResourceId(string url) returns string {
    string resourceId = EMPTY_STRING;
    string[] urlParts = stringutils:split(url, FORWARD_SLASH);
    int count = urlParts.length() - 1;
    string resourceType = getResourceType(url);
    if (resourceType == RESOURCE_TYPE_OFFERS) {
        if (count % 2 != 0) {
            resourceId = EMPTY_STRING;
        } else {
            int? lastIndex = str:lastIndexOf(url, FORWARD_SLASH);
            if (lastIndex is int) {
                resourceId = str:substring(url, lastIndex + 1);
            }
        }
        return resourceId.toLowerAscii();
    } else {
        if (count % 2 != 0) {
            if (count > 1) {
                int? lastIndex = str:lastIndexOf(url, FORWARD_SLASH);
                if (lastIndex is int) {
                    resourceId = str:substring(url, 1, lastIndex);
                }
            }
        } else {
            resourceId = str:substring(url, 1);
        }
        return resourceId;
    }
}

//  Prepare the url out of a given string array 
// 
//  + paths - array of strings with path of the url
//  + return - string representing the complete url
//
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
    return <@untainted>url;
}

//  Attach mandatory basic headers to call a REST endpoint.
//  
//  + request - http:Request to add headers to
//  + host - the host to which the request is sent
//  + keyToken - master or resource token
//  + tokenType - denotes the type of token: master or resource.
//  + tokenVersion - denotes the version of the token, currently 1.0.
//  + httpVerb - The HTTP verb of the request the headers are set to.
//  + requestPath - Request path of the request.
//  + return - If successful, returns same http:Request with newly appended headers. Else returns error.
//
function setMandatoryHeaders(http:Request request, string host, string token, string httpVerb, string requestPath) 
        returns error? {
    request.setHeader(API_VERSION_HEADER, API_VERSION);
    request.setHeader(HOST_HEADER, host);
    request.setHeader(ACCEPT_HEADER, ACCEPT_ALL);
    request.setHeader(http:CONNECTION, CONNECTION_KEEP_ALIVE);
    string tokenType = getTokenType(token);
    string? dateTime = check getDateTime();
    if (dateTime is string) {
        request.setHeader(DATE_HEADER, dateTime);
        string? signature = ();
        if (tokenType.toLowerAscii() == TOKEN_TYPE_MASTER) {
            signature = check generateMasterTokenSignature(httpVerb, getResourceType(requestPath), 
                    getResourceId(requestPath), token, tokenType, TOKEN_VERSION, dateTime);
        } else if (tokenType.toLowerAscii() == TOKEN_TYPE_RESOURCE) {
            signature = check encoding:encodeUriComponent(token, UTF8_URL_ENCODING);
        } else {
            return prepareUserError(NULL_RESOURCE_TYPE_ERROR);
        }
        if (signature is string) {
            request.setHeader(http:AUTH_HEADER, signature);
        } else {
            return prepareAzureError(NULL_AUTHORIZATION_SIGNATURE_ERROR);
        }
    } else {
        return prepareAzureError(NULL_DATE_ERROR);
    }
}

//  Set the optional header related to partitionkey value.
//  
//  + request - http:Request to set the header
//  + partitionKey - the array containing the value of the partition key
//  + return - If successful, returns same http:Request with newly appended headers. Else returns error.
//
isolated function setPartitionKeyHeader(http:Request request, any partitionKeyValue) {
    any[] partitionKeyArray = [partitionKeyValue];
    request.setHeader(PARTITION_KEY_HEADER, string `${partitionKeyArray.toString()}`);
}

//  Set the required headers related to query operations.
//  
//  + request - http:Request to set the header
//  + return - If successful, returns same http:Request with newly appended headers. Else returns error.
//
isolated function setHeadersForQuery(http:Request request) {
    var req = request.setContentType(CONTENT_TYPE_QUERY);
    request.setHeader(ISQUERY_HEADER, true.toString());
}

//  Set the optional header related to throughput options.
//  
//  + request - http:Request to set the header
//  + throughputOption - Optional. Throughput parameter of type int or json.
//  + return - If successful, returns same http:Request with newly appended headers. Else returns error.
//
isolated function setThroughputOrAutopilotHeader(http:Request request, (int|json) throughputOption = ()) returns error? {
    if (throughputOption is int) {
        if (throughputOption >= MIN_REQUEST_UNITS) {
            request.setHeader(THROUGHPUT_HEADER, throughputOption.toString());
        } else {
            return prepareUserError(MINIMUM_MANUAL_THROUGHPUT_ERROR);
        }
    } else {
        request.setHeader(AUTOPILET_THROUGHPUT_HEADER, throughputOption.toString());
    }
}

//  Set the optional headers to the HTTP request.
//  
//  + request - http:Request to set the header
//  + requestOptions - object of type RequestHeaderOptions containing the values for optional headers
//  + return - If successful, returns same http:Request with newly appended headers. Else returns error.
//
isolated function setOptionalHeaders(http:Request request, Options? requestOptions) {
    if (requestOptions?.indexingDirective != ()) {
        request.setHeader(INDEXING_DIRECTIVE_HEADER, <boolean>requestOptions?.indexingDirective ? INDEXING_TYPE_INCLUDE : 
                INDEXING_TYPE_EXCLUDE);
    }
    if (requestOptions?.consistancyLevel != ()) {
        request.setHeader(CONSISTANCY_LEVEL_HEADER, requestOptions?.consistancyLevel.toString());
    }
    if (requestOptions?.sessionToken != ()) {
        request.setHeader(SESSION_TOKEN_HEADER, requestOptions?.sessionToken.toString());
    }
    if (requestOptions?.changeFeedOption != ()) {
        request.setHeader(A_IM_HEADER, requestOptions?.changeFeedOption.toString());
    }
    if (requestOptions?.ifNoneMatchEtag != ()) {
        request.setHeader(http:IF_NONE_MATCH, requestOptions?.ifNoneMatchEtag.toString());
    }
    if (requestOptions?.partitionKeyRangeId != ()) {
        request.setHeader(PARTITIONKEY_RANGE_HEADER, requestOptions?.partitionKeyRangeId.toString());
    }
    if (requestOptions?.ifMatchEtag != ()) {
        request.setHeader(http:IF_MATCH, requestOptions?.ifMatchEtag.toString());
    }
    if (requestOptions?.enableCrossPartition == true) {
        request.setHeader(IS_ENABLE_CROSS_PARTITION_HEADER, requestOptions?.enableCrossPartition.toString());
    }
    if (requestOptions?.isUpsertRequest == true) {
        request.setHeader(IS_UPSERT_HEADER, requestOptions?.isUpsertRequest.toString());
    }
}

//  Set the optional header specifying time to live.
//  
//  + request - http:Request to set the header
//  + validationPeriod - the integer specifying the time to live value for a permission token
//  + return - If successful, returns same http:Request with newly appended headers. Else returns error.
//
isolated function setExpiryHeader(http:Request request, int validationPeriod) returns error? {
    if (validationPeriod >= MIN_TIME_TO_LIVE && validationPeriod <= MAX_TIME_TO_LIVE) {
        request.setHeader(EXPIRY_HEADER, validationPeriod.toString());
    } else {
        return prepareUserError(VALIDITY_PERIOD_ERROR);
    }
}

//  Get the current time in the specific format.
//  
//  + return - If successful, returns string representing UTC date and time 
//          (in "HTTP-date" format as defined by RFC 7231 Date/Time Formats). Else returns error.
//
isolated function getDateTime() returns string?|error {
    time:Time currentTime = time:currentTime();
    time:Time timeWithZone = check time:toTimeZone(currentTime, GMT_ZONE);
    string timeString = check time:format(timeWithZone, TIME_ZONE_FORMAT);
    return timeString; 
}

//  To construct the hashed token signature for a token to set  'Authorization' header.
//  
//  + verb - HTTP verb, such as GET, POST, or PUT
//  + resourceType - identifies the type of resource that the request is for, Eg. "dbs", "colls", "docs"
//  + resourceId -dentity property of the resource that the request is directed at
//  + keyToken - master or resource token
//  + tokenType - denotes the type of token: master or resource.
//  + tokenVersion - denotes the version of the token, currently 1.0.
//  + date - current GMT date and time
//  + return - If successful, returns string which is the  hashed token signature. Else returns () or error.
// 
isolated function generateMasterTokenSignature(string verb, string resourceType, string resourceId, string keyToken, 
        string tokenType, string tokenVersion, string date) returns string?|error {
    string payload = verb.toLowerAscii() + NEW_LINE + resourceType.toLowerAscii() + NEW_LINE + resourceId + NEW_LINE + 
            date.toLowerAscii() + NEW_LINE + EMPTY_STRING + NEW_LINE;
    byte[] decodedArray = check array:fromBase64(keyToken); 
    byte[] digest = crypto:hmacSha256(payload.toBytes(), decodedArray);
    string signature = array:toBase64(digest);
    string authorizationString = string `type=${tokenType}&ver=${tokenVersion}&sig=${signature}`;
    string? encodedAuthorizationString = check encoding:encodeUriComponent(authorizationString, "UTF-8");
    return encodedAuthorizationString;      
}

//  Handle sucess or error reponses to requests and extract the json payload.
//  
//  + httpResponse - http:Response or http:ClientError returned from an http:Request
//  + return - If successful, returns json. Else returns error. 
//
isolated function handleResponse(http:Response httpResponse) returns @tainted json|error {
    json jsonResponse = check httpResponse.getJsonPayload();
    if (httpResponse.statusCode == http:STATUS_OK) {
        //If status is 200, request is successful. Returns resulting payload.
        return jsonResponse;
    } else {
        string message = jsonResponse.message.toString();
        return prepareAzureError(message, (), httpResponse.statusCode);
    }
}

//  Handle sucess or error reponses to requests and extract the json payload.
//  
//  + httpResponse - http:Response or http:ClientError returned from an http:Request
//  + return - If successful, returns json. Else returns error. 
//
isolated function handleCreationResponse(http:Response httpResponse) returns @tainted boolean|error {
    if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED || 
            httpResponse.statusCode == http:STATUS_NO_CONTENT) {
        //If status is 200 the resource is replaced, 201 resource is created, request is successful returns true. 
        // Else Returns error.
        return true;
    } else {
        json jsonResponse = check httpResponse.getJsonPayload();
        string message = jsonResponse.message.toString();
        return prepareAzureError(message, (), httpResponse.statusCode);
    }
}

//  Map the json payload and necessary header values returend from a response to a tuple.
//  
//  + httpResponse - the http:Response or http:ClientError returned form the HTTP request
//  + return - returns a tuple of type [json, ResponseHeaders] if sucessful else, returns error
//
isolated function mapResponseToTuple(http:Response httpResponse) returns @tainted [json, 
        ResponseHeaders]|error {
    json responseBody = check handleResponse(httpResponse);
    ResponseHeaders responseHeaders = check mapResponseHeadersToHeadersRecord(httpResponse);
    return [responseBody, responseHeaders];
}

//  Map the json payload and necessary header values returend from a response to a tuple.
//  
//  + httpResponse - the http:Response or http:ClientError returned form the HTTP request
//  + return - returns a tuple of type [json, ResponseHeaders] if sucessful else, returns error
//
isolated function mapCreationResponseToTuple(http:Response httpResponse) returns @tainted [boolean, 
        ResponseHeaders]|error {
    boolean responseBody = check handleCreationResponse(httpResponse);
    ResponseHeaders responseHeaders = check mapResponseHeadersToHeadersRecord(httpResponse);
    return [responseBody, responseHeaders];
}

//  Get the http:Response and extract the headers to the record type ResponseHeaders
//  
//  + httpResponse - http:Response or http:ClientError returned from an http:Request
//  + return - If successful, returns record type ResponseHeaders. Else returns error.
//
isolated function mapResponseHeadersToHeadersRecord(http:Response httpResponse) returns @tainted ResponseHeaders|error {
    ResponseHeaders responseHeaders = {};
    responseHeaders.continuationHeader = getHeaderIfExist(httpResponse, CONTINUATION_HEADER);
    responseHeaders.sessionToken = getHeaderIfExist(httpResponse, SESSION_TOKEN_HEADER);
    responseHeaders.eTag = getHeaderIfExist(httpResponse, http:ETAG);
    return responseHeaders;
}

//  Convert json string values to int
//  
//  + httpResponse - http:Response returned from an http:RequestheaderName
//  + headerName - name of the header
//  + return - int value of specified json
//
isolated function getHeaderIfExist(http:Response httpResponse, string headerName) returns @tainted string {
    string headerValue = "";
    if (httpResponse.hasHeader(headerName)) {
        headerValue = httpResponse.getHeader(headerName);
    } 
    return headerValue;
} 

//  Get a stream of json documents which is returned as query results
//  
//  + azureCosmosClient - client which calls the azure endpoint
//  + path - pathe to which API call is made
//  + request - http request object 
//  + array - the array with the returned results
//  + maxItemCount - maximum item count per one page value 
//  + continuationHeader - the continuation header which points to the next page
// 
function getQueryResults(http:Client azureCosmosClient, string path, http:Request request, int? maxItemCount = ()) 
        returns @tainted stream<json>|error {
    // if (continuationHeader is string) {
    //     request.setHeader(CONTINUATION_HEADER, continuationHeader);
    // }
    http:Response response = <http:Response> check azureCosmosClient->post(path, request);
    var [payload, responseHeaders] = check mapResponseToTuple(response);

    if (payload.Documents is json) {
        json[] array =  <json[]>payload.Documents;
        stream<json> documentStream = (<@untainted>array).toStream();
        // This part of the code is for recursively calling the request when another page exits in the result and user 
        // wants to get those too.
        // if (responseHeaders?.continuationHeader != () && maxItemCount is ()) {
        //     documentStream = check getQueryResults(azureCosmosClient, path, request, array, (), 
        //      responseHeaders?.continuationHeader);
        // }
        return documentStream;
    } else if (payload.Offers is json) {
        json[] array = <json[]>payload.Offers;
        stream<json> offerStream = (<@untainted>array).toStream();
        // This part of the code is for recursively calling the request when another page exits in the result and user 
        // wants to get those too.
        // if (responseHeaders?.continuationHeader != () && maxItemCount is ()) {
        //     offerStream = check getQueryResults(azureCosmosClient, path, request, array, (), 
        //          responseHeaders?.continuationHeader);
        // }
        return offerStream;
    }
    else {
        return prepareAzureError(INVALID_RESPONSE_PAYLOAD_ERROR);
    }
}

function retriveStream(http:Client azureCosmosClient, string path, http:Request request) returns @tainted 
        stream<record{}>|error {
    // if (continuationHeader is string) {
    //     request.setHeader(CONTINUATION_HEADER, continuationHeader);
    // }
    http:Response response = <http:Response> check azureCosmosClient->get(path, request);
    var [payload, headers] = check mapResponseToTuple(response);
    stream<record{}> finalStream = check createStream(azureCosmosClient, path, request, payload);
    return finalStream;
}

isolated function createStream(http:Client azureCosmosClient, string path, http:Request request, json payload) 
        returns @tainted stream<record{}>|error {
    record{}[] finalArray = [];
    if (payload.Databases is json) {
        finalArray = convertToDatabaseArray(<json[]>payload.Databases);
    } else if (payload.DocumentCollections is json) {
        finalArray = convertToContainerArray(<json[]>payload.DocumentCollections);
    } else if (payload.Documents is json) {
        finalArray = convertToDocumentArray(<json[]>payload.Documents);
    } else if (payload.StoredProcedures is json) {
        finalArray = convertToStoredProcedureArray( <json[]>payload.StoredProcedures);
    } else if (payload.UserDefinedFunctions is json) {
        finalArray = convertsToUserDefinedFunctionArray(<json[]>payload.UserDefinedFunctions);
    } else if (payload.Triggers is json) {
        finalArray = convertToTriggerArray(<json[]>payload.Triggers);
    } else if (payload.Users is json) {
        finalArray = convertToUserArray(<json[]>payload.Users);
    } else if (payload.Permissions is json) {
        finalArray = convertToPermissionArray(<json[]>payload.Permissions);
    } else if (payload.PartitionKeyRanges is json) {
        finalArray = convertToPartitionKeyRangeArray(<json[]>payload.PartitionKeyRanges);
    } else if (payload.Offers is json) {
        finalArray = convertToOfferArray(<json[]>payload.Offers);
    } else {
        return prepareAzureError(INVALID_RESPONSE_PAYLOAD_ERROR);
    }

    stream<record{}> newStream = (<@untainted>finalArray).toStream();
    // This part of the code is for recursively calling the request when another page exits in the result and user wants
    // to get those too.
    // if (continuationHeader != () && maxItemCount is ()) {
    //     newStream = check retriveStream(azureCosmosClient, path, request, <@untainted>finalArray, (), 
    //      continuationHeader);
    // }
    return newStream;
}

//  Convert json string values to boolean.
//  
//  + value - json value which has reprsents boolean value
//  + return - boolean value of specified json
//
isolated function convertToBoolean(json|error value) returns boolean {
    if (value is json) {
        boolean|error result = 'boolean:fromString(value.toString());
        if (result is boolean) {
            return result;
        }
    }
    return false;
}

//  Convert json string values to int
//  
//  + value - json value which has reprsents int value
//  + return - int value of specified json
//
isolated function convertToInt(json|error value) returns int {
    if (value is json) {
        int|error result = 'int:fromString(value.toString());
        if (result is int) {
            return result;
        }
    }
    return 0;
}
