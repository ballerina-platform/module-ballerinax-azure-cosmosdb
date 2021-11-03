Ballerina Azure Cosmos DB Connector
===================
[![Build Status](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure-cosmosdb.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

The Cosmos DB SQL(Core) API supports all database-related operations that are carried out extensively by the existing 
developer community.

The Ballerina connector for Azure Cosmos DB provides the capability to connect to Azure Cosmos DB and to execute basic
CRUD (Create, Read, Update and Delete) operations on databases and containers, executing SQL queries to query 
containers, etc. In addition, it allows the special features provided by Cosmos DB such as operations via JavaScript 
language-integrated queries and management of users and permissions.

For more information, see module(s).
- [azure_cosmosdb](cosmosdb/Module.md)

## Building from the source
### Setting up the prerequisites
1.  Download and install Java SE Development Kit (JDK) version 11. You can install either [OpenJDK](https://adoptopenjdk.net/) or [Oracle JDK](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html).
   > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed
   JDK.
 
2. Download and install [Ballerina Swan Lake Beta3](https://ballerina.io/)
 
### Building the source
 
Execute the following commands to build from the source:
 
- To build the package:
   ```   
   bal pack ./cosmosdb
   ```
- To run tests after build:
   ```
   bal test ./cosmosdb
   ```
## Contributing to ballerina
 
As an open source project, Ballerina welcomes contributions from the community.
 
For more information, see [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).
 
## Code of conduct
 
All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).
 
## Useful links
 
* Discuss code changes of the Ballerina project via [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
