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
import ballerinax/azure.cosmosdb;

cosmosdb:ConnectionConfig config = {
    baseUrl: os:getEnv("BASE_URL"),
    primaryKeyOrResourceToken: os:getEnv("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = check new (config);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Get database container to get the resource ids of them.
    cosmosdb:Database database = checkpanic managementClient->getDatabase(databaseId);
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);

    log:printInfo("Creating user");
    string userId = string `user_${uuid.toString()}`;
    cosmosdb:User|error userCreationResult = managementClient->createUser(databaseId, userId);

    if (userCreationResult is cosmosdb:User) {
        log:printInfo(userCreationResult.toString());
        log:printInfo("Success!");
    } else {
        log:printError(userCreationResult.message());
    }

    log:printInfo("Replace user id");
    string newUserId = string `user_${uuid.toString()}`;
    cosmosdb:User|error userReplaceResult = managementClient->replaceUserId(databaseId, userId, newUserId);

    if (userReplaceResult is cosmosdb:User) {
        log:printInfo(userReplaceResult.toString());
        log:printInfo("Success!");
    } else {
        log:printError(userReplaceResult.message());
    }

    log:printInfo("Get user information");
    cosmosdb:User|error user = managementClient->getUser(databaseId, userId);

    if (user is cosmosdb:User) {
        log:printInfo(user.toString());
        log:printInfo("Success!");
    } else {
        log:printError(user.message());
    }

    log:printInfo("List users");
    stream<cosmosdb:User, error?>|error userList = managementClient->listUsers(databaseId);
    if (userList is stream<cosmosdb:User, error?) {
        error? e = userList.forEach(function (cosmosdb:User storedPrcedure) {
            log:printInfo(storedPrcedure.toString());
        });
        log:printInfo("Success!");
    } else {
        log:printError(userList.message());
    }

    //------------------------------------------------Permissions-------------------------------------------------------

    log:printInfo("Create permission for a user");
    string permissionId = string `permission_${uuid.toString()}`;
    cosmosdb:PermisssionMode permissionMode = "All";
    string permissionResource =
        string `dbs/${database?.resourceId.toString()}/colls/${container?.resourceId.toString()}`;

    cosmosdb:Permission|error permission = managementClient->createPermission(databaseId, userId, permissionId,
        permissionMode, <@untainted>permissionResource);

    if (permission is cosmosdb:Permission) {
        log:printInfo(permission.toString());
        log:printInfo("Success!");
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

    log:printInfo("Replace permission");
    cosmosdb:PermisssionMode permissionModeReplace = "All";
    string permissionResourceReplace = string `dbs/${databaseId}/colls/${containerId}`;

    permission = managementClient->replacePermission(databaseId, userId, permissionId,
        permissionModeReplace, permissionResourceReplace);

    if (permission is cosmosdb:Permission) {
        log:printInfo(permission.toString());
        log:printInfo("Success!");
    } else {
        log:printError(permission.message());
    }

    log:printInfo("List permissions");
    stream<cosmosdb:Permission, error?>|error permissionList = managementClient->listPermissions(databaseId, userId);
    if (permissionList is stream<cosmosdb:Permission, error?>) {
        error? e = permissionList.forEach(function (cosmosdb:Permission storedPrcedure) {
            log:printInfo(storedPrcedure.toString());
        });
        log:printInfo("Success!");
    } else {
        log:printError(permissionList.message());
    }

    log:printInfo("Get intormation about one permission");
    permission = managementClient->getPermission(databaseId, userId, permissionId);

    if (permission is cosmosdb:Permission) {
        log:printInfo(permission.toString());
        log:printInfo("Success!");
    } else {
        log:printError(permission.message());
    }

    log:printInfo("Delete permission");
    cosmosdb:DeleteResponse|error deleteResponse = managementClient->deletePermission(databaseId, userId, permissionId);

    if (deleteResponse is cosmosdb:DeleteResponse) {
        log:printInfo(deleteResponse.toString());
        log:printInfo("Success!");
    } else {
        log:printError(deleteResponse.message());
    }

    log:printInfo("Delete user");
    deleteResponse = managementClient->deleteUser(databaseId, userId);

    if (deleteResponse is cosmosdb:DeleteResponse) {
        log:printInfo(deleteResponse.toString());
        log:printInfo("Success!");
    } else {
        log:printError(deleteResponse.message());
    }

    log:printInfo("Success!");
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
