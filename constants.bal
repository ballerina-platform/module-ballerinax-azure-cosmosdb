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

# Calls the service API V1
public const string SERVICE_VERSION_V1 = "1.0";

# Whether to include indexing directive
public const string INDEXING_TYPE_INCLUDE = "Include";

# Whether to exclude indexing directive
public const string INDEXING_TYPE_EXCLUDE = "Exclude";

# Strong consistancy level
public const string CONSISTANCY_LEVEL_STRONG = "Strong";

# Bounded consistancy level
public const string CONSISTANCY_LEVEL_BOUNDED = "Bounded";

# Session consistancy level
public const string CONSISTANCY_LEVEL_SESSION = "Session";

# Eventual consistancy level
public const string CONSISTANCY_LEVEL_EVENTUAL = "Eventual";

// Request headers
const string CONTENT_TYPE_HEADER = "Content-Type";
const string API_VERSION_HEADER = "x-ms-version";
const string HOST_HEADER = "Host";
const string ACCEPT_HEADER = "Accept";
const string CONNECTION_HEADER = "Connection";
const string DATE_HEADER = "x-ms-date";
const string AUTHORIZATION_HEADER = "Authorization";
const string THROUGHPUT_HEADER = "x-ms-offer-throughput";
const string AUTOPILET_THROUGHPUT_HEADER = "x-ms-cosmos-offer-autopilot-settings";
const string INDEXING_DIRECTIVE_HEADER = "x-ms-indexing-directive";
const string IS_UPSERT_HEADER = "x-ms-documentdb-is-upsert";
const string MAX_ITEM_COUNT_HEADER = "x-ms-max-item-count";
const string CONSISTANCY_LEVEL_HEADER = "x-ms-consistency-level";
const string A_IM_HEADER = "A-IM";
const string NON_MATCH_HEADER = "If-None-Match";
const string IF_MATCH_HEADER = "If-Match";
const string PARTITIONKEY_RANGE_HEADER = "x-ms-documentdb-partitionkeyrangeid";
const string ISQUERY_HEADER = "x-ms-documentdb-isquery";
const string PARTITION_KEY_HEADER = "x-ms-documentdb-partitionkey";
const string EXPIRY_HEADER = "x-ms-documentdb-expiry-seconds";
const string IS_ENABLE_CROSS_PARTITION_HEADER = "x-ms-documentdb-query-enablecrosspartition";

// Values for request headers
const string CONTENT_TYPE_QUERY = "application/query+json";
const string ACCEPT_ALL = "*/*";
const string CONNECTION_KEEP_ALIVE = "keep-alive";

// Response headers
const string CONTINUATION_HEADER = "x-ms-continuation";
const string SESSION_TOKEN_HEADER = "x-ms-session-token";
const string REQUEST_CHARGE_HEADER = "x-ms-request-charge";
const string RESOURCE_USAGE_HEADER = "x-ms-resource-usage";
const string ITEM_COUNT_HEADER = "x-ms-item-count";
const string RESPONSE_DATE_HEADER = "Date";
const string ETAG_HEADER = "etag";

// Time Zone
const string GMT_ZONE = "Europe/London";
const string TIME_ZONE_FORMAT = "EEE, dd MMM yyyy HH:mm:ss z";

// HTTP methods
const string GET = "GET";
const string PUT = "PUT";
const string POST = "POST";
const string PATCH = "PATCH";
const string DELETE = "DELETE";

// Resources
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

// Cosmos DB SQL API version
const string API_VERSION = "2018-12-31";

// Token information
const string TOKEN_TYPE_MASTER = "master";
const string TOKEN_TYPE_RESOURCE = "resource";
const string TOKEN_VERSION = "1.0";

//Encoding types
const string UTF8_URL_ENCODING = "UTF-8";

// Error messages
const string MINIMUM_MANUAL_THROUGHPUT_ERROR = "The minimum manual throughput is 400 RU/s";
const string SETTING_BOTH_VALUES_ERROR = "Cannot set both throughput and maxThroughput headers at once";
const string NULL_PARTITIONKEY_VALUE_ERROR = "Partition key values are null";
const string INDEXING_DIRECTIVE_ERROR = "Indexing directive should be either Exclude or Include";
const string CONSISTANCY_LEVEL_ERROR = "Consistacy level should be one of Strong, Bounded, Session, or Eventual";
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

// json keys in response
const string JSON_KEY_ID = "id";
const string JSON_KEY_RESOURCE_ID = "_rid";
const string JSON_KEY_SELF_REFERENCE = "_self";
const string JSON_KEY_ETAG = "_etag";
const string JSON_KEY_TIMESTAMP = "_ts";
const string JSON_KEY_ATTACHMENTS = "_attachments";
const string JSON_KEY_DOCUMENTS = "Documents";
const string JSON_KEY_OFFERS = "Offers";

// Fields in record types
const string JSON_KEY_PERMISSIONMODE = "permissionMode";
const string JSON_KEY_RESOURCE = "resource";
const string JSON_KEY_OFFER_RESOURCE_ID = "offerResourceId";
const string JSON_KEY_OFFER_TYPE = "offerType";
const string JSON_KEY_OFFER_VERSION = "offerVersion";
const string JSON_KEY_CONTENT = "content";

// Property in record type representing headers
const string RESPONSE_HEADERS = "reponseMetadata";

// Elements in an error response
const string ACTIVITY_ID = "ActivityId";
const string STATUS = "status";
const string STATUS_NOT_FOUND_STRING = "404";

// Numeric constants
const int MIN_REQUEST_UNITS = 400;
const int MIN_TIME_TO_LIVE = 3600;
const int MAX_TIME_TO_LIVE = 18000;

// Algorithm Used for partitioning
const string PARTITIONING_ALGORITHM_TYPE_HASH = "Hash";

// String constants
const string SPACE_STRING = " ";
const string COLON_WITH_SPACE = " : ";
const string OFFER_VERSION_1 = "V1";
const string FORWARD_SLASH = "/";
const string EMPTY_STRING = "";
const string NEW_LINE = "\n";
const string HTTPS_REGEX = "^(https)://";
