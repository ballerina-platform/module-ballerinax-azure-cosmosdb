/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerinax.cosmosdb;

import com.azure.cosmos.models.CosmosStoredProcedureProperties;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.internal.JsonParser;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerinax.cosmosdb.Constants.STORED_PROCEDURE;

/**
 * This class provides functionality for the `RecordIterator` to iterate.
 */
public class RecordIteratorUtils {

    public static Object nextResult(BObject recordIterator) {
        RecordType targetType = (RecordType) recordIterator.getNativeData(Constants.RECORD_TYPE);
        if (targetType.getName().equals(STORED_PROCEDURE)) {
            Iterator<CosmosStoredProcedureProperties> results = (Iterator<CosmosStoredProcedureProperties>)
                    recordIterator.getNativeData(Constants.OBJECT_ITERATOR);
            if (results.hasNext()) {
                Map<String, Object> objectMap = new HashMap<>();
                CosmosStoredProcedureProperties next = results.next();
                objectMap.put("storedProcedure", fromString(next.getBody()));
                objectMap.put("id", fromString(next.getId()));
                objectMap.put("eTag", next.getETag());
                return ValueCreator.createRecordValue(ModuleUtils.getModule(), targetType.getName(), objectMap);
            }
            return null;
        } else {
            Iterator<Object> results = (Iterator<Object>) recordIterator.getNativeData(Constants.OBJECT_ITERATOR);
            ObjectMapper mapper = new ObjectMapper();
            if (results.hasNext()) {
                try {
                    return JsonParser.parse(mapper.writeValueAsString(results.next()));
                } catch (Exception e) {
                    return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
                }
            }
            return null;
        }
    }
}
