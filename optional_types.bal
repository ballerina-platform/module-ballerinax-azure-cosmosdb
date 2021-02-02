# Represent the optional parameters which can be passed to the function when creating a document.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy.
# + isUpsertRequest - A boolean value which specify if the request is an upsert request.
# + indexingDirective - The option whether to include the document in the index. Allowed values are "Include" or "Exclude".
public type DocumentCreateOptions record {|
    string? indexingDirective = ();
    string? sessionToken = ();
    boolean isUpsertRequest = false;
|};

# Represent the optional parameters which can be passed to the function when replacing a document.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy.
# + indexingDirective - The option whether to include the document in the index. Allowed values are "Include" or "Exclude".
# + ifMatchEtag - Used to make operation conditional for optimistic concurrency.
public type DocumentReplaceOptions record {|
    string? indexingDirective = ();
    string? sessionToken = ();
    string? ifMatchEtag = ();
|};

# Represent the optional parameters which can be passed to the function when reading the information about a document.
# 
# + consistancyLevel - The consistancy level override. Allowed values are "Strong", "Bounded", "Sesssion" or "Eventual".
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy. 
# + ifNoneMatchEtag - Specify "*" to return all new changes, "<eTag>" to return changes made sice that timestamp or 
#       otherwise omitted.Makes operation conditional to only execute if the resource has changed. The value should be 
#       the etag of the resource.
public type DocumentGetOptions record {|
    string? consistancyLevel = ();
    string? sessionToken = ();
    string? ifNoneMatchEtag = ();
|};

# Represent the optional parameters which can be passed to the function when listing information about the documents.
# 
# + consistancyLevel - The consistancy level override. Allowed values are "Strong", "Bounded", "Sesssion" or "Eventual".
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy. 
# + changeFeedOption - Must be set to "Incremental feed" or omitted otherwise.
# + ifNoneMatchEtag - Specify "*" to return all new changes, "<eTag>" to return changes made sice that timestamp or 
#       otherwise omitted.Makes operation conditional to only execute if the resource has changed. The value should be 
#       the etag of the resource.
# + partitionKeyRangeId - The partition key range ID for reading data.
public type DocumentListOptions record {|
    string? consistancyLevel = ();
    string? sessionToken = ();
    string? changeFeedOption = ();
    string? ifNoneMatchEtag = ();
    string? partitionKeyRangeId = ();
|};

public type StoredProcedureOptions record {|
    any[]? parameters = ();
    any? valueOfPartitionKey = ();
|};

# Represent the optional parameters which can be passed to the function when reading the information about other resources 
# in Cosmos DB such as Containers, StoredProcedures, Triggers, User Defined Functions etc.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy.
# + ifNoneMatchEtag - Specify "*" to return all new changes, "<eTag>" to return changes made sice that timestamp or 
#       otherwise omitted.Makes operation conditional to only execute if the resource has changed. The value should be 
#       the etag of the resource.
public type ResourceReadOptions record {|
    string? sessionToken = ();
    string? ifNoneMatchEtag = ();
|};

# Represent the optional parameters which can be passed to the function when querying containers.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy. 
# + enableCrossPartition -  Boolean value specifying whether to allow cross partitioning.
# + consistancyLevel - The consistancy level override. Allowed values are "Strong", "Bounded", "Sesssion" or "Eventual".
public type ResourceQueryOptions record {|
    string? sessionToken = ();
    boolean enableCrossPartition = false;
    string? consistancyLevel = ();
|};

# Represent the optional parameters which can be passed to the function when deleting other resources in Cosmos DB.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy.
# + ifMatchEtag - Used to make operation conditional for optimistic concurrency. The operation will be executed if the 
#       current etag is matched with the sent etag. If not 412 Precondition failure error will be returned.
public type ResourceDeleteOptions record {|
    string? sessionToken = ();
    string? ifMatchEtag = ();
|};

type Options DocumentCreateOptions|DocumentReplaceOptions|DocumentGetOptions|DocumentListOptions|ResourceReadOptions|
        ResourceQueryOptions|ResourceDeleteOptions;
