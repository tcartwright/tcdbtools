function Invoke-DBMoveIndexes {
    <#
    .SYNOPSIS
        Moves indexes from one file group to another including heaps.

    .DESCRIPTION
        Moves indexes from one file group to another. Both file groups must exist, neither
        will be created for you.

    .NOTES
        All of the include and exclude parameters are OR'ed together in the following order:

        - ExcludeIndexes
        - IncludeIndexes
        - ExcludeTables
        - IncludeTables
        - ExcludeSchemas
        - IncludeSchemas

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The databases to move indexes in.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER SourceFileGroupName
        The file group name to move indexes from.

    .PARAMETER TargetFileGroupName
        The file group where the indexes will be moved to.

    .PARAMETER Online
        Specifies whether underlying tables and associated indexes are available for queries and data
        modification during the index operation. The default is OFF.

    .PARAMETER IndexMoveTimeout
        The amount of time that controls how long a index move can run before timing out.

        NOTES: This timeout is in minutes.

    .PARAMETER IncludeSchemas
        A list of schemas to include in the move. If not provided then all schemas will be returned.

    .PARAMETER ExcludeSchemas
        A list of schemas to exclude from the move.

    .PARAMETER IncludeTables
        A list of tables to include in the move. If not provided then all tables will be returned.

    .PARAMETER ExcludeTables
        A list of tables to exclude from the move.

    .PARAMETER IncludeIndexes
        A list of indexes to include in the move. If not provided then all tables will be returned.

    .PARAMETER ExcludeIndexes
        A list of indexes to exclude from the move.

    .INPUTS
        None. You cannot pipe objects to this script.

    .OUTPUTS
        None.

    .EXAMPLE
        PS> Invoke-DBMoveIndexes -ServerInstance "ServerName" -Databases "AdventureWorks2008","AdventureWorks2012" -SourceFileGroupName SHRINK_DATA_TEMP -TargetFileGroupName PRIMARY

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [ValidateCount(1, 9999)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [string]$SourceFileGroupName = "PRIMARY",
        [Parameter(Mandatory=$true)]
        [string]$TargetFileGroupName,
        [switch]$Online,
        [int]$IndexMoveTimeout = 5,
        [string[]]$IncludeSchemas,
        [string[]]$ExcludeSchemas,
        [string[]]$IncludeTables,
        [string[]]$ExcludeTables,
        [string[]]$IncludeIndexes,
        [string[]]$ExcludeIndexes

    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials
        $server = New-DBSMOServer -ServerInstance $ServerInstance -Credentials $Credentials

        $IXMoveTimeout = ([Timespan]::FromMinutes($IndexMoveTimeout).TotalSeconds)

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $swFormat = "hh\:mm\:ss"
        Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] STARTING" -ForegroundColor Yellow

        $whereClause = ""
        $parameters = @()

        if ($ExcludeIndexes) {
            $params = Get-DBInClauseParams -prefix "ei" -values $ExcludeIndexes -type NVarChar -size 256
            $whereClause += "`r`n`t`tOR i.[name] NOT IN ($(Get-DBInClauseString -parameters $params))"
            $parameters += $params
        }
        if ($IncludeIndexes) {
            $params = Get-DBInClauseParams -prefix "ii" -values $IncludeIndexes -type NVarChar -size 256
            $whereClause += "`r`n`t`tOR i.[name] IN ($(Get-DBInClauseString -parameters $params))"
            $parameters += $params
        }
        if ($ExcludeTables) {
            $params = Get-DBInClauseParams -prefix "et" -values $ExcludeTables -type NVarChar -size 256
            $paramStr = Get-DBInClauseString -parameters $params -delimiter "), OBJECT_ID("
            $paramStr = "OBJECT_ID($($paramStr))"
            $whereClause += "`r`n`t`tOR i.[object_id] NOT IN ($paramStr)"
            $parameters += $params
        }
        if ($IncludeTables) {
            $params = Get-DBInClauseParams -prefix "it" -values $IncludeTables -type NVarChar -size 256
            $paramStr = Get-DBInClauseString -parameters $params -delimiter "), OBJECT_ID("
            $paramStr = "OBJECT_ID($($paramStr))"
            $whereClause += "`r`n`t`tOR i.[object_id] IN ($paramStr)"
            $parameters += $params
        }
        if ($ExcludeSchemas) {
            $params = Get-DBInClauseParams -prefix "es" -values $ExcludeSchemas -type NVarChar -size 256
            $whereClause += "`r`n`t`tOR OBJECT_SCHEMA_NAME(i.[object_id]) NOT IN ($(Get-DBInClauseString -parameters $params))"
            $parameters += $params
        }
        if ($IncludeSchemas) {
            $params = Get-DBInClauseParams -prefix "is" -values $IncludeSchemas -type NVarChar -size 256
            $whereClause += "`r`n`t`tOR OBJECT_SCHEMA_NAME(i.[object_id]) IN ($(Get-DBInClauseString -parameters $params))"
            $parameters += $params
        }

        if ($whereClause) {
            # strip off the first OR
            $whereClause = $whereClause.Substring(7)
            # now wrap it into a grouped AND predicate
            $whereClause = "`r`n`tAND (`r`n`t`t$whereClause`r`n`t)"
        }
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database]

            if ($db.Name -ne $Database) {
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'"
                continue
            };

            MoveIndexes -db $db `
                -fromFG $SourceFileGroupName `
                -toFG $TargetFileGroupName `
                -indicator "-->" `
                -timeout $IXMoveTimeout `
                -SqlCmdArguments $SqlCmdArguments `
                -whereClause $whereClause `
                -parameters $parameters `
                -Online:$Online.IsPresent
        }
    }

    end {
        $sw.Stop()
        Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] FINISHED" -ForegroundColor Yellow
    }
}



