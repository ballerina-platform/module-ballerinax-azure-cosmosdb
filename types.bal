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

# Represents configuration parameters to create Azure Cosmos DB client.
# 
# + baseUrl - Base URL of the Azure Cosmos DB account
# + masterOrResourceToken - The token used to make the request call authorized
public type AzureCosmosConfiguration record {|
    string baseUrl;
    string masterOrResourceToken;
|};

# Represents the response headers which is returned.
# 
# + continuationHeader - Token returned for queries and read-feed operations if there are more results to be read
# + sessionToken - Session token of the request
# + eTag - Resource etag for the resource retrieved
public type ResponseHeaders record {|
    string? continuationHeader = ();
    string sessionToken = "";
    string eTag = "";
|};

# Represents information about the status of the relevent create, update or delete request.
# 
# + success - A boolean representing the success status of the request
# + eTag - Resource etag for the resource
# + sessionToken - Session token of the request
public type Result record {|
    boolean success = false;
    string eTag = "";
    string sessionToken = "";
|};

# Represents the common elements representing information.
# 
# + resourceId - Resource id (_rid) - A unique identifier which is used internally for placement and navigation of the 
#          resource
# + selfReference - Self reference (_self) - A unique addressable URI for the resource
# + eTag - Resource etag for the resource retrieved
# + sessionToken - Session token of the request
public type Commons record {|
    string resourceId = "";
    string selfReference = "";
    string eTag = "";
    string sessionToken = "";
|};

# Represents the elements representing information about a database.
# 
# + id - User generated unique ID for the database 
public type Database record {|
    string id = "";
    *Commons;
|};

# Represents the elements representing information about a collection.
# 
# + id - User generated unique ID for the container
# + indexingPolicy - Record of type IndexingPolicy
# + partitionKey - Record of type PartitionKey
public type Container record {|
    string id = "";
    *Commons;
    IndexingPolicy indexingPolicy = {};
    PartitionKey partitionKey = {};
|};

# Represent the parameters representing information about a document in Cosmos DB.
# 
# + id - User generated unique ID for the document 
# + documentBody - JSON document
public type Document record {|
    string id = "";
    *Commons;
    json documentBody = {};
|};

# Represent the parameters necessary to create an indexing policy when creating a container.
# 
# + indexingMode - Mode of indexing
# + automatic - Whether indexing is automatic or not
# + includedPaths - Array of type IncludedPath representing included paths
# + excludedPaths - Array of type IncludedPath representing excluded paths
public type IndexingPolicy record {|
    string indexingMode = "";
    boolean automatic = true;
    IncludedPath[] includedPaths?;
    ExcludedPath[] excludedPaths?;
|};

# Represent the necessary parameters of included path type.
# 
# + path - Path for which the indexing behavior applies to
# + indexes - Array of type Index representing index values
public type IncludedPath record {|
    string path = "";
    Index[] indexes = [];
|};

# Represent the necessary parameters of excluded path type.
# 
# + path - Path that is excluded from indexing 
public type ExcludedPath record {|
    string path = "";
|};

# Represent the record type with necessary parameters to represent an index. 
# 
# + kind - Type of index. Can be `HASH`, `RANGE` or `SPATIAL`
# + dataType - Datatype for which the indexing behavior is applied to. Can be `String`, `Number`, `Point`, `Polygon` 
#        or `LineString`
# + precision - Precision of the index. Can be either set to -1 for maximum precision or between 1-8 for Number, 
#        and 1-100 for String. Not applicable for Point, Polygon, and LineString data types. Default is -1.
public type Index record {|
    IndexType kind = HASH;
    IndexDataType dataType = STRING;
    int precision = MAX_PRECISION;
|};

# Represent the record type with necessary parameters to represent a partition key.
# 
# + paths - Array of paths using which data within the collection can be partitioned. The array must contain only a 
#          single value.
# + kind - Algorithm used for partitioning. Only `Hash` is supported.
# + keyVersion - Version of partition key
public type PartitionKey record {|
    string[] paths = [];
    readonly string kind = PARTITIONING_ALGORITHM_TYPE_HASH;
    int keyVersion = DEFAULT_PARTITION_KEY_VERSION;
|};

# Represent the record type with necessary parameters to represent a stored procedure.
# 
# + id - User generated unique ID for the stored procedure
# + storedProcedure - JavaScript function
public type StoredProcedure record {|
    string id = "";
    *Commons;
    string storedProcedure = "";
|};

# Represent the record type with necessary parameters to represent a user defined function.
# 
# + id - User generated unique ID for the user defined function
# + userDefinedFunction - JavaScript function
public type UserDefinedFunction record {|
    string id = "";
    *Commons;
    string userDefinedFunction = "";
|};

# Represent the record type with necessary parameters to represent a trigger.
# 
# + id - User generated unique ID for the trigger
# + triggerFunction - JavaScript function
# + triggerOperation - Type of operation that invokes the trigger. Can be `All`, `Create`, `Replace` or `Delete`. 
# + triggerType - When the trigger is fired, `Pre` or `Post`
public type Trigger record {|
    string id = "";
    *Commons;
    string triggerFunction = "";
    TriggerOperation triggerOperation = ALL; 
    TriggerType triggerType = PRE;
|};

type JsonMap map<json>;

// ---------------------------------------------Managment Plane---------------------------------------------------------

# Represent the record type with necessary parameters to create partition key range.
# 
# + id - ID for the partition key range
# + minInclusive - Minimum partition key hash value for the partition key range 
# + maxExclusive - Maximum partition key hash value for the partition key range
public type PartitionKeyRange record {|
    string id = "";
    *Commons;
    string minInclusive = "";
    string maxExclusive = "";
|};

# Represent the record type with necessary parameters to represent a user.
# 
# + id - User generated unique ID for the user 
# + permissions - A system generated property that specifies the addressable path of the permissions resource
public type User record {|
    string id = "";
    *Commons;
    string permissions = "";
|};


# Represent the record type with necessary parameters to represent a permission.
# 
# + id - User generated unique ID for the permission
# + permissionMode - Access mode for the resource, Should be `All` or `Read`
# + resourcePath - Full addressable path of the resource associated with the permission
# + validityPeriodInSeconds - Optional. Validity period of the Resource Token.
# + token - System generated `Resource Token` for the particular resource and user
public type Permission record {|
    string id = "";
    *Commons;
    PermisssionMode permissionMode = ALL_PERMISSIONS;
    string resourcePath = "";
    int validityPeriodInSeconds = MIN_TIME_TO_LIVE_IN_SECONDS;
    string token = "";
|};

# Represent the record type with necessary parameters to represent an offer.
# 
# + id - User generated unique ID for the offer
# + offerVersion - Offer version, This value can be `V1` for pre-defined throughput levels and `V2` for user-defined 
#          throughput levels
# + offerType - Optional. Performance level for V1 offer version, allows `S1`, `S2` and `S3`.
# + content - Information about the offer
# + resourceResourceId - The resource id(_rid) of the collection
# + resourceSelfLink - The self-link of the collection
public type Offer record {|
    string id = "";
    *Commons;
    OfferVersion offerVersion = USER_DEFINED;
    string offerType = INVALID;
    json content = {};
    string resourceResourceId = "";
    string resourceSelfLink = "";
|};
