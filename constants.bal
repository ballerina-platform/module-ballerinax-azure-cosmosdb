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

# Represents the **Consistency Level Override** for document create and update.
# 
# + STRONG - Users are always guaranteed to read the latest committed write
# + BOUNDED - Reads might lag behind writes behind at most K updates of an item or by T time interval
# + SESSION - Reads are guaranteed to honor the consistent-prefix, monotonic reads, monotonic writes, read-your-writes, 
#             and write-follows-reads guarantees in a single client session
# + EVENTUAL - No ordering guarantee for reads. In the absence of any further writes, the replicas eventually converge.
public enum ConsistencyLevel {
    STRONG = "Strong",
    BOUNDED = "Bounded",
    SESSION = "Session",
    EVENTUAL = "Eventual"
}

# Represents whether to **include** or **exclude** the document in indexing.
#
# + INCLUDE - Adds the document to the index
# + EXCLUDE - Omits the document from indexing
public enum IndexingDirective {
    INCLUDE = "Include",
    EXCLUDE = "Exclude"
}

# Represents the type of an Index.
# 
# + HASH - Useful for equality comparisons
# + RANGE - Useful for equality, range comparisons and sorting
# + SPATIAL - Useful for spatial queries
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

# The mode of indexing for the container.
# 
# + CONSISTENT - The index is updated synchronously as you create, update or delete items
# + NONE - Indexing is disabled on the container
public enum IndexingMode {
    CONSISTENT = "consistent",
    NONE = "none"
}

# Type of operation that invokes the trigger.
# 
# + ALL - Trigger fires in all **create**, **replace** and **delete** operations
# + CREATE - Trigger fires only in a **create** operations
# + REPLACE - Trigger fires only in a **replace** operations
# + DELETE - Trigger fires only in a **delete** operations
public enum TriggerOperation {
    ALL = "All",
    CREATE = "Create",
    REPLACE = "Replace",
    DELETE = "Delete"
}

# When the trigger is fired.
# 
# + PRE - Triggers fire before an operation 
# + POST - Triggers fires after an operation
public enum TriggerType {
    PRE = "Pre",
    POST = "Post"
}

# The access mode for the resource.
# 
# + ALL_PERMISSION - Provides **read**, **write**, and **delete** access to a resource
# + READ_PERMISSION - Restricts the user to have only **read** access to the resource
public enum PermisssionMode {
    ALL_PERMISSION = "All",
    READ_PERMISSION = "Read"
}

# The specific version for a given offer.
# 
# + PRE_DEFINED - Represents pre-defined throughput levels
# + USER_DEFINED - Represents user-defined throughput levels
public enum OfferVersion {
    PRE_DEFINED = "V1",
    USER_DEFINED = "V2"
}

# The performance levels for a specific throughput level. They depend on the Cosmos DB region which the container 
# belongs to and partitioning nature of the container (ie: single partitioned or multiple partitioned).
# 
# + LEVEL_S1 - Performance level allows a low throughput and predefined amount of storage  
# + LEVEL_S2 - Performance level allows a medium throughput and predefined amount of storage
# + LEVEL_S3 - Performance level allows a high throughput and predefined amount of storage
# + INVALID - Performance level should set `Invalid` for `V2`, user-defined throughput levels
public enum OfferType {
    LEVEL_S1 = "S1",
    LEVEL_S2 = "S2",
    LEVEL_S3 = "S3",
    INVALID = "Invalid"
}

# Use to retrieve only the incremental changes to documents within the collection.
# 
# + INCREMENTAL - Provides a sorted list of documents that were changed in the order in which they were modified
public enum ChangeFeedOption {
    INCREMENTAL = "Incremental feed"
}

# The version of the partition key if it is smaller than 100 bytes
public const PARTITION_KEY_VERSION_1 = 1;

# The version of the partition key if it is larger than 100 bytes
public const PARTITION_KEY_VERSION_2 = 2;

# The version of the partition key
public type PartitionKeyVersion  PARTITION_KEY_VERSION_1|PARTITION_KEY_VERSION_2;

# Used for partition key
const PARTITIONING_ALGORITHM_TYPE_HASH = "Hash";

# Indexing Policy
const INDEXING_TYPE_INCLUDE = "Include";
const INDEXING_TYPE_EXCLUDE = "Exclude";
const int MAX_PRECISION = -1;

# Request headers
const API_VERSION_HEADER = "x-ms-version";
const HOST_HEADER = "Host";
const ACCEPT_HEADER = "Accept";
const DATE_HEADER = "x-ms-date";
const THROUGHPUT_HEADER = "x-ms-offer-throughput";
const AUTOPILET_THROUGHPUT_HEADER = "x-ms-cosmos-offer-autopilot-settings";
const INDEXING_DIRECTIVE_HEADER = "x-ms-indexing-directive";
const IS_UPSERT_HEADER = "x-ms-documentdb-is-upsert";
const MAX_ITEM_COUNT_HEADER = "x-ms-max-item-count";
const CONSISTANCY_LEVEL_HEADER = "x-ms-consistency-level";
const A_IM_HEADER = "A-IM";
const PARTITIONKEY_RANGE_HEADER = "x-ms-documentdb-partitionkeyrangeid";
const ISQUERY_HEADER = "x-ms-documentdb-isquery";
const PARTITION_KEY_HEADER = "x-ms-documentdb-partitionkey";
const EXPIRY_HEADER = "x-ms-documentdb-expiry-seconds";
const IS_ENABLE_CROSS_PARTITION_HEADER = "x-ms-documentdb-query-enablecrosspartition";

# Values for request headers
const CONTENT_TYPE_QUERY = "application/query+json";
const ACCEPT_ALL = "*/*";
const CONNECTION_KEEP_ALIVE = "keep-alive";

# Response headers
const CONTINUATION_HEADER = "x-ms-continuation";
const SESSION_TOKEN_HEADER = "x-ms-session-token";
const REQUEST_CHARGE_HEADER = "x-ms-request-charge";
const RETRY_AFTER_MILLISECONDS = "x-ms-retry-after-ms";
const ITEM_COUNT_HEADER = "x-ms-item-count";

# Time Zone
const GMT_ZONE = "Europe/London";
const TIME_ZONE_FORMAT = "E, dd MMM yyyy HH:mm:ss";

# Resources
const RESOURCE_TYPE_DATABASES = "dbs";
const RESOURCE_TYPE_COLLECTIONS = "colls";
const RESOURCE_TYPE_DOCUMENTS = "docs";
const RESOURCE_TYPE_STORED_POCEDURES = "sprocs";
const RESOURCE_TYPE_PK_RANGES = "pkranges";
const RESOURCE_TYPE_UDF = "udfs";
const RESOURCE_TYPE_TRIGGER = "triggers";
const RESOURCE_TYPE_USER = "users";
const RESOURCE_TYPE_PERMISSION = "permissions";
const RESOURCE_TYPE_OFFERS = "offers";

# Cosmos DB SQL API version
const API_VERSION = "2018-12-31";

# Token information
const TOKEN_TYPE_MASTER = "master";
const TOKEN_TYPE_RESOURCE = "resource";
const TOKEN_VERSION = "1.0";

# Encoding types
const UTF8_URL_ENCODING = "UTF-8";

# Error messages
const MINIMUM_MANUAL_THROUGHPUT_ERROR = "The minimum manual throughput is 400 RU/s";
const SETTING_BOTH_VALUES_ERROR = "Cannot set both throughput and maxThroughput headers at once";
const NULL_PARTITIONKEY_VALUE_ERROR = "Partition key values are null";
const INDEXING_DIRECTIVE_ERROR = "Indexing directive should be either Exclude or Include";
const CONSISTANCY_LEVEL_ERROR = "Consistency level should be one of Strong, Bounded, Session, or Eventual";
const VALIDITY_PERIOD_ERROR = "Resource token validity period must be between 3600 and 18000";
const MASTER_KEY_ERROR = "Enter a valid master key and token type should be master key";
const JSON_PAYLOAD_ACCESS_ERROR = "Error occurred while accessing the JSON payload of the response";
const REST_API_INVOKING_ERROR = "Error occurred while invoking the REST API";
const NULL_RESOURCE_TYPE_ERROR = "ResourceType is incorrect/null";
const NULL_DATE_ERROR = "Date is invalid/null";
const NULL_AUTHORIZATION_SIGNATURE_ERROR = "Authorization token is null";
const DECODING_ERROR = "Base64 Decoding error";
const TIME_STRING_ERROR = "Time is not correct";
const INVALID_RESPONSE_PAYLOAD_ERROR = "Invalid response payload";
const INVALID_RECORD_TYPE_ERROR = "Invalid record type";
const STREAM_IS_NOT_TYPE_ERROR = "The stream is not type";
const INVALID_STREAM_TYPE = "Invalid stream type";
const AZURE_ERROR = "Error occured";
const PAYLOAD_IS_NOT_JSON_ERROR = "Request payload is not json";
const EMPTY_BASE_URL_ERROR = "Base URL cannot be empty";
const EMPTY_MASTER_TOKEN_ERROR = "Master token cannot be empty";
const INVALID_MASTER_TOKEN_ERROR = "Master token is not valid";

# JSON keys in response
const JSON_KEY_ID = "id";
const JSON_KEY_RESOURCE_ID = "_rid";
const JSON_KEY_SELF_REFERENCE = "_self";
const JSON_KEY_ETAG = "_etag";
const JSON_KEY_TIMESTAMP = "_ts";
const JSON_KEY_ATTACHMENTS = "_attachments";
const JSON_KEY_DOCUMENTS = "Documents";
const JSON_KEY_OFFERS = "Offers";

# Fields in record types
const JSON_KEY_PERMISSIONMODE = "permissionMode";
const JSON_KEY_RESOURCE = "resource";
const JSON_KEY_OFFER_RESOURCE_ID = "offerResourceId";
const JSON_KEY_OFFER_TYPE = "offerType";
const JSON_KEY_OFFER_VERSION = "offerVersion";
const JSON_KEY_CONTENT = "content";

# Property in record type representing headers
const RESPONSE_HEADERS = "reponseMetadata";

# Elements in an error response
const ACTIVITY_ID = "ActivityId";
const STATUS = "status";
const STATUS_NOT_FOUND_STRING = "404";

# Numeric constants
const MIN_REQUEST_UNITS = 400;
const MIN_TIME_TO_LIVE_IN_SECONDS = 3600;
const MAX_TIME_TO_LIVE_IN_SECONDS = 18000;

# String constants
const SPACE_STRING = " ";
const COLON_WITH_SPACE = " : ";
const FORWARD_SLASH = "/";
const EMPTY_STRING = "";
const NEW_LINE = "\n";
const HTTPS_REGEX = "^(https):#";
const TRUE = "true";
const EMPTY_ARRAY_STRING = "[]";
