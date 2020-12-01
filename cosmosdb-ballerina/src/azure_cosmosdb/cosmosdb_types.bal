import ballerina/http;

public type AzureCosmosConfiguration record {|
    string baseUrl;    
    string masterKey;
    string host;
    string tokenType;
    string tokenVersion;
    http:ClientSecureSocket? secureSocketConfig;
|};

public type ResourceProperties record {|
    string databaseId = "";
    string containerId = "";
|};

public type Database record {|
    string id = "";
    string _rid?;
    string _self?;
    Headers?...;
|};

public type DatabaseList record {
    string _rid = "";
    Database[] Databases = [];
    Headers? reponseHeaders = ();
};

public type ThroughputProperties record {
    int? throughput = ();
    json? maxThroughput = ();
};

public type Headers record {|
    string? continuationHeader = ();
    string? sessionTokenHeader = ();
    string? requestChargeHeader = ();
    string? resourceUsageHeader = ();
    string? itemCountHeader = ();
    string? etagHeader = ();
    string? dateHeader = ();
|};

public type HeaderParameters record {|
    string verb = "";
    string apiVersion = API_VERSION;
    string resourceType = "";
    string resourceId = "";
|};

public type AzureError  distinct  error;
