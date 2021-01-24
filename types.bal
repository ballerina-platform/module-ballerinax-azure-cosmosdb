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

# Represents configuration parameters to create Azure Cosmos DB client.
# 
# + baseUrl - Base URL of the Azure Cosmos DB account.
# + masterOrResourceToken - The token used to make the request call.
public type AzureCosmosConfiguration record {|
    string baseUrl;
    string masterOrResourceToken;
|};

# Represents the common elements which are returned inside json reponse body.
# 
# + resourceId - Resource id (_rid), a unique identifier which is used internally for placement and navigation of the resource.
# + selfReference - Self reference (_self) unique addressable URI for the resource.
# + timeStamp - Timestamp (_ts) specifies the last updated timestamp of the resource.
public type Common record {|
    string resourceId = "";
    string selfReference = "";
    string timeStamp = "";
    ResponseMetadata responseHeaders = {};
|};

# Represents the response headers which is returned.
# 
# + continuationHeader - Token returned for queries and read-feed operations if there are more results to be read.
# + sessionToken - Session token of the request.
# + requestCharge - This is the number of normalized requests a.k.a. request units (RU) for the operation.
# + resourceUsage - Current usage count of a resource in an account.  
//# + itemCount - Number of items returned for a query or read-feed request.
# + etag - Resource etag for the resource retrieved same as eTag in the response. 
# + date - Date time of the response operation.
public type ResponseMetadata record {|
    string? continuationHeader?;
    string sessionToken?;
    string requestCharge?;
    string resourceUsage?;
    string etag?;
    string date?;
|};

# Represents the elements representing information about a database.
# 
# + id - User generated unique ID for the database. 
public type Database record {|
    string id = "";
    *Common;
|};

# Represents the elements representing information about a collection.
# 
# + id - User generated unique ID for the container.
# + indexingPolicy - Object of type IndexingPolicy. 
# + partitionKey - Object of type PartitionKey.
# + allowMaterializedViews - Representing whether to allow materialized views.
public type Container record {|
    string id = "";
    *Common;
    IndexingPolicy indexingPolicy?;
    PartitionKey partitionKey = {};
    boolean allowMaterializedViews?;
    ResponseMetadata?...;
|};

# Represent the parameters representing information about a document in Cosmos DB.
# 
# + id - User generated unique ID for the document. 
# + documentBody - BSON document.
public type Document record {|
    string id = "";
    *Common;
    json documentBody = {};
    ResponseMetadata?...;
|};

# Represent the parameters necessary to create an indexing policy when creating a container.
# 
# + indexingMode - Mode of indexing.
# + automatic - Whether indexing is automatic.
# + includedPaths - Array of type IncludedPath representing included paths.
# + excludedPaths - Array of type IncludedPath representing excluded paths.
public type IndexingPolicy record {|
    string indexingMode = "";
    boolean automatic?;
    IncludedPath[] includedPaths?;
    IncludedPath[] excludedPaths?;
|};

# Represent the necessary parameters of included path type.
# 
# + path - Path for which the indexing behavior applies to.
# + indexes - Array of type Index representing index values.
public type IncludedPath record {|
    string path = "";
    Index[] indexes?;
|};

# Represent the necessary parameters of excluded path type.
# 
# + path - Path that is excluded from indexing. 
public type ExcludedPath record {|
    string path?;
|};

# Represent the record type with necessary parameters to represent an index. 
# 
# + kind - Type of index. Can be "Hash", "Range" or "Spatial"
# + dataType - Datatype for which the indexing behavior is applied to. Can be "String", "Number", "Point", "Polygon" 
#               or "LineString"
# + precision - Precision of the index. Can be either set to -1 for maximum precision or between 1-8 for Number, 
#                   and 1-100 for String. Not applicable for Point, Polygon, and LineString data types.
public type Index record {|
    string kind = "";
    string dataType = "";
    int precision?;
|};

# Represent the record type with necessary parameters to represent a partition key.
# 
# + paths - Array of paths using which data within the collection can be partitioned. The array must contain only a 
#               single value.
# + kind - Algorithm used for partitioning. Only Hash is supported.
# + keyVersion - Version of partition key.
public type PartitionKey record {|
    string[] paths = [];
    string kind = "Hash";
    int keyVersion = 1;
|};

# Reprsent the record type with necessary paramaters to create partition key range.
# 
# + id - ID for the partition key range.
# + minInclusive - Minimum partition key hash value for the partition key range. 
# + maxExclusive - Maximum partition key hash value for the partition key range. 
# + status - 
public type PartitionKeyRange record {|
    string id = "";
    *Common;
    string minInclusive = "";
    string maxExclusive = "";
    string status = "";
    ResponseMetadata?...;
|};

# Represent the record type with necessary parameters to represent a stored procedure.
# 
# + id - User generated unique ID for the stored procedure. 
# + body - Body of the stored procedure.
public type StoredProcedure record {|
    string id = "";
    string body = "";
|};

public type StoredProcedureResponse record {|
    *StoredProcedure;
    *Common;
|};

public type UserDefinedFunction record {|
    string id = "";
    string body = "";
|};

public type UserDefinedFunctionResponse record {|
    *UserDefinedFunction;
    *Common;
|};

# Represent the record type with necessary parameters to represent a trigger.
# 
# + triggerOperation - Type of operation that invokes the trigger. Can be "All", "Create", "Replace" or "Delete".
# + triggerType - When the trigger is fired, "Pre" or "Post".
public type Trigger record {|
    *StoredProcedure;
    string triggerOperation = "";
    string triggerType = "";
|};

public type TriggerResponse record {|
    *Trigger;
    *Common;
|};

# Represent the record type with necessary parameters to represent a user.
# 
# + id - User generated unique ID for the user. 
# + permissions - Addressable path of the permissions resource.
public type User record {|
    string id = "";
    *Common;
    string permissions?;
    ResponseMetadata?...;
|};

# Represent the record type with necessary parameters to represent a permission.
# 
# + id - User generated unique ID for the permission.
# + permissionMode - Access mode for the resource, "All" or "Read".
# + resourcePath - Full addressable path of the resource associated with the permission.
# + validityPeriod - Optional. Validity period of the resource token.
# + token - System generated resource token for the particular resource and user.
public type Permission record {|
    string id = "";
    *Common;
    string permissionMode = "";
    string resourcePath = "";
    int validityPeriod?;
    string token?;
    ResponseMetadata?...;
|};

# Represent the record type with necessary parameters to represent an offer.
# 
# + id - User generated unique ID for the offer.
# + offerVersion - Offer version, This value can be V1 for pre-defined throughput levels and V2 for user-defined throughput levels.
# + offerType - Optional. Performance level for V1 offer version, allows S1,S2 and S3.
# + content - Information about the offer.
# + resourceResourceId - The resource id(_rid) of the collection.
# + resourceSelfLink - The self-link of the collection.
public type Offer record {|
    string id = "";
    *Common;
    string offerVersion = "";
    string? offerType?;
    json content = {};
    string resourceResourceId = "";
    string resourceSelfLink = "";
    ResponseMetadata?...;
|};

# Represent the record type with the necessary paramateres for creation of authorization signature.
# 
# + verb - HTTP verb of the request call.
# + apiVersion - Version of the API.
# + resourceType - Resource type, the relevent request targetted to.
# + resourceId - Resource ID, the relevent request targetted to.
type HeaderParameters record {|
    string verb = "";
    string apiVersion = API_VERSION;
    string resourceType = "";
    string resourceId = "";
|};

type JsonMap map<json>;

# Represents the record type which contain necessary elements for a query.
# 
# + query - The SQL query represented as string.
# + parameters - Parameters of the query if exists.
public type Query record {|
    string query = "";
    QueryParameter[]? parameters = [];
|};

# Represents the paramaters related to query.
# 
# + name - Name of the parameter.
# + value - Value of the parameter.
public type QueryParameter record {|
    string name = "";
    string|int|boolean value = "";
|};
