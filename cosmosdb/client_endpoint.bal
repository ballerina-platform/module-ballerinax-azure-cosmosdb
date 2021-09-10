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

# This is the Azure Cosmos DB SQL API, a fast NoSQL database servic offers rich querying over diverse data, helps 
# deliver configurable and reliable performance, is globally distributed, and enables rapid development. 
# 
# + httpClient - The HTTP Client
@display {
    label: "Azure Cosmos DB Client",
    iconPath: "resources/azure_cosmosdb.svg"
}
public isolated client class DataPlaneClient {
    final http:Client httpClient;
    final string baseUrl;
    final string primaryKeyOrResourceToken;
    final string host;

    # Gets invoked to initialize the `connector`.
    # The connector initialization requires setting the API credentials. 
    # Create an [Azure Cosmos DB account](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account) 
    # and obtain tokens following [this guide](https://docs.microsoft.com/en-us/azure/cosmos-db/database-security#primary-keys).
    #
    # + cosmosdbConfig - Configurations required to initialize the `Client` endpoint
    # + httpClientConfig - HTTP configuration
    # + return -  Error at failure of client initialization
    public isolated function init(ConnectionConfig cosmosdbConfig, http:ClientConfiguration httpClientConfig = {}) returns Error? {
        self.baseUrl = cosmosdbConfig.baseUrl;
        self.primaryKeyOrResourceToken = cosmosdbConfig.primaryKeyOrResourceToken;
        self.host = getHost(cosmosdbConfig.baseUrl);
        self.httpClient = check new (self.baseUrl, httpClientConfig);
    }
 
    # Creates a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, document is created
    # + document - A JSON document to be saved in the database
    # + partitionKey - The specific value related to the partition key field of the container 
    # + documentCreateOptions - The `cosmos_db:DocumentCreateOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:Document`. Else returns `cosmos_db:Error`.
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

    # Replaces a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing document
    # + document - A JSON document which will replace the existing document
    # + partitionKey - The specific value related to the partition key field of the container 
    # + documentReplaceOptions - The `cosmos_db:DocumentReplaceOptions` which can be used to add additional capabilities 
    #                            to the request
    # + return - If successful, returns a `cosmos_db:Document`. Else returns `cosmos_db:Error`.
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

    # Gets information about a document.
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document 
    # + partitionKey - The value of partition key field of the container
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns `cosmos_db:Document`. Else returns `cosmos_db:Error`.
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

    # Lists information of all the documents .
    # 
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentListOptions - The `cosmos_db:DocumentListOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns `stream<cosmos_db:Document, error>`. Else, returns `cosmos_db:Error`.
    @display {label: "Get Documents"}
    remote isolated function getDocumentList(@display {label: "Database ID"} string databaseId,
                                             @display {label: "Container ID"} string containerId,
                                             @display {label: "Optional Header Parameters"} DocumentListOptions?
                                             documentListOptions = ()) returns
                                             @tainted @display {label: "Stream of Documents"} stream<Document, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_DOCUMENTS]);
        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, documentListOptions);

        DocumentStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<Document, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes a document.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document
    # + partitionKey - The specific value related to the partition key field of the container
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
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

    # Queries documents.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container to query
    # + sqlQuery - A string containing the SQL query
    # + resourceQueryOptions - The `cosmos_db:ResourceQueryOptions` which can be used to add additional capabilities 
    #                          to the request
    # + return - If successful, returns a `stream<cosmos_db:Document, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Query Documents"}
    remote isolated function queryDocuments(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "SQL Query"} string sqlQuery,
                                            @display {label: "Optional Header Parameters"} ResourceQueryOptions?
                                            resourceQueryOptions = ()) returns
                                            @tainted @display {label: "Stream of Documents"}
                                            stream<Document, error?>|Error {
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
        stream<Document, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Creates a new stored procedure. 
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, stored procedure will be created
    # + storedProcedureId - A unique ID for the newly created stored procedure
    # + storedProcedure - A JavaScript function represented as a string
    # + return - If successful, returns a `cosmos_db:StoredProcedure`. Else returns `cosmos_db:Error`.
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

    # Replaces a stored procedure with new one.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing stored procedures
    # + storedProcedureId - The ID of the stored procedure to be replaced
    # + storedProcedure - A JavaScript function which will replace the existing one
    # + return - If successful, returns a `cosmos_db:StoredProcedure`. Else returns `cosmos_db:Error`.
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

    # Lists information of all stored procedures.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedures
    # + resourceReadOptions - The `cosmos_db:ResourceReadOptions` which can be used to add additional capabilities to 
    #                         the request
    # + return - If successful, returns a `stream<cosmos_db:StoredProcedure, error>`. Else returns `cosmos_db:Error`.
    @display {label: "Get Stored Procedures"}
    remote isolated function listStoredProcedures(@display {label: "Database ID"} string databaseId,
                                                  @display {label: "Container ID"} string containerId,
                                                  @display {label: "Optional Header Parameters"} ResourceReadOptions?
                                                  resourceReadOptions = ()) returns
                                                  @tainted @display {label: "Stream of Stored Procedures"}
                                                  stream<StoredProcedure, error?>|Error {
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId,
            RESOURCE_TYPE_STORED_POCEDURES]);

        map<string> headerMap = check setMandatoryGetHeaders(self.host, self.primaryKeyOrResourceToken, http:HTTP_GET,
            requestPath);
        headerMap = setOptionalGetHeaders(headerMap, resourceReadOptions);

        StoredProcedureStream objectInstance = check new (self.httpClient, requestPath, headerMap);
        stream<StoredProcedure, error?> finalStream = new (objectInstance);
        return finalStream;
    }

    # Deletes a stored procedure.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to delete
    # + resourceDeleteOptions - The `cosmos_db:ResourceDeleteOptions` which can be used to add additional capabilities 
    #                           to the request
    # + return - If successful, returns `cosmos_db:DeleteResponse`. Else returns `cosmos_db:Error`.
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

    # Executes a stored procedure.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to execute
    # + storedProcedureExecuteOptions - A record `cosmos_db:StoredProcedureExecuteOptions` to specify the 
    #                                   additional parameters
    # + return - If successful, returns `json` with the output from the executed function. Else returns `cosmos_db:Error`.
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
