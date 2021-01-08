// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/java;

// # Extract the resource type related to cosmos db from a given url
// #
// # + url - the URL from which we want to extract resource type
// # + return - string representing the resource type
isolated function getResourceType(string url) returns string {
    string resourceType = EMPTY_STRING;
    string[] urlParts = stringutils:split(url, FORWARD_SLASH);
    int count = urlParts.length()-1;
    if (count % 2 != 0) {
        resourceType = urlParts[count];
        if (count > 1) {
            int? lastIndex = str:lastIndexOf(url, FORWARD_SLASH);
        }
    } else {
        resourceType = urlParts[count-1];
    }
    return resourceType;
}

// # Extract the resource type related to cosmos db from a given url
// #
// # + url - the URL from which we want to extract resource type
// # + return - string representing the resource id
isolated function getResourceId(string url) returns string {
    string resourceId = EMPTY_STRING;
    string[] urlParts = stringutils:split(url, FORWARD_SLASH);
    int count = urlParts.length()-1;
    string resourceType = getResourceType(url);
    if (resourceType == RESOURCE_TYPE_OFFERS) {
        if (count % 2 != 0) {
            resourceId = EMPTY_STRING;
        } else {
            int? lastIndex = str:lastIndexOf(url, FORWARD_SLASH);
            if (lastIndex is int) {
                resourceId = str:substring(url, lastIndex+1);
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

// # Extract the host of the cosmos db from the base url.
// #
// # + url - the Base URL given by the user from which we want to extract host.
// # + return - string representing the resource id.
isolated function getHost(string url) returns string {
    string replaced = stringutils:replaceFirst(url, HTTPS_REGEX, EMPTY_STRING);  
    int? lastIndex = str:lastIndexOf(replaced, FORWARD_SLASH);
    if (lastIndex is int) {
        replaced = replaced.substring(0,lastIndex);    
    }
    return replaced;
}

// # Prepare the url out of a given string array 
// #
// # + paths - array of strings with path of the url
// # + return - string representing the complete url
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

isolated function prepareError(string message, error? err = ()) returns error { 
    error azureError;
    if (err is error) {
        azureError = AzureError(message, err);
    } else {
        azureError = AzureError(message);
    }
    return azureError;
}

// # Maps the parameters which are needed for the creation of authorization signature to HeaderParameters type.
// #
// # + httpVerb - HTTP verb of the relevent request.
// # + url - The endpoint to which the request call is made.
// # + return - An instance of record type HeaderParameters.
isolated function mapParametersToHeaderType(string httpVerb, string url) returns HeaderParameters {
    HeaderParameters params = {};
    params.verb = httpVerb;
    params.resourceType = getResourceType(url);
    params.resourceId = getResourceId(url);
    return params;
}

// # Attach mandatory basic headers to call a REST endpoint.
// # 
// # + request - http:Request to add headers to
// # + host - the host to which the request is sent
// # + keyToken - master or resource token
// # + tokenType - denotes the type of token: master or resource.
// # + tokenVersion - denotes the version of the token, currently 1.0.
// # + httpVerb - The HTTP verb of the request the headers are set to.
// # + requestPath - Request path of the request.
// # + return - If successful, returns same http:Request with newly appended headers. Else returns error.
isolated function setMandatoryHeaders(http:Request request, string host, string keyToken, string tokenType, string tokenVersion, 
                    string httpVerb, string requestPath) returns http:Request | error {
    HeaderParameters params = mapParametersToHeaderType(httpVerb, requestPath);
    request.setHeader(API_VERSION_HEADER, params.apiVersion);
    request.setHeader(HOST_HEADER, host);
    request.setHeader(ACCEPT_HEADER, ACCEPT_ALL);
    request.setHeader(CONNECTION_HEADER, CONNECTION_KEEP_ALIVE);
    string? | error date = getTime();
    if (date is string) {
        request.setHeader(DATE_HEADER, date);
        string? signature = ();
        if (tokenType.toLowerAscii() == TOKEN_TYPE_MASTER) {
            signature = check generateMasterTokenSignature(params.verb, params.resourceType, params.resourceId, keyToken, 
            tokenType, tokenVersion, date);
        } else if (tokenType.toLowerAscii() == TOKEN_TYPE_RESOURCE) {
            signature = check encoding:encodeUriComponent(keyToken, UTF8_URL_ENCODING); 
        } else {
            return prepareError(NULL_RESOURCE_TYPE_ERROR);
        }
        if (signature is string) {
            request.setHeader(AUTHORIZATION_HEADER, signature);
        } else {
            return prepareError(NULL_AUTHORIZATION_SIGNATURE_ERROR);
        }
    } else {
        return prepareError(NULL_DATE_ERROR);
    }
    return request;
}

isolated function createRequest((DocumentCreateOptions|DocumentGetOptions|DocumentListOptions|ResourceReadOptions|ResourceQueryOptions|
                        ResourceDeleteOptions)? requestOptions) returns http:Request|error {
    http:Request request = new;
    if (requestOptions != ()) {
        request = check setRequestOptions(request, requestOptions);
    }
    return request;
}

// # Set the optional header related to throughput options.
// # 
// # + request - http:Request to set the header
// # + throughputOption - Optional. Throughput parameter of type int or json.
// # + return - If successful, returns same http:Request with newly appended headers. Else returns error.
isolated function setThroughputOrAutopilotHeader(http:Request request, (int|json)? throughputOption = ()) returns 
                    http:Request | error {
    if (throughputOption is int) {
        if (throughputOption >= MIN_REQUEST_UNITS) {
            request.setHeader(THROUGHPUT_HEADER, throughputOption.toString());
        } else {
            return prepareError(MINIMUM_MANUAL_THROUGHPUT_ERROR);
        }
    } else if (throughputOption != ()) {
        request.setHeader(AUTOPILET_THROUGHPUT_HEADER, throughputOption.toString());
    }
    return request;
}

// # Set the optional header related to partitionkey value.
// # 
// # + request - http:Request to set the header
// # + partitionKey - the array containing the value of the partition key
// # + return - If successful, returns same http:Request with newly appended headers. Else returns error.
isolated function setPartitionKeyHeader(http:Request request, any[]? partitionKey) returns http:Request | error {
    if (partitionKey is ()) {
        return request;
    }
    request.setHeader(PARTITION_KEY_HEADER, string `${partitionKey.toString()}`);
    return request;
}

// # Set the required headers related to query operations.
// # 
// # + request - http:Request to set the header
// # + return - If successful, returns same http:Request with newly appended headers. Else returns error.
isolated function setHeadersForQuery(http:Request request) returns http:Request | error {
    var header = request.setContentType(CONTENT_TYPE_QUERY);
    request.setHeader(ISQUERY_HEADER, true.toString());
    return request;
}

// # Set the optional headers to the HTTP request.
// # 
// # + request - http:Request to set the header
// # + requestOptions - object of type RequestHeaderOptions containing the values for optional headers
// # + return - If successful, returns same http:Request with newly appended headers. Else returns error.
isolated function setRequestOptions(http:Request request, (DocumentCreateOptions|DocumentGetOptions|DocumentListOptions|
                    ResourceReadOptions|ResourceQueryOptions|ResourceDeleteOptions)? requestOptions) returns http:Request | error {
    if (requestOptions?.indexingDirective != ()) {
        if (requestOptions?.indexingDirective == INDEXING_TYPE_INCLUDE || requestOptions?.indexingDirective == INDEXING_TYPE_EXCLUDE) {
            request.setHeader(INDEXING_DIRECTIVE_HEADER, requestOptions?.indexingDirective.toString());
        } else {
            return prepareError(INDEXING_DIRECTIVE_ERROR);
        }
    }
    if (requestOptions?.isUpsertRequest == true) {
        request.setHeader(IS_UPSERT_HEADER, requestOptions?.isUpsertRequest.toString());
    }
    if (requestOptions?.consistancyLevel != ()) {
        if (requestOptions?.consistancyLevel == CONSISTANCY_LEVEL_STRONG || requestOptions?.consistancyLevel == 
        CONSISTANCY_LEVEL_BOUNDED ||  requestOptions?.consistancyLevel == CONSISTANCY_LEVEL_SESSION ||  
        requestOptions?.consistancyLevel == CONSISTANCY_LEVEL_EVENTUAL) {
            request.setHeader(CONSISTANCY_LEVEL_HEADER, requestOptions?.consistancyLevel.toString());
        } else {
            return prepareError(CONSISTANCY_LEVEL_ERROR);
        }
    }
    if (requestOptions?.sessionToken != ()) {
        request.setHeader(SESSION_TOKEN_HEADER, requestOptions?.sessionToken.toString());
    }
    if (requestOptions?.changeFeedOption != ()) {
        request.setHeader(A_IM_HEADER, requestOptions?.changeFeedOption.toString()); 
    }
    if (requestOptions?.ifNoneMatchEtag != ()) {
        request.setHeader(NON_MATCH_HEADER, requestOptions?.ifNoneMatchEtag.toString());
    }
    if (requestOptions?.partitionKeyRangeId != ()) {
        request.setHeader(PARTITIONKEY_RANGE_HEADER, requestOptions?.partitionKeyRangeId.toString());
    }
    if (requestOptions?.ifMatchEtag != ()) {
        request.setHeader(IF_MATCH_HEADER, requestOptions?.ifMatchEtag.toString());
    }
    if (requestOptions?.enableCrossPartition == true) {
        request.setHeader(IS_ENABLE_CROSS_PARTITION_HEADER, requestOptions?.enableCrossPartition.toString());
    }
    return request;
}

// # Set the optional header specifying time to live.
// # 
// # + request - http:Request to set the header
// # + validationPeriod - the integer specifying the time to live value for a permission token
// # + return - If successful, returns same http:Request with newly appended headers. Else returns error.
isolated function setExpiryHeader(http:Request request, int validationPeriod) returns http:Request | error {
    if (validationPeriod >= MIN_TIME_TO_LIVE && validationPeriod <= MAX_TIME_TO_LIVE) {
        request.setHeader(EXPIRY_HEADER, validationPeriod.toString());
        return request;
    } else {
        return prepareError(VALIDITY_PERIOD_ERROR);
    }
}

// # Get the current time in the specific format.
// # 
// # + return - If successful, returns string representing UTC date and time 
// #               (in "HTTP-date" format as defined by RFC 7231 Date/Time Formats). Else returns error.
isolated function getTime() returns string? | error {
    time:Time time1 = time:currentTime();
    var timeWithZone = check time:toTimeZone(time1, GMT_ZONE);
    string | error timeString = time:format(timeWithZone, TIME_ZONE_FORMAT);
    if (timeString is string) {
        return timeString;
    } else {
        return prepareError(TIME_STRING_ERROR);
    }
}

// # To construct the hashed token signature for a token to set  'Authorization' header.
// # 
// # + verb - HTTP verb, such as GET, POST, or PUT
// # + resourceType - identifies the type of resource that the request is for, Eg. "dbs", "colls", "docs"
// # + resourceId -dentity property of the resource that the request is directed at
// # + keyToken - master or resource token
// # + tokenType - denotes the type of token: master or resource.
// # + tokenVersion - denotes the version of the token, currently 1.0.
// # + date - current GMT date and time
// # + return - If successful, returns string which is the  hashed token signature. Else returns () or error. 
isolated function generateMasterTokenSignature(string verb, string resourceType, string resourceId, string keyToken, 
                    string tokenType, string tokenVersion, string date) returns string? | error {    
    string authorization;
    string payload = verb.toLowerAscii() + NEW_LINE + resourceType.toLowerAscii() + NEW_LINE + resourceId + NEW_LINE
                        + date.toLowerAscii() + NEW_LINE + EMPTY_STRING + NEW_LINE;
    var decoded = array:fromBase64(keyToken);
    if (decoded is byte[]) {
        byte[] digest = crypto:hmacSha256(payload.toBytes(), decoded);
        string signature = array:toBase64(digest);
        authorization = 
        check encoding:encodeUriComponent(string `type=${tokenType}&ver=${tokenVersion}&sig=${signature}`, "UTF-8");   
        return authorization;
    } else {   
        return prepareError(DECODING_ERROR);
    }
}

// # Map the json payload and necessary header values returend from a response to a tuple.
// # 
// # + httpResponse - the http:Response or http:ClientError returned form the HTTP request
// # + return - returns a tuple of type [json, ResponseMetadata] if sucessful else, returns error
isolated function mapResponseToTuple(http:Response|http:PayloadType|error httpResponse) returns @tainted [json, ResponseMetadata] | error {
    json responseBody = check handleResponse(httpResponse);
    ResponseMetadata responseHeaders = check mapResponseHeadersToHeadersObject(httpResponse);
    return [responseBody, responseHeaders];
}

// # Handle sucess or error reponses to requests and extract the json payload.
// # 
// # + httpResponse - http:Response or http:ClientError returned from an http:Request
// # + return - If successful, returns json. Else returns error. 
isolated function handleResponse(http:Response|http:PayloadType|error httpResponse) returns @tainted json | boolean | error { 
    if (httpResponse is http:Response) {   
        if (httpResponse.statusCode == http:STATUS_OK || httpResponse.statusCode == http:STATUS_CREATED) {
            json|error jsonResponse = httpResponse.getJsonPayload();
            if (jsonResponse is json) {
                return jsonResponse;
            } else {
                return prepareError(JSON_PAYLOAD_ACCESS_ERROR);
            }
        } else if (httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json|error jsonResponse = httpResponse.getJsonPayload();
            if (jsonResponse is json) {
                string message = jsonResponse.message.toString();
                string errorMessage = httpResponse.statusCode.toString() + SPACE_STRING + httpResponse.reasonPhrase; 
                var stoppingIndex = message.indexOf(ACTIVITY_ID);
                if (stoppingIndex is int) {
                    errorMessage += COLON_WITH_SPACE + message.substring(0, stoppingIndex);
                }
                error details = error(errorMessage, status = httpResponse.statusCode);
                return details;
            } else {
                return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR); 
            }
        }
    } else {
        return prepareError(REST_API_INVOKING_ERROR);
    }
}

// # Get the http:Response and extract the headers to the record type ResponseMetadata
// # 
// # + httpResponse - http:Response or http:ClientError returned from an http:Request
// # + return - If successful, returns record type ResponseMetadata. Else returns error. 
isolated function mapResponseHeadersToHeadersObject(http:Response|http:PayloadType|error httpResponse) returns @tainted ResponseMetadata | error {
    ResponseMetadata responseHeaders = {};
    if (httpResponse is http:Response) {
        responseHeaders.continuationHeader = getHeaderIfExist(httpResponse, CONTINUATION_HEADER);
        responseHeaders.sessionToken = getHeaderIfExist(httpResponse, SESSION_TOKEN_HEADER);
        responseHeaders.requestCharge = getHeaderIfExist(httpResponse, REQUEST_CHARGE_HEADER);
        responseHeaders.resourceUsage = getHeaderIfExist(httpResponse, RESOURCE_USAGE_HEADER);
        responseHeaders.etag = getHeaderIfExist(httpResponse, ETAG_HEADER);
        responseHeaders.date = getHeaderIfExist(httpResponse, RESPONSE_DATE_HEADER);
        return responseHeaders;
    } else {
        return prepareError(REST_API_INVOKING_ERROR);
    }
}

// # Convert json string values to boolean.
// # 
// # + value - json value which has reprsents boolean value
// # + return - boolean value of specified json
isolated function convertToBoolean(json | error value) returns boolean { 
    if (value is json) {
        boolean | error result = 'boolean:fromString(value.toString());
        if (result is boolean) {
            return result;
        }
    }
    return false;
}

// # Convert json string values to int
// # 
// # + value - json value which has reprsents int value
// # + return - int value of specified json
isolated function convertToInt(json | error value) returns int {
    if (value is json) {
        int | error result = 'int:fromString(value.toString());
        if (result is int) {
            return result;
        }
    }
    return 0;
}

// # Convert json string values to int
// # 
// # + httpResponse - http:Response returned from an http:RequestheaderName
// # + headerName - name of the header
// # + return - int value of specified json
isolated function getHeaderIfExist(http:Response httpResponse, string headerName) returns @tainted string? {
    if (httpResponse.hasHeader(headerName)) {
        return httpResponse.getHeader(headerName);
    } else {
        return ();
    }
}

function retriveStream(http:Client azureCosmosClient, string path, http:Request request, Offer[] | Document[] | 
        Database[] | Container[] | StoredProcedure[] | UserDefinedFunction[] | Trigger[] | User[] | Permission[] | 
        PartitionKeyRange[] array, int? maxItemCount = (), string? continuationHeader = (), boolean? isQuery = ()) 
        returns @tainted stream<Offer> | stream<Document> | stream<Database> | stream<Container> | stream<StoredProcedure> | 
        stream<UserDefinedFunction> | stream<Trigger> | stream<User> | stream<Permission> | stream<PartitionKeyRange>| error {
    if (continuationHeader is string) {
        request.setHeader(CONTINUATION_HEADER, continuationHeader);
    }
    http:Response|http:PayloadType|error response;
    if (isQuery ==  true) {
        response = azureCosmosClient->post(path, request);
    } else  {
        response = azureCosmosClient->get(path, request);
    }
    var [payload, headers] = check mapResponseToTuple(response);        
    var arrayType = typeof array; 
    if (arrayType is typedesc<Offer[]>) {
        Offer[] offers = <Offer[]>array;
        if (payload.Offers is json) {
            Offer[] finalArray = ConvertToOfferArray(offers, <json[]>payload.Offers);
            stream<Offer> offerStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<Offer>>) {
                    offerStream = <stream<Offer>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof offerStream).toString()}.`); 
                }
            }
            return offerStream;
        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else if (arrayType is typedesc<Document[]>) {
        Document[] documents = <Document[]>array;
        if (payload.Documents is json) {
            Document[] finalArray = convertToDocumentArray(documents, <json[]>payload.Documents);
            stream<Document> documentStream = (<@untainted>finalArray).toStream(); 
            if (headers?.continuationHeader != () && maxItemCount is ()) {  
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<Document>>) {
                    documentStream = <stream<Document>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof documentStream).toString()}.`); 
                }
            }
            return documentStream;
        } else {
            return prepareError(JSON_PAYLOAD_ACCESS_ERROR);
        }
    } else if (arrayType is typedesc<Database[]>) {
        Database[] databases = <Database[]>array;
        if (payload.Databases is json) {
            Database[] finalArray = convertToDatabaseArray(databases, <json[]>payload.Databases);
            stream<Database> databaseStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<Database>>) {
                    databaseStream = <stream<Database>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof databaseStream).toString()}.`); 
                }
            }
            return databaseStream;
        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else if (arrayType is typedesc<Container[]>) {
        Container[] containers = <Container[]>array;
        if (payload.DocumentCollections is json) {
            Container[] finalArray = convertToContainerArray(containers, <json[]>payload.DocumentCollections);
            stream<Container> containerStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<Container>>) {
                    containerStream = <stream<Container>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof containerStream).toString()}.`); 
                }
            }
            return containerStream;
        } else {
            return prepareError(JSON_PAYLOAD_ACCESS_ERROR);
        }
    } else if (arrayType is typedesc<StoredProcedure[]> || arrayType is typedesc<UserDefinedFunction[]>) {
        StoredProcedure[] storedProcedures = <StoredProcedure[]>array;
        UserDefinedFunction[] userDefinedFunctions = <UserDefinedFunction[]>array;
        if (payload.StoredProcedures is json) {
            StoredProcedure[] finalArray = convertToStoredProcedureArray(storedProcedures, <json[]>payload.StoredProcedures);
            stream<StoredProcedure> storedProcedureStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<StoredProcedure>>) {
                    storedProcedureStream = <stream<StoredProcedure>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof storedProcedureStream).toString()}.`); 
                }
            }
            return storedProcedureStream;
        } else if (payload.UserDefinedFunctions is json) {
            UserDefinedFunction[] finalArray = convertsToUserDefinedFunctionArray(userDefinedFunctions, <json[]>payload.UserDefinedFunctions);
            stream<UserDefinedFunction> userDefinedFunctionStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<UserDefinedFunction>>) {
                    userDefinedFunctionStream = <stream<UserDefinedFunction>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof userDefinedFunctionStream).toString()}.`); 
                }
            }
            return userDefinedFunctionStream;
        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else if (arrayType is typedesc<Trigger[]>) {
        Trigger[] triggers = <Trigger[]>array;
        if (payload.Triggers is json) {
            Trigger[] finalArray = convertToTriggerArray(triggers, <json[]>payload.Triggers);
            stream<Trigger> triggerStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<Trigger>>) {
                    triggerStream = <stream<Trigger>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof triggerStream).toString()}.`); 
                }
            }
            return triggerStream;
        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else if (arrayType is typedesc<User[]>) {
        User[] users = <User[]>array;
        if (payload.Users is json) {
            User[] finalArray = convertToUserArray(users, <json[]>payload.Users);
            stream<User> userStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<User>>) {
                    userStream = <stream<User>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof userStream).toString()}.`); 
                }
            }
            return userStream;
        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else if (arrayType is typedesc<Permission[]>) {
        Permission[] permissions = <Permission[]>array;
        if (payload.Permissions is json) {
            Permission[] finalArray = convertToPermissionArray(permissions, <json[]>payload.Permissions);
            stream<Permission> permissionStream = (<@untainted>finalArray).toStream();
            if (headers?.continuationHeader != () && maxItemCount is ()) {            
                var streams = check retriveStream(azureCosmosClient, path, request, finalArray, (), headers?.continuationHeader);
                if (typeof streams is typedesc<stream<Permission>>) {
                    permissionStream = <stream<Permission>>streams;
                } else  {
                    return prepareError(STREAM_IS_NOT_TYPE_ERROR + string `${(typeof permissionStream).toString()}.`); 
                }
            }
            return permissionStream;
        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else if (arrayType is typedesc<PartitionKeyRange[]>) {
        if (payload.PartitionKeyRanges is json) {
            PartitionKeyRange[] finalArray = convertToPartitionKeyRangeArray(<json[]>payload.PartitionKeyRanges);
            stream<PartitionKeyRange> partitionKeyrangesStream = (<@untainted>finalArray).toStream();
            return partitionKeyrangesStream;

        } else {
            return prepareError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    } else {
        return prepareError(INVALID_STREAM_TYPE); 
    }
}

# Create a random UUID removing the unnessary hyphens which will interrupt querying opearations.
# 
# + return - A string UUID withoout hyphens
public function createRandomUUIDBallerina() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string){
        stringUUID = stringutils:replace(stringUUID, "-", "");
        return stringUUID;
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name : "randomUUID", 
    'class : "java.util.UUID"
} external;
