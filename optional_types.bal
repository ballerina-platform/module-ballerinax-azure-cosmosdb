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

# Represent the optional parameters which can be passed to the function when creating a document.
# 
# + indexingDirective - The option whether to include the document in the index. Allowed values are `Include` or 
#       `Exclude`.
# + isUpsertRequest - A boolean value which specify if the request is an upsert request
public type DocumentCreateOptions record {|
    string? indexingDirective = ();
    boolean isUpsertRequest = false;
|};

# Represent the optional parameters which can be passed to the function when replacing a document.
# 
# + indexingDirective - The option whether to include the document in the index. Allowed values are `Include` or 
#       `Exclude`.
# + ifMatchEtag - Used to make operation conditional for optimistic concurrency. will check if the resource's ETag value 
#       matches the ETag value provided in the Condition property. If the resource has changes a 412 Precondition 
#       failure error will be returned.
public type DocumentReplaceOptions record {|
    boolean? indexingDirective = ();
    string? ifMatchEtag = ();
|};

# Represent the optional parameters which can be passed to the function when listing information about the documents.
# 
# + consistancyLevel - The consistency level override. Allowed values are `Strong`, `Bounded`, `Sesssion` or `Eventual`.
# + sessionToken - Echo the latest read value of sessionTokenHeader to acquire session level consistency 
# + changeFeedOption - Must be set to `Incremental feed` or omitted otherwise
# + ifNoneMatchEtag - Specify `*` to return all new changes, `<eTag>` to return changes made sice that timestamp or 
#       otherwise omitted. Makes operation conditional to only execute if the resource has changed. The value should be 
#       the etag of the resource.
# + partitionKeyRangeId - The partition key range ID for reading data
public type DocumentListOptions record {|
    Consistency? consistancyLevel = ();
    string? sessionToken = ();
    string? changeFeedOption = ();
    string? ifNoneMatchEtag = ();
    string? partitionKeyRangeId = ();
|};

public type StoredProcedureOptions record {|
    any[]? parameters = ();
    any? partitionKey = ();
|};

# Represent the optional parameters which can be passed to the function when reading the information about other 
# resources in Cosmos DB such as Containers, StoredProcedures, Triggers, User Defined Functions etc.
# 
# + consistancyLevel - The consistency level override. Allowed values are `Strong`, `Bounded`, `Sesssion` or `Eventual`.
# + sessionToken - Echo the latest read value of sessionTokenHeader to acquire session level consistency
# + ifNoneMatchEtag - Check if the resource's ETag value does not matches the ETag value provided in the Condition 
#       property. This is applicable only on GET. Makes operation conditional to only execute if the resource has 
#       changed. The value should be the etag of the resource.
public type ResourceReadOptions record {|
    Consistency? consistancyLevel = ();
    string? sessionToken = ();
    string? ifNoneMatchEtag = ();
|};

# Represent the optional parameters which can be passed to the function when querying containers.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to acquire session level consistency 
# + enableCrossPartition - Boolean value specifying whether to allow cross partitioning
# + consistancyLevel - The consistency level override. Allowed values are `Strong`, `Bounded`, `Sesssion` or `Eventual`.
public type ResourceQueryOptions record {|
    Consistency? consistancyLevel = ();
    string? sessionToken = ();
    boolean enableCrossPartition = false;
|};

# Represent the optional parameters which can be passed to the function when deleting other resources in Cosmos DB.
# 
# + sessionToken - Echo the latest read value of sessionTokenHeader to acquire session level consistency
# + ifMatchEtag - Used to make operation conditional for optimistic concurrency. will check if the resource's ETag value 
#       matches the ETag value provided in the Condition property. If the resource has changes a 412 Precondition 
#       failure error will be returned.
public type ResourceDeleteOptions record {|
    string? sessionToken = ();
    string? ifMatchEtag = ();
|};

type Options DocumentCreateOptions|DocumentReplaceOptions|DocumentListOptions|ResourceReadOptions|
        ResourceQueryOptions|ResourceDeleteOptions;
