# Represent the optional parameters which can be passed to the function when creating a document.
# 
# + isUpsertRequest - A boolean value which specify if the request is an upsert request.
# + indexingDirective - The option whether to include the document in the index. Allowed values are "Include" or "Exclude".
public type DocumentCreateOptions record {|
    string? indexingDirective = ();
    boolean isUpsertRequest = false;
|};

# Represent the optional parameters which can be passed to the function when replacing a document.
# 
# + indexingDirective - The option whether to include the document in the index. Allowed values are "Include" or "Exclude".
# + ifMatchEtag - Used to make operation conditional for optimistic concurrency. will check if the resource's ETag value 
#       matches the ETag value provided in the Condition property. If the resource has changes a 412 Precondition 
#       failure error will be returned.
public type DocumentReplaceOptions record {|
    string? indexingDirective = ();
    string? ifMatchEtag = ();
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
# + consistancyLevel - The consistancy level override. Allowed values are "Strong", "Bounded", "Sesssion" or "Eventual".
# + sessionToken - Echo the latest read value of sessionTokenHeader to aquire session level consistancy.
# + ifNoneMatchEtag - Check if the resource's ETag value does not matches the ETag value provided in the Condition property. 
#       This is applicable only on GET. Makes operation conditional to only execute if the resource has changed. The 
#       value should be the etag of the resource.
public type ResourceReadOptions record {|
    string? consistancyLevel = ();
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
# + ifMatchEtag - Used to make operation conditional for optimistic concurrency. will check if the resource's ETag value 
#       matches the ETag value provided in the Condition property. If the resource has changes a 412 Precondition 
#       failure error will be returned.
public type ResourceDeleteOptions record {|
    string? sessionToken = ();
    string? ifMatchEtag = ();
|};

type Options DocumentCreateOptions|DocumentReplaceOptions|DocumentListOptions|ResourceReadOptions|
        ResourceQueryOptions|ResourceDeleteOptions;
