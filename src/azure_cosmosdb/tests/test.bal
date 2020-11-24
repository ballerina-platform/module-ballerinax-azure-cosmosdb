import ballerina/io;
import ballerina/test;
import ballerina/config;
import ballerina/system;

AzureCosmosConfiguration config = {
    baseUrl : getConfigValue("BASE_URL"),
    masterKey : getConfigValue("MASTER_KEY"),
    host : getConfigValue("HOST"),
    tokenType : getConfigValue("TOKEN_TYPE"),
    tokenVersion : getConfigValue("TOKEN_VERSION"),
    secureSocketConfig :{
                            trustStore: {
                            path: "/usr/lib/ballerina/distributions/ballerina-slp4/bre/security/ballerinaTruststore.p12",
                            password: "ballerina"
                            }
                        }
};

@test:Config {
    //enable: false
}
function createDB() {
    io:println("--------------Create database------------------------\n\n");

    Client AzureCosmosClient = new(config);

    DatabaseProperties db = {};
    db.id = "extreme";
    var result = AzureCosmosClient->createDatabase(db);
    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
    io:println("\n\n");
}

function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}