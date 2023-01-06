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

* [Invoke-DBSafeShrink](/docs/Invoke-DBSafeShrink.md) : Can be used to shrink an mdf file ***and*** rebuild all indexes at the same time. Typically faster then a normal shrink. Can not be used to shrink an LDF file.
* [Invoke-DBMoveIndexes](/docs/Invoke-DBMoveIndexes.md) : Moves all indexes from one file group to another, including heaps.
* [Invoke-DBCompareServerSettings](/docs/Invoke-DBCompareServerSettings.md) : Compares the server settings between two or more servers.
* [Invoke-DBExtractCLRDLL](/docs/Invoke-DBExtractCLRDLL.md) : Extracts all user defined CLR dlls from a SQL server.
* [Invoke-DBScriptObjects](/docs/Invoke-DBScriptObjects.md) : Scripts all objects from a database to individual files per object.
* [Invoke-DBRenameConstraints](/docs/Invoke-DBRenameConstraints.md) : Will rename all indexes and constraints to match naming conventions. 
* [Find-DBInvalidSettings](/docs/Find-DBInvalidSettings.md) : Finds settings and options that may or may not be invalid depending upon design choices. They are typically invalid however and should be investigated.

## Helper Functions

* [New-DBScripterObject](/docs/New-DBScripterObject.md) : Creates a database scripting object that can be modified and used by Invoke-DBScriptObjects.
* [New-DBSqlConnection](/docs/New-DBSqlConnection.md) : Creates a SqlConnection.
* [New-DBSqlObjects](/docs/New-DBSqlObjects.md) : Creates two objects that can be used for connectivity.

* Invoke-DBScalarQuery : Executes the query, and returns the first column of the first row in the result set returned by the query. Additional columns or rows are ignored.
* Invoke-DBNonQuery : Executes a Transact-SQL statement against the connection and returns the number of rows affected.
* Invoke-DBReaderQuery : Sends the CommandText to the Connection and builds a SqlDataReader.
* Invoke-DBDataSetQuery : Executes a Transact-SQL statement against the connection and returns a DataSet containing a DataTable for each result set returned.
* New-SqlParameter : Creates a new instance of a SqlParameter object.
* [Get-InClauseParams](/docs/Get-InClauseParams.md) : Can be used to create a set of parameters that can be used with an IN clause.
* [Get-InClauseString](/docs/Get-InClauseString.md) : Creates the string representation of the parameters that can be used with an IN clause.





[def]: https://www.powershellgallery.com/packages/tcdbtools