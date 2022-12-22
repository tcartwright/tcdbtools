# TCDbTools 

## Table of Contents

* [Description](#description) 
* [Installation](#installation)
* [Functions](#functions)

##  Description

Collection of Powershell tools for SQL Server management. 

## Installation

TCDbTools is published to the [Powershell Gallery](https://www.powershellgallery.com/packages/tcdbtools)
and can be installed as follows:

```powershell
Install-Module tcdbtools
```

## Functions

* [Invoke-DBSafeShrink](docs/Invoke-DBSafeShrink.md) : Can be used to shrink an mdf file and rebuild all indexes at the same time. Typically faster then a normal shrink. This function does NOT make use of DBCC SHRINKDATABASE or DBCC SHRINKFILE.
* [Invoke-DBMoveIndexes](docs/Invoke-DBMoveIndexes.md) : Moves all indexes from one file group to another, including heaps.
* [Invoke-DBCompareServerSettings](docs/Invoke-DBCompareServerSettings.md) : Compares the server settings between two or more servers.
* [Invoke-DBExtractCLRDLL](docs/Invoke-DBExtractCLRDLL.md) : Extracts all user defined CLR dlls from a SQL server.
* [Invoke-DBScriptObjects](docs/Invoke-DBScriptObjects.md) : Scripts all objects from a database to individual files per object.
* [Invoke-DBRenameConstraints](docs/Invoke-DBRenameConstraints.md) : Will rename all indexes and constraints to match naming conventions. 

## Helper Functions

* [New-DBScripterObject](docs/New-DBScripterObject.md) : Creates a database scripting object that can be modified and used by Invoke-DBScriptObjects.
* [New-DBSqlConnection](docs/New-DBSqlConnection.md) : Creates a SqlConnection.
* [New-DBSqlObjects](docs/New-DBSqlObjects.md) : Creates two objects that can be used for connectivity.

