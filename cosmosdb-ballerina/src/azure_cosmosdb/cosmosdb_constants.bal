#   Supported HTTP methods.
 public const GET = "GET";
 public const PUT = "PUT";
 public const POST = "POST";
 public const PATCH = "PATCH";
 public const DELETE = "DELETE";

# Holds the value for the resource types in Azure Cosmos db.
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

# Azure Cosmos DB Document API (REST) version
final  string API_VERSION = "2018-12-31";

# Constant field `FORWARD_SLASH`. Holds the value of "/".
final  string FORWARD_SLASH = "/";

# Constant field `FORWARD_SLASH`. Holds the value of "".
final  string EMPTY_STRING = "";

# Constant fields REST request headers.
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

# Constant fields of Azure SQL API REST response  headers.
const string CONTINUATION_HEADER = "x-ms-continuation";
const string SESSION_TOKEN_HEADER = "x-ms-session-token";
const string REQUEST_CHARGE_HEADER = "x-ms-request-charge";
const string RESOURCE_USAGE_HEADER = "x-ms-resource-usage";
const string ITEM_COUNT_HEADER = "x-ms-item-count";
const string RESPONSE_DATE_HEADER = "Date";
const string ETAG_HEADER = "etag";

# Constant field for GMT time zone
const string GMT_ZONE = "Europe/London";
