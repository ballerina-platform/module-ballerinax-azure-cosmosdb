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

import com.azure.cosmos.ConsistencyLevel;
import com.azure.cosmos.CosmosClientBuilder;
import com.azure.cosmos.DirectConnectionConfig;
import com.azure.cosmos.GatewayConnectionConfig;
import com.azure.cosmos.models.CosmosItemRequestOptions;
import com.azure.cosmos.models.CosmosQueryRequestOptions;
import com.azure.cosmos.models.CosmosStoredProcedureRequestOptions;
import com.azure.cosmos.models.DedicatedGatewayRequestOptions;
import com.azure.cosmos.models.IndexingDirective;
import com.azure.cosmos.models.PartitionKey;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BValue;

import java.time.Duration;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;
import static io.ballerinax.cosmosdb.Constants.BOUNDED_STALENESS;
import static io.ballerinax.cosmosdb.Constants.CONNECTION_ENDPOINT_REDESCOVERY;
import static io.ballerinax.cosmosdb.Constants.CONNECTION_SHARING_ACROSS_CLIENTS;
import static io.ballerinax.cosmosdb.Constants.CONNECTION_TIMEOUT;
import static io.ballerinax.cosmosdb.Constants.CONSISTENCY_LEVEL;
import static io.ballerinax.cosmosdb.Constants.CONSISTENT_PREFIX;
import static io.ballerinax.cosmosdb.Constants.CONTENT_RESPONSE_ON_WRITE_ENABLED;
import static io.ballerinax.cosmosdb.Constants.DEDICATED_GATEWAY_REQUEST_OPTIONS;
import static io.ballerinax.cosmosdb.Constants.DIRECT_CONNECTION_CONFIG;
import static io.ballerinax.cosmosdb.Constants.DIRECT_MODE;
import static io.ballerinax.cosmosdb.Constants.EVENTUAL;
import static io.ballerinax.cosmosdb.Constants.EXCLUDE;
import static io.ballerinax.cosmosdb.Constants.GATEWAY_CONNECTION_CONFIG;
import static io.ballerinax.cosmosdb.Constants.IDLE_CONNECTION_TIMEOUT;
import static io.ballerinax.cosmosdb.Constants.IDLE_ENDPOINT_TIMEOUT;
import static io.ballerinax.cosmosdb.Constants.IF_MATCH_ETAG;
import static io.ballerinax.cosmosdb.Constants.IF_NONE_MATCH_ETAG;
import static io.ballerinax.cosmosdb.Constants.INCLUDE;
import static io.ballerinax.cosmosdb.Constants.INDEXING_DIRECTIVE;
import static io.ballerinax.cosmosdb.Constants.INDEX_METRICS_ENABLED;
import static io.ballerinax.cosmosdb.Constants.LIMIT_KB;
import static io.ballerinax.cosmosdb.Constants.MAX_BUFFERED_ITEM_COUNT;
import static io.ballerinax.cosmosdb.Constants.MAX_CONNECTIONS_PER_ENDPOINT;
import static io.ballerinax.cosmosdb.Constants.MAX_CONNECTION_POOL_SIZE;
import static io.ballerinax.cosmosdb.Constants.MAX_DEGREE_PARALLELISM;
import static io.ballerinax.cosmosdb.Constants.MAX_INTEGRATED_CACHE_STALENESS;
import static io.ballerinax.cosmosdb.Constants.MAX_REQUESTS_PER_CONNECTION;
import static io.ballerinax.cosmosdb.Constants.NETWORK_TIMEOUT;
import static io.ballerinax.cosmosdb.Constants.PARAMETERS;
import static io.ballerinax.cosmosdb.Constants.PARTITION_KEY;
import static io.ballerinax.cosmosdb.Constants.POST_TRIGGER_INCLUDE;
import static io.ballerinax.cosmosdb.Constants.PREFERRED_REGIONS;
import static io.ballerinax.cosmosdb.Constants.PRE_TRIGGER_INCLUDE;
import static io.ballerinax.cosmosdb.Constants.QUERY_METRICS_ENABLED;
import static io.ballerinax.cosmosdb.Constants.SCAN_QUERY_ENABLED;
import static io.ballerinax.cosmosdb.Constants.SCRIPT_LOGGING_ENABLED;
import static io.ballerinax.cosmosdb.Constants.SESSION;
import static io.ballerinax.cosmosdb.Constants.SESSION_TOKEN;
import static io.ballerinax.cosmosdb.Constants.SP_PROCEDURE_REQUEST_OPTIONS;
import static io.ballerinax.cosmosdb.Constants.STRONG;
import static io.ballerinax.cosmosdb.Constants.THRESHOLD_DIAGNOSIS_TRACER;
import static io.ballerinax.cosmosdb.Constants.THRESHOLD_FOR_DIAGNOSTICS;
import static io.ballerinax.cosmosdb.Constants.THROUHPUT_CONTROL;
import static io.ballerinax.cosmosdb.Constants.USER_AGENT_SUFFIX;

public class Utils {

    public static void setCustomConfiguration(CosmosClientBuilder cosmosClientBuilder, Object customConfig) {
        if (customConfig != null) {
            BMap<BString, Object> customConfigMap = (BMap<BString, Object>) customConfig;
            if (customConfigMap.containsKey(CONSISTENCY_LEVEL)) {
                cosmosClientBuilder.consistencyLevel(setCosistencyLevel(customConfigMap.
                        getStringValue(CONSISTENCY_LEVEL)));
            }
            if (customConfigMap.containsKey(DIRECT_MODE)) {
                setDirectMode(cosmosClientBuilder, (BMap<BString, BValue>) customConfigMap.getMapValue(DIRECT_MODE));
            }
            if (customConfigMap.containsKey(CONNECTION_SHARING_ACROSS_CLIENTS)) {
                cosmosClientBuilder.connectionSharingAcrossClientsEnabled(customConfigMap.
                        getBooleanValue(CONNECTION_SHARING_ACROSS_CLIENTS));
            }
            if (customConfigMap.containsKey(USER_AGENT_SUFFIX)) {
                cosmosClientBuilder.userAgentSuffix(customConfigMap.getStringValue(USER_AGENT_SUFFIX).getValue());
            }
            if (customConfigMap.containsKey(PREFERRED_REGIONS)) {
                cosmosClientBuilder.preferredRegions(Arrays.asList(customConfigMap.getArrayValue(PREFERRED_REGIONS).
                        getStringArray()));
            }
            if (customConfigMap.containsKey(CONTENT_RESPONSE_ON_WRITE_ENABLED)) {
                cosmosClientBuilder.contentResponseOnWriteEnabled(customConfigMap.
                        getBooleanValue(CONTENT_RESPONSE_ON_WRITE_ENABLED));
            }
        }
    }

    private static void setDirectMode(CosmosClientBuilder cosmosClientBuilder, BMap<BString, BValue> mapValue) {
        if (mapValue.containsKey(GATEWAY_CONNECTION_CONFIG) && mapValue.containsKey(DIRECT_CONNECTION_CONFIG)) {
            GatewayConnectionConfig gatewayConfig = setGatewayConnectionConfig(
                    (BMap<BString, BValue>) mapValue.getMapValue(GATEWAY_CONNECTION_CONFIG));
            DirectConnectionConfig directConfig = setDirectConnectionConfig(
                    (BMap<BString, BValue>) mapValue.getMapValue(DIRECT_CONNECTION_CONFIG));
            cosmosClientBuilder.directMode(directConfig, gatewayConfig);
        } else if (mapValue.containsKey(DIRECT_CONNECTION_CONFIG)) {
            DirectConnectionConfig directConfig = setDirectConnectionConfig(
                    (BMap<BString, BValue>) mapValue.getMapValue(DIRECT_CONNECTION_CONFIG));
            cosmosClientBuilder.directMode(directConfig);
        }
    }

    public static PartitionKey createPartitionKey(Object partitionKey) {
        PartitionKey pk = null;
        String type = TypeUtils.getType(partitionKey).toString();
        switch (type) {
            case "string":
                pk = new PartitionKey(partitionKey.toString());
                break;
            case "int":
                pk = new PartitionKey(Integer.valueOf(partitionKey.toString()));
                break;
            case "float":
            case "decimal":
                pk = new PartitionKey(Double.valueOf(partitionKey.toString()));
                break;
        }
        return pk;
    }

    public static CosmosItemRequestOptions createRequestOptions(Object requestOptions) {
        CosmosItemRequestOptions options = new CosmosItemRequestOptions();
        if (requestOptions != null) {
            BMap<BString, Object> mapValue = ((BMap<BString, Object>) requestOptions);
            if (mapValue.containsKey(CONSISTENCY_LEVEL)) {
                options.setConsistencyLevel(setCosistencyLevel(mapValue.getStringValue(CONSISTENCY_LEVEL)));
            }
            if (mapValue.containsKey(INDEXING_DIRECTIVE)) {
                options.setIndexingDirective(setIndexingDirective(mapValue.getStringValue(INDEXING_DIRECTIVE)));
            }
            if (mapValue.containsKey(CONTENT_RESPONSE_ON_WRITE_ENABLED)) {
                options.setContentResponseOnWriteEnabled(mapValue.getBooleanValue(CONTENT_RESPONSE_ON_WRITE_ENABLED));
            }
            if (mapValue.containsKey(DEDICATED_GATEWAY_REQUEST_OPTIONS)) {
                options.setDedicatedGatewayRequestOptions(setDedicatedGatewayRequestOptions((BMap<BString, BValue>)
                        mapValue.getMapValue(DEDICATED_GATEWAY_REQUEST_OPTIONS)));
            }
            if (mapValue.containsKey(IF_MATCH_ETAG)) {
                options.setIfMatchETag(mapValue.getStringValue(IF_MATCH_ETAG).getValue());
            }
            if (mapValue.containsKey(IF_NONE_MATCH_ETAG)) {
                options.setIfNoneMatchETag(mapValue.getStringValue(IF_NONE_MATCH_ETAG).getValue());
            }
            if (mapValue.containsKey(POST_TRIGGER_INCLUDE)) {
                options.setPreTriggerInclude(Arrays.asList(mapValue.getArrayValue((POST_TRIGGER_INCLUDE)).
                        getStringArray()));
            }
            if (mapValue.containsKey(PRE_TRIGGER_INCLUDE)) {
                options.setPreTriggerInclude(Arrays.asList(mapValue.getArrayValue((PRE_TRIGGER_INCLUDE)).
                        getStringArray()));
            }
            if (mapValue.containsKey(SESSION_TOKEN)) {
                options.setThroughputControlGroupName(mapValue.getStringValue(SESSION_TOKEN).getValue());
            }
            if (mapValue.containsKey(THRESHOLD_FOR_DIAGNOSTICS)) {
                options.setThresholdForDiagnosticsOnTracer(Duration.ofSeconds(
                        mapValue.getIntValue(THRESHOLD_FOR_DIAGNOSTICS)));
            }
            if (mapValue.containsKey(THROUHPUT_CONTROL)) {
                options.setThroughputControlGroupName(mapValue.getStringValue(THROUHPUT_CONTROL).getValue());
            }
        }
        return options;
    }

    public static CosmosQueryRequestOptions setQueryOptions(Object requestOptions) {
        CosmosQueryRequestOptions options = new CosmosQueryRequestOptions();
        if (requestOptions != null) {
            BMap<BString, Object> mapValue = (BMap<BString, Object>) requestOptions;
            if (mapValue.containsKey(CONSISTENCY_LEVEL)) {
                options.setConsistencyLevel(setCosistencyLevel(mapValue.getStringValue(CONSISTENCY_LEVEL)));
            }
            if (mapValue.containsKey(DEDICATED_GATEWAY_REQUEST_OPTIONS)) {
                options.setDedicatedGatewayRequestOptions(setDedicatedGatewayRequestOptions((BMap<BString, BValue>)
                        mapValue.getMapValue(DEDICATED_GATEWAY_REQUEST_OPTIONS)));
            }
            if (mapValue.containsKey(INDEX_METRICS_ENABLED)) {
                options.setIndexMetricsEnabled(mapValue.getBooleanValue(INDEX_METRICS_ENABLED));
            }
            if (mapValue.containsKey(MAX_BUFFERED_ITEM_COUNT)) {
                options.setMaxBufferedItemCount(Math.toIntExact(mapValue.getIntValue(MAX_BUFFERED_ITEM_COUNT)));
            }
            if (mapValue.containsKey(MAX_DEGREE_PARALLELISM)) {
                options.setMaxDegreeOfParallelism(Math.toIntExact(mapValue.getIntValue(MAX_DEGREE_PARALLELISM)));
            }
            if (mapValue.containsKey(PARTITION_KEY)) {
                options.setPartitionKey(createPartitionKey(mapValue.getObjectValue(INDEX_METRICS_ENABLED)));
            }
            if (mapValue.containsKey(QUERY_METRICS_ENABLED)) {
                options.setQueryMetricsEnabled(mapValue.getBooleanValue(QUERY_METRICS_ENABLED));
            }
            if (mapValue.containsKey(LIMIT_KB)) {
                options.setResponseContinuationTokenLimitInKb(Math.toIntExact(mapValue.getIntValue(LIMIT_KB)));
            }
            if (mapValue.containsKey(SCAN_QUERY_ENABLED)) {
                options.setScanInQueryEnabled(mapValue.getBooleanValue(SCAN_QUERY_ENABLED));
            }
            if (mapValue.containsKey(SESSION_TOKEN)) {
                options.setSessionToken(mapValue.getStringValue(SESSION_TOKEN).toString());
            }
            if (mapValue.containsKey(THRESHOLD_DIAGNOSIS_TRACER)) {
                options.setThresholdForDiagnosticsOnTracer(Duration.ofSeconds((
                        mapValue.getIntValue(THRESHOLD_DIAGNOSIS_TRACER))));
            }
            if (mapValue.containsKey(THROUHPUT_CONTROL)) {
                options.setThroughputControlGroupName(mapValue.getStringValue(THROUHPUT_CONTROL).getValue());
            }
        }
        return options;
    }

    public static DirectConnectionConfig setDirectConnectionConfig(BMap<BString, BValue> mapValue) {
        DirectConnectionConfig connectionConfig = new DirectConnectionConfig();
        if (mapValue.containsKey(CONNECTION_TIMEOUT)) {
            connectionConfig.setConnectTimeout(Duration.ofSeconds(mapValue.getIntValue(CONNECTION_TIMEOUT)));
        }
        if (mapValue.containsKey(IDLE_CONNECTION_TIMEOUT)) {
            connectionConfig.setIdleConnectionTimeout(Duration.ofSeconds(
                    mapValue.getIntValue(IDLE_CONNECTION_TIMEOUT)));
        }
        if (mapValue.containsKey(IDLE_ENDPOINT_TIMEOUT)) {
            connectionConfig.setIdleEndpointTimeout(Duration.ofSeconds(mapValue.getIntValue(IDLE_ENDPOINT_TIMEOUT)));
        }
        if (mapValue.containsKey(MAX_CONNECTIONS_PER_ENDPOINT)) {
            connectionConfig.setMaxConnectionsPerEndpoint(Math.toIntExact(
                    mapValue.getIntValue(MAX_CONNECTIONS_PER_ENDPOINT)));
        }
        if (mapValue.containsKey(MAX_REQUESTS_PER_CONNECTION)) {
            connectionConfig.setMaxRequestsPerConnection(Math.toIntExact(
                    mapValue.getIntValue(MAX_REQUESTS_PER_CONNECTION)));
        }
        if (mapValue.containsKey(NETWORK_TIMEOUT)) {
            connectionConfig.setNetworkRequestTimeout(Duration.ofSeconds(mapValue.getIntValue(NETWORK_TIMEOUT)));
        }
        if (mapValue.containsKey(CONNECTION_ENDPOINT_REDESCOVERY)) {
            connectionConfig.setConnectionEndpointRediscoveryEnabled(
                    mapValue.getBooleanValue(CONNECTION_ENDPOINT_REDESCOVERY));
        }
        return connectionConfig;
    }

    public static GatewayConnectionConfig setGatewayConnectionConfig(BMap<BString, BValue> mapValue) {
        GatewayConnectionConfig connectionConfig = new GatewayConnectionConfig();
        if (mapValue.containsKey(MAX_CONNECTION_POOL_SIZE)) {
            connectionConfig.setMaxConnectionPoolSize(Math.toIntExact(mapValue.getIntValue(MAX_CONNECTION_POOL_SIZE)));
        }
        if (mapValue.containsKey(IDLE_CONNECTION_TIMEOUT)) {
            connectionConfig.setIdleConnectionTimeout(Duration.ofSeconds(
                    mapValue.getIntValue(IDLE_CONNECTION_TIMEOUT)));
        }
        return connectionConfig;
    }


    public static ConsistencyLevel setCosistencyLevel(BString level) {
        ConsistencyLevel consistencyLevel = null;
        switch (level.getValue()) {
            case STRONG:
                consistencyLevel = ConsistencyLevel.STRONG;
                break;
            case BOUNDED_STALENESS:
                consistencyLevel = ConsistencyLevel.BOUNDED_STALENESS;
                break;
            case SESSION:
                consistencyLevel = ConsistencyLevel.SESSION;
                break;
            case EVENTUAL:
                consistencyLevel = ConsistencyLevel.EVENTUAL;
                break;
            case CONSISTENT_PREFIX:
                consistencyLevel = ConsistencyLevel.CONSISTENT_PREFIX;
                break;
        }
        return consistencyLevel;
    }

    public static IndexingDirective setIndexingDirective(BString directive) {
        IndexingDirective indexingDirective = null;
        switch (directive.getValue()) {
            case INCLUDE:
                indexingDirective = IndexingDirective.INCLUDE;
                break;
            case EXCLUDE:
                indexingDirective = IndexingDirective.EXCLUDE;
                break;
        }
        return indexingDirective;
    }

    private static DedicatedGatewayRequestOptions setDedicatedGatewayRequestOptions(BMap<BString, BValue> mapValue) {
        DedicatedGatewayRequestOptions options = new DedicatedGatewayRequestOptions();
        options.setMaxIntegratedCacheStaleness(Duration.ofSeconds(
                mapValue.getIntValue(MAX_INTEGRATED_CACHE_STALENESS)));
        return options;
    }

    public static CosmosStoredProcedureRequestOptions setStoredProcedureRequestOptions(Object requestOptions) {
        CosmosStoredProcedureRequestOptions options = new CosmosStoredProcedureRequestOptions();
        setStoredProcedureRequestOptions(options, requestOptions);
        return options;
    }

    private static void setStoredProcedureRequestOptions(CosmosStoredProcedureRequestOptions options,
                                                         Object requestOptions) {
        if (requestOptions != null) {
            BMap<BString, Object> mapValue = (BMap<BString, Object>) requestOptions;
            if (mapValue.containsKey(IF_MATCH_ETAG)) {
                options.setIfMatchETag(mapValue.getStringValue(IF_MATCH_ETAG).getValue());
            }
            if (mapValue.containsKey(IF_NONE_MATCH_ETAG)) {
                options.setIfNoneMatchETag(mapValue.getStringValue(IF_NONE_MATCH_ETAG).getValue());
            }
            if (mapValue.containsKey(PARTITION_KEY)) {
                options.setPartitionKey(createPartitionKey(mapValue.getObjectValue(INDEX_METRICS_ENABLED)));
            }
            if (mapValue.containsKey(SCRIPT_LOGGING_ENABLED)) {
                options.setScriptLoggingEnabled(mapValue.getBooleanValue(SCRIPT_LOGGING_ENABLED));
            }
            if (mapValue.containsKey(SESSION_TOKEN)) {
                options.setSessionToken(mapValue.getStringValue(SESSION_TOKEN).toString());
            }
        }
    }

    public static CosmosStoredProcedureRequestOptions setExecuteStoredProcedureRequestOptions(Object partitionKey,
                                                                                              Object requestOptions) {
        CosmosStoredProcedureRequestOptions options = new CosmosStoredProcedureRequestOptions();
        options.setPartitionKey(createPartitionKey(partitionKey));
        if (requestOptions != null) {
            BMap<BString, Object> mapValue = (BMap<BString, Object>) requestOptions;
            if (mapValue.containsKey(SP_PROCEDURE_REQUEST_OPTIONS)) {
                setStoredProcedureRequestOptions(options, mapValue.getObjectValue(SP_PROCEDURE_REQUEST_OPTIONS));
            }
        }
        return options;
    }

    public static List<Object> setProcedureParams(Object requestOptions) {
        if (requestOptions != null) {
            BMap<BString, Object> mapValue = (BMap<BString, Object>) requestOptions;
            if (mapValue.containsKey(PARAMETERS)) {
                BArray value = mapValue.getArrayValue(PARAMETERS);
                return Arrays.asList(value.getStringArray());
            }
        }
        return null;
    }

    /**
     * Convert Map to BMap.
     *
     * @param object Object used to convert to BMap.
     * @return Converted BMap object.
     */
    public static BMap<BString, Object> toBMap(Object object) {
        ObjectMapper objectMapper = new ObjectMapper();
        Map map = objectMapper.convertValue(object, Map.class);
        BMap<BString, Object> returnMap = ValueCreator.createMapValue();
        if (map != null) {
            for (Object aKey : map.keySet().toArray()) {
                returnMap.put(fromString(aKey.toString()),
                        fromString(map.get(aKey).toString()));
            }
        }
        return returnMap;
    }
}
