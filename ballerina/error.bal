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

# Extra HTTP status code detail of an error.
#
# + status - The HTTP status code of the error  
public type HttpDetail record {
    int status; 
};

# The errors which will come from the Azure API call itself.  
public type PayloadValidationError distinct error;

# The payload access errors where the error detail contains the HTTP status.  
public type DbOperationError error<HttpDetail>;

# The errors which occur when providing an invalid value.  
public type InputValidationError distinct error;

# The union of all types of errors in the connector.  
public type Error PayloadValidationError|DbOperationError|InputValidationError|error;
