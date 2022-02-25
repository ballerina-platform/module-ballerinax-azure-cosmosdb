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

import ballerina/jballerina.java;

# This is the Azure Cosmos DB SQL API, a fast NoSQL database servic offers rich querying over diverse data, helps 
# deliver configurable and reliable performance, is globally distributed, and enables rapid development. 
@display {
    label: "Azure Cosmos DB Client",
    iconPath: "icon.png"
}
public isolated client class DataPlaneClient {

    # Gets invoked to initialize the `connector`.
    # The connector initialization requires setting the API credentials. 
    # Create an [Azure Cosmos DB account](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-manage-database-account) 
    # and obtain tokens following [this guide](https://docs.microsoft.com/en-us/azure/cosmos-db/database-security#primary-keys).
    #
    # + connectionConfig - Configurations required to initialize the `Client` endpoint
    # + httpClientConfig - HTTP configuration
    # + return - Error at failure of client initialization
    public isolated function init(ConnectionConfig connectionConfig, ClientConfiguration? advanceClientConfig = ()) 
    returns error? {
        check initClient(self, connectionConfig, advanceClientConfig);
    }

    # Creates a document.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, document is created
    # + documemtId - ID of the document
    # + document - A JSON document to be saved in the database
    # + partitionKey - The specific value related to the partition key field of the container 
    # + requestOptions - The `cosmos_db:RequestOptions` which can be used to add additional capabilities that can 
    # override client configuration provided in the inilization
    # + return - Error if failed
    @display {label: "Create Document"}
    remote isolated function createDocument(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "Document ID"} string documemtId,
                                            @display {label: "Document"} record {} document,
                                            @display {label: "Partition Key"} int|float|decimal|string partitionKey,
                                            @display {label: "Optional Header Parameters"} RequestOptions?
                                            requestOptions = ()) returns DocumentResponse|error {

        json jsonDocument = check document.cloneWithType(json);
        json updatedDocument = check jsonDocument.mergeJson({"id": documemtId});
        return createDocument(databaseId, containerId, <map<json>>updatedDocument, partitionKey, requestOptions);
    }

    # Replaces a document.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the existing document
    # + documemtId - ID of the document
    # + document - A JSON document which will replace the existing document
    # + partitionKey - The specific value related to the partition key field of the container 
    # + requestOptions - The `cosmos_db:RequestOptions` which can be used to add additional capabilities that can 
    # override client configuration provided in the inilization
    # + return - Error if failed
    @display {label: "Replace Document"}
    remote isolated function replaceDocument(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "Document ID"} string documemtId,
                                            @display {label: "New Document"} record {} document,
                                            @display {label: "Partition Key"} int|float|decimal|string partitionKey,
                                            @display {label: "Optional Header Parameters"} RequestOptions?
                                            requestOptions = ()) returns DocumentResponse|error {
        json jsonDocument = check document.cloneWithType(json);
        json updatedDocument = check jsonDocument.mergeJson({"id": documemtId});
        return replaceDocument(databaseId, containerId, documemtId, <map<json>>updatedDocument, partitionKey, 
        requestOptions);
    }

    # Gets information about a document.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document 
    # + partitionKey - The value of partition key field of the container
    # + returnType - Type need to be inferred.
    # + requestOptions - The `cosmos_db:RequestOptions` which can be used to add additional capabilities that can 
    # override client configuration provided in the inilization
    # + return - If successful, returns given target record. Else returns error.
    @display {label: "Get Document"}
    remote isolated function getDocument(@display {label: "Database ID"} string databaseId,
                                        @display {label: "Container ID"} string containerId,
                                        @display {label: "Document ID"} string documentId,
                                        @display {label: "Partition Key"} int|float|decimal|string partitionKey,
                                        @display {label: "Optional Header Parameters"} RequestOptions?
                                        requestOptions = (), typedesc<record {}> returnType = <>)
                                        returns returnType|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    # Lists information of all the documents .
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + partitionKey - The value of partition key field of the container
    # + queryOptions - The `cosmos_db:QueryOptions` which can be used to add additional capabilities that can 
    # override client configuration provided in the inilization
    # + returnType - Type need to be inferred.
    # + return - If successful, returns `stream<returnType, error>`. Else, returns error.
    @display {label: "Get Documents"}
    remote isolated function getDocumentList(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "Partition Key"} int|float|decimal|string partitionKey,
                                            @display {label: "Optional Header Parameters"} QueryOptions?
                                            queryOptions = (), typedesc<record {}> returnType = <>)
                                            returns stream<returnType, error?>|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    # Deletes a document.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the document
    # + documentId - ID of the document
    # + partitionKey - The specific value related to the partition key field of the container
    # + requestOptions - The `cosmos_db:RequestOptions` which can be used to add additional capabilities that can 
    # override client configuration provided in the inilization
    # + return - Error if failed
    @display {label: "Delete Document"}
    remote isolated function deleteDocument(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "Document ID"} string documentId,
                                            @display {label: "Partition Key"} int|float|decimal|string partitionKey,
                                            @display {label: "Optional Header Parameters"} RequestOptions?
                                            requestOptions = ()) returns DocumentResponse|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    # Queries documents.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container to query
    # + sqlQuery - A string containing the SQL query
    # + queryOptions - The `cosmos_db:QueryOptions` which can be used to add additional capabilities that can 
    # override client configuration provided in the inilization
    # + returnType - Type need to be inferred.
    # + return - If successful, returns a `stream<returnType, error>`. Else returns error.
    @display {label: "Query Documents"}
    remote isolated function queryDocuments(@display {label: "Database ID"} string databaseId,
                                            @display {label: "Container ID"} string containerId,
                                            @display {label: "SQL Query"} string sqlQuery,
                                            @display {label: "Optional Header Parameters"} QueryOptions? queryOptions
                                            = (), typedesc<record {}> returnType = <>) 
                                            returns stream<returnType, error?>|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    # Creates a new stored procedure. 
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container where, stored procedure will be created
    # + storedProcedureId - A unique ID for the newly created stored procedure
    # + storedProcedure - A JavaScript function represented as a string
    # + options - The `cosmos_db:CosmosStoredProcedureRequestOptions` which can be used to add additional capabilities
    #  that can override client configuration provided in the inilization
    # + return - If successful, returns a `cosmos_db:StoredProcedure`. Else returns error.
    @display {label: "Create Stored Procedure"}
    remote isolated function createStoredProcedure(@display {label: "Database ID"} string databaseId,
                                                    @display {label: "Container ID"} string containerId,
                                                    @display {label: "Stored Procedure ID"} string storedProcedureId,
                                                    @display {label: "Stored Procedure Function"} string 
                                                    storedProcedure, CosmosStoredProcedureRequestOptions? options = ())
                                                    returns StoredProcedureResponse|error {
        return createStoredProcedure(databaseId, containerId, storedProcedureId, storedProcedure, options);
    }

    # Lists information of all stored procedures.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedures
    # + return - If successful, returns a `stream<cosmos_db:StoredProcedure, error>`. Else returns error.
    @display {label: "Get Stored Procedures"}
    remote isolated function listStoredProcedures(@display {label: "Database ID"} string databaseId,
                                                @display {label: "Container ID"} string containerId) returns
                                                @display {label: "Stream of Stored Procedures"}
                                                stream<StoredProcedure, error?>|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    # Deletes a stored procedure.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to delete
    # + return - Error if failed
    @display {label: "Delete Stored Procedure"}
    remote isolated function deleteStoredProcedure(@display {label: "Database ID"} string databaseId,
                                                    @display {label: "Container ID"} string containerId,
                                                    @display {label: "Stored Procedure ID"} string storedProcedureId
                                                    ) returns StoredProcedureResponse|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    # Executes a stored procedure.
    #
    # + databaseId - ID of the database to which the container belongs to
    # + containerId - ID of the container which contains the stored procedure
    # + storedProcedureId - ID of the stored procedure to execute
    # + patitionKey - The specific value related to the partition key field of the container
    # + storedProcedureExecuteOptions - A record `cosmos_db:StoredProcedureExecuteOptions` to specify the 
    # additional parameters
    # + return - error if failed
    @display {label: "Execute Stored Procedure"}
    remote isolated function executeStoredProcedure(@display {label: "Database ID"} string databaseId,
                                                    @display {label: "Container ID"} string containerId,
                                                    @display {label: "Stored Procedure ID"} string storedProcedureId,
                                                    @display {label: "Partition Key"} int|float|decimal|string 
                                                    patitionKey, @display {label: "Execution Options"}
                                                    StoredProcedureExecuteOptions? storedProcedureExecuteOptions = ())
                                                    returns StoredProcedureResponse|error = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

    remote isolated function close() returns error? = @java:Method {
        'class: "io.ballerinax.cosmosdb.DataplaneClient"
    } external;

}

isolated function initClient(DataPlaneClient dataClient, ConnectionConfig config, ClientConfiguration?
customConfig = ()) returns error? = @java:Method {
    'class: "io.ballerinax.cosmosdb.DataplaneClient"
} external;

isolated function createDocument(string databaseId, string containerId,
                                    map<json> document, int|float|decimal|string partitionKey, RequestOptions? 
                                    documentCreateOptions = ()) returns DocumentResponse|error = @java:Method {
    'class: "io.ballerinax.cosmosdb.DataplaneClient"
} external;

isolated function replaceDocument(string databaseId, string containerId, string id,
                                    map<json> document, int|float|decimal|string partitionKey,
                                    RequestOptions? documentCreateOptions = ()) returns DocumentResponse|error = 
                                    @java:Method {
    'class: "io.ballerinax.cosmosdb.DataplaneClient"
} external;

isolated function createStoredProcedure(string databaseId, string containerId,
                                    string storedProcedureId, string storedProcedure,
                                    CosmosStoredProcedureRequestOptions? options = ()) returns 
                                    StoredProcedureResponse|error = @java:Method {
    'class: "io.ballerinax.cosmosdb.DataplaneClient"
} external;
