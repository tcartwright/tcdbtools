# TCDbTools 

## Table of Contents

* [Description](#description) 
* [Installation](#installation)
* [Functions](#functions)

##  Description

Collection of PowerShell tools for SQL Server management. 

## Installation

TCDbTools is published to the [Powershell Gallery][def]
and can be installed as follows:

```powershell
Install-Module tcdbtools
```

## Functions

* [Invoke-DBSafeShrink](/docs/Invoke-DBSafeShrink.md) : Can be used to shrink an mdf file ***and*** rebuild all indexes at the same time. Typically faster then a normal shrink. Can not be used to shrink an LDF file. Does not cause fragmentation like a normal shrink. Based upon Paul Randal's shrinking methodology. 
* [Invoke-DBDeployAgentJob](/docs/Invoke-DBDeployAgentJob.md) : This function is designed to deploy SQL Agent jobs using variables that can customize the deployment for each server. Can be used to quickly update all of your jobs across your entire network even if they need customization per server.
* [Invoke-DBSqlAgentScripter](/docs/Invoke-DBSqlAgentScripter.md) : Will script out all Sql Agent objects to sql script files. 
* [Invoke-DBMoveIndexes](/docs/Invoke-DBMoveIndexes.md) : Moves all indexes from one file group to another, including heaps.
* [Invoke-DBCompareServerSettings](/docs/Invoke-DBCompareServerSettings.md) : Compares the server settings between two or more servers.
* [Invoke-DBExtractCLRDLL](/docs/Invoke-DBExtractCLRDLL.md) : Extracts all user defined CLR objects from a SQL server.
* [Invoke-DBScriptObjects](/docs/Invoke-DBScriptObjects.md) : Scripts all objects from a database to individual files per object in a schema\type\script hierarchy.
* [Invoke-DBRenameConstraints](/docs/Invoke-DBRenameConstraints.md) : Will rename all indexes and constraints to match naming conventions. The naming conventions can be customized. 
* [Find-DBInvalidSettings](/docs/Find-DBInvalidSettings.md) : Finds settings and options that may or may not be invalid depending upon design choices. They are typically invalid however and should be investigated.
* [Find-DBValue](/docs/Find-DBValue.md) : Scans a database for a value. Returns all tables and columns that contain that value, as well as the value itself. The scan is broken up into multiple threads. 
* [Test-DBReadOnlyRouting](/docs/Test-DBReadOnlyRouting.md) : Tests read only routing for an availability group, and returns whether or not the routing is valid.
* [Find-DBColumnDataTypeDiscrepancies](/docs/Find-DBColumnDataTypeDiscrepancies.md) : Scans the database for columns in different tables that have the same names, but differ by data type.


## Helper Functions

* [New-DBScripterObject](/docs/New-DBScripterObject.md) : Creates a database scripting object that can be modified and used by Invoke-DBScriptObjects.
* [New-DBSqlConnection](/docs/New-DBSqlConnection.md) : Creates a SqlConnection.
* [New-DBSMOServer](/docs/New-DBSqlCmdArguments.md) : Returns a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections.
* [New-DBSqlCmdArguments](/docs/New-DBSqlCmdArguments.md) : Creates a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.
* Invoke-DBScalarQuery : Executes the query, and returns the first column of the first row in the result set returned by the query. Additional columns or rows are ignored.
* Invoke-DBNonQuery : Executes a Transact-SQL statement against the connection and returns the number of rows affected.
* Invoke-DBReaderQuery : Sends the CommandText to the Connection and builds a SqlDataReader.
* Invoke-DBDataSetQuery : Executes a Transact-SQL statement against the connection and returns a DataSet containing a DataTable for each result set returned.
* New-DBSqlParameter : Creates a new instance of a SqlParameter object.
* [Get-DBInClauseParams](/docs/Get-DBInClauseParams.md) : Can be used to create a set of parameters that can be used with an IN clause.
* [Get-DBInClauseString](/docs/Get-DBInClauseString.md) : Creates the string representation of the parameters that can be used with an IN clause.


[def]: https://www.powershellgallery.com/packages/tcdbtools
