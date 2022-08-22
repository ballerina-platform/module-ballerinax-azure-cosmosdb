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

# Configuration parameters to create Azure Cosmos DB client.
# 
# + baseUrl - Base URL of the Azure Cosmos DB account
# + primaryKeyOrResourceToken - The token used to make the request call authorized
# + advanceClientConfig - Custom parameters for client creation
@display{label: "Connection Config"}
public type ConnectionConfig record {|
    @display{label: "Base URL"}
    string baseUrl;
    @display{label: "Primary Key"}
    string primaryKeyOrResourceToken;
    @display{label: "Advanced Client Config"}
    CustomClientConfiguration advanceClientConfig?;
|};

# Custom parameters for client creation
#
# + consistencyLevel - The ConsistencyLevel to be used By default, ConsistencyLevel.SESSION consistency will be used
# + directMode - The default DIRECT connection configuration to be used  
# + connectionSharingAcrossClientsEnabled - Enables connections sharing across multiple Cosmos Clients  
# + contentResponseOnWriteEnabled - The boolean to only return the headers and status code in Cosmos DB response 
# in case of Create, Update and Delete operations on CosmosItem  
# + preferredRegions - The preferred regions for geo-replicated database accounts  
# + userAgentSuffix - The value of the user-agent suffix
public type CustomClientConfiguration record {|
    @display{label: "Consistency Level"}
    ConsistencyLevel consistencyLevel;
    @display{label: "Direct mode"}
    DirectMode directMode;
    @display{label: "Cnnection Sharing Across Clients to be Enabled?"}
    boolean connectionSharingAcrossClientsEnabled;
    @display{label: "Content Response On Write to be Enabled?"}
    boolean contentResponseOnWriteEnabled;
    @display{label: "Preferred Regions"}
    string[] preferredRegions;
    @display{label: "User Agent Suffix"}
    string userAgentSuffix;
|};

# Represents DirectMode configuration.
#
# + directConnectionConfig - Direct Connection Configuration
# + gatewayConnectionConfig - Gateway Connection Configuration 
public type DirectMode record {|
    DirectConnectionConfig directConnectionConfig?;
    GatewayConnectionConfig gatewayConnectionConfig?;
|};

# Represents Gateway Connection Configuration
#
# + maxConnectionPoolSize - Max Connection Pool Size  
# + idleConnectionTimeout - Idle Connection Timeout  
public type GatewayConnectionConfig record {
    int maxConnectionPoolSize?;
    int idleConnectionTimeout?;
};

# Represents the direct connection configuration.
#
# + connectTimeout - Represents timeout for establishing connections with an endpoint (in seconds)
# + idleConnectionTimeout - The idle connection timeout (in seconds)
# + idleEndpointTimeout - Idle endpoint timeout Default value is 1 hour (in seconds)
# + maxConnectionsPerEndpoint - Max connections per endpoint This represents the size of connection pool for a specific endpoint Default value is 130  
# + maxRequestsPerConnection - Mmax requests per connection This represents the number of requests that will be queued on a single connection for a specific endpoint Default value is 30 
# + networkRequestTimeout - The network request timeout interval (time to wait for response from network peer).
# + connectionEndpointRediscoveryEnabled - Value indicating whether Direct TCP connection endpoint rediscovery should be enabled
public type DirectConnectionConfig record {
    int connectTimeout?;
    int idleConnectionTimeout?;
    int idleEndpointTimeout?;
    int maxConnectionsPerEndpoint?;
    int maxRequestsPerConnection?;
    int networkRequestTimeout?;
    boolean connectionEndpointRediscoveryEnabled?;
};

# Metadata headers which will return for a delete request.
# 
# + sessionToken - Session token from the response
@display{label: "Deletion Response"}
public type DeleteResponse record {|
    @display{label: "Session Token"}
    string sessionToken;
|};

# Common elements representing information.
# 
# + resourceId - A unique identifier which is used internally for placement and navigation of the resource
# + selfReference - A unique addressable URI for the resource
# + eTag - Resource etag for the resource retrieved
# + sessionToken - Session token of the request
@display{label: "Response Metadata"}
public type Commons record {|
    @display{label: "Resource Id"}
    string resourceId?;
    @display{label: "Self URI"}
    string selfReference?;
    @display{label: "ETag"}
    string eTag?;
    @display{label: "Session Token"}
    string sessionToken?;
|};

# Parameters representing information about a database.
# 
# + id - User generated unique ID for the database 
@display{label: "Database"}
public type Database record {|
    @display{label: "Database Name"}
    string id;
    *Commons;
|};

# Parameters representing information about a container.
# 
# + id - User generated unique ID for the container
# + indexingPolicy - Record of type `IndexingPolicy`
# + partitionKey - Record of type `PartitionKey`
@display{label: "Container"}
public type Container record {|
    @display{label: "Container Name"}
    string id;
    *Commons;
    @display{label: "Indexing Policy"}
    IndexingPolicy indexingPolicy;
    @display{label: "Partition Key Definition"}
    PartitionKey partitionKey;
|};

# Parameters representing information about a document.
# 
# + id - User generated unique ID for the document 
# + documentBody - The document reprsented as a map of json
@display{label: "Document"}
public type Document record {|
    @display{label: "Document Id"}
    string id;
    *Commons;
    @display{label: "Document Body"}
    map<json> documentBody;
|};


# Parameters necessary to create an indexing policy when creating a container.
# 
# + indexingMode - Mode of indexing. Can be `consistent` or `none`
# + automatic - Specify whether indexing is done automatically or not
#              - Must be `true` if indexing must be automatic and `false` otherwise.
# + includedPaths - Array of type `IncludedPath` representing included paths
# + excludedPaths - Array of type `IncludedPath` representing excluded paths
@display{label: "Indexing Policy"}
public type IndexingPolicy record {|
    @display{label: "Indexing Mode"}
    IndexingMode indexingMode?;
    @display{label: "Is Automated"}
    boolean automatic = true;
    @display{label: "Included Paths"}
    IncludedPath[] includedPaths?;
    @display{label: "Excluded Paths"}
    ExcludedPath[] excludedPaths?;
|};

# Parameters representing included path type.
# 
# + path - Path to which the indexing behavior applies to
# + indexes - Array of type `Index`, representing index values
@display{label: "Included Path"}
public type IncludedPath record {|
    @display{label: "Parameter Path"}
    string path;
    @display{label: "Index Values"}
    Index[] indexes = [];
|};

# Parameters representing excluded path type.
# 
# + path - Path that is excluded from indexing 
@display{label: "Excluded Path"}
public type ExcludedPath record {|
    @display{label: "Parameter Path"}
    string path;
|};

# Parameters representing an index. 
# 
# + kind - Type of index
#        - Can be `Hash`, `Range` or `Spatial`.
# + dataType - Datatype for which the indexing behavior is applied to
#            - Can be `String`, `Number`, `Point`, `Polygon` or `LineString`.
# + precision - Precision of the index
#             - Can be either set to -1 for maximum precision or between 1-8 for `Number`, and 1-100 for `String`
#             - Not applicable for `Point`, `Polygon`, and `LineString` data types. Default is -1.
@display{label: "Index"}
public type Index record {|
    @display{label: "Index Type"}
    IndexType kind = HASH;
    @display{label: "Indexing Data Type"}
    IndexDataType dataType = STRING;
    @display{label: "Precision of the Index"}
    int precision = MAX_PRECISION;
|};

# Parameters representing a partition key.
# 
# + paths - Array of paths using which, data within the collection can be partitioned. The array must contain only a
#           single value.
# + kind - Algorithm used for partitioning
#        - Only **Hash** is supported.
# + keyVersion - Version of partition key. Default is **1**. To use a large partition key, set the version to **2**. 
@display{label: "Partition Key Definition"}
public type PartitionKey record {|
    @display{label: "Partition Key Path"}
    string[] paths = [];
    @display{label: "Partitioning Algorithm"}
    readonly string kind = PARTITIONING_ALGORITHM_TYPE_HASH;
    @display{label: "Partition Key Version"}
    PartitionKeyVersion keyVersion = PARTITION_KEY_VERSION_1;
|};

# Parameters representing a stored procedure.
# 
# + id - User generated unique ID for the stored procedure
# + storedProcedure - A JavaScript function, respresented as a string
@display{label: "Stored Procedure"}
public type StoredProcedure record {|
    @display{label: "Stored Procedure Id"}
    string id;
    *Commons;
    @display{label: "Stored Procedure"}
    string storedProcedure;
|};

# Parameters representing a user defined function.
# 
# + id - User generated unique ID for the user defined function
# + userDefinedFunction - A JavaScript function, respresented as a string
@display{label: "User Defined Function"}
public type UserDefinedFunction record {|
    @display{label: "User Defined Function Id"}
    string id;
    *Commons;
    @display{label: "User Defined Function"}
    string userDefinedFunction;
|};

# Parameters representing a trigger.
# 
# + id - User generated unique ID for the trigger
# + triggerFunction - A JavaScript function, respresented as a string
# + triggerOperation - Type of operation that invokes the trigger
#                    - Can be `All`, `Create`, `Replace` or `Delete`.
# + triggerType - When the trigger is fired, `Pre` or `Post`
@display{label: "Trigger"}
public type Trigger record {|
    @display{label: "Trigger Id"}
    string id;
    *Commons;
    @display{label: "Trigger"}
    string triggerFunction;
    @display{label: "Triggered Operation"}
    TriggerOperation triggerOperation = ALL;
    @display{label: "Trigger Type"}
    TriggerType triggerType = PRE;
|};

# Parameters representing a partition key range.
# 
# + id - ID for the partition key range
# + minInclusive - Minimum partition key hash value for the partition key range
# + maxExclusive - Maximum partition key hash value for the partition key range
@display{label: "Partition Key Range"}
public type PartitionKeyRange record {|
    @display{label: "Partition Key Range Id"}
    string id;
    *Commons;
    @display{label: " Minimum Partition Key Hash"}
    string minInclusive;
    @display{label: " Maximum Partition Key Hash"}
    string maxExclusive;
|};

# Parameters representing a user.
# 
# + id - User generated unique ID for the user 
# + permissions - A system generated property that specifies the addressable path of the permissions resource
@display{label: "User"}
public type User record {|
    @display{label: "User Id"}
    string id;
    *Commons;
    @display{label: "Permission Path"}
    string permissions;
|};

# Parameters representing a permission.
# 
# + id - User generated unique ID for the permission
# + permissionMode - Access mode for the resource, Should be `All` or `Read`
# + resourcePath - Full addressable path of the resource associated with the permission
# + token - System generated `Resource-Token` for the particular resource and user
@display{label: "Permission"}
public type Permission record {|
    @display{label: "Permission Id"}
    string id;
    *Commons;
    @display{label: "Access Mode"}
    PermisssionMode permissionMode;
    @display{label: "Resource Path"}
    string resourcePath;
    @display{label: "Resource Token"}
    string token;
|};

# Parameters representing an offer.
# 
# + id - User generated unique ID for the offer
# + offerVersion - Offer version
#                - This value can be `V1` for pre-defined throughput levels and `V2` for user-defined throughput levels
# + offerType - Performance level for V1 offer version, allows `S1`, `S2` and `S3`.
# + content - Information about the offer
#           - For `V2` offers, it contains the throughput of the collection.
# + resourceResourceId - The resource id(_rid) of the collection
# + resourceSelfLink - The self-link(_self) of the collection
@display{label: "Offer"}
public type Offer record {|
    @display{label: "Offer Id"}
    string id;
    *Commons;
    @display{label: "Offer Version"}
    OfferVersion offerVersion;
    @display{label: "Offer Type"}
    OfferType offerType;
    @display{label: "Offer Information"}
    map<json> content;
    @display{label: "Resource Id"}
    string resourceResourceId;
    @display{label: "Self URI"}
    string resourceSelfLink;
|};

# Optional parameters which can be passed to the function when creating a document.
# 
# + indexingDirective - The option whether to include the document in the index
#                     - Allowed values are `Include` or `Exclude`.
# + isUpsertRequest - A boolean value which specify whether the request is an upsert request
# + consistancyLevel - Consistency level required for the request
# + contentResponseOnWriteEnabled - The boolean to only return the headers and status code in Cosmos DB response in case of Create, Update and Delete operations on CosmosItem
# + dedicatedGatewayRequestOptions - The Dedicated Gateway Request Options
# + ifMatchETag - The If-Match (ETag) associated with the request in the Azure Cosmos DB service
# + ifNoneMatchETag - The If-None-Match (ETag) associated with the request in the Azure Cosmos DB service
# + postTriggerInclude - Triggers to be invoked after the operation
# + preTriggerInclude - Triggers to be invoked before the operation
# + sessionToken - The token for use with session consistency
# + thresholdForDiagnosticsOnTracer - ThresholdForDiagnosticsOnTracer, if latency on CRUD operation is greater than this diagnostics will be sent to open telemetry exporter as events in tracer span of end to end CRUD api
# + throughputControlGroupName - The throughput control group name
@display{label: "Document Create Options"}
public type RequestOptions record {|
    @display{label: "Indexing Option"}
    IndexingDirective indexingDirective?;
    @display{label: "Is Upsert"}
    boolean isUpsertRequest = false;
    @display{label: "Consistency Level"}
    ConsistencyLevel consistancyLevel?;
    @display{label: "Content Response On Write to be Enabled"}
    boolean contentResponseOnWriteEnabled?;
    @display{label: "Dedicated Gateway Request Options"}
    DedicatedGatewayRequestOptions dedicatedGatewayRequestOptions?;
    @display{label: "If Match ETag"}
    string ifMatchETag?;
    @display{label: "If Match None ETag"}
    string ifNoneMatchETag?;
    @display{label: "Post Trigger Include"}
    string[] postTriggerInclude?;
    @display{label: "Pre Trigger Include"}
    string[] preTriggerInclude?;
    @display{label: "SessionToken"}
    string sessionToken?;
    @display{label: "Threshold For Diagnostics On Tracer"}
    int thresholdForDiagnosticsOnTracer?;
    @display{label: "Throughput Control Group Name"}
    string throughputControlGroupName?;
|};


# Query Options
#
# + consistencyLevel - Consistency level required for the request
# + dedicatedGatewayRequestOptions - Dedicated Gateway Request Options  
# + indexMetricsEnabled - Used to obtain the index metrics to understand how the query engine used existing indexes and
#                           could use potential new indexes.  
# + maxBufferedItemCount - Number of items that can be buffered client side during parallel query execution
# + maxDegreeOfParallelism - Number of concurrent operations run client side during parallel query execution
# + partitionKey - Used to identify the current request's target partition.  
# + queryMetricsEnabled - Option to enable/disable getting metrics relating to query execution on item query requests  
# + limitInKb - Option for item query requests in the Azure Cosmos DB service
# + scanInQueryEnabled - Option to allow scan on the queries which couldn't be served as indexing was opted out on the
#                        requested paths
# + sessionToken - Session token for use with session consistency  
# + thresholdForDiagnosticsOnTracer - If latency on query operation is greater than this diagnostics will be send to 
#                                       open telemetry exporter as events in tracer span of end to end CRUD api.
# + throughputControlGroupName - Throughput control group name.
public type QueryOptions record {
    @display{label: "Consistency Level"}
    ConsistencyLevel consistencyLevel?;
    @display{label: "Dedicated Gateway Request Options"}
    DedicatedGatewayRequestOptions dedicatedGatewayRequestOptions?;
    @display{label: "Index Metrics to be Enabled?"}
    boolean indexMetricsEnabled?;
    @display{label: "Max Buffered Item Count"}
    int maxBufferedItemCount?;
    @display{label: "Max Degree of Parallelism"}
    int maxDegreeOfParallelism?;
    @display{label: "Partitionkey"}
    int|float|decimal|string partitionKey?;
    @display{label: "Query Metrics to be Enabled?"}
    boolean queryMetricsEnabled?;
    @display{label: "Limit in Kb"}
    int limitInKb?;
    @display{label: "Scan In Query to be Enabled?"}
    boolean scanInQueryEnabled?;
    @display{label: "Session token"}
    string sessionToken?;
    @display{label: "Threshold for Diagnostics On Tracer"}
    int thresholdForDiagnosticsOnTracer?;
    @display{label: "Throughput Control Group Name"}
    string throughputControlGroupName?;
};


# Dedicated Gateway Request Options
#
# + maxIntegratedCacheStaleness - The staleness value associated with the request in the Azure CosmosDB service. 
public type DedicatedGatewayRequestOptions record {
    @display{label: "Max Integrated Cache Staleness"}
    int maxIntegratedCacheStaleness;
};

# Encapsulates options that can be specified for a request issued to cosmos stored procedure. 
#
# + ifMatchETag - The If-Match (ETag) associated with the request in the Azure Cosmos DB service 
# + ifNoneMatchETag - the If-None-Match (ETag) associated with the request in the Azure Cosmos DB service  
# + scriptLoggingEnabled - Sets whether Javascript stored procedure logging is enabled for the current request in the 
#                           Azure Cosmos DB database service or not  
# + sessionToken - The token for use with session consistency. 
public type CosmosStoredProcedureRequestOptions record {
    @display{label: "If Match ETag"}
    string ifMatchETag?;
    @display{label: "If None Match ETag"}
    string ifNoneMatchETag?;
    @display{label: "Script Logging to be Enabled"}
    boolean scriptLoggingEnabled?;
    @display{label: "Session Token"}
    string sessionToken?;
};

# Optional parameters which can be passed to the function when replacing a document.
# 
# + indexingDirective - The option whether to include the document in the index
#                     - Allowed values are 'Include' or 'Exclude'.
@display{label: "Document Replace Options"}
public type DocumentReplaceOptions record {|
    @display{label: "Indexing Option"}
    IndexingDirective indexingDirective?;
|};

# Optional parameters which can be passed to the function when listing information about the documents.
# 
# + consistancyLevel - The consistency level override
#                    - Allowed values are `Strong`, `Bounded`, `Session` or `Eventual`.
#                    - The override must be the same or weaker than the Cosmos DB account’s configured consistency level.
# + sessionToken - Echo the latest read value of `session token header` to acquire session level consistency 
# + changeFeedOption - Must be set to `Incremental feed` or omitted otherwise
# + partitionKeyRangeId - The partition key range ID for reading data
@display{label: "Document List Options"}
public type DocumentListOptions record {|
    @display{label: "Consistency Level Override"}
    ConsistencyLevel consistancyLevel?;
    @display{label: "Session Token"}
    string sessionToken?;
    @display{label: "Change Feed Option"}
    ChangeFeedOption changeFeedOption?;
    @display{label: "Partition Key Range Id"}
    string partitionKeyRangeId?;
|};

# The options which can be passed for execution of stored procedures.
# 
# + parameters - An array of parameters which has values match the function parameters of a stored procedure
# + cosmosStoredProcedureRequestOptions - 
@display{label: "Stored Procedure Execute Options"}
public type StoredProcedureExecuteOptions record {|
    @display{label: "Function Parameters"}
    string[] parameters = [];
    @display{label: "Cosmos Stored Procedure Request Options"}
    CosmosStoredProcedureRequestOptions cosmosStoredProcedureRequestOptions?;
|};

# Optional parameters which can be passed to the function when reading the information about other 
# resources in Cosmos DB such as Containers, StoredProcedures, Triggers, User Defined Functions, etc.
# 
# + consistancyLevel - The consistency level override
#                    - Allowed values are `Strong`, `Bounded`, `Session` or `Eventual`.
#                    - The override must be the same or weaker than the account’s configured consistency level.
# + sessionToken - Echo the latest read value of `sessionToken` to acquire session level consistency
@display{label: "Resource Read Options"}
public type ResourceReadOptions record {|
    @display{label: "Consistancy Level"}
    ConsistencyLevel consistancyLevel?;
    @display{label: "Session Token"}
    string sessionToken?;
|};

# Optional parameters which can be passed to the function when querying containers.
# 
# + consistancyLevel - The consistency level override
#                    - Allowed values are `Strong`, `Bounded`, `Session` or `Eventual`.
#                    - The override must be the same or weaker than the account’s configured consistency level.
# + sessionToken - Echo the latest read value of `sessionToken` to acquire session level consistency 
# + enableCrossPartition - Boolean value specifying whether to allow cross partitioning <br/> Default is `true` where, 
#                          it allows to query across all logical partitions.
# + partitionKey - Optional. The value of partition key field of the container.
@display{label: "Resource Query Options"}
public type ResourceQueryOptions record {|
    @display{label: "Consistancy Level"}
    ConsistencyLevel consistancyLevel?;
    @display{label: "Session Token"}
    string sessionToken?;
    @display{label: "Enable/Disale Cross Partitioning"}
    boolean enableCrossPartition = true;
    @display{label: "Value of the Partition Key"}
    (int|float|decimal|string)? partitionKey = ();
|};

# Optional parameters which can be passed to the function when deleting other resources in Cosmos DB.
# 
# + sessionToken - Echo the latest read value of `sessionToken` to acquire session level consistency
@display{label: "Resource Delete Options"}
public type ResourceDeleteOptions record {|
    @display{label: "Session Token"}
    string sessionToken?;
|};

type Options RequestOptions|DocumentReplaceOptions|DocumentListOptions|ResourceReadOptions|
    ResourceQueryOptions|ResourceDeleteOptions;

# Document response.
#
# + activityId - Activity ID for the request
# + currentResourceQuotaUsage - Current size of this entity (in megabytes (MB) for server resources and in count for master resources)  
# + maxResourceQuota - Maximum size limit for this entity (in megabytes (MB) for server resources and in count for master resources).  
# + etag - ETag from the response headers
# + responseHeaders - Headers associated with the response.
# + sessionToken - Token used for managing client's consistency requirements.  
# + statusCode - HTTP status code associated with the response
# + requestCharge - Request charge as request units (RU) consumed by the operation
# + duration - End-to-end request latency for the current request to Azure Cosmos DB service 
# + diagnostics - Diagnostics information for the current request to Azure Cosmos DB service  
# + item - Field Description  
public type DocumentResponse record {
    string activityId;
    string currentResourceQuotaUsage;
    string maxResourceQuota;
    string? etag?;
    map<string> responseHeaders;
    string sessionToken;
    int statusCode;
    float requestCharge;
    int duration;
    Diagnostics diagnostics?;
    json? item?;
};

# Stored procedure response.
#
# + activityId -  Activity ID for the request 
# + requestCharge - Request charge as request units (RU) consumed by the operation  
# + responseAsString - Response of the stored procedure as a string  
# + scriptLog - Output from stored procedure console.log() statements
# + sessionToken - Token used for managing client's consistency requirements
# + statusCode - HTTP status code associated with the response
public type StoredProcedureResponse record {
    string activityId;
    float requestCharge;
    string? responseAsString?;
    string? scriptLog?;
    string sessionToken;
    int statusCode;
};

#  Diagnostic statistics associated with a request to Azure Cosmos DB.
#
# + regionsContacted - Regions contacted for this request  
# + duration - Response Diagnostic String 
public type Diagnostics record {
    string[] regionsContacted?;
    int duration;
};
