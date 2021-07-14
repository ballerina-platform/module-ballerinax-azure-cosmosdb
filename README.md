Ballerina Azure Cosmos DB Connector
===================
[![Build Status](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure-cosmosdb.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-cosmosdb/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

*The Cosmos DB SQL(Core) API which has the full support for all the database related operations and where used 
extensively by the existing developer community.*

*Ballerina connector for Azure Cosmos DB provides the capability to connect to Azure Cosmos DB and to execute basic 
database operations like Create, Read, Update and Delete Databases and Containers, Executing SQL queries to query Containers, etc. Apart from this, it allows
the special features provided by Cosmos DB like operations on JavaScript language-integrated queries, management of
users and permissions.*

For more information, go to the module(s).
- [ballerinax/azure_cosmosdb](https://central.ballerina.io/ballerinax/azure_cosmosdb)

## Building from the Source
### Setting Up the Prerequisites
1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).

* [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

* [OpenJDK](https://adoptopenjdk.net/)

  > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed
  JDK.

2. Download and install [Ballerina SLBeta 2](https://ballerina.io/)


### Building the Source

Execute the commands below to build from the source.

1. To build the package:
   ```   
   bal build -c ./cosmosdb
   ```
2. To run the without tests:
   ```
   bal build -c --skip-tests ./cosmosdb
   ```
## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
