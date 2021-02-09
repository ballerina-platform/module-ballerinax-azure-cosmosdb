import ballerinax/cosmosdb;
import ballerina/log;
import ballerina/config;

cosmosdb:AzureCosmosConfiguration configuration = {
    baseUrl: config:getAsString("BASE_URL"),
    masterOrResourceToken: config:getAsString("MASTER_OR_RESOURCE_TOKEN")
};

cosmosdb:CoreClient azureCosmosClient = new (configuration);

public function main() {
    string databaseId = "my_database";
    string containerId = "my_container";
    string udfId = "my_udf";

    // Create User Defined Function
    log:print("Creating a user defined function");
    string userDefinedFunctionBody = string `function tax(income){
                                                if (income == undefined)
                                                    throw 'no input';

                                                if (income < 1000)
                                                    return income * 0.1;
                                                else if (income < 10000)
                                                    return income * 0.2;
                                                else
                                                    return income * 0.4;
                                            }`;
    cosmosdb:UserDefinedFunction newUDF = {
        id: udfId,
        userDefinedFunction: userDefinedFunctionBody
    };
    cosmosdb:Result udfCreateResult = checkpanic azureCosmosClient->createUserDefinedFunction(databaseId, containerId, newUDF);
    log:print("Success!");
}
