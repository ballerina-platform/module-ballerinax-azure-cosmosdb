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

# Azure Cosmos DB Client Object for executing data plane operations.
# 
# + httpClient - the HTTP Client
public client class DataPlaneClient {
    private http:Client httpClient;
    private string baseUrl;
    private string masterOrResourceToken;
    private string host;

    public function init(Configuration azureConfig) {
        self.baseUrl = azureConfig.baseUrl;
        self.masterOrResourceToken = azureConfig.masterOrResourceToken;
        self.host = getHost(azureConfig.baseUrl);
        self.httpClient = checkpanic new(self.baseUrl);
    }
 
    # Create a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, document is created
    # + document - A JSON document to be saved in the database
    # + partitionKey - The specific value related to the partition key field of the container 
    # + documentCreateOptions - Optional. The `DocumentCreateOptions` which can be used to add additional 
    #                           capabilities to the request.
    # + return - If successful, returns `Document`. Else returns `error`.
    remote function createDocument(string databaseId, string containerId, record {|string id; json...;|} document, 
                                   int|float|decimal|string partitionKey, 
                                   DocumentCreateOptions? documentCreateOptions = ()) returns 
        @tainted Document|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, documentCreateOptions);
        request.setJsonPayload(document);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # Replace a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing document
    # + document - A JSON document which will replace the existing document
    # + partitionKey - The specific value related to the partition key field of the container 
    # + documentReplaceOptions - Optional. The `DocumentReplaceOptions` which can be used to add additional capabilities 
    #                            to the request.
    # + return - If successful, returns a `Document`. Else returns `error`.
    remote function replaceDocument(string databaseId, string containerId, 
                                    @tainted record {|string id; json...;|} document, 
                                    int|float|decimal|string partitionKey, 
        DocumentReplaceOptions? documentReplaceOptions = ()) 
        returns @tainted Document|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS, document.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, documentReplaceOptions);
        request.setJsonPayload(<@untainted>document);
        
        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDocumentType(jsonResponse); 
    }

    # Get information about a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - Id of the document 
    # + partitionKey - The value of partition key field of the container
    # + resourceReadOptions - Optional. The `ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request.
    # + return - If successful, returns `Document`. Else returns `error`.
    remote function getDocument(string databaseId, string containerId, string documentId, 
                                int|float|decimal|string partitionKey, 
                                ResourceReadOptions? resourceReadOptions = ()) returns 
        @tainted Document|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # List information of all the documents .
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + maxItemCount - Optional. Maximum number of `Document` records in one returning page.
    # + documentListOptions - Optional. The `DocumentListOptions` which can be used to add additional capabilities to 
    #                         the request.
    # + return - If successful, returns `stream<Document>`. Else, returns `error`. 
    remote function getDocumentList(string databaseId, string containerId, int? maxItemCount = (), 
                                    DocumentListOptions? documentListOptions = ()) 
                                    returns @tainted stream<Document>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, documentListOptions);

        Document[] initialArray = [];
        return <stream<Document>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Delete a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document
    # + partitionKey - The specific value related to the partition key field of the container
    # + resourceDeleteOptions - Optional. The `ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request.
    # + return - If successful, returns `DeleteResponse`. Else returns `error`.
    remote function deleteDocument(string databaseId, string containerId, string documentId, 
                                   int|float|decimal|string partitionKey, 
                                   ResourceDeleteOptions? resourceDeleteOptions = ()) returns 
        @tainted DeleteResponse|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Query documents.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container to query
    # + sqlQuery - A string containing the SQL query
    # + resourceQueryOptions - The `ResourceQueryOptions` which can be used to add additional capabilities to 
    #                          the request.    
    # + maxItemCount - Optional. Maximum number of documents in one returning page.
    # + return - If successful, returns a `stream<Document>`. Else returns `error`.
    remote function queryDocuments(string databaseId, string containerId, string sqlQuery, 
                                   ResourceQueryOptions resourceQueryOptions = {}, 
                                   int? maxItemCount = ()) returns 
                                   @tainted stream<Document>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, resourceQueryOptions?.partitionKey);
        setOptionalHeaders(request, resourceQueryOptions);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        json payload = {
            query: sqlQuery,
            parameters:[]
        };
        request.setJsonPayload(<@untainted>payload);

        check setHeadersForQuery(request);
        return <stream<Document>> check getQueryResults(self.httpClient, requestPath, request);
    }

    # Create a new stored procedure. Stored procedure is a piece of application logic written in JavaScript that is 
    # registered and executed against a container as a single transaction.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, stored procedure will be created 
    # + storedProcedureId - A unique ID for the newly created stored procedure
    # + storedProcedure - A JavaScript function represented as a string
    # + return - If successful, returns a `StoredProcedure`. Else returns `error`. 
    remote function createStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                                          string storedProcedure) returns @tainted StoredProcedure|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);

        json payload = {
            id: storedProcedureId,
            body: storedProcedure
        };
        request.setJsonPayload(payload); 

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToStoredProcedure(jsonResponse);
    }

    # Replace a stored procedure with new one.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing stored procedures
    # + storedProcedureId - The ID of the stored procedure to be replaced
    # + storedProcedure - A JavaScript function which will replace the existing one
    # + return - If successful, returns a `StoredProcedure`. Else returns `error`. 
    remote function replaceStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                                           string storedProcedure) returns @tainted StoredProcedure|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: storedProcedureId,
            body: storedProcedure
        };
        request.setJsonPayload(<@untainted>payload);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToStoredProcedure(jsonResponse);
    }

    # List information of all stored procedures.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedures
    # + maxItemCount - Optional. Maximum number of stored procedure records in one returning page.
    # + resourceReadOptions - Optional. The `ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request.
    # + return - If successful, returns a `stream<StoredProcedure>`. Else returns `error`. 
    remote function listStoredProcedures(string databaseId, string containerId, int? maxItemCount = (), 
                                         ResourceReadOptions? resourceReadOptions = ()) returns 
                                         @tainted stream<StoredProcedure>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES]);
        
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        StoredProcedure[] initialArray = [];
        return <stream<StoredProcedure>> check retrieveStream(self.httpClient, requestPath, request, initialArray);
    }

    # Delete a stored procedure.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to delete
    # + resourceDeleteOptions - Optional. The `ResourceDeleteOptions` which can be used to add additional 
    #                           capabilities to the request.
    # + return - If successful, returns `DeleteResponse`. Else returns `error`.
    remote function deleteStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                                          ResourceDeleteOptions? resourceDeleteOptions = ()) returns 
                                          @tainted DeleteResponse|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Execute a stored procedure.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to execute
    # + storedProcedureOptions - Optional. A record of type `StoredProcedureOptions` to specify the additional 
    #                            parameters.
    # + return - If successful, returns `json` with the output from the executed function. Else returns `error`. 
    remote function executeStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
                                           StoredProcedureOptions? storedProcedureOptions = ()) returns 
                                           @tainted json|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, storedProcedureOptions?.partitionKey);

        string parameters = let var param = storedProcedureOptions?.parameters in param is string[] ? param.toString() : 
            EMPTY_ARRAY_STRING;
        request.setTextPayload(parameters);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        return check handleResponse(response);
    }
}
