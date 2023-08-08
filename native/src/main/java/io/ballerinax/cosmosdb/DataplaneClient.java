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

import com.azure.cosmos.CosmosClient;
import com.azure.cosmos.CosmosClientBuilder;
import com.azure.cosmos.CosmosContainer;
import com.azure.cosmos.CosmosDatabase;
import com.azure.cosmos.models.CosmosItemResponse;
import com.azure.cosmos.models.CosmosQueryRequestOptions;
import com.azure.cosmos.models.CosmosStoredProcedureProperties;
import com.azure.cosmos.models.CosmosStoredProcedureRequestOptions;
import com.azure.cosmos.models.CosmosStoredProcedureResponse;
import com.azure.cosmos.util.CosmosPagedIterable;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.runtime.api.values.BValue;
import org.ballerinalang.langlib.value.FromJsonStringWithType;

import java.util.Iterator;
import java.util.List;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerinax.cosmosdb.Constants.BASEURL;
import static io.ballerinax.cosmosdb.Constants.COSMOS_RESULT_ITERATOR_OBJECT;
import static io.ballerinax.cosmosdb.Constants.STORED_PROCEDURE;
import static io.ballerinax.cosmosdb.Constants.TOKEN;
import static io.ballerinax.cosmosdb.Utils.createDocumentResponse;
import static io.ballerinax.cosmosdb.Utils.createPartitionKey;
import static io.ballerinax.cosmosdb.Utils.createRequestOptions;
import static io.ballerinax.cosmosdb.Utils.createStoredProcedureMap;
import static io.ballerinax.cosmosdb.Utils.setExecuteStoredProcedureRequestOptions;
import static io.ballerinax.cosmosdb.Utils.setProcedureParams;
import static io.ballerinax.cosmosdb.Utils.setQueryOptions;
import static io.ballerinax.cosmosdb.Utils.setStoredProcedureRequestOptions;

/**
 * The class provides dataplane operations for Azure CosmosDB interactions.
 */
public class DataplaneClient {

    private static CosmosClientBuilder cosmosClientBuilder;
    private static CosmosClient cosmosClient;
    private static ObjectMapper objectMapper = new ObjectMapper();

    public static Object initClient(Environment env, BObject client, BMap<BString, BValue> config,
                                    Object customConfig) {
        String baseUrl = config.containsKey(BASEURL) ? config.getStringValue(BASEURL).getValue() : "";
        String token = config.containsKey(TOKEN) ? config.getStringValue(TOKEN).getValue() : "";
        cosmosClientBuilder = new CosmosClientBuilder();
        try {
            cosmosClientBuilder.endpoint(baseUrl).key(token);
            Utils.setCustomConfiguration(cosmosClientBuilder, customConfig);
            cosmosClient = cosmosClientBuilder.buildClient();
            return null;
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object createDocument(Environment env, BString databaseId, BString containerId, BMap document,
                                        Object partitionKey, Object requestOptions) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            Object documentObject = objectMapper.readValue(document.toString(), Object.class);
            CosmosItemResponse<Object> response = container.createItem(documentObject, createPartitionKey(partitionKey),
                    createRequestOptions(requestOptions));
            return createDocumentResponse(response);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object replaceDocument(Environment env, BString databaseId, BString containerId, BString documentId,
                                         BMap document, Object partitionKey, Object requestOptions) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            Object documentObject = objectMapper.readValue(document.toString(), Object.class);
            CosmosItemResponse<Object> response = container.replaceItem(documentObject, documentId.getValue(),
                    createPartitionKey(partitionKey), createRequestOptions(requestOptions));
            return createDocumentResponse(response);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object getDocument(Environment env, BObject client, BString databaseId, BString containerId,
                                     BString documentId, Object partitionKey, Object requestOptions,
                                     BTypedesc recordType) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            Object item = container.readItem(documentId.toString(), createPartitionKey(partitionKey),
                    createRequestOptions(requestOptions), Object.class).getItem();
            String jsonStringItem = objectMapper.writeValueAsString(item);
            return FromJsonStringWithType.fromJsonStringWithType(fromString(jsonStringItem), recordType);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object queryDocuments(Environment env, BObject client, BString databaseId, BString containerId,
                                        BString query, Object queryOptions, BTypedesc recordType) {

        CosmosQueryRequestOptions options = setQueryOptions(queryOptions);

        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            CosmosPagedIterable<Object> objects = container.queryItems(query.getValue(), options, Object.class);
            Iterator<Object> objectIterator = objects.iterator();
            RecordType targetType = (RecordType) recordType.getDescribingType();

            BObject bObject = ValueCreator.createObjectValue(ModuleUtils.getModule(), Constants.RESULT_ITERATOR_OBJECT,
                    ValueCreator.createObjectValue(ModuleUtils.getModule(), COSMOS_RESULT_ITERATOR_OBJECT));
            bObject.addNativeData(Constants.OBJECT_ITERATOR, objectIterator);
            bObject.addNativeData(Constants.RECORD_TYPE, targetType);
            return ValueCreator.createStreamValue(TypeCreator.createStreamType(targetType, PredefinedTypes.TYPE_NULL),
                    bObject);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object getDocumentList(Environment env, BObject client, BString databaseId, BString containerId,
                                         Object partitionKey, Object queryOptions, BTypedesc recordType) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            CosmosQueryRequestOptions options = setQueryOptions(queryOptions);
            CosmosPagedIterable<Object> objects = container.readAllItems(createPartitionKey(partitionKey), options,
                    Object.class);
            Iterator<Object> objectIterator = objects.iterator();
            RecordType targetType = (RecordType) recordType.getDescribingType();

            BObject bObject = ValueCreator.createObjectValue(ModuleUtils.getModule(), Constants.RESULT_ITERATOR_OBJECT,
                    ValueCreator.createObjectValue(ModuleUtils.getModule(), COSMOS_RESULT_ITERATOR_OBJECT));
            bObject.addNativeData(Constants.OBJECT_ITERATOR, objectIterator);
            bObject.addNativeData(Constants.RECORD_TYPE, targetType);
            return ValueCreator.createStreamValue(TypeCreator.createStreamType(targetType, PredefinedTypes.TYPE_NULL),
                    bObject);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }


    public static Object deleteDocument(Environment env, BObject client, BString databaseId, BString containerId,
                                        BString itemId, Object partitionKey, Object requestOptions) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            CosmosItemResponse<Object> response = container.deleteItem(itemId.getValue(),
                    createPartitionKey(partitionKey), createRequestOptions(requestOptions));
            return createDocumentResponse(response);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object createStoredProcedure(Environment env, BString databaseId, BString containerId,
                                               BString storedProcedureId, BString storedProcedure,
                                               Object requestOptions) {
        CosmosStoredProcedureProperties properties = new CosmosStoredProcedureProperties(storedProcedureId.getValue(),
                storedProcedure.getValue());
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            CosmosStoredProcedureResponse response = container.getScripts().createStoredProcedure(properties,
                    setStoredProcedureRequestOptions(requestOptions));
            return createStoredProcedureMap(response);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object listStoredProcedures(Environment env, BObject client, BString databaseId,
                                              BString containerId) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            CosmosPagedIterable<CosmosStoredProcedureProperties> cosmosStoredProcedures = container.getScripts().
                    readAllStoredProcedures();
            Iterator<CosmosStoredProcedureProperties> iterator = cosmosStoredProcedures.iterator();

            RecordType returnType = TypeCreator.createRecordType(STORED_PROCEDURE, ModuleUtils.getModule(), 0,
                    true, 0);
            BObject bObject = ValueCreator.createObjectValue(ModuleUtils.getModule(), Constants.RESULT_ITERATOR_OBJECT,
                    ValueCreator.createObjectValue(ModuleUtils.getModule(), COSMOS_RESULT_ITERATOR_OBJECT));
            bObject.addNativeData(Constants.OBJECT_ITERATOR, iterator);
            bObject.addNativeData(Constants.RECORD_TYPE, returnType);

            return ValueCreator.createStreamValue(TypeCreator.createStreamType(returnType, PredefinedTypes.TYPE_NULL),
                    bObject);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object deleteStoredProcedure(Environment env, BObject client, BString databaseId, BString containerId,
                                               BString storedProcedureId) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            CosmosStoredProcedureResponse response = container.getScripts().getStoredProcedure(
                    storedProcedureId.getValue()).delete();
            return createStoredProcedureMap(response);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object executeStoredProcedure(Environment env, BObject client, BString databaseId,
                                                BString containerId, BString storedProcedureId, Object partitionKey,
                                                Object storedProcedureExecuteOptions) {
        try {
            CosmosContainer container = getContainer(databaseId, containerId);
            List<Object> parameters = setProcedureParams(storedProcedureExecuteOptions);
            CosmosStoredProcedureRequestOptions options = setExecuteStoredProcedureRequestOptions(partitionKey,
                    storedProcedureExecuteOptions);
            CosmosStoredProcedureResponse response = container.getScripts().getStoredProcedure(
                    storedProcedureId.getValue()).execute(parameters, options);
            return createStoredProcedureMap(response);
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    public static Object close() {
        try {
            cosmosClient.close();
            return null;
        } catch (Exception e) {
            return BallerinaErrorGenerator.createBallerinaDatabaseError(e);
        }
    }

    private static CosmosContainer getContainer(BString databaseId, BString containerId) {
        CosmosDatabase database = cosmosClient.getDatabase(databaseId.getValue());
        return database.getContainer(containerId.getValue());
    }
}
