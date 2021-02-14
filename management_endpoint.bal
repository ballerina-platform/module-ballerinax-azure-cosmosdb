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

# Azure Cosmos DB Client Object for management operations.
# 
# + httpClient - the HTTP Client
public client class ManagementClient {
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

    # Create a Database inside an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the new database. Must be unique.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function createDatabase(string databaseId, (int|json)? throughputOption = ()) returns @tainted Result|error {
        // Creating a new request
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);
        // Setting mandatory headers for the request
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        // Setting optional headers
        check setThroughputOrAutopilotHeader(request, throughputOption);

        // Setting a request payload
        json jsonPayload = {id: databaseId};
        request.setJsonPayload(jsonPayload);

        // Get the response
        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        // Map the payload and headers, of the request to a tuple 
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        // Map the reponse payload and the headers to a record type
        return mapTupleToResultType(jsonResponse);
    }

    # Create a Database inside an Azure Cosmos DB account only if the specified database ID does not exist already.
    # 
    # + databaseId - ID of the new database
    # + throughputOption - Optional. Throughput parameter of type int OR json.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function createDatabaseIfNotExist(string databaseId, (int|json)? throughputOption = ()) returns @tainted 
           Result?|error {
        var result = self->createDatabase(databaseId);
        if result is error {
            if (result.detail()[STATUS].toString() == http:STATUS_CONFLICT.toString()) {
                return;
            }
        }
        return result;
    }

    # Retrive information of a given Database in an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the database to retrieve information 
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function getDatabase(string databaseId, ResourceReadOptions? requestOptions = ()) returns @tainted 
            Database|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToDatabaseType(jsonResponse);
    }

    # List information of all Databases in an Azure Cosmos DB account.
    # 
    # + maxItemCount - Optional. Maximum number of Database records in one returning page.
    # + return - If successful, returns stream<cosmosdb:Database>. else returns error. 
    remote function listDatabases(int? maxItemCount = ()) returns @tainted stream<Database>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);

        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        stream<Database> databaseStream = <stream<Database>> check retriveStream(self.httpClient, requestPath, request);
        return databaseStream;
    }

    # Delete a given Database in an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the database to delete
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities 
    #       to the request.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function deleteDatabase(string databaseId, ResourceDeleteOptions? requestOptions = ()) returns @tainted 
            Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Create a Container inside the given Database.
    # 
    # + databaseId - ID of the database the container belongs to
    # + containerId - ID of the new container container
    # + partitionKey - A cosmosdb:PartitionKey record
    # + indexingPolicy - Optional. A cosmosdb:IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function createContainer(string databaseId, string containerId, PartitionKey partitionKey, 
            IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        check setThroughputOrAutopilotHeader(request, throughputOption);

        json jsonPayload = {
            id: containerId,
            partitionKey: {
                paths: check partitionKey.paths.cloneWithType(json),
                kind: partitionKey.kind,
                Version: partitionKey?.keyVersion
            }
        };
        if (indexingPolicy != ()) {
            jsonPayload = check jsonPayload.mergeJson({indexingPolicy: check indexingPolicy.cloneWithType(json)});
        }
        request.setJsonPayload(<@untainted>jsonPayload);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Create a Container inside an Azure Cosmos DB account only if the specified container ID does not exist already.
    # 
    # + databaseId - ID of the database the container belongs to
    # + containerId - ID of the new container   
    # + partitionKey - A cosmosdb:PartitionKey record
    # + indexingPolicy - Optional. A cosmosdb:IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Result if a new container is created or () if container already exists. 
    #       Else returns error.  
    remote function createContainerIfNotExist(string databaseId, string containerId, PartitionKey partitionKey, 
            IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) returns @tainted Result?|error { 
        var result = self->createContainer(databaseId, containerId, partitionKey, indexingPolicy, throughputOption);
        if result is error {
            if (result.detail()[STATUS].toString() == http:STATUS_CONFLICT.toString()) {
                return;
            }
        }
        return result;
    }

    # Retrive information about a Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container to retrive infromation  
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns cosmosdb:Container. Else returns error.  
    remote function getContainer(string databaseId, string containerId, ResourceReadOptions? requestOptions = ()) 
            returns @tainted Container|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # List information of all Containers.
    # 
    # + databaseId - ID of the database where the containers belong to
    # + maxItemCount - Optional. Maximum number of Container records in one returning page.
    # + return - If successful, returns stream<cosmosdb:Container>. Else returns error.  
    remote function listContainers(string databaseId, int? maxItemCount = ()) returns @tainted stream<Container>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        stream<Container> containerStream = <stream<Container>> check retriveStream(self.httpClient, requestPath, 
                request);
        return containerStream;
    }

    # Delete a given Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container to delete
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to the 
    #       request.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function deleteContainer(string databaseId, string containerId, ResourceDeleteOptions? requestOptions = ()) 
            returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Retrieve a list of partition key ranges for the Container.
    # 
    # + databaseId - ID of the database which container belongs to
    # + containerId - ID of the container where the partition key ranges are related to    
    # + return - If successful, returns stream<cosmosdb:PartitionKeyRange>. Else returns error.  
    remote function listPartitionKeyRanges(string databaseId, string containerId) returns @tainted 
            stream<PartitionKeyRange>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_PK_RANGES]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);

        stream<PartitionKeyRange> partitionKeyStream = <stream<PartitionKeyRange>> check retriveStream(self.httpClient, 
                requestPath, request);
        return partitionKeyStream;
    }

    # Create a User for a given Database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of the new user
    # + return - If successful, returns a cosmosdb:Result. Else returns error.
    remote function createUser(string databaseId, string userId) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);

        json reqBody = {id: userId};
        request.setJsonPayload(reqBody);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Replace the ID of an existing User.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - Old ID of the user
    # + newUserId - New ID for the user
    # + return - If successful, returns a cosmosdb:Result. Else returns error.
    remote function replaceUserId(string databaseId, string userId, string newUserId) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);

        json reqBody = {id: newUserId};
        request.setJsonPayload(reqBody);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # To get information of a User.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user to get
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a cosmosdb:User. Else returns error.
    remote function getUser(string databaseId, string userId, ResourceReadOptions? requestOptions = ()) returns @tainted 
            User|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Lists Users in a specific Database.
    # 
    # + databaseId - ID of the database where users is created
    # + maxItemCount - Optional. Maximum number of User records in one returning page.
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<cosmosdb:User>. Else returns error.
    remote function listUsers(string databaseId, int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) 
            returns @tainted stream<User>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, requestOptions);

        stream<User> userStream = <stream<User>> check retriveStream(self.httpClient, requestPath, request);
        return userStream;
    }

    # Delete a User.
    # 
    # + databaseId - ID of the database where user is created
    # + userId - ID of user to delete
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function deleteUser(string databaseId, string userId, ResourceDeleteOptions? requestOptions = ()) 
            returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);  
    }

    # Create a Permission for a User. 
    # 
    # + databaseId - ID of the database where user is created
    # + userId - ID of user to which the permission belongs
    # + permissionId - A unique ID for the newly created Permission
    # + permissionMode - The mode to which the Permission is scoped
    # + resourcePath - The resource this permission is allowing the User to access
    # + validityPeriodInSeconds - Optional. Validity period of the permission.
    # + return - If successful, returns a cosmosdb:Result. Else returns error.
    remote function createPermission(string databaseId, string userId, string permissionId, string permissionMode, 
            string resourcePath, int? validityPeriodInSeconds = ()) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        if (validityPeriodInSeconds is int) {
            check setExpiryHeader(request, validityPeriodInSeconds);
        }

        json jsonPayload = {
            id: permissionId,
            permissionMode: permissionMode,
            'resource: resourcePath
        };
        request.setJsonPayload(jsonPayload);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Replace an existing Permission.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user where the the permission is created
    # + permissionId - The ID of the Permission to be replaced
    # + permissionMode - The mode to which the Permission is scoped
    # + resourcePath - The resource this permission is allowing the User to access
    # + validityPeriodInSeconds - Optional. Validity period of the permission.
    # + return - If successful, returns a cosmosdb:Permission. Else returns error.
    remote function replacePermission(string databaseId, string userId, string permissionId, string permissionMode, 
            string resourcePath, int? validityPeriodInSeconds = ()) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);
        if (validityPeriodInSeconds is int) {
            check setExpiryHeader(request, validityPeriodInSeconds);
        }

        json jsonPayload = {
            id: permissionId,
            permissionMode: permissionMode,
            'resource: resourcePath
        };
        request.setJsonPayload(<@untainted>jsonPayload);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # To get information of a Permission.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user where the the permission belongs to
    # + permissionId - ID of the permission to get information
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a cosmosdb:Permission. Else returns error.
    remote function getPermission(string databaseId, string userId, string permissionId, ResourceReadOptions? 
            requestOptions = ()) returns @tainted Permission|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists Permissions belong to a User.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user where the the permissions is created
    # + maxItemCount - Optional. Maximum number of Permission records in one returning page.
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<cosmosdb:Permission>. Else returns error.
    remote function listPermissions(string databaseId, string userId, int? maxItemCount = (), ResourceReadOptions? 
            requestOptions = ()) returns @tainted stream<Permission>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, requestOptions);

        stream<Permission> permissionStream = <stream<Permission>> check retriveStream(self.httpClient, requestPath, 
                request);
        return permissionStream;
    }

    # Deletes a Permission belongs to a User.
    # 
    # + databaseId - ID of the database where the user is created
    # + userId - ID of user which the permission belongs to
    # + permissionId - ID of the permission to delete
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns cosmosdb:Result. Else returns error.  
    remote function deletePermission(string databaseId, string userId, string permissionId, ResourceDeleteOptions? 
            requestOptions = ()) returns @tainted Result|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_DELETE, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);   
    }

    # Replace an existing Offer.
    # 
    # + offer - A cosmosdb:Offer record
    # + offerType - Optional. Type of the offer.
    # + return - If successful, returns a cosmosdb:Result. Else returns error.
    remote function replaceOffer(Offer offer, string? offerType = ()) returns @tainted Result|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offer.id]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_PUT, requestPath);

        json jsonPaylod = {
            offerVersion: offer.offerVersion,
            content: offer.content,
            'resource: offer.resourceSelfLink,
            offerResourceId: offer.resourceResourceId,
            id: offer.id,
            _rid: offer?.resourceId
        };
        if (offerType is string && offer.offerVersion == OFFER_VERSION_1) {
            json selectedType = {offerType: offerType};
            jsonPaylod = checkpanic jsonPaylod.mergeJson(selectedType);
        }
        request.setJsonPayload(jsonPaylod);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseHeaders] jsonResponse = check mapCreationResponseToTuple(response);
        return mapTupleToResultType(jsonResponse);
    }

    # Get information about an Offer.
    # 
    # + offerId - The ID of the offer
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a cosmosdb:Offer. Else returns error.
    remote function getOffer(string offerId, ResourceReadOptions? requestOptions = ()) returns @tainted Offer|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offerId]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        setOptionalHeaders(request, requestOptions);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseHeaders] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Gets information of Offers inside Azure Cosmos DB account.
    # Each Azure Cosmos DB collection is provisioned with an associated performance level represented as an 
    # Offer resource in the REST model. Azure Cosmos DB supports offers representing both user-defined performance 
    # levels and pre-defined performance levels. 
    # 
    # + maxItemCount - Optional. Maximum number of Offer records in one returning page.
    # + requestOptions - Optional. The ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<cosmosdb:Offer> Else returns error.
    remote function listOffers(int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) returns @tainted 
            stream<Offer>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }
        setOptionalHeaders(request, requestOptions);

        stream<Offer> offerStream = <stream<Offer>> check retriveStream(self.httpClient, requestPath, request);
        return offerStream;
    }

    # Perform queries on Offer resources.
    # 
    # + sqlQuery - A string value containing SQL query
    # + maxItemCount - Optional. Maximum number of offers in one returning page.
    # + requestOptions - Optional. The ResourceQueryOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<json>. Else returns error.
    remote function queryOffer(string sqlQuery, int? maxItemCount = (), ResourceQueryOptions? requestOptions = ()) 
            returns @tainted stream<json>|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.masterOrResourceToken, http:HTTP_POST, requestPath);
        setOptionalHeaders(request, requestOptions);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        request.setJsonPayload({query: sqlQuery});
        setHeadersForQuery(request);

        stream<json> offerStream = <stream<json>> check getQueryResults(self.httpClient, requestPath, request);
        return offerStream;
    }
}
