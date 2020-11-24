#Supported HTTP methods.
 public const GET = "GET";
 public const PUT = "PUT";
 public const POST = "POST";
 public const PATCH = "PATCH";
 public const DELETE = "DELETE";

#Holds the value for the paths of the azure cosmos db resources.
const string RESOURCE_PATH_DATABASES = "dbs";
const string RESOURCE_PATH_COLLECTIONS = "colls";
const string RESOURCE_PATH_DOCUMENTS = "docs";
const string RESOURCE_PATH_STORED_POCEDURES = "sprocs";
const string RESOURCE_PATH_PK_RANGES = "pkranges";

#Azure Cosmos DB Document API (REST) version
final  string API_VERSION = "2018-12-31";

#Constant field `FORWARD_SLASH`. Holds the value of "/".
final  string FORWARD_SLASH = "/";

#Constant field `FORWARD_SLASH`. Holds the value of "".
final  string EMPTY_STRING = "";

#Constant fields of Azure SQL API REST request  headers.
const string CONTENT_TYPE_HEADER = "Content-Type";
const string API_VERSION_HEADER = "x-ms-version";
const string HOST_HEADER = "Host";
const string ACCEPT_HEADER = "Accept";
const string CONNECTION_HEADER = "Connection";
const string DATE_HEADER = "x-ms-date";
const string AUTHORIZATION_HEADER = "Authorization";
const string THROUGHPUT_HEADER = "x-ms-offer-throughput";
const string AUTOPILET_THROUGHPUT_HEADER = "x-ms-cosmos-offer-autopilot-settings";

#Constant fields of Azure SQL API REST response  headers.
const string CONTINUATION_HEADER = "x-ms-continuation";
const string SESSION_TOKEN_HEADER = "x-ms-session-token";
const string REQUEST_CHARGE_HEADER = "x-ms-request-charge";
const string RESOURCE_USAGE_HEADER = "x-ms-resource-usage";
const string ITEM_COUNT_HEADER = "x-ms-item-count";
const string RESPONSE_DATE_HEADER = "Date";
const string ETAG_HEADER = "etag";

#Constant field for GMT time zone
const string GMT_ZONE = "Europe/London";
