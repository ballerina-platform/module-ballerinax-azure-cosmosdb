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

public type AzureError distinct error;
public type UserError distinct error;

isolated function prepareAzureError(string message, error? err = (), int? status = ()) returns error {
    error azureError;
    if (status is int) {
        return AzureError(message, status = status);
    }
    if (err is error){
        return AzureError(message, err);
    }
    return AzureError(message);
}

isolated function prepareUserError(string message, error? err = (), int? status = ()) returns error {
    error userError;
    if (status is int) {
        return UserError(message, status = status);
    }
    if (err is error){
        return UserError(message, err);
    }
    return UserError(message);
}
