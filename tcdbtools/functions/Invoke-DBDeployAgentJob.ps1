using namespace System.Collections.Generic
function Invoke-DBDeployAgentJob {
    <#
    .SYNOPSIS
        This function is designed to deploy SQL Agent jobs using variables that can customize the deployment for
        each server deployed to.

    .DESCRIPTION
        This function is designed to deploy SQL Agent jobs using variables that can customize the deployment for
        each server deployed to.

    .NOTES
        To signify custom variables in your script you will use the SqlCmd format of $(variable_name). Each one of these
        tokens will be replaced by variables that are provided in either the ServerVariables or the GlobalVariables.

    .PARAMETER ServerVariables
        The server variables define which server the job is deployed to, and what server specific variables there are.
        Any server variable that has the same name of a global variable will override the value for the global variable.

        The server variables are a nested HashTable, where the key of the top level HashTable is the server name, and the
        keys for the nested HashTable are the variable keys.

        NOTE: A variable must be supplied for all $(tokens) in the script.

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

        When deploying to server1/instance1 each instance of $(key1) will be replaced with server1_value1 and $(key2) will
        be replaced with server1_value2 within the job script.

        As server3 defines no variables, then only global variables will be used for its deployment.

    .PARAMETER AgentScriptFile
        The path to the sql agent job file. Invoke-DBSqlAgentScripter can be used to script agent jobs out, or you can
        script your own. This file must exist.

        The special key word "example" can be passed here, and the file /sql/SqlAgentJobExample.sql will be used. The job created
        will be named DeployAgentJobExample when using this.

    .PARAMETER GlobalVariables
        Global variables are default values for variables that can be used when you only wish to override the globals sometimes
        with certain servers.

        Example:

        $globalVariables = @{
            Key1 = "globals value 1"
            Key2 = "globals value 2"
        }

    .PARAMETER Resources
        Resources are also a HashTable. The key of the resource is path to a valid zip file. It must be a zip file. Then the
        value of the HashTable is a UNC path to a folder. If the folder resides on each server, then use the substitution token
        <<server_name>> in the path, and the script will replace that token with the current server name.

        Example:

        $resources = @{
            "c:\temp\SomeZipFile.zip"  = "\\<<server_name>>\ShareName\Jobs\FolderName"
            "c:\temp\SomeZipFile2.zip" = "\\<<server_name>>\ShareName\Jobs\FolderName2"
        }


    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used. The credentials used
        will be the same for all the server connections.

    .EXAMPLE
        An example showing multiple servers with the example job script.

        # global variables will be overwritten by ServerVariables with the same name
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

        Invoke-DBDeployAgentJob -GlobalVariables $globalVariables -ServerVariables $serverVariables -AgentScriptFile "example"

    .EXAMPLE
        An example showing multiple servers with the example job script that also deploy resources to each server. Server3 in
        this case is also using a custom port.

        # global variables will be overwritten by ServerVariables with the same name
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

        Invoke-DBDeployAgentJob -GlobalVariables $globalVariables -ServerVariables $serverVariables -AgentScriptFile "example" -Resources $resources

    .NOTES
        If you need to use an $ in the sql that is NOT a token then you should replace the $ with $(dollar).

        Example:
            $(dollar)(ESCAPE_SQUOTE(SRVR)

        When deployed to the server this will revert to:
            $(ESCAPE_SQUOTE(SRVR)

        More info on SQL Agent Job tokens: https://learn.microsoft.com/en-us/sql/ssms/agent/use-tokens-in-job-steps?view=sql-server-ver16#sql-server-agent-tokens

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    [Alias("Invoke-DBDeploySqlAgentJob")]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_.Count -ge 1})]
        [HashTable]$ServerVariables,
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.Name -ieq "example" -or $_.Exists })]
        [System.IO.FileInfo]$AgentScriptFile,
        [HashTable]$GlobalVariables,
        [HashTable]$Resources,
        [pscredential]$Credentials
    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance "--NA--" -Credentials $Credentials

        $variables = New-Object System.Collections.Generic.Dictionary"[string, string]" ([StringComparer]::CurrentCultureIgnoreCase)
        # this variable is ALWAYS added so that dollar signs can be encoded in the scripts and not interpreted as sqlcmd variables
        # EX, $(ESCAPE_SQUOTE(SRVR) should be written as $(dollar)(ESCAPE_SQUOTE(SRVR) so that it will be translated to the the desired result
        $variables.Add("dollar", "$") | Out-Null

        foreach ($key in $GlobalVariables.Keys) {
            $variables.Add($key, $($GlobalVariables[$key])) | Out-Null
        }

        if ($AgentScriptFile.Name -ine "example") {
            Write-Information "Deploying job script $($AgentScriptFile.FullName)"
            $jobScript = Get-Content -Path $AgentScriptFile.FullName -Raw -Encoding ascii
        } else {
            Write-Information "Deploying job script SqlAgentJobExample.sql"
            $jobScript = GetSQLFileContent -fileName "SqlAgentJobExample.sql"
        }
    }

    process {
        foreach($serverName in $ServerVariables.Keys) {
            $SqlCmdArguments.ServerInstance = $serverName

            # strip off the instance name if one is there
            $hostName = ($serverName -split "\\|,", 2) | Select-Object -First 1
            foreach ($key in $Resources.Keys) {
                $resource = $key
                $destination = ($Resources[$key] -ireplace "<<server_name>>", $hostName)

                if (-not (Test-Path $destination -PathType Container)) {
                    New-Item -Path $destination -ItemType Directory -ErrorAction SilentlyContinue
                }
                Write-InformationColorized "Deploying $resource to $destination" -ForegroundColor Green
                Expand-Archive -Path $resource -DestinationPath $destination -Force
            }

            # set up the var object for the server and add the globals
            $serverVars = New-Object System.Collections.Generic.Dictionary"[string, string]" ([StringComparer]::CurrentCultureIgnoreCase)
            foreach ($dictKey in $variables.Keys) {
                $serverVars.Add($dictKey, $variables[$dictKey]) | Out-Null
            }

            # add all the server variables, overriding any globals of the same name
            foreach($key in $ServerVariables[$serverName].Keys) {
                $value = $($ServerVariables[$serverName][$key])
                if (-not $serverVars.ContainsKey($key)) {
                    $serverVars.Add($key, $value) | Out-Null
                } else {
                    $serverVars[$key] = $value
                }
            }
            $sql = New-Object System.Text.StringBuilder

            # Prepend the setvar statements to the job sql. I hate using the -Variable, can never get it to work right
            # plus this way I can eventually dump it out with -WhatIf when I get around to adding that
            foreach ($key in $serverVars.Keys){
                $sql.AppendLine(":setvar $key ""$($serverVars[$key])""") | Out-Null
            }
            $sql.AppendLine("`r`n") | Out-Null
            $sql.AppendLine($jobScript) | Out-Null

            Write-InformationColorized "Deploying sql for [$serverName]" -ForegroundColor Yellow
            Write-Verbose $sql

            Invoke-SqlCmd @SqlCmdArguments -Query ($sql.ToString())
        }
    }

    end {
        Write-Information "Done"
    }
}
