# Find-DBValue
**Author** Tim Cartwright

## Synopsis
Scans a database for a value. Returns all tables and columns that contain that value, as well as the value itself.

## Description
Scans a database for a value. Returns all tables and columns that contain that value, as well as the value itself.

## Syntax
    Find-DBValue
        [-ServerInstance] <String> 
        [-Database] <String> 
        [[-Credentials] <PSCredential>] 
        [-LookForValue] <String> 
        [[-LookForValueType] <String>] 
        [-IncludeMaxWidthColumns ] 
        [[-IncludeSchemas] <String[]>] 
        [[-ExcludeSchemas] <String[]>] 
        [[-IncludeTables] <String[]>] 
        [[-ExcludeTables] <String[]>] 
        [[-MaxThreads] <Int32>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        The sql server instance to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Database <String>
        Specifies the name of the database.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -LookForValue <String>
        The value to search for in the database. This string supports LIKE clause syntax.

        Required?                    true
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -LookForValueType <String>
        The type of value being looked for. The valid values are "string" and "number". Use the appropriate one to scan the
        correct type of columns for the value you are looking for. Defaults to "string".

        Required?                    false
        Position?                    5
        Default value                string
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeMaxWidthColumns <SwitchParameter>
        Max width columns are not scanned by default unless this switch is enabled.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeSchemas <String[]>
        A list of schemas to include in the results. If not provided then all schemas will be returned.

        Required?                    false
        Position?                    6
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ExcludeSchemas <String[]>
        A list of schemas to exclude from the results.

        Required?                    false
        Position?                    7
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeTables <String[]>
        A list of tables to include in the results. If not provided then all tables will be returned.

        Required?                    false
        Position?                    8
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ExcludeTables <String[]>
        A list of tables to exclude from the results.

        Required?                    false
        Position?                    9
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MaxThreads <Int32>
        The max number of threads to run sets of queries with. Defaults to 6.

        Required?                    false
        Position?                    10
        Default value                6
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example 

```powershell
# Scans all string columns in all user defined tables in the dbo schema for the value "%tim%"
Find-DBValue-ServerInstance "ServerName" -Database "DBName" -LookForValue "%tim%" -IncludeSchemas @("dbo") | Format-Table
```

[Back](/README.md)