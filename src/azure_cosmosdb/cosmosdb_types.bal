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
# + id - The user generated unique name for the database. 
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
# + id - The user generated unique name for the container. 
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
    IndexingPolicy indexingPolicy?;
    PartitionKey partitionKey = {};
    string collections?;
    string storedProcedures?;
    string triggers?;
    string userDefinedFunctions?;
    string conflicts?;
    boolean allowMaterializedViews?;
    Headers?...;
|};

# Represents the elements representing information about a document.
# 
# + id - The user generated unique name for the document. 
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
    boolean automatic?;
    IncludedPath[] includedPaths?;
    IncludedPath[] excludedPaths?;
|};

# Represent the structure of included path type.
# 
# + path - A string specifying the path for which the indexing behavior applies to.
# + indexes - An array of index values.
public type IncludedPath record {|
    string path = "";
    Index[] indexes?;
|};

# Represent the structure of excluded path type.
# 
# + path - Path that is excluded from indexing. 
public type ExcludedPath record {|
    string path?;
|};

# Represent the record type with elements represent an index. 
# 
# + kind - The type of index. Can be "Hash", "Range" or "Spatial"
# + dataType - The datatype for which the indexing behavior is applied to. Can be "String", "Number", "Point", "Polygon" 
#   or "LineString"
# + precision - The precision of the index. Can be either set to -1 for maximum precision or between 1-8 for Number, 
#   and 1-100 for String. Not applicable for Point, Polygon, and LineString data types.
public type Index record {|
    string kind = "";
    string dataType = "";
    int precision?;
|};

# Represent the record type with elements represent a partition key.
# 
# + paths - An array of paths using which data within the collection can be partitioned. The array must contain only a 
#   single value.
# + kind - The algorithm used for partitioning. Only Hash is supported.
# + keyVersion - An optional field, if not specified the default value is 1. To use the large partition key, set the 
#   version to 2.
public type PartitionKey record {|
    string[] paths = [];
    string kind = "";
    int keyVersion?;
|};

# Reprsnets the record type with necessary paramaters to create partition key list.
# 
# + resourceId - 
# + PartitionKeyRanges -
# + count - 
public type PartitionKeyList record {|
    string resourceId = "";
    PartitionKeyRange[] PartitionKeyRanges = [];
    int count?;
    Headers?...;
|};

# Reprsnets the record type with necessary paramaters to create partition key range.
# 
# + id - The ID for the partition key range.
# + minInclusive - The maximum partition key hash value for the partition key range. 
# + maxExclusive - The minimum partition key hash value for the partition key range. 
# + status - 
public type PartitionKeyRange record {|
    string id = "";
    *Common;
    string minInclusive = "";
    string maxExclusive = "";
    string status = "";
    Headers?...;
|};

# Represent the record type with elements represent a stored procedure.
# 
# + id - The user generated unique name for the stored procedure. 
# + body - The body of the stored procedure.
public type StoredProcedure record {|
    string id = "";
    *Common;
    string body = "";
    Headers?...;
|};

public type UserDefinedFunction record {|
    string id = "";
    *Common;
    string body = "";    
    Headers?...;
|};

# Represent the record type with elements represent a trigger.
# 
# + triggerOperation - The type of operation that invokes the trigger. Can be "All", "Create", "Replace" or "Delete".
# + triggerType - Specifies when the trigger is fired, "Pre" or "Post".
public type Trigger record {|
    *StoredProcedure;
    string triggerOperation = "";
    string triggerType = "";
    Headers?...;
|};

# Represent the record type with elements represent a user.
# 
# + id - The user generated unique name for the user. 
# + permissions - The addressable path of the permissions resource.
public type User record {|
    string id = "";
    *Common;
    string permissions?;
    Headers?...;
|};

# Represent the record type with elements represent a permission.
# 
# + id - The user generated unique name for the permission.
# + permissionMode - The access mode for the resource, "All" or "Read".
# + resourcePath - The full addressable path of the resource associated with the permission.
# + validityPeriod - The validity period of the resource token.
# + token - A system generated resource token for the particular resource and user.
public type Permission record {|
    string id = "";
    *Common;
    string permissionMode = "";
    string resourcePath = "";
    int validityPeriod?;
    string token?;
    Headers?...;
|};

# Represent the record type with elements represent an offer.
# 
# + id - The user generated unique name for the offer.
# + offerVersion - Offer version, This value can be V1 for pre-defined throughput levels and V2 for user-defined throughput levels.
# + offerType - Indicates the performance level for V1 offer version, allows S1,S2 and S3.
# + content - Contains information about the offer.
# + offerResourceId - A property which is automatically done, associated to the resource ID(_rid).
# + resourceSelfLink - When creating a new collection, this property is set to the self-link of the collection.
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

# Represent the record type with options represent for throughput.
# 
# + throughput - The manual throughput value which must be more than 400RU/s.
# + maxThroughput - The autoscaling throughout which is represented as a json object.
public type ThroughputProperties record {
    int? throughput = ();
    json? maxThroughput = ();
};

# Represent the record type with the necessary paramateres for creation of authorization signature.
# 
# + verb - HTTP verb of the request call.
# + apiVersion - Version of the API as given by the user.
# + resourceType - The resource type, the relevent request targetted to.
# + resourceId - The resource ID, the relevent request targetted to.
public type HeaderParameters record {|
    string verb = "";
    string apiVersion = API_VERSION;
    string resourceType = "";
    string resourceId = "";
|};

public type AzureError distinct error;

type JsonMap map<json>;

# Represents the record type which contain necessary elements for a query.
# 
# + query - The SQL query represented as string.
# + parameters - Parameters of the query if exists.
public type Query record {|
    string query = "";
    QueryParameter[]? parameters = [];
|};

# Represnent the paramaters related to query.
# 
# + name - Name of the paramater.
# + value - Value of the paramater.
public type QueryParameter record {|
    string name = "";
    string value = "";
|};
