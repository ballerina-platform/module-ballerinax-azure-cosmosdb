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

isolated function ofEpochSecond(int epochSeconds, int nanoAdjustments) returns handle = @java:Method {
    'class: "java.time.Instant",
    name: "ofEpochSecond"
} external;

isolated function getZoneId(handle zoneId) returns handle = @java:Method {
    'class: "java.time.ZoneId",
    name: "of"
} external;

isolated function atZone(handle receiver, handle zoneId) returns handle = @java:Method {
    'class: "java.time.Instant",
    name: "atZone"
} external;

isolated function ofPattern(handle pattern) returns handle = @java:Method {
    'class: "java.time.format.DateTimeFormatter",
    name: "ofPattern"
} external;

isolated function format(handle receiver, handle dateTimeFormatter) returns handle = @java:Method {
    'class: "java.time.ZonedDateTime",
    name: "format"
} external;
