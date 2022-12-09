# tcdbtools

Collection of powershell tools for SQL Server management.

- Invoke-DBSafeShrink : Can be used to shrink an mdf file without causing any index fragmentation increase.
    
- Invoke-DBMoveIndexes : Moves all indexes from one file group to another, including heaps.

- Invoke-DBCompareServerSettings : Compares the server settings between two or more servers.

- Invoke-DBExtractCLRDLL : Extracts all user defined CLR dlls from a SQL server.

- Invoke-DBScriptObjects : Scripts all objects from a database to individual files per object.
