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

# Represents configuration parameters to create Azure Cosmos DB client.
# 
# + baseUrl - Base URL of the Azure Cosmos DB account.
# + keyOrResourceToken - The token usesd to make the request call.
# + host - The host of the Azure Cosmos DB account.
# + tokenType - The type of token usesd to make the request call "master" or "resource". 
# + tokenVersion - The version of the token.
# + secureSocketConfig - The secure socket config.
public type AzureCosmosConfiguration record {|
    string baseUrl;
    string keyOrResourceToken;
    string host;
    string tokenType;
    string tokenVersion;
    http:ClientSecureSocket? secureSocketConfig;
|};

# Represents resource properties which are needed to make the request call.
# 
# + databaseId - Id of the database which the request is made.
# + containerId - Id of the container which the request is made.
public type ResourceProperties record {|
    string databaseId = "";
    string containerId = "";
|};

# Represents the common elements which are returned inside json reponse body.
# 
# + resourceId - Resource id (_rid), a unique identifier which is used internally for placement and navigation of the resource.
# + selfReference - Self reference (_self) unique addressable URI for the resource.
# + timeStamp - Timestamp (_ts) specifies the last updated timestamp of the resource.
# + eTag - Representing the resource etag (_etag) required for optimistic concurrency control. 
public type Common record {|
    string resourceId?;
    string selfReference?;
    string timeStamp?;
    string eTag?;
|};

# Represents the optional request headers which can be set in a request.
# 
# + isUpsertRequest - A boolean value which specify if the request is an upsert request.
# + indexingDirective - The option whether to include the document in the index. Allowed values are "Include" or "Exclude".
# + consistancyLevel - The consistancy level override. Allowed values are "Strong", "Bounded", "Sesssion" or "Eventual".
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy. 
# + changeFeedOption - Must be set to "Incremental feed" or omitted otherwise.
# + ifNoneMatch - Specify "*" to return all new changes, "<eTag>" to return changes made sice that timestamp or otherwise omitted.
# + partitionKeyRangeId - The partition key range ID for reading data.
# + enableCrossPartition -  Boolean value specifying whether to allow cross partitioning.
# + ifMatch - Used to make operation conditional for optimistic concurrency. 
public type RequestHeaderOptions record {|
    boolean? isUpsertRequest = ();
    string? indexingDirective = ();
    string? consistancyLevel = ();
    string? sessionToken = ();
    string? changeFeedOption = ();
    string? ifNoneMatch = ();
    string? partitionKeyRangeId = ();
    boolean? enableCrossPartition = ();
    string? ifMatch = ();
|};

# Represents the response headers which is returned.
# 
# + continuationHeader - A string token returned for queries and read-feed operations if there are more results to be read.
# + sessionTokenHeader - The session token of the request.
# + requestChargeHeader - This is the number of normalized requests a.k.a. request units (RU) for the operation.
# + resourceUsageHeader - Shows the current usage count of a resource in an account.  
# + itemCountHeader - The number of items returned for a query or read-feed request.
# + etagHeader - Shows the resource etag for the resource retrieved same as eTag in the response. 
# + dateHeader - The date time of the response operation.
public type Headers record {|
    string? continuationHeader = ();
    string? sessionTokenHeader = ();
    string? requestChargeHeader = ();
    string? resourceUsageHeader = ();
    string? itemCountHeader = ();
    string? etagHeader = ();
    string? dateHeader = ();
|};

# Represents the elements representing information about a database.
# 
# + id - Unique id created by the user.
# + collections - Specifies the addressable path of the collections resource.
# + users - Specifies the addressable path of the users resource.
public type Database record {|
    string id = "";
    *Common;
    string collections?;
    string users?;
    Headers?...;
|};

# Represents the elements representing information about a collection.
# 
# + id - Unique id created by the user.
# + collections - Specifies the addressable path of the collections resource.
# + storedProcedures - Specifies the addressable path of the stored procedures resource.
# + triggers - Specifies the addressable path of the triggers resource.
# + userDefinedFunctions - specifies the addressable path of the user-defined functions resource.
# + conflicts - Specifies the addressable path of the conflicts resource. 
# + allowMaterializedViews - Boolean representing whether to allow materialized views.
# + indexingPolicy - Object of type IndexingPolicy.
# + partitionKey - Object of type PartitionKey.
public type Container record {|
    string id = "";
    *Common;
    string collections?;
    string storedProcedures?;
    string triggers?;
    string userDefinedFunctions?;
    string conflicts?;
    boolean allowMaterializedViews?;
    IndexingPolicy indexingPolicy?;
    PartitionKey partitionKey?;
    Headers?...;
|};

# Represents the elements representing information about a document.
# 
# + id - Unique id created by the user.
# + documentBody - The bson document.
# + partitionKey - Array containing the value for the selected partition key.
# + attachments - Specifies the addressable path for the attachments resource.
public type Document record {|
    string id = "";
    *Common;
    json? documentBody = {};
    any[]? partitionKey = ();
    string attachments?;
    Headers?...;
|};

# Represents the elements representing information about a document.
# 
# + indexingMode - The mode of indexing.
# + automatic - A boolean specifying whether indexing is automatic.
# + includedPaths - Array of type included paths representing included paths.
# + excludedPaths - Array of type included paths representing excluded paths.
public type IndexingPolicy record {|
    string indexingMode = "";
    boolean automatic = true;
    IncludedPath[] includedPaths?;
    IncludedPath[] excludedPaths?;
|};

public type IncludedPath record {|
    string path = "";
    Index[] indexes?;
|};

public type ExcludedPath record {|
    string path?;
|};

public type Index record {|
    string kind = "";
    string dataType = "";
    int precision?;
|};

public type PartitionKey record {|
    string[] paths = [];
    string kind = "";
    int? keyVersion?;
|};

public type PartitionKeyList record {|
    string resourceId = "";
    PartitionKeyRange[] PartitionKeyRanges = [];
    Headers reponseHeaders?;
    int count = 0;
|};

public type PartitionKeyRange record {|
    string id = "";
    string minInclusive = "";
    string maxExclusive = "";
    int ridPrefix?;
    int throughputFraction?;
    string status = "";
    Headers reponseHeaders?;
|};

public type StoredProcedure record {|
    string id = "";
    *Common;
    string body = "";
    Headers?...;
|};

public type UserDefinedFunction record {|
    *StoredProcedure;
    Headers?...;
|};

public type Trigger record {|
    *StoredProcedure;
    string triggerOperation = "";
    string triggerType = "";
    Headers?...;
|};

public type User record {|
    string id = "";
    *Common;
    string permissions?;
    Headers?...;
|};

public type Permission record {|
    string id = "";
    *Common;
    string permissionMode = "";
    string resourcePath = "";
    int validityPeriod?;
    string token?;
    Headers?...;
|};

public type Offer record {|
    string id = "";
    *Common;
    string offerVersion = "";
    string? offerType?; 
    json content = {};
    string offerResourceId = "";
    string resourceSelfLink = "";
    Headers?...;
|};

public type ThroughputProperties record {
    int? throughput = ();
    json? maxThroughput = ();
};

public type HeaderParameters record {|
    string verb = "";
    string apiVersion = API_VERSION;
    string resourceType = "";
    string resourceId = "";
|};

public type AzureError distinct error;

type JsonMap map<json>;

public type Query record {|
    string query = "";
    QueryParameter[]? parameters = [];
|};

public type QueryParameter record {|
    string name = "";
    string value = "";
|};
