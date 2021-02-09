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

    // Replace User Defined Function
    log:print("Replacing a user defined function");
    string newUserDefinedFunctionBody = string `function taxIncome(income){
                                                    if (income == undefined)
                                                        throw 'no input';
                                                    if (income < 1000)
                                                        return income * 0.1;
                                                    else if (income < 10000)
                                                        return income * 0.2;
                                                    else
                                                        return income * 0.4;
                                                }`;
    cosmosdb:UserDefinedFunction replacementUdf = {
        id: udfId,
        userDefinedFunction: newUserDefinedFunctionBody
    };
    cosmosdb:Result udfReplaceResult = checkpanic azureCosmosClient->replaceUserDefinedFunction(databaseId, containerId, replacementUdf);
    log:print("Success!");
}
