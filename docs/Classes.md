# Classes
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/private/Classes.ps1)

## Synopsis
Classes for use by the module 

### TCDbTools.DBServer Class

#### Properties

| Property |  |
| -------- | --- |
| public string ServerInstance { get; set; }    | The server instance to connect to. |
| public string Database { get; set; }          | The database name. Defaults to master. |
| public PSCredential Credentials { get; set; } | SQL Server credentials if needed. If null, then a trusted connection is used. See: [Get-DBUserCredential](/docs/Get-DBUserCredential.md) |
| public Hashtable SqlCmdArgs { get;set;}       | Arguments that will be used to customize the query per server. These are not real SQL CMD arguments. Merely search and replace tokens |

### Constructors

| Constructor | |
| -------- | --- |
| DBServer(string serverInstance, string database = "master", PSCredential credentials = null, Hashtable sqlCmdArgs = null) | Initializes a new instance of the TCDbTools.DBServer class. |

### Example 

```powershell
$servers = @()
$servers += [TCDbTools.DBServer]::new("Server1", "DbName1", $null, @{ arg1 = "server1"; arg2 = "more info..." })
```

<br/>
<br/>
  
[Back](/README.md)
