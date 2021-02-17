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

# Represents the Consistency Level Override for document create and update.
# 
# + STRONG - `Strong` consistency level where Users are always guaranteed to read the latest committed write
# + BOUNDED - `Bounded` consistency level where Reads might lag behind writes behind at most K updates of an item or by 
#              T time interval
# + SESSION - `Session` consistency level where in a single client session reads are guaranteed to honor the 
#              consistent-prefix, monotonic reads, monotonic writes, read-your-writes, and write-follows-reads 
#              guarantees
# + EVENTUAL - `Eventual` consistency level where there's no ordering guarantee for reads. In the absence of any further 
#               writes, the replicas eventually converge.
public enum ConsistencyLevel {
    STRONG = "Strong",
    BOUNDED = "Bounded",
    SESSION = "Session",
    EVENTUAL = "Eventual"
}

# Represents whether to include or exclude the document in indexing.
#
# + INCLUDE - `Include` adds the document to the index
# + EXCLUDE - `Exclude` omits the document from indexing     
public enum IndexingDirective {
    INCLUDE = "Include",
    EXCLUDE = "Exclude"
}

# Represents the type of an Index.
# 
# + HASH - `Hash` indexes are useful for equality comparisons
# + RANGE - `Range` indexes are useful for equality, range comparisons and sorting
# + SPATIAL - `Spatial` indexes are useful for spatial queries
public enum IndexType {
    HASH = "Hash",
    RANGE = "Range",
    SPATIAL = "Spatial"
}

# The datatype for which the indexing behavior is applied to.
# 
# + STRING - Represents a string data type
# + NUMBER - Represents a numeric data type
# + POINT - Represents a point data type
# + POLYGON - Represents a polygon data type
# + LINESTRING - Represents a line string data type
public enum IndexDataType {
    STRING = "String",
    NUMBER = "Number",
    POINT = "Point",
    POLYGON = "Polygon",
    LINESTRING = "LineString"
}

# Type of operation that invokes the trigger.
# 
# + ALL - `All` where trigger fires in all create, replace and delete operations
# + CREATE - `Create` trigger fires only in a create operations
# + REPLACE - `Replace` trigger fires only in a replace operations
# + DELETE - `Delete` trigger fires only in a delete operations
public enum TriggerOperation {
    ALL = "All",
    CREATE = "Create",
    REPLACE = "Replace",
    DELETE = "Delete"
}

# When is the trigger is fired.
# 
# + PRE - `Pre` triggers fire before an operation 
# + POST - `Post` triggers fires after an operation
public enum TriggerType {
    PRE = "Pre",
    POST = "Post"
}

# The access mode for the resource.
# + ALL_PERMISSION - `All` provides read, write, and delete access to a resource
# + READ_PERMISSION - `Read` restricts the user to read access on the resource
public enum PermisssionMode {
    ALL_PERMISSION = "All",
    READ_PERMISSION = "Read"
}

# The specific version for a given offer.
# 
# + PRE_DEFINED - `V1` represents pre-defined throughput levels
# + USER_DEFINED - `V2` represents user-defined throughput levels
public enum OfferVersion {
    PRE_DEFINED = "V1",
    USER_DEFINED = "V2"
}

# The performance levels for a specific throughput level.
# 
# + LEVEL_S1 - `S1` represents performance level for pre-defined throughput level 
# + LEVEL_S2 - `S2` represents performance level for pre-defined throughput level
# + LEVEL_S3 - `S3` represents performance level for pre-defined throughput level
# + INVALID - The performance level is set `Invalid` for `V2` user-defined throughput levels
public enum OfferType {
    LEVEL_S1 = "S1",
    LEVEL_S2 = "S2",
    LEVEL_S3 = "S3",
    INVALID = "Invalid"
}

# Use to retrieve only the incremental changes to documents within the collection.
# 
# + INCREMENTAL - Must be set to `Incremental feed`, or omitted otherwise
public enum ChangeFeedOption {
    INCREMENTAL = "Incremental feed"
}

# Indexing Policy
const string INDEXING_TYPE_INCLUDE = "Include";
const string INDEXING_TYPE_EXCLUDE = "Exclude";
const int MAX_PRECISION = -1;

# Request headers
const string API_VERSION_HEADER = "x-ms-version";
const string HOST_HEADER = "Host";
const string ACCEPT_HEADER = "Accept";
const string DATE_HEADER = "x-ms-date";
const string THROUGHPUT_HEADER = "x-ms-offer-throughput";
const string AUTOPILET_THROUGHPUT_HEADER = "x-ms-cosmos-offer-autopilot-settings";
const string INDEXING_DIRECTIVE_HEADER = "x-ms-indexing-directive";
const string IS_UPSERT_HEADER = "x-ms-documentdb-is-upsert";
const string MAX_ITEM_COUNT_HEADER = "x-ms-max-item-count";
const string CONSISTANCY_LEVEL_HEADER = "x-ms-consistency-level";
const string A_IM_HEADER = "A-IM";
const string PARTITIONKEY_RANGE_HEADER = "x-ms-documentdb-partitionkeyrangeid";
const string ISQUERY_HEADER = "x-ms-documentdb-isquery";
const string PARTITION_KEY_HEADER = "x-ms-documentdb-partitionkey";
const string EXPIRY_HEADER = "x-ms-documentdb-expiry-seconds";
const string IS_ENABLE_CROSS_PARTITION_HEADER = "x-ms-documentdb-query-enablecrosspartition";

# Values for request headers
const string CONTENT_TYPE_QUERY = "application/query+json";
const string ACCEPT_ALL = "*/*";
const string CONNECTION_KEEP_ALIVE = "keep-alive";

# Response headers
const string CONTINUATION_HEADER = "x-ms-continuation";
const string SESSION_TOKEN_HEADER = "x-ms-session-token";
const string REQUEST_CHARGE_HEADER = "x-ms-request-charge";
const string RETRY_AFTER_MILLISECONDS = "x-ms-retry-after-ms";
const string ITEM_COUNT_HEADER = "x-ms-item-count";

# Time Zone
const string GMT_ZONE = "Europe/London";
const string TIME_ZONE_FORMAT = "EEE, dd MMM yyyy HH:mm:ss z";

# Resources
const string RESOURCE_TYPE_DATABASES = "dbs";
const string RESOURCE_TYPE_COLLECTIONS = "colls";
const string RESOURCE_TYPE_DOCUMENTS = "docs";
const string RESOURCE_TYPE_STORED_POCEDURES = "sprocs";
const string RESOURCE_TYPE_PK_RANGES = "pkranges";
const string RESOURCE_TYPE_UDF = "udfs";
const string RESOURCE_TYPE_TRIGGER = "triggers";
const string RESOURCE_TYPE_USER = "users";
const string RESOURCE_TYPE_PERMISSION = "permissions";
const string RESOURCE_TYPE_OFFERS = "offers";

# Cosmos DB SQL API version
const string API_VERSION = "2018-12-31";

# Token information
const string TOKEN_TYPE_MASTER = "master";
const string TOKEN_TYPE_RESOURCE = "resource";
const string TOKEN_VERSION = "1.0";

# Encoding types
const string UTF8_URL_ENCODING = "UTF-8";

# Error messages
const string MINIMUM_MANUAL_THROUGHPUT_ERROR = "The minimum manual throughput is 400 RU/s";
const string SETTING_BOTH_VALUES_ERROR = "Cannot set both throughput and maxThroughput headers at once";
const string NULL_PARTITIONKEY_VALUE_ERROR = "Partition key values are null";
const string INDEXING_DIRECTIVE_ERROR = "Indexing directive should be either Exclude or Include";
const string CONSISTANCY_LEVEL_ERROR = "Consistency level should be one of Strong, Bounded, Session, or Eventual";
const string VALIDITY_PERIOD_ERROR = "Resource token validity period must be between 3600 and 18000";
const string MASTER_KEY_ERROR = "Enter a valid master key and token type should be master key";
const string JSON_PAYLOAD_ACCESS_ERROR = "Error occurred while accessing the JSON payload of the response";
const string REST_API_INVOKING_ERROR = "Error occurred while invoking the REST API";
const string NULL_RESOURCE_TYPE_ERROR = "ResourceType is incorrect/null";
const string NULL_DATE_ERROR = "Date is invalid/null";
const string NULL_AUTHORIZATION_SIGNATURE_ERROR = "Authorization token is null";
const string DECODING_ERROR = "Base64 Decoding error";
const string TIME_STRING_ERROR = "Time string is not correct";
const string INVALID_RESPONSE_PAYLOAD_ERROR = "Invalid response payload";
const string STREAM_IS_NOT_TYPE_ERROR = "The stream is not type";
const string INVALID_STREAM_TYPE = "Invalid stream type";
const string AZURE_ERROR = "Error occured";
const string PAYLOAD_IS_NOT_JSON_ERROR = "Request payload is not json";
const string EMPTY_BASE_URL_ERROR = "Base URL cannot be empty";
const string EMPTY_MASTER_TOKEN_ERROR = "Master token cannot be empty";
const string INVALID_MASTER_TOKEN_ERROR = "Master token is not valid";

# JSON keys in response
const string JSON_KEY_ID = "id";
const string JSON_KEY_RESOURCE_ID = "_rid";
const string JSON_KEY_SELF_REFERENCE = "_self";
const string JSON_KEY_ETAG = "_etag";
const string JSON_KEY_TIMESTAMP = "_ts";
const string JSON_KEY_ATTACHMENTS = "_attachments";
const string JSON_KEY_DOCUMENTS = "Documents";
const string JSON_KEY_OFFERS = "Offers";

# Fields in record types
const string JSON_KEY_PERMISSIONMODE = "permissionMode";
const string JSON_KEY_RESOURCE = "resource";
const string JSON_KEY_OFFER_RESOURCE_ID = "offerResourceId";
const string JSON_KEY_OFFER_TYPE = "offerType";
const string JSON_KEY_OFFER_VERSION = "offerVersion";
const string JSON_KEY_CONTENT = "content";

# Property in record type representing headers
const string RESPONSE_HEADERS = "reponseMetadata";

# Elements in an error response
const string ACTIVITY_ID = "ActivityId";
const string STATUS = "status";
const string STATUS_NOT_FOUND_STRING = "404";

# Numeric constants
const int MIN_REQUEST_UNITS = 400;
const int MIN_TIME_TO_LIVE_IN_SECONDS = 3600;
const int MAX_TIME_TO_LIVE_IN_SECONDS = 18000;

# Algorithm Used for partitioning
const string PARTITIONING_ALGORITHM_TYPE_HASH = "Hash";
const int DEFAULT_PARTITION_KEY_VERSION = 1;

# String constants
const string SPACE_STRING = " ";
const string COLON_WITH_SPACE = " : ";
const string FORWARD_SLASH = "/";
const string EMPTY_STRING = "";
const string NEW_LINE = "\n";
const string HTTPS_REGEX = "^(https):#";
const string TRUE = "true";
