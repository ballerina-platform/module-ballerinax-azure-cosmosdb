// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# Represents ResultIterator.
public class ResultIterator {

    private Error? err;

    public isolated function init(Error? err = ()) {
        self.err = err;
    }

    public isolated function next() returns record {|record {} value;|}|Error? {
        record {}|Error? result;
        result = nextResult(self);
        if (result is record {}) {
            record {|
                record {} value;
            |} streamRecord = {value: result};
            return streamRecord;
        } else {
            self.err = result;
            return self.err;
        }
    }
}

isolated function nextResult(ResultIterator iterator) returns record {}|Error? = @java:Method {
    'class: "io.ballerinax.cosmosdb.RecordIteratorUtils"
} external;

# Represents CosmosResultIterator.
public class CosmosResultIterator {
    public isolated function nextResult(ResultIterator iterator) returns record {}|Error? = @java:Method {
        'class: "io.ballerinax.cosmosdb.RecordIteratorUtils"
    } external;
}
