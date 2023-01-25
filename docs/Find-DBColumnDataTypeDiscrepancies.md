# Find-DBColumnDataTypeDiscrepancies
**Author** Tim Cartwright

## Synopsis
Scans the database for columns in different tables that have the same names, but differ by data type.

## Description
Scans the database for columns in different tables that have the same names, but differ by data type. Helps to track down and unify data types. This can also help prevent potential rounding errors with decimals that may get stored in different tables.

Obviously, there are some columns with the same name that you do not care if they have different data types or sizes. This report is there to help you find the ones that do matter.

## Syntax
    Find-DBColumnDataTypeDiscrepancies 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [[-Timeout] <Int32>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        The sql server instance to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Databases <String[]>
        The databases.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Timeout <Int32>
        The wait time (in seconds) before terminating the attempt to execute a 
        command and generating an error. The default is 30 seconds.

        Required?                    false
        Position?                    4
        Default value                30
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example 

```powershell
Find-DBColumnDataTypeDiscrepancies `
    -ServerInstance "ServerName" `
    -Databases "db1", "db1" `
    -Timeout 60 `
    -InformationAction Continue
```

### Example 
Finds all column data type discrepancies across all user databases.
    
```powershell
Find-DBColumnDataTypeDiscrepancies `
    -ServerInstance "ServerName" `
    -Databases "ALL_USER_DATABASES" `
    -Timeout 60 `
    -InformationAction Continue
```

### Example Output
This is example output from running the command.

| db_name | table_name | column_name | type_name_desc |
| ------- | ---------- | ----------- | -------------- |
| SampleDB | dbo.Table1 | area | DECIMAL (19,2) |
| SampleDB | dbo.Table2 | area | INT |
| SampleDB | dbo.Table1 | actionType | VARCHAR (1) |
| SampleDB | dbo.Table2 | actionType | VARCHAR (1) |
| SampleDB | dbo.Table3 | actionType | VARCHAR (1) |
| SampleDB | dbo.Table4 | actionType | VARCHAR (1) |
| SampleDB | dbo.Table5 | actionType | VARCHAR (1) |
| SampleDB | dbo.Table6 | actionType | VARCHAR (25) |
| SampleDB | dbo.Table7 | actionType | VARCHAR (5) |
| SampleDB | dbo.Table1 | addDate | DATETIME |
| SampleDB | dbo.Table2 | addDate | DATETIME |
| SampleDB | dbo.Table3 | addDate | DATETIME |
| SampleDB | dbo.Table4 | addDate | DATETIME2 (7) |
| SampleDB | dbo.Table5 | addDate | SMALLDATETIME |
| SampleDB | dbo.Table6 | addDate | SMALLDATETIME |
| SampleDB | dbo.Table7 | addDate | SMALLDATETIME |

  
  
<br/>
<br/>
  
[Back](/README.md)
