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
import ballerina/http;

# Azure Cosmos DB Client Object for management operations.
# 
# + httpClient - the HTTP Client
public client class CoreManagementClient {
    private http:Client httpClient;
    private string baseUrl;
    private string masterToken;
    private string host;
    private string tokenType;
    private string tokenVersion;

    public function init(AzureCosmosManagementConfiguration azureConfig) {
        self.baseUrl = checkpanic validateBaseUrl(azureConfig.baseUrl);
        self.masterToken = checkpanic validateMasterToken(azureConfig.masterToken);
        self.host = getHost(azureConfig.baseUrl);
        self.tokenType = TOKEN_TYPE_MASTER;
        self.tokenVersion = TOKEN_VERSION;
        self.httpClient = new (self.baseUrl);
    }

    # Create a database inside an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the new database. Must be unique.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function createDatabase(string databaseId, (int|json)? throughputOption = ()) returns @tainted Database|error {
        // Creating a new request
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES]);
        // Setting mandatory headers for the request
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, POST, requestPath);
        // Setting optional headers
        check setThroughputOrAutopilotHeader(request, throughputOption);

        // Setting a request payload
        json jsonPayload = {id: databaseId};
        request.setJsonPayload(jsonPayload);

        // Get the response
        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        // Map the payload and headers, of the request to a tuple 
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        // Map the reponse payload and the headers to a record type
        return mapJsonToDatabaseType(jsonResponse);
    }

    # Create a database inside an Azure Cosmos DB account only if the specified database ID does not exist already.
    # 
    # + databaseId - ID of the new database.
    # + throughputOption - Optional. Throughput parameter of type int OR json.
    # + return - If successful, returns cosmosdb:Database. Else returns error.  
    remote function createDatabaseIfNotExist(string databaseId, (int|json)? throughputOption = ()) returns @tainted 
           Database?|error {
        var result = self->createDatabase(databaseId);
        if result is error {
            if (result.detail()[STATUS].toString() == http:STATUS_CONFLICT.toString()) {
                return;
            }
        }
        return result;
    }

    # Delete a given database in an Azure Cosmos DB account.
    # 
    # + databaseId - ID of the database to delete.
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities 
    #       to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteDatabase(string databaseId, ResourceDeleteOptions? requestOptions = ()) returns @tainted 
            boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        //return <boolean>check handleResponse(response);  - this is the way in gmail connector
        json|error value = handleResponse(response);
        if (value is json) {
            return true;
        } else {
            return value;
        }
    }

    # Create a container in the given database.
    # 
    # + databaseId - ID of the database the container belongs to.
    # + containerId - ID of the new container container.
    # + partitionKey - A cosmosdb:PartitionKey.
    # + indexingPolicy - Optional. A cosmosdb:IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns cosmosdb:Container. Else returns error.  
    remote function createContainer(string databaseId, string containerId, PartitionKey partitionKey, 
            IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) returns @tainted Container|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, POST, requestPath);
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
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToContainerType(jsonResponse);
    }

    # Create a container inside an Azure Cosmos DB account only if the specified container ID does not exist already.
    # 
    # + databaseId - ID of the database the container belongs to.
    # + containerId - ID of the new container.    
    # + partitionKey - A cosmosdb:PartitionKey.
    # + indexingPolicy - Optional. A cosmosdb:IndexingPolicy.
    # + throughputOption - Optional. Throughput parameter of type int or json.
    # + return - If successful, returns Container if a new container is created or () if container already exists. 
    #       Else returns error.  
    remote function createContainerIfNotExist(string databaseId, string containerId, PartitionKey partitionKey, 
            IndexingPolicy? indexingPolicy = (), (int|json)? throughputOption = ()) returns @tainted Container?|error { 
        var result = self->createContainer(databaseId, containerId, partitionKey, indexingPolicy, throughputOption);
        if result is error {
            if (result.detail()[STATUS].toString() == http:STATUS_CONFLICT.toString()) {
                return;
            }
        }
        return result;
    }

    # Delete a given container in a database.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container to delete.
    # + requestOptions - Optional. The ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteContainer(string databaseId, string containerId, ResourceDeleteOptions? requestOptions = ()) 
            returns @tainted boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }
    }

    # Retrieve a list of partition key ranges for the container.
    # 
    # + databaseId - ID of the database which container belongs to.
    # + containerId - ID of the container where the partition key ranges are related to.    
    # + return - If successful, returns stream<cosmosdb:PartitionKeyRange>. Else returns error.  
    remote function listPartitionKeyRanges(string databaseId, string containerId) returns @tainted 
            stream<PartitionKeyRange>|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_COLLECTIONS, containerId, 
                RESOURCE_TYPE_PK_RANGES]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);

        PartitionKeyRange[] newArray = [];
        stream<PartitionKeyRange> partitionKeyStream = <stream<PartitionKeyRange>> check retriveStream(self.httpClient, 
                requestPath, request, newArray);
        return partitionKeyStream;
    }

    # Create a user in a database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of the new user.
    # + return - If successful, returns a User. Else returns error.
    remote function createUser(string databaseId, string userId) returns @tainted CreationResult|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, POST, requestPath);

        json reqBody = {id: userId};
        request.setJsonPayload(reqBody);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Replace the id of an existing user for a database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - Old ID of the user.
    # + newUserId - New ID for the user.
    # + return - If successful, returns a User. Else returns error.
    remote function replaceUserId(string databaseId, string userId, string newUserId) returns @tainted CreationResult|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, PUT, requestPath);

        json reqBody = {id: newUserId};
        request.setJsonPayload(reqBody);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # To get information of a user from a database.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user to get.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a User. Else returns error.
    remote function getUser(string databaseId, string userId, ResourceReadOptions? requestOptions = ()) returns @tainted 
            User|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToUserType(jsonResponse);
    }

    # Lists users in a database account.
    # 
    # + databaseId - ID of the database where users is created.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<User>. Else returns error.
    remote function listUsers(string databaseId, int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) 
            returns @tainted stream<User>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        User[] newArray = [];
        stream<User> userStream = <stream<User>> check retriveStream(self.httpClient, requestPath, request, newArray, 
                maxItemCount);
        return userStream;
    }

    # Delete a user from a database account.
    # 
    # + databaseId - ID of the database where user is created.
    # + userId - ID of user to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deleteUser(string databaseId, string userId, ResourceDeleteOptions? requestOptions = ()) 
            returns @tainted boolean|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }   
    }

    # Create a permission for a user. 
    # 
    # + databaseId - ID of the database where user is created.
    # + userId - ID of user to which the permission belongs.
    # + permission - A cosmosdb:Permission.
    # + validityPeriod - Optional. Validity period of the permission.
    # + return - If successful, returns a Permission. Else returns error.
    remote function createPermission(string databaseId, string userId, Permission permission, int? validityPeriod = ()) 
            returns @tainted CreationResult|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, POST, requestPath);
        if (validityPeriod is int) {
            check setExpiryHeader(request, validityPeriod);
        }

        json jsonPayload = {
            id: permission.id,
            permissionMode: permission.permissionMode,
            'resource: permission.resourcePath
        };
        request.setJsonPayload(jsonPayload);

        http:Response response = <http:Response> check self.httpClient->post(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Replace an existing permission.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user where the the permission is created.
    # + permission - A cosmosdb:Permission.
    # + validityPeriod - Optional. Validity period of the permission
    # + return - If successful, returns a Permission. Else returns error.
    remote function replacePermission(string databaseId, string userId, @tainted Permission permission, 
            int? validityPeriod = ()) returns @tainted CreationResult|error { 
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION, permission.id]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, PUT, requestPath);
        if (validityPeriod is int) {
            check setExpiryHeader(request, validityPeriod);
        }

        json jsonPayload = {
            id: permission.id,
            permissionMode: permission.permissionMode,
            'resource: permission.resourcePath
        };
        request.setJsonPayload(<@untainted>jsonPayload);

        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # To get information of a permission belongs to a user.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user where the the permission belongs to.
    # + permissionId - ID of the permission to get information.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a Permission. Else returns error.
    remote function getPermission(string databaseId, string userId, string permissionId, ResourceReadOptions? requestOptions = ()) 
            returns @tainted Permission|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToPermissionType(jsonResponse);
    }

    # Lists permissions belong to a user.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user where the the permissions is created.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<Permission>. Else returns error.
    remote function listPermissions(string databaseId, string userId, int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) 
            returns @tainted stream<Permission>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Permission[] newArray = [];
        stream<Permission> permissionStream = <stream<Permission>> check retriveStream(self.httpClient, requestPath, 
                request, newArray, maxItemCount);
        return permissionStream;
    }

    # Deletes a permission belongs to a user.
    # 
    # + databaseId - ID of the database where the user is created.
    # + userId - ID of user which the permission belongs to.
    # + permissionId - ID of the permission to delete.
    # + requestOptions - Optional. The cosmosdb:ResourceDeleteOptions which can be used to add addtional capabilities to the request.
    # + return - If successful, returns boolean specifying 'true' if delete is sucessful. Else returns error. 
    remote function deletePermission(string databaseId, string userId, string permissionId, ResourceDeleteOptions? requestOptions = ()) 
            returns @tainted boolean|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_DATABASES, databaseId, RESOURCE_TYPE_USER, userId, 
                RESOURCE_TYPE_PERMISSION, permissionId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, DELETE, requestPath);

        http:Response response = <http:Response> check self.httpClient->delete(requestPath, request);
        json|error value = handleResponse(response); 
        if (value is json) {
            return true;
        } else {
            return value;
        }   
    }

    # Replace an existing offer.
    # 
    # + offer - A cosmosdb:Offer.
    # + offerType - Optional. Type of the offer.
    # + return - If successful, returns a Offer. Else returns error.
    remote function replaceOffer(Offer offer, string? offerType = ()) returns @tainted CreationResult|error {
        http:Request request = new;
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offer.id]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, PUT, requestPath);

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
        [boolean, ResponseMetadata] jsonResponse = check mapCreationResponseToTuple(response);
        return mapJsonToResultType(jsonResponse);
    }

    # Get information about an offer.
    # 
    # + offerId - The ID of the offer.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a Offer. Else returns error.
    remote function getOffer(string offerId, ResourceReadOptions? requestOptions = ()) returns @tainted Offer|error {
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS, offerId]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);

        http:Response response = <http:Response> check self.httpClient->get(requestPath, request);
        [json, ResponseMetadata] jsonResponse = check mapResponseToTuple(response);
        return mapJsonToOfferType(jsonResponse);
    }

    # Gets information of offers inside database account.
    # 
    # Each Azure Cosmos DB collection is provisioned with an associated performance level represented as an 
    # Offer resource in the REST model. Azure Cosmos DB supports offers representing both user-defined performance 
    # levels and pre-defined performance levels. 
    # 
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceReadOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<Offer> Else returns error.
    remote function listOffers(int? maxItemCount = (), ResourceReadOptions? requestOptions = ()) returns @tainted 
            stream<Offer>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, GET, requestPath);
        if (maxItemCount is int) {
            request.setHeader(MAX_ITEM_COUNT_HEADER, maxItemCount.toString());
        }

        Offer[] newArray = [];
        stream<Offer> offerStream = <stream<Offer>> check retriveStream(self.httpClient, requestPath, request, newArray,
                maxItemCount);
        return offerStream;
    }

    # Perform queries on Offer resources.
    # 
    # + sqlQuery - SQL query.
    # + maxItemCount - Optional. Maximum number of records to obtain.
    # + requestOptions - Optional. The cosmosdb:ResourceQueryOptions which can be used to add addtional capabilities to 
    #       the request.
    # + return - If successful, returns a stream<Offer>. Else returns error.
    remote function queryOffer(Query sqlQuery, int? maxItemCount = (), ResourceQueryOptions? requestOptions = ()) 
            returns @tainted stream<Offer>|error { 
        http:Request request = new;
        check createRequest(request, requestOptions);
        string requestPath = prepareUrl([RESOURCE_TYPE_OFFERS]);
        check setMandatoryHeaders(request, self.host, self.masterToken, self.tokenType, self.tokenVersion, POST, requestPath);

        request.setJsonPayload(check sqlQuery.cloneWithType(json));
        setHeadersForQuery(request);

        Offer[] newArray = [];
        stream<Offer> offerStream = <stream<Offer>> check retriveStream(self.httpClient, requestPath, request, newArray, 
                maxItemCount, (), true);
        return offerStream;
    }
}
