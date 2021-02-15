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

# Azure Cosmos DB Client Object for data plane operations.
# 
# + httpClient - the HTTP Client
public client class CoreClient {
    private http:Client httpClient;
    private string baseUrl;
    private string masterOrResourceToken;
    private string host;

    public function init(AzureCosmosConfiguration azureConfig) {
        self.baseUrl = azureConfig.baseUrl;
        self.masterOrResourceToken = azureConfig.masterOrResourceToken;
        self.host = getHost(azureConfig.baseUrl);
        self.httpClient = new(self.baseUrl);
    }

    # Create a Document inside a Container.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which Document belongs to
    # + documentId - A unique ID for the document to save in the Database
    # + document - A JSON document to be saved in the Database
    # + partitionKey - The value of partition key field of the Container 
    # + documentCreateOptions - Optional. The DocumentCreateOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns Result. Else returns error.
    remote function createDocument(string databaseId, string containerId, string documentId, json document, 
            any partitionKey, DocumentCreateOptions? documentCreateOptions = ()) returns @tainted Document|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, documentCreateOptions);

        json payload = {
            id: documentId
        };
        _ = check payload.mergeJson(document);
        request.setJsonPayload(payload);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # Replace a Document inside a Container.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which Document belongs to
    # + documentId - The ID of the Document to be replaced
    # + document - A JSON document saved in the Database
    # + partitionKey - The value of partition key field of the Container 
    # + documentReplaceOptions - Optional. The DocumentReplaceOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a Result. Else returns error. 
    remote function replaceDocument(string databaseId, string containerId, string documentId, json document, 
            any partitionKey, DocumentReplaceOptions? documentReplaceOptions = ()) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, documentReplaceOptions);

        json payload = {id: documentId};
        _ = check payload.mergeJson(document);
        request.setJsonPayload(<@untainted>payload);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Get information about one Document in a Container.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which Document belongs to
    # + documentId - Id of the Document to retrieve 
    # + partitionKey - The value of partition key field of the Container
    # + resourceReadOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns Document. Else returns error.
    remote function getDocument(string databaseId, string containerId, string documentId, any partitionKey, 
            ResourceReadOptions? resourceReadOptions = ()) returns @tainted Document|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, resourceReadOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDocumentType(jsonResponse);
    }

    # List information of all the Documents in a Container.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which Document belongs to
    # + maxItemCount - Optional. Maximum number of Document records in one returning page.
    # + documentListOptions - Optional. The DocumentListOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns stream<Document> Else, returns error. 
    remote function getDocumentList(string databaseId, string containerId, int? maxItemCount = (), 
            DocumentListOptions? documentListOptions = ()) returns @tainted stream<Document>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, documentListOptions);

        stream<Document> documentStream = <stream<Document>> check retrieveStream(self.httpClient, requestPath, request);
        return documentStream;
    }

    # Delete a Document in a Container.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which Document belongs to
    # + documentId - ID of the document to delete
    # + partitionKey - The value of partition key field of the container
    # + resourceDeleteOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns Result. Else returns error.
    remote function deleteDocument(string databaseId, string containerId, string documentId, any partitionKey, 
            ResourceDeleteOptions? resourceDeleteOptions = ()) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS, documentId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Query a Container.
    # 
    # + databaseId - ID of the database which Container belongs to
    # + containerId - ID of the Container to query
    # + sqlQuery - A string containing the SQL query
    # + partitionKey - Optional. The value of partition key field of the container.
    # + maxItemCount - Optional. Maximum number of documents in one returning page.
    # + resourceQueryOptions - Optional. The ResourceQueryOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns a stream<json>. Else returns error.
    remote function queryDocuments(string databaseId, string containerId, string sqlQuery, int? maxItemCount = (), any? 
            partitionKey = (), ResourceQueryOptions? resourceQueryOptions = ()) returns @tainted stream<json>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_DOCUMENTS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, partitionKey);
        setOptionalHeaders(request, resourceQueryOptions);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        json payload = {
            query: sqlQuery,
            parameters:[]
        };
        request.setJsonPayload(<@untainted>payload);

        setHeadersForQuery(request);
        stream<json> documentStream = <stream<json>> check getQueryResults(self.httpClient, requestPath, request);
        return documentStream;
    }

    # Create a new Stored Procedure inside a Container.
    # A stored procedure is a piece of application logic written in JavaScript that is registered and executed against a 
    # collection as a single transaction.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which Stored Procedure will be created 
    # + storedProcedureId - A unique ID for the newly created Stored Procedure
    # + storedProcedure - A JavaScript function
    # + return - If successful, returns a Result. Else returns error. 
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
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToStoredProcedure(jsonResponse);
    }

    # Replace a Stored Procedure in a Container with new one.
    # 
    # + databaseId - ID of the Database which Container belongs to
    # + containerId - ID of the Container which existing Stored Procedure belongs to
    # + storedProcedureId - The ID of the Stored Procedure to be replaced
    # + storedProcedure - A JavaScript function
    # + return - If successful, returns a Result. Else returns error. 
    remote function replaceStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
            string storedProcedure) returns @tainted Result|error { 
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
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # List information of all Stored Procedures in a Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container which contain the stored procedures
    # + maxItemCount - Optional. Maximum number of Stored Procedure records in one returning page.
    # + resourceReadOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns a stream<StoredProcedure>. Else returns error. 
    remote function listStoredProcedures(string databaseId, string containerId, int? maxItemCount = (), 
            ResourceReadOptions? resourceReadOptions = ()) returns @tainted stream<StoredProcedure>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_STORED_POCEDURES]);
        
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        stream<StoredProcedure> storedProcedureStream = <stream<StoredProcedure>> check retrieveStream(self.httpClient, 
                requestPath, request);
        return storedProcedureStream;
    }

    # Delete a Stored Procedure in a Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container which contain the stored procedure
    # + storedProcedureId - ID of the stored procedure to delete
    # + resourceDeleteOptions - Optional. The ResourceDeleteOptions which can be used to add addtional 
    #       capabilities to the request.
    # + return - If successful, returns Result. Else returns error.
    remote function deleteStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
            ResourceDeleteOptions? resourceDeleteOptions = ()) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Execute a Stored Procedure in a Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container which contain the stored procedure
    # + storedProcedureId - ID of the stored procedure to execute
    # + storedProcedureOptions - Optional. A record of type StoredProcedureOptions to specify the additional parameters.
    # + return - If successful, returns json with the output from the executed function. Else returns error. 
    remote function executeStoredProcedure(string databaseId, string containerId, string storedProcedureId, 
            StoredProcedureOptions? storedProcedureOptions = ()) returns @tainted json|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_STORED_POCEDURES, storedProcedureId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setPartitionKeyHeader(request, storedProcedureOptions?.partitionKey);

        request.setTextPayload(storedProcedureOptions?.parameters.toString());

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        json jsonResponse = check handleResponse(response);
        return jsonResponse;
    }

    # Create a new User Defined Function inside a Container.
    # A user-defined function (UDF) is a side effect free piece of application logic written in JavaScript. 
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container which user defined will be created
    # + userDefinedFunctionId - A unique ID for the newly created User Defined Function
    # + userDefinedFunction - A JavaScript function
    # + return - If successful, returns a Result. Else returns error. 
    remote function createUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionId, 
            string userDefinedFunction) returns @tainted UserDefinedFunction|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
                
        json payload = {
            id: userDefinedFunctionId,
            body: userDefinedFunction
        };
        request.setJsonPayload(payload); 

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserDefinedFunction(jsonResponse);
    }

    # Replace an existing User Defined Function in a Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container in which user defined function is created
    # + userDefinedFunctionId - The ID of the User Defined Function to replace
    # + userDefinedFunction - A JavaScript function
    # + return - If successful, returns a Result. Else returns error. 
    remote function replaceUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionId, 
            string userDefinedFunction) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF, userDefinedFunctionId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: userDefinedFunctionId,
            body: userDefinedFunction
        };
        request.setJsonPayload(<@untainted>payload); 

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Get a list of existing User Defined Functions inside a Container.
    # 
    # + databaseId - ID of the database which user belongs to
    # + containerId - ID of the container which user defined functions belongs to
    # + maxItemCount - Optional. Maximum number of User Defined Function records in one returning page.
    # + resourceReadOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<UserDefinedFunction>. Else returns error. 
    remote function listUserDefinedFunctions(string databaseId, string containerId, int? maxItemCount = (), 
            ResourceReadOptions? resourceReadOptions = ()) returns @tainted stream<UserDefinedFunction>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        stream<UserDefinedFunction> userDefinedFunctionStream = <stream<UserDefinedFunction>> check retrieveStream(
        self.httpClient, requestPath, request);
        return userDefinedFunctionStream;
    }

    # Delete an existing User Defined Function inside a Container.
    # 
    # + databaseId - ID of the database which container is created
    # + containerId - ID of the container which user defined function is created
    # + userDefinedFunctionid - Id of UDF to delete
    # + resourceDeleteOptions - Optional. The ResourceDeleteOptions which can be used to add addtional 
    #       capabilities to the request.
    # + return - If successful, returns Result. Else returns error.
    remote function deleteUserDefinedFunction(string databaseId, string containerId, string userDefinedFunctionid, 
            ResourceDeleteOptions? resourceDeleteOptions = ()) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_UDF, userDefinedFunctionid]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Create a Trigger inside a Container. 
    # Triggers are pieces of application logic that can be executed before (pre-triggers) and after (post-triggers) 
    # creation, deletion, and replacement of a document. Triggers are written in JavaScript.
    #  
    # + databaseId - ID of the Database where Container is created
    # + containerId - ID of the Container where Trigger is created
    # + triggerId - A unique ID for the newly created Trigger
    # + trigger - A JavaScript function
    # + triggerOperation - The specific operation in which trigger will be executed
    # + triggerType - The instance in which trigger will be executed `Pre` or `Post`
    # + return - If successful, returns a Result. Else returns error. 
    remote function createTrigger(string databaseId, string containerId, string triggerId, string trigger, 
            string triggerOperation, string triggerType) returns @tainted Trigger|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);

        json payload = {
            id: triggerId,
            body: trigger,
            triggerOperation: triggerOperation,
            triggerType: triggerType
        };
        request.setJsonPayload(payload); 
        
        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToTrigger(jsonResponse);
    }

    # Replace an existing Trigger inside a Container.
    # 
    # + databaseId - ID of the Database where Container is created
    # + containerId - ID of the Container where Trigger is created
    # + triggerId - The of the Trigger to be replaced
    # + trigger - A JavaScript function
    # + triggerOperation - The specific operation in which trigger will be executed
    # + triggerType - The instance in which trigger will be executed `Pre` or `Post`
    # + return - If successful, returns a Result. Else returns error. 
    remote function replaceTrigger(string databaseId, string containerId, string triggerId, string trigger, 
            string triggerOperation, string triggerType) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER, triggerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);

        json payload = {
            id: triggerId,
            body: trigger,
            triggerOperation: triggerOperation,
            triggerType: triggerType
        };
        request.setJsonPayload(<@untainted>payload);
        
        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # List existing Triggers inside a Container.
    # 
    # + databaseId - ID of the Database where the Container is created
    # + containerId - ID of the Container where the Triggers are created
    # + maxItemCount - Optional. Maximum number of Trigger records in one returning page.
    # + resourceReadOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns a stream<Trigger>. Else returns error. 
    remote function listTriggers(string databaseId, string containerId, int? maxItemCount = (), 
            ResourceReadOptions? resourceReadOptions = ()) returns @tainted stream<Trigger>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, resourceReadOptions);

        stream<Trigger> triggerStream = <stream<Trigger>> check retrieveStream(self.httpClient, requestPath, request);
        return triggerStream;
    }

    # Delete an existing Trigger inside a Container.
    # 
    # + databaseId - ID of the Database where the Container is created
    # + containerId - ID of the Container where the Trigger is created 
    # + triggerId - ID of the Trigger to be deleted
    # + resourceDeleteOptions - Optional. The ResourceDeleteOptions which can be used to add addtional 
    #       capabilities to the request.
    # + return - If successful, returns Result. Else returns error.
    remote function deleteTrigger(string databaseId, string containerId, string triggerId, 
            ResourceDeleteOptions? resourceDeleteOptions = ()) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_TRIGGER, triggerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, resourceDeleteOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleCreationResponse(response); 
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }
}
