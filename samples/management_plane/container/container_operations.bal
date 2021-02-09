import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;
import ballerina/java;
import ballerina/stringutils;

cosmosdb:AzureCosmosConfiguration managementConfig = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:ManagementClient managementClient = new(managementConfig);

public function main() {

    string databaseId = "my_database";
    var uuid = createRandomUUIDWithoutHyphens();

    string containerId = "my_container";
    string containerWithIndexingId = string `containero_${uuid.toString()}`;
    string containerManualId = string `containerm_${uuid.toString()}`;
    string containerAutoscalingId = string `containera_${uuid.toString()}`;
    string containerIfnotExistId = string `containerx_${uuid.toString()}`;

    
    // Create a container
    log:print("Creating container");
    cosmosdb:PartitionKey partitionKey = {
        paths: ["/id"],
        keyVersion: 2
    };
    cosmosdb:Result containerResult = checkpanic managementClient->createContainer(databaseId, containerId, partitionKey);

    // Create container with indexing policy
    log:print("Creating container with indexing policy");   
    cosmosdb:IndexingPolicy indexingPolicy = {
        indexingMode: "consistent",
        automatic: true,
        includedPaths: [{
            path: "/*",
            indexes: [{
                dataType: "String",
                precision: -1,
                kind: "Range"
            }]
        }]
    };
    cosmosdb:PartitionKey partitionKeyWithIndexing = {
        paths: ["/id"],
        kind: "Hash",
        keyVersion: 2
    };
    containerResult = checkpanic managementClient->createContainer(databaseId, containerWithIndexingId, partitionKeyWithIndexing, indexingPolicy);

    //Create container with manual throughput policy
    log:print("Creating container with manual throughput policy");
    int throughput = 600;
    cosmosdb:PartitionKey partitionKeyManual = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };
    containerResult = checkpanic managementClient->createContainer(databaseId, containerManualId, partitionKeyManual, (), throughput);

    //Create container with autoscaling throughput policy
    log:print("Creating container with autoscaling throughput policy");
    json maxThroughput = {"maxThroughput": 4000};
    cosmosdb:PartitionKey partitionKeyAutoscaling = {
        paths: ["/id"],
        kind: "Hash",
        keyVersion: 2
    };
    containerResult = checkpanic managementClient->createContainer(databaseId, containerAutoscalingId, partitionKeyAutoscaling, (), maxThroughput);

    //Create container if not exist
    log:print("Creating container if not exist");
    cosmosdb:PartitionKey partitionKey5 = {
        paths: ["/AccountNumber"],
        kind: "Hash",
        keyVersion: 2
    };
    cosmosdb:Result? containerIfResult = checkpanic managementClient->createContainerIfNotExist(databaseId, containerIfnotExistId, partitionKey5);

    // Read container info
    log:print("Reading container info");
    cosmosdb:Container container = checkpanic managementClient->getContainer(databaseId, containerId);
    string? etag = container.responseHeaders?.etag;
    string? sessiontoken = container.responseHeaders?.sessionToken;

    // Read container info with options   
    log:print("Reading container info with request options");
    cosmosdb:ResourceReadOptions options = {
        sessionToken: sessiontoken
    };
    container = checkpanic managementClient->getContainer(databaseId, containerId, options);

    // Chack the response of this kind of request from postaman and develop
    // log:print("Reading container info with request options");
    // cosmosdb:ResourceReadOptions options2 = {
    //     ifNoneMatchEtag: etag
    // };
    // container = checkpanic azureCosmosClient->getContainer(databaseId, containerId, options2);

    // Get a list of containers
    log:print("Getting list of containers");
    stream<cosmosdb:Container> containerList = checkpanic managementClient->listContainers(databaseId, 2);

    // Delete a container
    log:print("Deleting the container");
    _ = checkpanic managementClient->deleteContainer(databaseId, containerId);
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