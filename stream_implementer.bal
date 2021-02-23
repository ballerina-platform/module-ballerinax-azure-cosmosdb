import ballerina/http;

class DocumentStream {
    Document[] currentEntries = [];
    int index = 0;
    http:Client httpClient;
    string path;
    http:Request request;
    string continuationToken;
    
    function init(http:Client httpClient, string path, http:Request request) returns @tainted error? {
        self.httpClient = httpClient;
        self.path = path;
        self.request = request;
        self.continuationToken = EMPTY_STRING;
        self.currentEntries = check self.fetchDocuments();
    }

    public isolated function next() returns record {| Document value; |}|error? {
        if(self.index < self.currentEntries.length()) {
            record {| Document value; |} document = {value: self.currentEntries[self.index]};  
            self.index += 1;
            return document;
        }
        // if (self.continuationToken != EMPTY_STRING) {
        //     self.index = 0;
        //     // Fetch documents again when the continuation token is provided. But this function has a remote method call
        //     // So it is not isolated.
        //     self.currentEntries = check self.fetchDocuments(); 
        //     record {| Document value; |} document = {value: self.currentEntries[self.index]};  
        //     self.index += 1;
        //     return document;
        // }
    }

    function fetchDocuments() returns @tainted Document[]|error {
        if (self.continuationToken != EMPTY_STRING) {
            self.request.setHeader(CONTINUATION_HEADER, self.continuationToken);
        }
        http:Response response = <http:Response> check self.httpClient->get(self.path, self.request);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header : 
                EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Documents is json) {
            json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
            return convertToDocumentArray(array);        
        } else {
            return prepareAzureError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}

class DatabaseStream {
    Database[] currentEntries = [];
    int index = 0;
    json payload;

    isolated function init(json payload) {
        self.payload = payload;
    }

    public isolated function next() returns @tainted record {| Database value; |}|error? { 
        if(self.index < self.currentEntries.length()){
            self.currentEntries = check self.fetchDocuments(self.payload);
            record {| Database value; |} database = {value: self.currentEntries[self.index]};
            self.index += 1;
            return database;
        } else {

        }
    }

    isolated function fetchDocuments(json payload) returns @tainted Database[]|error {
        Database[] finalArray = [];
        if (payload.Databases is json) {
            json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
            finalArray = convertToDatabaseArray(array);        
        } 
        // else if (payload.DocumentCollections is json) {
        //     finalArray = convertToContainerArray(<json[]>payload.DocumentCollections);
        // } else if (payload.StoredProcedures is json) {
        //     finalArray = convertToStoredProcedureArray( <json[]>payload.StoredProcedures);
        // } else if (payload.UserDefinedFunctions is json) {
        //     finalArray = convertsToUserDefinedFunctionArray(<json[]>payload.UserDefinedFunctions);
        // } else if (payload.Triggers is json) {
        //     finalArray = convertToTriggerArray(<json[]>payload.Triggers);
        // } else if (payload.Users is json) {
        //     finalArray = convertToUserArray(<json[]>payload.Users);
        // } else if (payload.Permissions is json) {
        //     finalArray = convertToPermissionArray(<json[]>payload.Permissions);
        // } else if (payload.PartitionKeyRanges is json) {
        //     finalArray = convertToPartitionKeyRangeArray(<json[]>payload.PartitionKeyRanges);
        // } else if (payload.Offers is json) {
        //     finalArray = convertToOfferArray(<json[]>payload.Offers);
        // }
        return finalArray;
    }
}