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
import ballerina/java;
import ballerina/stringutils;

cosmosdb:Configuration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Get database container to get the resource ids of them.
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);

    log:print("Creating user");
    string userId = string `user_${uuid.toString()}`;
    cosmosdb:User userCreationResult = checkpanic managementClient->createUser(databaseId, userId);

    log:print("Replace user id");
    string newReplaceId = string `user_${uuid.toString()}`;
    cosmosdb:Result userReplaceResult = checkpanic managementClient->replaceUserId(databaseId, userId, newReplaceId);

    log:print("Get user information");
    cosmosdb:User user  = checkpanic managementClient->getUser(databaseId, userId);

    log:print("List users");
    stream<cosmosdb:User> result5 = checkpanic managementClient->listUsers(databaseId);

    //------------------------------------------------Permissions-------------------------------------------------------

    log:print("Create permission for a user");
    string permissionId = string `permission_${uuid.toString()}`;
    string permissionMode = "All";
    string permissionResource = 
            string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;
    cosmosdb:Permission createPermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };
    cosmosdb:Permission createPermissionResult = checkpanic managementClient->createPermission(databaseId, userId,
            <@untainted>createPermission);

    // Create permission with time to live
    // 
    // string newPermissionMode = "Read";
    // string newPermissionResource = string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.
    // toString()}`;
    // int validityPeriod = 9000;
    // cosmosdb:Permission newPermission = {
    //     id: string `permissionttl_${uuid.toString()}`,
    //     permissionMode: newPermissionMode,
    //     resourcePath: newPermissionResource
    // };
    // var result7 = azureCosmosClient->createPermission(databaseId, userId, <@untainted>newPermission, validityPeriod);
    // if (result7 is cosmosdb:Permission) {
    //     io:println("Permission is successfully created!");
    // } else {
    //     io:println("Permission is not created ", result7.message());
    // }

    log:print("Replace permission");
    string permissionModeReplace = "All";
    string permissionResourceReplace = string `dbs/${databaseId}/colls/${containerId}`;
    cosmosdb:Permission replacePermission = {
        id: permissionId,
        permissionMode: permissionMode,
        resourcePath: permissionResource
    };
    cosmosdb:Result replacePermissionResult = checkpanic managementClient->replacePermission(databaseId, userId, 
            replacePermission);

    log:print("List permissions");
    stream<cosmosdb:Permission> permissionList = checkpanic managementClient->listPermissions(databaseId, userId);

    log:print("Get intormation about one permission");
    cosmosdb:Permission permission = checkpanic managementClient->getPermission(databaseId, userId, permissionId);

    log:print("Delete permission");
    _ = checkpanic managementClient->deletePermission(databaseId, userId, permissionId);

    log:print("Delete user");
    _ = checkpanic  managementClient->deleteUser(databaseId, userId);
    log:print("Success!");
}

public function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = stringutils:replace(stringUUID, "-", "");
        return stringUUID;
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
