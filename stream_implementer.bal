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

// This is a test file for stream implementer
import ballerina/http;

class DocumentStream {
    private Document[] currentEntries = [];
    private string continuationToken;

    int index = 0;
    private final http:Client httpClient;
    private final string path;
    private final http:Request request;
    
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
        // This code block is for retrieving the next batch of records when the initial batch is finished. It has some
        // error.
        if (self.continuationToken != EMPTY_STRING) {
            self.index = 0;
            // Fetch documents again when the continuation token is provided. But this function has a remote method 
            // call So, it is not isolated.
            self.currentEntries = check self.fetchDocuments(); /// Here is the problem
            record {| Document value; |} document = {value: self.currentEntries[self.index]};  
            self.index += 1;
            return document;
        }
    }

    function fetchDocuments() returns @tainted Document[]|Error {
        if (self.continuationToken != EMPTY_STRING) {
            self.request.setHeader(CONTINUATION_HEADER, self.continuationToken);
        }
        http:Response response = check self.httpClient->get(self.path, self.request);
        self.continuationToken = let var header = response.getHeader(CONTINUATION_HEADER) in header is string ? header : 
            EMPTY_STRING;
        json payload = check handleResponse(response);
        if (payload.Documents is json) {
            Document[] documents = [];
            json[] array = let var load = payload.Documents in load is json ? <json[]>load : [];
            convertToDocumentArray(documents,array);
            return documents;
        } else {
            return error PayloadAccessError(INVALID_RESPONSE_PAYLOAD_ERROR);
        }
    }
}
