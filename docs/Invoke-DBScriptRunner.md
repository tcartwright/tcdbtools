# Invoke-DBScriptRunner
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/Invoke-DBScriptRunner.ps1)

## Synopsis
Runs a query against one or more servers and databases. Captures the results and any messages. The execution of the scripts is multi threaded.

## Description
Runs a query against one or more servers and databases. Captures the results and any messages. The execution of the scripts is multi threaded.

## Syntax
    Invoke-DBScriptRunner 
        [-Servers] <DBServer[]> 
        [[-Credentials] <PSCredential>] 
        [[-Query] <String>] 
        [[-MaxThreads] <Int32>] 
        [[-CommandTimeout] <Int32>] 
        [<CommonParameters>]

## Parameters
    -Servers <DBServer[]>
        Collection of server / database names to run the query against. An array of type TCDbTools.DbServer. 

        NOTE: The ctor has this signature:
        public DBServer(string serverInstance, string database = "master", PSCredential credentials = null)

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Query <String>
        The query to run against each server / database combo.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MaxThreads <Int32>
        The max number of threads to run the query with. Defaults to 8.

        Required?                    false
        Position?                    4
        Default value                8
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CommandTimeout <Int32>
        The command timeout for the query in seconds.

        Required?                    false
        Position?                    5
        Default value                30
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Outputs
- ServerInstance: The ServerInstance passed in.
- Database: The Database passed in.
- Results: The results of they query if there are any as a [System.Data.DataTable]. 
- Messages: the output of any PRINT statements used in the query.
- Success: True if the query succeeded, else false.
- Exception: A [System.Exception] if the query fails for any reason.

### Example 

```powershell
# Scans all string columns in all user defined tables in the dbo schema for the value "%tim%"

$servers = @()
$servers += [TCDbTools.DBServer]::new("Server1", "DbName1")
$servers += [TCDbTools.DBServer]::new("Server1", "DbName2")
$servers += [TCDbTools.DBServer]::new("Server2", "DbName1")
$servers += [TCDbTools.DBServer]::new("Server2", "DbName2")

$query = "
    SET NOCOUNT ON
    PRINT CONCAT('HELLO WORLD FROM USER: ', ORIGINAL_LOGIN())
    SELECT @@SERVERNAME AS [SERVERNAME],
        DB_NAME() AS [DB_NAME]
    "
$results = Invoke-DBScriptRunner -Servers $servers -Query $query

# the metadata return for each query invoked
$results
# output the total DataTable results of each query
$results.Results | Format-Table
```

### Example Output

| ServerInstance | Database | Results | Messages | Success | Exception |
| -------------- | -------- | ------- | -------- | ------- | --------- |
| Server1 | DbName1 | System.Data.DataRow | HELLO WORLD FROM USER: tim.cartwright | True |  |
| Server1 | DbName2 | System.Data.DataRow | HELLO WORLD FROM USER: tim.cartwright | True |  |
| Server2 | DbName1 | System.Data.DataRow | HELLO WORLD FROM USER: tim.cartwright | True |  |
| Server2 | DbName2 | System.Data.DataRow | HELLO WORLD FROM USER: tim.cartwright | True |  |

| SERVERNAME | DB_NAME |
| ---------- | ------- |
| Server1 | DbName1 |
| Server1 | DbName2 |
| Server2 | DbName1 |
| Server2 | DbName2 |

<br/>
<br/>
  
[Back](/README.md)
