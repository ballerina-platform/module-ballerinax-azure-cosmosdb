# Change Log
This file contains all the notable changes done to the Ballerina Azure Cosmos DB package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Migrated to Java 17 and bumped the minimum supported Ballerina distribution to Swan Lake Update 8 (`2201.8.0`)
- Upgraded the Azure Cosmos DB Java SDK to `4.83.0`, along with `azure-core` `1.59.1`, `reactor-core` `3.7.19`, `reactor-netty` `1.2.18` and `micrometer` `1.15.12`
- Updated Netty to `4.1.137.Final` and Jackson to `2.18.11` to fix security vulnerabilities
- Migrated the build and release workflows to the centralized Ballerina library connector templates

### Fixed
- [Fixed `ManagementClient` operations failing with a `No content` error due to an invalid `Host` header](https://github.com/ballerina-platform/ballerina-library/issues/9231)
