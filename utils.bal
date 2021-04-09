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

import ballerina/crypto;
import ballerina/url;
import ballerina/http;
import ballerina/jballerina.java;
import ballerina/lang.array;
import ballerina/regex;
import ballerina/time;

# Extract the type of token used for accessing the Cosmos DB.
# 
# + token - The token provided by the user to access Cosmos DB
# + return - A string value which represents the type of token
isolated function getTokenType(string token) returns string {
    boolean ifContain = token.includes(TOKEN_TYPE_RESOURCE);
    if (ifContain) {
        return TOKEN_TYPE_RESOURCE;
    } else {
        return TOKEN_TYPE_MASTER;
    }
}

# Extract the host of the Cosmos DB from the base URL.
# 
# + url - The Base URL given by the user from which we want to extract host
# + return - String representing the resource id
isolated function getHost(string url) returns string {
    string replacedString = regex:replaceFirst(url, HTTPS_REGEX, EMPTY_STRING);
    int? lastIndex = replacedString.lastIndexOf(FORWARD_SLASH);
    if (lastIndex is int) {
        replacedString = replacedString.substring(0, lastIndex);
    }
    return replacedString;
}

# Extract the resource type related to Cosmos DB from a given URL.
# 
# + url - The URL from which we want to extract resource type
# + return - String representing the resource type
isolated function getResourceType(string url) returns string {
    string resourceType = EMPTY_STRING;
    string[] urlParts = regex:split(url, FORWARD_SLASH);
    int count = urlParts.length() - 1;
    if (count % 2 != 0) {
        resourceType = urlParts[count];
        if (count > 1) {
            int? lastIndex = url.lastIndexOf(FORWARD_SLASH);
        }
    } else {
        resourceType = urlParts[count - 1];
    }
    return resourceType;
}

# Extract the resource ID related to Cosmos DB from a given URL.
# 
# + url - The URL from which we want to extract resource type
# + return - String representing the resource id
isolated function getResourceId(string url) returns string {
    string resourceId = EMPTY_STRING;
    string[] urlParts = regex:split(url, FORWARD_SLASH);
    int count = urlParts.length() - 1;
    string resourceType = getResourceType(url);
    if (resourceType == RESOURCE_TYPE_OFFERS) {
        if (count % 2 != 0) {
            resourceId = EMPTY_STRING;
        } else {
            int? lastIndex = url.lastIndexOf(FORWARD_SLASH);
            if (lastIndex is int) {
                resourceId = url.substring(lastIndex + 1);
            }
        }
        return resourceId.toLowerAscii();
    } else {
        if (count % 2 != 0) {
            if (count > 1) {
                int? lastIndex = url.lastIndexOf(FORWARD_SLASH);
                if (lastIndex is int) {
                    resourceId = url.substring(1, lastIndex);
                }
            }
        } else {
            resourceId = url.substring(1);
        }
        return resourceId;
    }
}

# Prepare the complete URL out of a given string array. 
# 
# + paths - Array of strings with parts of the URL
# + return - String representing the complete URL
isolated function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;
    if (paths.length() > 0) {
        foreach string path in paths {
            if (!path.startsWith(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return <@untainted>url;
}

# Attach mandatory basic headers to HTTP request.
# 
# + request - The http:Request to add headers to
# + host - The host to which the request is sent
# + token - Master or resource token
# + httpVerb - The HTTP verb of the request the headers are set to
# + requestPath - Request path for the request
# + return - If successful, request will be appended with headers. Else returns `Error`.
isolated function setMandatoryHeaders(http:Request request, string host, string token, http:HttpOperation httpVerb, 
                                      string requestPath) returns Error? {
    request.setHeader(API_VERSION_HEADER, API_VERSION);
    request.setHeader(HOST_HEADER, host);
    request.setHeader(ACCEPT_HEADER, ACCEPT_ALL);
    request.setHeader(http:CONNECTION, CONNECTION_KEEP_ALIVE);
    string tokenType = getTokenType(token);
    string dateTime = check getDateTime();
    request.setHeader(DATE_HEADER, dateTime);
    string signature = EMPTY_STRING;
    if (tokenType.toLowerAscii() == TOKEN_TYPE_MASTER) {
        signature = check generatePrimaryKeySignature(httpVerb, getResourceType(requestPath), 
            getResourceId(requestPath), token, tokenType, dateTime);
    } else if (tokenType.toLowerAscii() == TOKEN_TYPE_RESOURCE) {
        signature = check url:encode(token, UTF8_URL_ENCODING);
    } else {
        return error InputValidationError(NULL_RESOURCE_TYPE_ERROR);
    }
    request.setHeader(http:AUTH_HEADER, signature);
}

# Attach mandatory basic headers to HTTP GET request.
# 
# + host - The host to which the request is sent
# + token - Master or resource token
# + httpVerb - The HTTP verb of the request the headers are set to
# + requestPath - Request path for the request
# + return - If successful, request will be appended with headers. Else returns `Error`.
isolated function setMandatoryGetHeaders(string host, string token, http:HttpOperation httpVerb, string requestPath) 
                                         returns map<string>|Error {
    string tokenType = getTokenType(token);
    string dateTime = check getDateTime();
    string signature = EMPTY_STRING;
    if (tokenType.toLowerAscii() == TOKEN_TYPE_MASTER) {
        signature = check generatePrimaryKeySignature(httpVerb, getResourceType(requestPath), 
            getResourceId(requestPath), token, tokenType, dateTime);
    } else if (tokenType.toLowerAscii() == TOKEN_TYPE_RESOURCE) {
        signature = check url:encode(token, UTF8_URL_ENCODING);
    } else {
        return error InputValidationError(NULL_RESOURCE_TYPE_ERROR);
    }

    return {
        [API_VERSION_HEADER] : API_VERSION,
        [HOST_HEADER] : host,
        [ACCEPT_HEADER] : ACCEPT_ALL,
        [http:CONNECTION] : CONNECTION_KEEP_ALIVE,
        [DATE_HEADER] : dateTime,
        [http:AUTH_HEADER] : signature
    };
}

# Set the optional header related to partitionkey value.
#
# + request - The http:Request to set the header
# + partitionKeyValue - The value of the partition key
isolated function setPartitionKeyHeader(http:Request request, (int|float|decimal|string)? partitionKeyValue) {
    if (partitionKeyValue is (int|float|decimal|string)) {
        if (partitionKeyValue is string) {
            request.setHeader(PARTITION_KEY_HEADER, string `["${partitionKeyValue.toString()}"]`);        
        } else {
            request.setHeader(PARTITION_KEY_HEADER, string `[${partitionKeyValue.toString()}]`);
        }
    }
    return;
}

# Set the optional header related to partitionkey value in GET requests.
#
# + headerMap - A map of type string.
# + partitionKeyValue - The value of the partition key
# + return - A map of strings.
isolated function setGetPartitionKeyHeader(map<string> headerMap, (int|float|decimal|string)? partitionKeyValue) returns 
                                           map<string> {
    if (partitionKeyValue is (int|float|decimal|string)) {
        if (partitionKeyValue is string) {
            headerMap[PARTITION_KEY_HEADER] = string `["${partitionKeyValue.toString()}"]`;
        } else {
            headerMap[PARTITION_KEY_HEADER] = string `[${partitionKeyValue.toString()}]`;
        }
    }
    return headerMap;
}

# Set the required headers related to query operations.
#
# + request - The http:Request to set the header
# + return - If successful, request will be appended with headers. Else returns `Error`
isolated function setHeadersForQuery(http:Request request) returns Error? {
    check request.setContentType(CONTENT_TYPE_QUERY);
    request.setHeader(ISQUERY_HEADER, TRUE);
}

# Set the optional header related to throughput options.
#
# + request - The http:Request to set the header
# + throughputOption - Throughput parameter of type int or json
# + return - If successful, request will be appended with headers. Else returns `Error`.
isolated function setThroughputOrAutopilotHeader(http:Request request, 
                                                (int|record{|int maxThroughput;|})? throughputOption = ()) 
                                                returns Error? {
    if (throughputOption is int) {
        if (throughputOption >= MIN_REQUEST_UNITS) {
            request.setHeader(THROUGHPUT_HEADER, throughputOption.toString());
        } else {
            return error InputValidationError(MINIMUM_MANUAL_THROUGHPUT_ERROR);
        }
    } else if (throughputOption is record{|int maxThroughput;|}) {
        request.setHeader(AUTOPILET_THROUGHPUT_HEADER, throughputOption.toString());
    } else {
        return;
    }
}

# Set the optional headers to the HTTP request.
#
# + request - The http:Request to set the header
# + requestOptions - Record of type Options containing the values for optional headers
isolated function setOptionalHeaders(http:Request request, Options? requestOptions) {
    if (requestOptions?.indexingDirective is IndexingDirective) {
        request.setHeader(INDEXING_DIRECTIVE_HEADER, <string>requestOptions?.indexingDirective);
    }
    if (requestOptions?.consistancyLevel is ConsistencyLevel) {
        request.setHeader(CONSISTANCY_LEVEL_HEADER, <string>requestOptions?.consistancyLevel);
    }
    if (requestOptions?.sessionToken is string) {
        request.setHeader(SESSION_TOKEN_HEADER, <string>requestOptions?.sessionToken);
    }
    if (requestOptions?.changeFeedOption is ChangeFeedOption){
        request.setHeader(A_IM_HEADER, <string>requestOptions?.changeFeedOption);
    }
    if (requestOptions?.partitionKeyRangeId is string) {
        request.setHeader(PARTITIONKEY_RANGE_HEADER, <string>requestOptions?.partitionKeyRangeId);
    }
    if (requestOptions?.enableCrossPartition == true) {
        request.setHeader(IS_ENABLE_CROSS_PARTITION_HEADER, TRUE);
    }
    if (requestOptions?.isUpsertRequest == true) {
        request.setHeader(IS_UPSERT_HEADER, TRUE);
    }
}

# Set the optional headers to the HTTP GET request.
#
# + headerMap - A map of type string.
# + requestOptions - Record of type Options containing the values for optional headers
# + return - A map of strings.
isolated function setOptionalGetHeaders(map<string> headerMap, Options? requestOptions) returns map<string> {
    if (requestOptions?.indexingDirective is IndexingDirective) {
        headerMap[INDEXING_DIRECTIVE_HEADER] =  <string>requestOptions?.indexingDirective;
    }
    if (requestOptions?.consistancyLevel is ConsistencyLevel) {
        headerMap[CONSISTANCY_LEVEL_HEADER] =  <string>requestOptions?.consistancyLevel;
    }
    if (requestOptions?.sessionToken is string) {
        headerMap[SESSION_TOKEN_HEADER] =  <string>requestOptions?.sessionToken;
    }
    if (requestOptions?.changeFeedOption is ChangeFeedOption) {
        headerMap[A_IM_HEADER] =  <string>requestOptions?.changeFeedOption;
    }
    if (requestOptions?.partitionKeyRangeId is string) {
        headerMap[PARTITIONKEY_RANGE_HEADER] =  <string>requestOptions?.partitionKeyRangeId;
    }
    if (requestOptions?.enableCrossPartition == true) {
        headerMap[IS_ENABLE_CROSS_PARTITION_HEADER] = TRUE;
    }
    if (requestOptions?.isUpsertRequest == true) {
        headerMap[IS_UPSERT_HEADER] = TRUE;
    }
    return headerMap;
}

# Set the optional header specifying Time To Live for token.
#
# + request - The http:Request to set the header
# + validityPeriodInSeconds - An integer specifying the Time To Live value for a permission token
# + return - If successful, request will be appended with headers. Else returns `Error`.
isolated function setExpiryHeader(http:Request request, int validityPeriodInSeconds) returns Error? {
    if (validityPeriodInSeconds >= MIN_TIME_TO_LIVE_IN_SECONDS && validityPeriodInSeconds 
        <= MAX_TIME_TO_LIVE_IN_SECONDS) {
        request.setHeader(EXPIRY_HEADER, validityPeriodInSeconds.toString());
    } else {
        return error InputValidationError(VALIDITY_PERIOD_ERROR);
    }
}

# Get the current time(GMT) in the specific format.
#
# + return - If successful, returns `string` representing UTC date and time 
#            (in `HTTP-date` format as defined by RFC 1123 Date/Time Formats). Else returns `Error`.
isolated function getDateTime() returns string|Error {
    [int, decimal] & readonly currentTime = time:utcNow(); 
    string time = check utcToString(currentTime, TIME_ZONE_FORMAT);
    return check utcToString(currentTime, TIME_ZONE_FORMAT) + " GMT";
}

isolated function utcToString(time:Utc utc, string pattern) returns string|error {
    [int, decimal][epochSeconds, lastSecondFraction] = utc;
    int nanoAdjustments = <int>(lastSecondFraction * 1000000000);
    var instant = ofEpochSecond(epochSeconds, nanoAdjustments);
    var zoneId = getZoneId(java:fromString("Z"));
    var zonedDateTime = atZone(instant, zoneId);
    var dateTimeFormatter = ofPattern(java:fromString(pattern));
    handle formatString = format(zonedDateTime, dateTimeFormatter);
    return formatString.toBalString();
}

# To construct the hashed token signature for a token to set 'Authorization' header.
# 
# + verb - HTTP verb, such as GET, POST, or PUT
# + resourceType - Identifies the type of resource that the request is for, Eg. `dbs`, `colls`, `docs`
# + resourceId - Identity property of the resource that the request is directed at
# + token - master or resource token
# + tokenType - denotes the type of token: master or resource
# + date - current GMT date and time
# + return - If successful, returns `string` which is the hashed token signature. Else returns `Error`.
isolated function generatePrimaryKeySignature(string verb, string resourceType, string resourceId, string token, 
                                              string tokenType, string date) returns string|Error {
    string payload = string `${verb.toLowerAscii()}${NEW_LINE}${resourceType.toLowerAscii()}${NEW_LINE}${resourceId}`
        + string `${NEW_LINE}${date.toLowerAscii()}${NEW_LINE}${EMPTY_STRING}${NEW_LINE}`;
    byte[] decodedArray = check array:fromBase64(token); 
    byte[] digest = check crypto:hmacSha256(payload.toBytes(), decodedArray);
    string signature = digest.toBase64();
    string authorizationString = string `type=${tokenType}&ver=${TOKEN_VERSION}&sig=${signature}`;
    return check url:encode(authorizationString, "UTF-8");
}

# Handle success or error responses to requests and extract the JSON payload.
#
# + httpResponse - The http:Response returned from an HTTP request
# + return - If successful, returns `json`. Else returns `Error`. 
isolated function handleResponse(http:Response httpResponse) returns @tainted json|Error {
    json jsonResponse = check httpResponse.getJsonPayload();
    if (httpResponse.statusCode is http:STATUS_OK|http:STATUS_CREATED) {
        return jsonResponse;
    }
    string message = let var msg = jsonResponse.message in msg is string ? msg : REST_API_INVOKING_ERROR;
    return error DbOperationError(message, status = httpResponse.statusCode);
}

# Handle success or error responses to requests which does not need to return a payload.
# 
# + httpResponse - The http:Response returned from an HTTP request
# + return - If successful, returns `nil`. Else returns `Error`. 
isolated function handleHeaderOnlyResponse(http:Response httpResponse) returns @tainted Error? {
    if (httpResponse.statusCode is http:STATUS_OK|http:STATUS_NO_CONTENT) {
        //If status is 200 the resource is replaced, 201 resource is created, request is successful returns true. 
        // Else Returns error.
        return;
    } else {
        json jsonResponse = check httpResponse.getJsonPayload();
        string message = let var msg = jsonResponse.message in msg is string ? msg : REST_API_INVOKING_ERROR;
        return error DbOperationError(message, status = httpResponse.statusCode);
    }
}

// This is the older version of the stram implementation
// # Get a stream of JSON documents which is returned as query results.
// # 
// # + azureCosmosClient - Client which calls the azure endpoint
// # + path - Path to which API call is made
// # + request - HTTP request object 
// # + return - A `stream<json> or stream<Document>`. Else returns `Error`
// isolated function getQueryResults(http:Client azureCosmosClient, string path, http:Request request) returns 
//                                   @tainted stream<json>|stream<Document>|Error {
//     http:Response response = <http:Response> check azureCosmosClient->post(path, request);
//     json payload = check handleResponse(response);
//     string newContinuationHeader = let var header = 
//         response.getHeader(CONTINUATION_HEADER) in header is string ? header : EMPTY_STRING;

//     if (payload.Documents is json) {
//         Document[] documents = [];
//         json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
//         convertToDocumentArray(documents, array);
//         return (<@untainted>documents).toStream();
//     } else if (payload.Offers is json) {
//         json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
//         return array.toStream();
//     } else {
//         return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//     }
// }

// # Make a request call to the azure endpoint to get a list of resources.
// # 
// # + azureCosmosClient - The http:Client object which is used to call azure endpoints
// # + path - Path to which API call is made
// # + headerMap - The map of strings which contain the headers necessary for the call
// # + array - Initial recory array which will be filled in every request call
// # + continuationHeader - The continuation header which is use to obtain next pages
// # + return - A `stream<record{}>` if successful. Else returns`Error`.
// isolated function retrieveStream(http:Client azureCosmosClient, string path, map<string> headerMap, 
//                                  @tainted record{}[] array, @tainted string? continuationHeader = ()) returns 
//                                  @tainted stream<record{}>|Error {
//     if (continuationHeader is string && continuationHeader != EMPTY_STRING) {
//         headerMap[CONTINUATION_HEADER] = continuationHeader;
//     }

//     http:Response response = check azureCosmosClient->get(path, headerMap);
//     string newContinuationHeader = let var header = 
//         response.getHeader(CONTINUATION_HEADER) in header is string ? header : EMPTY_STRING;

//     json payload = check handleResponse(response);
//     return check createStream(azureCosmosClient, path, headerMap, payload, array, newContinuationHeader);
// }

// # Create a stream from the array obtained from the request call.
// # 
// # + azureCosmosClient - The http:Client object which is used to call azure endpoints
// # + path - Path to which API call is made
// # + headerMap - The map of strings which contain the headers necessary for the call
// # + payload - JSON payload returned from the response
// # + initalArray - Initial recory array which will be filled in every request call
// # + continuationHeader - The continuation header which is use to obtain next pages
// # + return - A `<record{}>` if successful. Else returns `Error`
// isolated function createStream(http:Client azureCosmosClient, string path, map<string> headerMap, json payload, 
//                                record{}[] initalArray, @tainted string? continuationHeader = ()) returns 
//                                @tainted stream<record{}>|Error {
//     var arrayType = typeof initalArray;
//     record{}[] finalArray = initalArray;

//     if (arrayType is typedesc<Offer[]>) {
//         if (payload.Offers is json) {
//             json[] array = let var load = payload.Offers in load is json ? <json[]>load : [];
//             convertToOfferArray(<Offer[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<Document[]>) {
//         if (payload.Documents is json) {
//             json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
//             convertToDocumentArray(<Document[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<Database[]>) {
//         if (payload.Databases is json) {
//             json[] array = let var load = payload.Databases in load is json ? <json[]>load : [];
//             convertToDatabaseArray(<Database[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<Container[]>) {
//         if (payload.DocumentCollections is json) {
//             json[] array = let var load = payload.DocumentCollections in load is json ? <json[]>load : [];
//             convertToContainerArray(<Container[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<StoredProcedure[]>) {
//         if (payload.StoredProcedures is json) {
//             json[] array = let var load = payload.StoredProcedures in load is json ? <json[]>load : [];
//             convertToStoredProcedureArray(<StoredProcedure[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }     
//     } else if (arrayType is typedesc<UserDefinedFunction[]>) {
//         if (payload.UserDefinedFunctions is json) {
//             json[] array = let var load = payload.UserDefinedFunctions in load is json ? <json[]>load : [];
//             convertsToUserDefinedFunctionArray(<UserDefinedFunction[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<Trigger[]>) {
//         if (payload.Triggers is json) {
//             json[] array = let var load = payload.Triggers in load is json ? <json[]>load : [];
//             convertToTriggerArray(<Trigger[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<User[]>) {
//         if (payload.Users is json) {
//             json[] array = let var load = payload.Users in load is json ? <json[]>load : [];
//             convertToUserArray(<User[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<Permission[]>) {
//         if (payload.Permissions is json) {
//             json[] array = let var load = payload.Permissions in load is json ? <json[]>load : [];
//             convertToPermissionArray(<Permission[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else if (arrayType is typedesc<PartitionKeyRange[]>) {
//         if (payload.PartitionKeyRanges is json) {
//             json[] array = let var load = payload.PartitionKeyRanges in load is json ? <json[]>load : [];
//             convertToPartitionKeyRangeArray(<PartitionKeyRange[]>initalArray, array);
//         } else {
//             return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
//         }
//     } else {
//         return error PayloadValidationError(INVALID_RECORD_TYPE_ERROR);
//     }

//     stream<record{}> newStream = (<@untainted>finalArray).toStream();
//     if (continuationHeader != EMPTY_STRING) {
//         newStream = check retrieveStream(azureCosmosClient, path, headerMap, <@untainted>finalArray, continuationHeader);
//     }
//     return newStream;
// }

# Get the enum value for a given string which represents the type of index.
#
# + kind - The index type
# + return - An enum value of `IndexType`
isolated function getIndexType(string kind) returns IndexType {
    match kind {
        "Range" => {
            return RANGE;
        }
        "Spatial" => {
            return SPATIAL;
        }
    }
    return HASH;
}

# Get the enum value for a given string which represents the indexing mode of index.
#
# + mode - The indexing mode of container
# + return - An enum value of `IndexingMode` 
isolated function getIndexingMode(string mode) returns IndexingMode {
    match mode {
        "consistent" => {
            return CONSISTENT;
        }
    }
    return NONE;
}

# Get the enum value for a given string which represents the data type index is applied to.
#
# + dataType - The string representing the data type index have applied to
# + return - An enum value of `IndexDataType` 
isolated function getIndexDataType(string dataType) returns IndexDataType {
    match dataType {
        "Number" => {
            return NUMBER;
        }
        "Point" => {
            return POINT;
        }
        "Polygon" => {
            return POLYGON;
        }
        "LineString" => {
            return LINESTRING;
        }
    }
    return STRING;
}

# Get the enum value for a given string which represent the operation a trigger is applied to.
#
# + triggerOperation - The string representing the operation which is capable of firing the trigger
# + return - An enum value of `TriggerOperation` 
isolated function getTriggerOperation(string triggerOperation) returns TriggerOperation {
    match triggerOperation {
        "Create" => {
            return CREATE;
        }
        "Replace" => {
            return REPLACE;
        }
        "Delete" => {
            return DELETE;
        }
    }
    return ALL;
}

# Get the enum value for a given string which represent when the trigger is fired.
#
# + triggerType - The string representing when the trigger will be fired
# + return - An enum value of `TriggerType`
isolated function getTriggerType(string triggerType) returns TriggerType {
    match triggerType {
        "Post" => {
            return POST;
        }
    }
    return PRE;
}

# Get the enum value for a given string which represent the access rights for the specific permission.
#
# + permissionMode - The string representing the permisssionMode
# + return - An enum value of `PermisssionMode`
isolated function getPermisssionMode(string permissionMode) returns PermisssionMode {
    match permissionMode {
        "Read" => {
            return READ_PERMISSION;
        }
    }
    return ALL_PERMISSION;
}

# Get the enum value for a given string which represent the offer version of a specific offer.
#
# + offerVersion - The string representing the offer version
# + return - An enum value of `PermisssionMode`
isolated function getOfferVersion(string offerVersion) returns OfferVersion {
    match offerVersion {
        "V1" => {
            return PRE_DEFINED;
        }
    }
    return USER_DEFINED;
}

# Get the enum value for a given string which represent the offer type of a specific offer.
#
# + offerType - The string representing the offer type
# + return - An enum value of `OfferType`
isolated function getOfferType(string offerType) returns OfferType {
    match offerType {
        "S1" => {
            return LEVEL_S1;
        }
        "S2" => {
            return LEVEL_S2;
        }
        "S3" => {
            return LEVEL_S3;
        }
    }
    return INVALID;
}

# Get the const value for a given integer which represent the version of a specific partition key.
#
# + partitionKeyVersion - An integer representing the version of partition key
# + return - An const value of `PartitionKeyVersion`
isolated function getPartitionKeyVersion(int partitionKeyVersion) returns PartitionKeyVersion {
    match partitionKeyVersion {
        1 => {
            return PARTITION_KEY_VERSION_2;
        }
    }
    return PARTITION_KEY_VERSION_1;
}
