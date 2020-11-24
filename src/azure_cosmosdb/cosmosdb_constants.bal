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