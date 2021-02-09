import ballerinax/cosmosdb;
import ballerina/config;
import ballerina/log;
import ballerina/java;
import ballerina/stringutils;

cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:CoreClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    var uuid = createRandomUUIDWithoutHyphens();

    // Create a stored procedure
    log:print("Creating stored procedure");
    string storedProcedureId = string `sproc_${uuid.toString()}`;
    string storedProcedureBody = string `function (){
                                            var context = getContext();
                                            var response = context.getResponse();
                                            response.setBody("Hello,  World");
                                        }`;
    cosmosdb:StoredProcedure storedProcedureRecord = {
        id: storedProcedureId,
        storedProcedure: storedProcedureBody
    };

    cosmosdb:Result storedProcedureCreateResult = checkpanic azureCosmosClient->createStoredProcedure(databaseId, containerId, storedProcedureRecord);

    // Replace stored procedure
    log:print("Replacing stored procedure");
    string newStoredProcedureBody = string `function heloo(personToGreet){
                                                var context = getContext();
                                                var response = context.getResponse();
                                                response.setBody("Hello, " + personToGreet);
                                            }`;
    cosmosdb:StoredProcedure newStoredProcedure = {
        id: storedProcedureId,
        storedProcedure: newStoredProcedureBody
    };
    cosmosdb:Result storedProcedureReplaceResult = checkpanic azureCosmosClient->replaceStoredProcedure(databaseId, containerId, newStoredProcedure);

    // Get a list of stored procedures
    log:print("List stored procedure");
    stream<cosmosdb:StoredProcedure> result5 = checkpanic azureCosmosClient->listStoredProcedures(databaseId, containerId);

    // Execute stored procedure
    log:print("Executing stored procedure");
    cosmosdb:StoredProcedureOptions options = {
        parameters: ["Sachi"]
    };

    json result = checkpanic azureCosmosClient->executeStoredProcedure(databaseId, containerId, storedProcedureId, 
            options);

    // Delete Stored procedure
    log:print("Deleting stored procedure");
    _ = checkpanic azureCosmosClient->deleteStoredProcedure(databaseId, containerId, storedProcedureId);
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