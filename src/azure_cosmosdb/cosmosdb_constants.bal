# Represents Forward slash
public const FORWARD_SLASH = "/";
 
# Represents Empty string
public const string EMPTY_STRING = "";

# Represents Token type for a master token
public const string TOKEN_TYPE_MASTER = "master";

# Represents Token type for a resource token
public const string TOKEN_TYPE_RESOURCE = "resource";

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

const string CONTINUATION_HEADER = "x-ms-continuation";
const string SESSION_TOKEN_HEADER = "x-ms-session-token";
const string REQUEST_CHARGE_HEADER = "x-ms-request-charge";
const string RESOURCE_USAGE_HEADER = "x-ms-resource-usage";
const string ITEM_COUNT_HEADER = "x-ms-item-count";
const string RESPONSE_DATE_HEADER = "Date";
const string ETAG_HEADER = "etag";

const string GMT_ZONE = "Europe/London";

const string GET = "GET";
const string PUT = "PUT";
const string POST = "POST";
const string PATCH = "PATCH";
const string DELETE = "DELETE";

const string RESOURCE_PATH_DATABASES = "dbs";
const string RESOURCE_PATH_COLLECTIONS = "colls";
const string RESOURCE_PATH_DOCUMENTS = "docs";
const string RESOURCE_PATH_STORED_POCEDURES = "sprocs";
const string RESOURCE_PATH_PK_RANGES = "pkranges";
const string RESOURCE_PATH_UDF = "udfs";
const string RESOURCE_PATH_TRIGGER = "triggers";
const string RESOURCE_PATH_USER = "users";
const string RESOURCE_PATH_PERMISSION = "permissions";
const string RESOURCE_PATH_OFFER = "offers";

const string API_VERSION = "2018-12-31";
const string RESPONSE_HEADERS = "reponseHeaders";
const string CONTENT_TYPE_QUERY = "application/query+json";
const string CONNECTION_VALUE = "keep-alive";
const string ACTIVITY_ID = "ActivityId";
const int MIN_REQUEST_UNITS = 400;
const int MIN_TIME_TO_LIVE = 3600;
const int MAX_TIME_TO_LIVE = 18000;
const string UTF8_URL_ENCODING = "UTF-8";

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
