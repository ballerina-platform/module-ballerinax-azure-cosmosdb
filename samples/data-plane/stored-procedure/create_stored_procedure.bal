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

import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;

cosmosdb:Configuration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};
cosmosdb:DataPlaneClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    string storedProcedureId = "my_stored_procedure";
    
    log:print("Creating stored procedure");
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;

    cosmosdb:StoredProcedure storedProcedureCreateResult = checkpanic azureCosmosClient->createStoredProcedure(databaseId, 
            containerId, storedProcedureId, storedProcedureBody);
    log:print("Success!");
}
