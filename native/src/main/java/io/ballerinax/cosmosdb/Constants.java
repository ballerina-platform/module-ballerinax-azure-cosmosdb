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

import io.ballerina.runtime.api.values.BString;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;

/**
 * The class holds the constants relevant to the module.
 */
public class Constants {

    public static final BString BASEURL = fromString("baseUrl");
    public static final BString TOKEN = fromString("primaryKeyOrResourceToken");

    public static final BString CONSISTENCY_LEVEL = fromString("consistencyLevel");
    public static final String STRONG = "Strong";
    public static final String BOUNDED_STALENESS = "BoundedStaleness";
    public static final String SESSION = "Session";
    public static final String EVENTUAL = "Eventual";
    public static final String CONSISTENT_PREFIX = "ConsistentPrefix";
    public static final BString DIRECT_MODE = fromString("directMode");
    public static final BString DIRECT_CONNECTION_CONFIG = fromString("directConnectionConfig");
    public static final BString GATEWAY_CONNECTION_CONFIG = fromString("gatewayConnectionConfig");

    public static final BString CONNECTION_TIMEOUT =  fromString("connectTimeout");
    public static final BString IDLE_CONNECTION_TIMEOUT =   fromString("idleConnectionTimeout");
    public static final BString IDLE_ENDPOINT_TIMEOUT =   fromString("idleEndpointTimeout");
    public static final BString MAX_CONNECTIONS_PER_ENDPOINT =  fromString("maxConnectionsPerEndpoint");
    public static final BString MAX_REQUESTS_PER_CONNECTION =  fromString("maxRequestsPerConnection");
    public static final BString NETWORK_TIMEOUT =  fromString("networkRequestTimeout");
    public static final BString CONNECTION_ENDPOINT_REDESCOVERY = fromString("connectionEndpointRediscoveryEnabled");

    public static final BString MAX_CONNECTION_POOL_SIZE = fromString("maxConnectionPoolSize");

    public static final BString CONNECTION_SHARING_ACROSS_CLIENTS = fromString("connectionSharingAcrossClientsEnabled");
    public static final BString USER_AGENT_SUFFIX = fromString("userAgentSuffix");
    public static final BString PREFERRED_REGIONS = fromString("preferredRegions");
    public static final BString CONTENT_RESPONSE_ON_WRITE_ENABLED = fromString("contentResponseOnWriteEnabled");

    public static final BString INDEXING_DIRECTIVE = fromString("indexingDirective");
    public static final String INCLUDE = "Include";
    public static final String EXCLUDE = "Exclude";
    public static final BString DEDICATED_GATEWAY_REQUEST_OPTIONS = fromString("dedicatedGatewayRequestOptions");
    public static final BString IF_MATCH_ETAG = fromString("ifMatchETag");
    public static final BString IF_NONE_MATCH_ETAG = fromString("ifNoneMatchETag");
    public static final BString POST_TRIGGER_INCLUDE = fromString("postTriggerInclude");
    public static final BString PRE_TRIGGER_INCLUDE = fromString("preTriggerInclude");
    public static final BString SESSION_TOKEN = fromString("sessionToken");
    public static final BString THRESHOLD_FOR_DIAGNOSTICS = fromString("throughputControlGroupName");
    public static final BString THROUHPUT_CONTROL = fromString("throughputControlGroupName");

    public static final BString INDEX_METRICS_ENABLED = fromString("indexMetricsEnabled");
    public static final BString MAX_BUFFERED_ITEM_COUNT = fromString("maxBufferedItemCount");
    public static final BString MAX_DEGREE_PARALLELISM = fromString("maxDegreeOfParallelism");
    public static final BString PARTITION_KEY = fromString("partitionkey");
    public static final BString QUERY_METRICS_ENABLED = fromString("queryMetricsEnabled");
    public static final BString LIMIT_KB = fromString("limitInKb");
    public static final BString SCAN_QUERY_ENABLED = fromString("scanInQueryEnabled");
    public static final BString THRESHOLD_DIAGNOSIS_TRACER = fromString("thresholdForDiagnosticsOnTracer");

    public static final BString MAX_INTEGRATED_CACHE_STALENESS = fromString("maxIntegratedCacheStaleness");
    public static final BString SP_PROCEDURE_REQUEST_OPTIONS = fromString("cosmosStoredProcedureRequestOptions");
    public static final BString PARAMETERS = fromString("parameters");
    public static final BString SCRIPT_LOGGING_ENABLED = fromString("scriptLoggingEnabled");

    public static final String RESULT_ITERATOR_OBJECT = "ResultIterator";
    public static final String COSMOS_RESULT_ITERATOR_OBJECT = "CosmosResultIterator";
    public static final String RECORD_TYPE = "recordType";
    public static final String OBJECT_ITERATOR = "ObjectIterator";
    public static final String STORED_PROCEDURE = "StoredProcedure";
    public static final String DIAGNOSTICS = "Diagnostics";
    public static final String DOCUMENT_RESPONSE = "DocumentResponse";
    public static final String STORED_PROCEDURE_RESPONSE = "StoredProcedureResponse";

}
