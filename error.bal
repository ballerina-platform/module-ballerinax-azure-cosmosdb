// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

isolated function prepareModuleError(string message, error? err = (), int? status = ()) returns error {
    error azureError;
    if (status is int) {
        azureError = AzureError(message, status = status);
    } else if (err is error){
        azureError = AzureError(message, err);
    } else {
        azureError = AzureError(message);
    }
    return azureError;
}

// isolated function prepareLanguageError(string message, error? err = (), int? status = ()) returns error {
//     error languageError;
//     if (status is int) {
//         languageError = BallerinaLanguageError(message, status = status);
//     } else if (err is error){
//         languageError = BallerinaLanguageError(message, err);
//     } else {
//         languageError = BallerinaLanguageError(message);
//     }
//     return languageError;
// }

isolated function prepareUserError(string message, error? err = (), int? status = ()) returns error {
    error userError;
    if (status is int) {
        userError = UserError(message, status = status);
    } else if (err is error){
        userError = UserError(message, err);
    } else {
        userError = UserError(message);
    }
    return userError;
}
