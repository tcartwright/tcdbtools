# Invoke-DBDeployAgentJob
**Author** Tim Cartwright

## Synopsis
This function is designed to deploy SQL Agent jobs using variables that can customize the deployment for each server.

## Description
This function is designed to deploy SQL Agent jobs using variables that can customize the deployment for each server.

## Notes
To signify custom variables in your script you will use the SqlCmd format of $(variable_name). Each one of these tokens will be replaced by variables that are provided in either the ServerVariables or the GlobalVariables.

If you need to use an $ in the sql that is NOT a token then you should replace the $ with $(dollar) in the sql file.

Example:
    $(dollar)(ESCAPE_SQUOTE(SRVR)

When deployed to the server this will revert to:
    $(ESCAPE_SQUOTE(SRVR)    

More info on [SQL Agent Job tokens](https://learn.microsoft.com/en-us/sql/ssms/agent/use-tokens-in-job-steps?view=sql-server-ver16#sql-server-agent-tokens)

## Syntax
    Invoke-DBDeployAgentJob 
        [-ServerVariables] <Hashtable> 
        [-AgentScriptFile] <FileInfo> 
        [[-GlobalVariables] <Hashtable>] 
        [[-Resources] <Hashtable>] 
        [[-Credentials] <PSCredential>] 
        [<CommonParameters>]

## Parameters
    -ServerVariables <Hashtable>
        The server variables define which server the job is deployed to, and 
		what server specific variables there are. Any server variable that has 
		the same name of a global variable will override the value for the 
		global variable.
        
        The server variables are a nested HashTable, where the key of the top 
		level HashTable is the server name, and the  keys for the nested 
		HashTable are the variable keys.
        
        NOTE: A variable must be supplied for all $(tokens) in the script. On 
		the flip side, a variable can be used that does not have an associated 
		token. It will just end up being ignored.
        
        Example:
        
        $serverVariables = @{
            "server1\instance1" = @{
                key1 = "server1_value1"
                key2 = "server1_value2"
            }
            "server2\instance1" = @{
                key1 = "server2_value1" 
                key2 = "server2_value2"
            }
            "server3" = @{}
        } 
        
        When deploying to server1/instance1 each instance of $(key1) will be 
		replaced with server1_value1 and $(key2) will be replaced with 
		server1_value2 within the job script. 
        
        As server3 defines no variables, then only global variables will be used 
		for its deployment.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -AgentScriptFile <FileInfo>
        The path to the sql agent job file. Invoke-DBSqlAgentScripter can be 
		used to script agent jobs out, or you can script your own. This file 
		must exist.
        
        The special key word "example" can be passed here, and the 
		file /sql/SqlAgentJobExample.sql will be used. The job created will be 
		named DeployAgentJobExample when using this.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -GlobalVariables <Hashtable>
        Global variables are default values for variables that can be used when 
		you only wish to override the globals sometimes with certain servers.
        
        Example:
        
        $globalVariables = @{
            Key1 = "globals value 1" 
            Key2 = "globals value 2"
        }

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Resources <Hashtable>
        Resources are also a HashTable. The key of the resource is path to a 
		valid zip file. It must be a zip file. Then the value of the HashTable 
		is a UNC path to a folder. If the folder resides on each server, then 
		use the substitution token <<server_name>> in the path, and the script 
        will replace that token with the current server name.
        
        Example:
        
        $resources = @{
            "c:\temp\SomeZipFile.zip" = "\\<<server_name>>\ShareName\Jobs\FolderName" 
            "c:\temp\SomeZipFile2.zip" = "\\<<server_name>>\ShareName\Jobs\FolderName2" 
        }

        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
		then a trusted connection will be used. The credentials used will be the 
		same for all the server connections.

        Required?                    false
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false


### Example
An example showing multiple servers with the example job script.

```powershell
# global variables will be overwritten by server variables with the same name
$globalVariables = @{
    Key1 = "globals value 1" 
    Key2 = "globals value 2"
}

$serverVariables = @{
    "server1\instance1" = @{
        key1 = "server1_value1"
        key2 = "server1_value2"
    }
    "server2\instance1" = @{
        key1 = "server2_value1" 
        key2 = "server2_value2"
    }
    "server3" = @{}
} 

# When passing "example" for the script file, this file will be used [SqlAgentJobExample.sql](/sql/SqlAgentJobExample.sql)
Invoke-DBDeployAgentJob `
    -GlobalVariables $globalVariables `
    -ServerVariables $serverVariables `
    -AgentScriptFile "example" `
    -InformationAction Continue
```

### Example
An example showing multiple servers with the example job script that also deploy resources to each server. Server3 in this case is also using a custom port.

```powershell
# global variables will be overwritten by server variables with the same name
$globalVariables = @{
    Key1 = "globals value 1" 
    Key2 = "globals value 2"
}

$serverVariables = @{
    "server1\instance1" = @{
        key1 = "server1_value1"
        key2 = "server1_value2"
    }
    "server2\instance1" = @{
        key1 = "server2_value1" 
        key2 = "server2_value2"
    }
    "server3,2866" = @{}
} 

$resources = @{
    "c:\temp\SomeZipFile.zip"  = "\\<<server_name>>\ShareName\Jobs\FolderName"  
}

Invoke-DBDeployAgentJob `
    -GlobalVariables $globalVariables `
    -ServerVariables $serverVariables `
    -AgentScriptFile "c:\example_path\job.sql" `
    -Resources $resources `
    -InformationAction Continue
```

[Back](/README.md)