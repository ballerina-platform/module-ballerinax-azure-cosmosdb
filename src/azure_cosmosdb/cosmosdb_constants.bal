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
