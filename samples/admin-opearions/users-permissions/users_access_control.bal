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

import ballerina/jballerina.java;
import ballerina/log;
import ballerina/os;
import ballerina/regex;
import ballerinax/azure_cosmosdb as cosmosdb;

cosmosdb:Configuration config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Get database container to get the resource ids of them.
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);

    log:print("Creating user");
    string userId = string `user_${uuid.toString()}`;
    cosmosdb:User|error userCreationResult = managementClient->createUser(databaseId, userId);

    if (userCreationResult is cosmosdb:User) {
        log:print(userCreationResult.toString());
        log:print("Success!");
    } else {
        log:printError(userCreationResult.message());
    }

    log:print("Replace user id");
    string newUserId = string `user_${uuid.toString()}`;
    cosmosdb:User|error userReplaceResult = managementClient->replaceUserId(databaseId, userId, newUserId);

    if (userReplaceResult is cosmosdb:User) {
        log:print(userReplaceResult.toString());
        log:print("Success!");
    } else {
        log:printError(userReplaceResult.message());
    }

    log:print("Get user information");
    cosmosdb:User|error user = managementClient->getUser(databaseId, userId);

    if (user is cosmosdb:User) {
        log:print(user.toString());
        log:print("Success!");
    } else {
        log:printError(user.message());
    }

    log:print("List users");
    stream<cosmosdb:User>|error userList = managementClient->listUsers(databaseId);

    if (userList is stream<cosmosdb:User>) {
        error? e = userList.forEach(function (cosmosdb:User user) {
            log:print(user.toString());
        });
        log:print("Success!");
    } else {
        log:printError(userList.message());
    }

    //------------------------------------------------Permissions-------------------------------------------------------

    log:print("Create permission for a user");
    string permissionId = string `permission_${uuid.toString()}`;
    cosmosdb:PermisssionMode permissionMode = "All";
    string permissionResource = 
        string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;
        
    cosmosdb:Permission|error permission = managementClient->createPermission(databaseId, userId, permissionId, 
        permissionMode, <@untainted>permissionResource);

    if (permission is cosmosdb:Permission) {
        log:print(permission.toString());
        log:print("Success!");
    } else {
        log:printError(permission.message());
    }

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
    cosmosdb:PermisssionMode permissionModeReplace = "All";
    string permissionResourceReplace = string `dbs/${databaseId}/colls/${containerId}`;

    permission = managementClient->replacePermission(databaseId, userId, permissionId, 
        permissionModeReplace, permissionResourceReplace);

    if (permission is cosmosdb:Permission) {
        log:print(permission.toString());
        log:print("Success!");
    } else {
        log:printError(permission.message());
    }

    log:print("List permissions");
    stream<cosmosdb:Permission>|error permissionList = managementClient->listPermissions(databaseId, userId);

    if (permissionList is stream<cosmosdb:Permission>) {
        error? e = permissionList.forEach(function (cosmosdb:Permission permission) {
            log:print(permission.toString());
        });
        log:print("Success!");
    } else {
        log:printError(permissionList.message());
    }

    log:print("Get intormation about one permission");
    permission = managementClient->getPermission(databaseId, userId, permissionId);

    if (permission is cosmosdb:Permission) {
        log:print(permission.toString());
        log:print("Success!");
    } else {
        log:printError(permission.message());
    }

    log:print("Delete permission");
    cosmosdb:DeleteResponse|error deleteResponse = managementClient->deletePermission(databaseId, userId, permissionId);

    if (deleteResponse is cosmosdb:DeleteResponse) {
        log:print(deleteResponse.toString());
        log:print("Success!");
    } else {
        log:printError(deleteResponse.message());
    }

    log:print("Delete user");
    deleteResponse = managementClient->deleteUser(databaseId, userId);

    if (deleteResponse is cosmosdb:DeleteResponse) {
        log:print(deleteResponse.toString());
        log:print("Success!");
    } else {
        log:printError(deleteResponse.message());
    }

    log:print("Success!");
}

function createRandomUUIDWithoutHyphens() returns string {
    string? stringUUID = java:toString(createRandomUUID());
    if (stringUUID is string) {
        stringUUID = 'string:substring(regex:replaceAll(stringUUID, "-", ""), 1, 4);
        return stringUUID;
    } else {
        return "";
    }
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;
