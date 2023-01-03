function Invoke-DBMoveIndexes {
    <#
    .SYNOPSIS
        Moves indexes from one file group to another including heaps.

    .DESCRIPTION
        Moves indexes from one file group to another. Both file groups must exist, neither
        will be created for you.

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

    .PARAMETER IndexMoveTimeout
        The amount of time that controls how long a index move can run before timing out.

        NOTES: This timeout is in minutes.

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
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [Parameter(Mandatory=$true)]
        [string]$SourceFileGroupName = "PRIMARY",
        [Parameter(Mandatory=$true)]
        [string]$TargetFileGroupName,
        [int]$IndexMoveTimeout = 5
    )

    begin {
        $sqlCon = New-DBSqlObjects -ServerInstance $ServerInstance -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
        $server = $sqlCon.server

        $IndexMoveTimeout = ([Timespan]::FromMinutes($IndexMoveTimeout).TotalSeconds)

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $swFormat = "hh\:mm\:ss"
        Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] STARTING" -ForegroundColor Yellow
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database]

            if ($db.Name -ne $Database) {
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'"
                continue
            };

            MoveIndexes -db $db -fromFG $SourceFileGroupName -toFG $TargetFileGroupName -indicator "-->" -timeout $IndexMoveTimeout -SqlCmdArguments $SqlCmdArguments
        }
    }

    end {
        $sw.Stop()
        Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] FINISHED" -ForegroundColor Yellow
    }
}



