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

import ballerina/http;

// This stream implementer works for GET requests
class DatabaseStream {
    private Database[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchDatabases();
    }

    public isolated function next() returns @tainted record {| Database value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Database value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchDatabases();
            record {| Database value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchDatabases() returns @tainted Database[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Databases is json) {
            json[] array = let var load = payload.Databases in load is json ? <json[]>load : [];
            return convertToDatabaseArray(array);

        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class ContainerStream {
    private Container[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchContainers();
    }

    public isolated function next() returns @tainted record {| Container value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Container value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchContainers();
            record {| Container value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchContainers() returns @tainted Container[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);

        if (payload.DocumentCollections is json) {
            json[] array = let var load = payload.DocumentCollections in load is json ? <json[]>load : [];
            return convertToContainerArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class DocumentStream {
    private Document[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchDocuments();
    }

    public isolated function next() returns @tainted record {| Document value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Document value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchDocuments();
            record {| Document value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchDocuments() returns @tainted Document[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Documents is json) {
            json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
            return convertToDocumentArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class StoredProcedureStream {
    private StoredProcedure[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchStoredProcedures();
    }

    public isolated function next() returns @tainted record {| StoredProcedure value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| StoredProcedure value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchStoredProcedures();
            record {| StoredProcedure value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchStoredProcedures() returns @tainted StoredProcedure[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.StoredProcedures is json) {
            json[] array = let var load = payload.StoredProcedures in load is json ? <json[]>load : [];
            return convertToStoredProcedureArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class UserDefiinedFunctionStream {
    private UserDefinedFunction[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchUserDefinedFunctions();
    }

    public isolated function next() returns @tainted record {| UserDefinedFunction value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| UserDefinedFunction value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchUserDefinedFunctions();
            record {| UserDefinedFunction value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchUserDefinedFunctions() returns @tainted UserDefinedFunction[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);

        if (payload.UserDefinedFunctions is json) {
            json[] array = let var load = payload.UserDefinedFunctions in load is json ? <json[]>load : [];
            return convertsToUserDefinedFunctionArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class TriggerStream {
    private Trigger[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchTriggers();
    }

    public isolated function next() returns @tainted record {| Trigger value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Trigger value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchTriggers();
            record {| Trigger value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchTriggers() returns @tainted Trigger[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);

        if (payload.Triggers is json) {
            json[] array = let var load = payload.Triggers in load is json ? <json[]>load : [];
            return convertToTriggerArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class UserStream {
    private User[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchUsers();
    }

    public isolated function next() returns @tainted record {| User value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| User value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchUsers();
            record {| User value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchUsers() returns @tainted User[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);

        if (payload.Users is json) {
            json[] array = let var load = payload.Users in load is json ? <json[]>load : [];
            return convertToUserArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}


class PermissionStream {
    private Permission[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchPermission();
    }

    public isolated function next() returns @tainted record {| Permission value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Permission value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchPermission();
            record {| Permission value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchPermission() returns @tainted Permission[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);

        if (payload.Permissions is json) {
            json[] array = let var load = payload.Permissions in load is json ? <json[]>load : [];
            return convertToPermissionArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class OfferStream {
    private Offer[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchOffers();
    }

    public isolated function next() returns @tainted record {| Offer value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Offer value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchOffers();
            record {| Offer value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchOffers() returns @tainted Offer[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Offers is json) {
            json[] array = let var load = payload.Offers in load is json ? <json[]>load : [];
            return convertToOfferArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class PartitionKeyRangeStream {
    private PartitionKeyRange[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private map<string> headerMap;

    isolated function  init(http:Client httpClient, string path, map<string> headerMap) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.headerMap = headerMap;
        self.currentEntries = check self.fetchPKRanges();
    }

    public isolated function next() returns @tainted record {| PartitionKeyRange value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| PartitionKeyRange value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchPKRanges();
            record {| PartitionKeyRange value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchPKRanges() returns @tainted PartitionKeyRange[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.headerMap[CONTINUATION_HEADER] = self.continuationToken;
        }
        http:Response response = check self.httpClient->get(self.path, self.headerMap);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.PartitionKeyRanges is json) {
            json[] array = let var load = payload.PartitionKeyRanges in load is json ? <json[]>load : [];
            return convertToPartitionKeyRangeArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

// This stream implementer works for POST requests
class DocumentQueryResultStream {
    private Document[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    http:Request request;

    isolated function  init(http:Client httpClient, string path, http:Request request) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.request = request;
        self.currentEntries = check self.fetchQueryResults();
    }

    public isolated function next() returns @tainted record {| Document value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Document value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchQueryResults();
            record {| Document value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchQueryResults() returns @tainted Document[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.request.setHeader(CONTINUATION_HEADER, self.continuationToken);
        }
        http:Response response = check self.httpClient->post(self.path, self.request);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Documents is json) {
            json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
            return convertToDocumentArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class OfferQueryResultStream {
    private Offer[] currentEntries = [];
    private string continuationToken;
    int index = 0;
    private final http:Client httpClient;
    private final string path;
    http:Request request;

    isolated function  init(http:Client httpClient, string path, http:Request request) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.continuationToken = EMPTY_STRING;
        self.request = request;
        self.currentEntries = check self.fetchOfferQueryResults();
    }

    public isolated function next() returns @tainted record {| Offer value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Offer value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
        // This code block is for retrieving the next batch of records when the initial batch is finished.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            self.currentEntries = check self.fetchOfferQueryResults();
            record {| Offer value; |} singleRecord = {value: self.currentEntries[self.index]};
            self.index += 1;
            return singleRecord;
        }
    }

    isolated function fetchOfferQueryResults() returns @tainted Offer[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.request.setHeader(CONTINUATION_HEADER, self.continuationToken);
        }
        http:Response response = check self.httpClient->post(self.path, self.request);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header :
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Offers is json) {
            json[] array = let var load = payload.Offers in load is json ? <json[]>load : [];
            return convertToOfferArray(array);
        } else {
            return error PayloadValidationError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

# Convert JSON array of database information in to an array of type `Database`.
# 
# + sourceDatabaseArrayJsonObject - JSON object which contain the array of database information
# + return - An array of type `Database`
isolated function convertToDatabaseArray(json[] sourceDatabaseArrayJsonObject) returns Database[] {
    Database[] databases = [];
    foreach json databaseObject in sourceDatabaseArrayJsonObject {
        Database database = mapJsonToDatabaseType(databaseObject);
        databases.push(database);
    }
    return databases;
}

# Convert JSON array of container information in to an array of type `Container`.
# 
# + sourceContainerArrayJsonObject - JSON object which contain the array of container information
# + return - An array of type `Container`
isolated function convertToContainerArray(json[] sourceContainerArrayJsonObject) returns Container[] {
    Container[] containers = [];
    foreach json jsonCollection in sourceContainerArrayJsonObject {
        Container container = mapJsonToContainerType(jsonCollection);
        containers.push(container);
    }
    return containers;
}

# Convert JSON array of document information in to an array of type `Document`.
# 
# + sourceDocumentArrayJsonObject - JSON object which contain the array of document information
# + return - An array of type `Document`
isolated function convertToDocumentArray(json[] sourceDocumentArrayJsonObject) returns Document[] {
    Document[] documents = [];
    foreach json documentObject in sourceDocumentArrayJsonObject {
        Document document = mapJsonToDocumentType(documentObject);
        documents.push(document);
    }
    return documents;
}

# Convert JSON array of stored procedure information in to an array of type `StoredProcedure`.
# 
# + sourceStoredProcedureArrayJsonObject - JSON object which contain the array of stored procedure information
# + return - An array of type `StoredProcedure`
isolated function convertToStoredProcedureArray(json[] sourceStoredProcedureArrayJsonObject) returns 
                                                StoredProcedure[] {
    StoredProcedure[] storedProcedures = [];
    foreach json storedProcedureObject in sourceStoredProcedureArrayJsonObject {
        StoredProcedure storedProcedure = mapJsonToStoredProcedure(storedProcedureObject);
        storedProcedures.push(storedProcedure);
    }
    return storedProcedures;
}

# Convert JSON array of user defined function information in to an array of type `UserDefinedFunction`.
# 
# + sourceUdfArrayJsonObject - JSON object which contain the array of user defined function information
# + return - An array of type `UserDefinedFunction`
isolated function convertsToUserDefinedFunctionArray(json[] sourceUdfArrayJsonObject) returns UserDefinedFunction[] {
    UserDefinedFunction[] userDefinedFunctions = [];
    foreach json userDefinedFunctionObject in sourceUdfArrayJsonObject {
        UserDefinedFunction userDefinedFunction = mapJsonToUserDefinedFunction(userDefinedFunctionObject);
        userDefinedFunctions.push(userDefinedFunction);
    }
    return userDefinedFunctions;
}

# Convert JSON array of trigger information in to an array of type `Trigger`.
# 
# + sourceTriggerArrayJsonObject - JSON object which contain the array of trigger information
# + return - An array of type `Trigger`
isolated function convertToTriggerArray(json[] sourceTriggerArrayJsonObject) returns Trigger[] {
    Trigger[] triggers = [];
    foreach json triggerObject in sourceTriggerArrayJsonObject {
        Trigger trigger = mapJsonToTrigger(triggerObject);
        triggers.push(trigger);
    }
    return triggers;
}

# Convert JSON array of user information in to an array of type `User`.
# 
# + sourceUserArrayJsonObject - JSON object which contain the array of user information
# + return - An array of type `User`
isolated function convertToUserArray(json[] sourceUserArrayJsonObject) returns User[] {
    User[] users = [];
    foreach json userObject in sourceUserArrayJsonObject {
        User user = mapJsonToUserType(userObject);
        users.push(user);
    }
    return users;
}

# Convert JSON array of permission information in to an array of type `Permission`.
# 
# + sourcePermissionArrayJsonObject - JSON object which contain the array of permission information
# + return - An array of type `Permission`
isolated function convertToPermissionArray(json[] sourcePermissionArrayJsonObject) returns Permission[] {
    Permission[] permissions = [];
    foreach json permissionObject in sourcePermissionArrayJsonObject {
        Permission permission = mapJsonToPermissionType(permissionObject);
        permissions.push(permission);
    }
    return permissions;
}

# Convert JSON array of offer infromation in to an array of type `Offer`.
# 
# + sourceOfferArrayJsonObject - JSON object which contain the array of offer information
# + return - An array of type `Offer`
isolated function convertToOfferArray(json[] sourceOfferArrayJsonObject) returns Offer[] {
    Offer[] offers = [];
    foreach json offerObject in sourceOfferArrayJsonObject {
        Offer offer = mapJsonToOfferType(offerObject);
        offers.push(offer);
    }
    return offers;
}

# Convert JSON array of partition key ranges in to an array of type `PartitionKeyRange`.
# 
# + sourcePrtitionKeyArrayJsonObject - JSON object which contain the array of partition key range information
# + return - An array of type `PartitionKeyRange`
isolated function convertToPartitionKeyRangeArray(json[] sourcePrtitionKeyArrayJsonObject) returns 
                                                  PartitionKeyRange[] {
    PartitionKeyRange[] partitionKeyRangesArray = [];
    foreach json jsonPartitionKey in sourcePrtitionKeyArrayJsonObject {
        PartitionKeyRange value = {
            id: let var id = jsonPartitionKey.id in id is string ? id : EMPTY_STRING,
            minInclusive: let var min = jsonPartitionKey.minInclusive in min is string ? min : EMPTY_STRING,
            maxExclusive: let var max = jsonPartitionKey.maxExclusive in max is string ? max : EMPTY_STRING
        };
        partitionKeyRangesArray.push(value);
    }
    return partitionKeyRangesArray;
}
