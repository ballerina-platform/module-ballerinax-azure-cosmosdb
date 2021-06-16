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
@display {
    label: "Azure Cosmos DB Client",
    iconPath: "AzureCosmosDBLogo.svg"
}
public client class DataPlaneClient {
    private http:Client httpClient;
    private string baseUrl;
    private string primaryKeyOrResourceToken;
    private string host;

    public isolated function init(Configuration azureConfig) returns Error? {
        self.baseUrl = azureConfig.baseUrl;
        self.primaryKeyOrResourceToken = azureConfig.primaryKeyOrResourceToken;
        self.host = getHost(azureConfig.baseUrl);
        self.httpClient = check new(self.baseUrl);
    }
 
    # Create a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, document is created
    # + document - A JSON document to be saved in the database
    # + partitionKey - The specific value related to the partition key field of the container 
    # + documentCreateOptions - The `DocumentCreateOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `Document`. Else returns `Error`.
    @display {label: "Create Document"}
    remote isolated function createDocument(@display {label: "Database ID"} string databaseId, 
                                            @display {label: "Container ID"} string containerId, 
                                            @display {label: "Document"} record {|string id; json...;|} document, 
                                            @display {label: "Partition Key"} int|float|decimal|string partitionKey, 
                                            @display {label: "Optional Header Parameters"} DocumentCreateOptions? 
                                            documentCreateOptions = ()) returns @tainted Document|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, documentCreateOptions);
        request.setJsonPayload(document);

        http:Response response = check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # Replace a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing document
    # + document - A JSON document which will replace the existing document
    # + partitionKey - The specific value related to the partition key field of the container 
    # + documentReplaceOptions - The `DocumentReplaceOptions` which can be used to add additional capabilities to the 
    #                            request
    # + return - If successful, returns a `Document`. Else returns `Error`.
    @display {label: "Replace Document"}
    remote isolated function replaceDocument(@display {label: "Database ID"} string databaseId, 
                                             @display {label: "Container ID"} string containerId, 
                                             @display {label: "New Document"} @tainted record {|string id; json...;|} 
                                             document, 
                                             @display {label: "Partition Key"} int|float|decimal|string partitionKey,  
                                             @display {label: "Optional Header Parameters"} DocumentReplaceOptions? 
                                             documentReplaceOptions = ()) returns @tainted Document|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS, document.id]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, documentReplaceOptions);
        request.setJsonPayload(<@untainted>document);
        
        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDocumentType(jsonResponse); 
    }

    # Get information about a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document 
    # + partitionKey - The value of partition key field of the container
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns `Document`. Else returns `Error`.
    @display {label: "Get Document"}
    remote isolated function getDocument(@display {label: "Database ID"} string databaseId, 
                                         @display {label: "Container ID"} string containerId, 
                                         @display {label: "Document ID"} string documentId, 
                                         @display {label: "Partition Key"} int|float|decimal|string partitionKey, 
                                         @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                         resourceReadOptions = ()) returns @tainted Document|Error { 
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS, documentId]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, 
            requestPath);
        headerMap = setGetPartitionKeyHeader(headerMap, partitionKey);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        http:Response response = check self.httpClient->get(requestPath, headerMap);
        json jsonResponse = check handleResponse(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # List information of all the documents .
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentListOptions - The `DocumentListOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns `stream<Document, error>`. Else, returns `Error`. 
    @display {label: "Get Documents"}
    remote isolated function getDocumentList(@display {label: "Database ID"} string databaseId, 
                                             @display {label: "Container ID"} string containerId, 
                                             @display {label: "Optional Header Parameters"} DocumentListOptions? 
                                             documentListOptions = ()) returns 
                                             @tainted @display {label: "Stream of Documents"} stream<Document, error>|Error { 
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, 
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, documentListOptions);

        DocumentStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Document, error> finalStream = new (objectInstance);
        return finalStream;
    }

    # Delete a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document
    # + partitionKey - The specific value related to the partition key field of the container
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    @display {label: "Delete Document"}
    remote isolated function deleteDocument(@display {label: "Database ID"} string databaseId, 
                                            @display {label: "Container ID"} string containerId, 
                                            @display {label: "Document ID"} string documentId, 
                                            @display {label: "Partition Key"} int|float|decimal|string partitionKey, 
                                            @display {label: "Optional Header Parameters"} ResourceDeleteOptions? 
                                            resourceDeleteOptions = ()) returns @tainted DeleteResponse|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Query documents.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container to query
    # + sqlQuery - A string containing the SQL query
    # + resourceQueryOptions - The `ResourceQueryOptions` which can be used to add additional capabilities to the 
    #                          request
    # + return - If successful, returns a `stream<Document, error>`. Else returns `Error`.
    @display {label: "Query Documents"}
    remote isolated function queryDocuments(@display {label: "Database ID"} string databaseId, 
                                            @display {label: "Container ID"} string containerId, 
                                            @display {label: "SQL Query"} string sqlQuery, 
                                            @display {label: "Optional Header Parameters"} ResourceQueryOptions? 
                                            resourceQueryOptions = ()) returns 
                                            @tainted @display {label: "Stream of Documents"} 
                                            stream<Document, error>|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, resourceQueryOptions?.partitionKey);
        setOptionalHeaders(request, resourceQueryOptions);

        json payload = {
            query: sqlQuery,
            parameters:[]
        };
        request.setJsonPayload(<@untainted>payload);

        check setHeadersForQuery(request);
        DocumentQueryResultStream objectInstance = check new (self.httpClient, requestPath, request);
        stream<Document, error> finalStream = new (objectInstance);
        return finalStream;
    }

    # Create a new stored procedure. Stored Procedure is a piece of application logic written in JavaScript that is 
    # registered and executed against a container as a single transaction.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, stored procedure will be created 
    # + storedProcedureId - A unique ID for the newly created stored procedure
    # + storedProcedure - A JavaScript function represented as a string
    # + return - If successful, returns a `StoredProcedure`. Else returns `Error`. 
    @display {label: "Create Stored Procedure"}
    remote isolated function createStoredProcedure(@display {label: "Database ID"} string databaseId,
                                                   @display {label: "Container ID"} string containerId,
                                                   @display {label: "Stored Procedure ID"} string storedProcedureId,
                                                   @display {label: "Stored Procedure Function"} string storedProcedure)
                                                   returns @tainted StoredProcedure|Error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);

        json payload = {
            id: storedProcedureId,
            body: storedProcedure
        };
        request.setJsonPayload(payload);

        http:Response response = check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToStoredProcedure(jsonResponse);
    }

    # Replace a stored procedure with new one.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing stored procedures
    # + storedProcedureId - The ID of the stored procedure to be replaced
    # + storedProcedure - A JavaScript function which will replace the existing one
    # + return - If successful, returns a `StoredProcedure`. Else returns `Error`. 
    @display {label: "Replace Stored Procedure"}
    remote isolated function replaceStoredProcedure(@display {label: "Database ID"} string databaseId, 
                                                    @display {label: "Container ID"} string containerId, 
                                                    @display {label: "Stored Procedure ID"} string storedProcedureId, 
                                                    @display {label: "Stored Procedure Function"} string storedProcedure) 
                                                    returns @tainted StoredProcedure|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: storedProcedureId,
            body: storedProcedure
        };
        request.setJsonPayload(<@untainted>payload);

        http:Response response = check self.httpClient->put(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return mapJsonToStoredProcedure(jsonResponse);
    }

    # List information of all stored procedures.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedures
    # + resourceReadOptions - The `ResourceReadOptions` which can be used to add additional capabilities to the request
    # + return - If successful, returns a `stream<StoredProcedure, error>`. Else returns `Error`. 
    @display {label: "Get Stored Procedures"}
    remote isolated function listStoredProcedures(@display {label: "Database ID"} string databaseId, 
                                                  @display {label: "Container ID"} string containerId, 
                                                  @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                                  resourceReadOptions = ()) returns 
                                                  @tainted @display {label: "Stream of Stored Procedures"} 
                                                  stream<StoredProcedure, error>|Error { 
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES]);
        
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET, 
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        StoredProcedureStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<StoredProcedure, error> finalStream = new (objectInstance);
        return finalStream;
    }

    # Delete a stored procedure.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to delete
    # + resourceDeleteOptions - The `ResourceDeleteOptions` which can be used to add additional capabilities to the 
    #                           request
    # + return - If successful, returns `DeleteResponse`. Else returns `Error`.
    @display {label: "Delete Stored Procedure"}
    remote isolated function deleteStoredProcedure(@display {label: "Database ID"} string databaseId, 
                                                   @display {label: "Container ID"} string containerId, 
                                                   @display {label: "Stored Procedure ID"} string storedProcedureId, 
                                                   @display {label: "Optional Header Parameters"} ResourceDeleteOptions? 
                                                   resourceDeleteOptions = ()) returns @tainted DeleteResponse|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = check self.httpClient->delete(requestPath, request);
        check handleHeaderOnlyResponse(response);
        return mapHeadersToResultType(response); 
    }

    # Execute a stored procedure.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to execute
    # + storedProcedureExecuteOptions - A record of type `StoredProcedureExecuteOptions` to specify the additional 
    #                            parameters
    # + return - If successful, returns `json` with the output from the executed function. Else returns `Error`. 
    @display {label: "Execute Stored Procedure"}
    remote isolated function executeStoredProcedure(@display {label: "Database ID"} string databaseId, 
                                                    @display {label: "Container ID"} string containerId, 
                                                    @display {label: "Stored Procedure ID"} string storedProcedureId, 
                                                    @display {label: "Execution Options"} 
                                                    StoredProcedureExecuteOptions storedProcedureExecuteOptions) 
                                                    returns @tainted @display {label: "JSON Response"} json|Error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
            RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.primaryKeyOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, storedProcedureExecuteOptions?.partitionKey);

        request.setTextPayload(storedProcedureExecuteOptions?.parameters.toString());

        http:Response response = check self.httpClient->post(requestPath, request);
        return check handleResponse(response);
    }
}
