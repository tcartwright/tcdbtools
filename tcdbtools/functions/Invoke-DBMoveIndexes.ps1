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
            The databases to shrink. A string array.

        .PARAMETER UserName
            The sql user to connect as.

            NOTES: If UserName or Password are missing, then trusted connections will be used.

        .PARAMETER Password
            The password for the sql user.

            NOTES: If UserName or Password are missing, then trusted connections will be used.

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
            PS> .\Invoke-DBMoveIndexes -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -SourceFileGroupName SHRINK_DATA_TEMP -TargetFileGroupName PRIMARY

        .EXAMPLE
            PS> .\Invoke-DBMoveIndexes -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -UserName "user.name" -Password "ilovelamp" -SourceFileGroupName PRIMARY -TargetFileGroupName SHRINK_DATA_TEMP

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
        [string]$UserName,
        [SecureString]$Password,
        [Parameter(Mandatory=$true)]
        [string]$SourceFileGroupName = "PRIMARY",
        [Parameter(Mandatory=$true)]
        [string]$TargetFileGroupName,
        [int]$IndexMoveTimeout = 5
    )

    begin {
        $sqlCon = InitSqlConnection -ServerInstance $ServerInstance -UserName $UserName -Password $Password
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
        $server = $sqlCon.server

        $IndexMoveTimeout = ([Timespan]::FromMinutes($IndexMoveTimeout).TotalSeconds)

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $swFormat = "hh\:mm\:ss"
        Write-Information "[$($sw.Elapsed.ToString($swFormat))] STARTING"
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
        Write-Information "[$($sw.Elapsed.ToString($swFormat))] FINISHED"
    }
}



