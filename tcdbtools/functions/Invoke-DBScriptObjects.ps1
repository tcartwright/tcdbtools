function Invoke-DBScriptObjects {
    <#
    .SYNOPSIS
        Generate file-per-object scripts of specified server and database.

    .DESCRIPTION
        Generate file-per-object scripts of specified server and database to specified directory. Attempts to create specified directory if not found.

    .PARAMETER ServerInstance
        Specifies the database server hostname.

    .PARAMETER Databases
        Specifies the name of the databases you want to script. Each database will be scripted to its own directory.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER Scripter
        An object of type [Microsoft.SqlServer.Management.Smo.Scripter]. Allows for custom scripter options to be set. If not provided a default scripter will be created.

    .PARAMETER SavePath
        Specifies the directory where you want to store the generated scripts. If the SavePath is not supplied, then the users temp directory will be used.

    .NOTES
        Author: Phil Factor
        Adapted from http://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/
        Edits By: Tim Cartwright:
            - Changed to script Service Broker objects.
            - Script into folders per object type and schema, instead of one flat folder
            - Ability to use username and password instead of trusted. Trusted can still be used.

        Example directory structure created:
            ├───dbo
            │   ├───StoredProcedures
            │   │       dbo.proc1.sql
            │   │       dbo.proc2.sql
            │   │        ...
            │   ├───Tables
            │   │       dbo.table1.sql
            │   │       dbo.table2.sql
            │   │       ...
            │   └───Views
            │   │       dbo.view1.sql
            │   │       dbo.view2.sql
            │   │       ...


    .EXAMPLE
        If you need to ignore names of certain types, you can define a variable that follows this pattern $ignore + Type that is of type Regex. Any object name that matches will not be scripted.

        EX: Say that you wanted to ignore certain domain users, you could define the following variable before calling the function:

        PS> $ignoreUsers = ".*DomainName.*"
        PS> Invoke-DBScriptObjects -ServerInstance "ServerName" -Database "DatabaseName"

        To ignore other types just define more variables, like $ignoreStoredProcedures or $ignoreTables

    .EXAMPLE
        Creating a customized scripter that ignores extended properties:

        PS> $scripter = New-DBScripterObject -ServerInstance "ServerName"
        PS> $Scripter.Options.ExtendedProperties = $false
        PS> Invoke-DBScriptObjects -ServerInstance "ServerName" -Databases "DatabaseName1", "DatabaseName2" -SavePath "C:\db_scripts" -Scripter $scripter -InformationAction Continue

    .LINK
        https://github.com/tcartwright/tcdbtools

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ServerInstance,
        [Parameter(Mandatory = $true, Position = 2)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [Microsoft.SqlServer.Management.Smo.Scripter]$Scripter,
        [System.IO.DirectoryInfo]$SavePath
    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials
        $server = New-DBSMOServer -ServerInstance $ServerInstance -Credentials $Credentials

        if (-not $SavePath) {
            $path = $env:TEMP
        } else {
            $path = $SavePath.FullName
        }
        # create a scripter object if they did not pass one in (used by the function ScriptOutDbObj())
        if (-not $Scripter) {
            $Scripter = New-DBScripterObject -ServerInstance $ServerInstance -Credentials $Credentials
        }

        # now get all the object types except extended stored procedures and a few others we don't want
        # by creating a bit flags of the DatabaseObjectTypes enum:
        $objectTypeFlags = [long][Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::All -bxor (
            [long][Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Certificate +
            [long][Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::DatabaseRole +
            [long][Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::ExtendedStoredProcedure +
            [long][Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::SqlAssembly +
            [long][Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::DatabaseScopedConfiguration
        )
    }

    process {
        foreach ($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database]
            $dbSavePath = [System.IO.Path]::Combine($path, (ReplaceInvalidPathChars -str $Database))

            if (!(Test-Path -Path $dbSavePath)) {
                Write-Verbose "Creating directory at '$dbSavePath'"
                New-Item $dbSavePath -Type Directory -Force | Out-Null
            }

            if ($db.Name -ne $Database) {
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'"
                continue
            };

            #get everything except the information schema, system views, and some other extra items
            $objects = $db.EnumObjects($objectTypeFlags) |
            Where-Object {
                $_.Schema -ine "sys" -and
                $_.Name -ine "sys" -and
                $_.Schema -ine "information_schema" -and
                $_.Name -ine "information_schema" -and
                $_.Schema -inotlike "db_*" -and
                $_.Name -inotlike "db_*" -and
                $_.Name -inotlike "sp_*diagram*" -and
                $_.Name -ine "fn_diagramobjects" -and
                $_.Name -ine "sysdiagrams" -and
                $_.Schema -ine "guest" -and
                $_.Name -ine "guest"
            }

            $cnt = 0
            $total = $objects.Count + $db.Triggers.Count + 1
            $activity = "SCRIPTING DATABASE: [$($db.Name)]"

            Write-InformationColorized "$activity" -ForegroundColor Yellow

            #  write out each scriptable object as a file in the directory you specify
            $objects | ForEach-Object {
                #for every object we have in the datatable.
                $cnt = ScriptOutDbObj -scripter $Scripter -dbObj $_ -SavePath $dbSavePath -WriteProgressActivity $activity -WriteProgressCount $cnt -WriteProgressTotal $total
            }

            # Next, script out Database Triggers (DatabaseDdlTrigger) separately because they are not returned by Database.EnumObjects()
            foreach ($trigger in $db.Triggers) {
                $cnt = ScriptOutDbObj -scripter $Scripter -dbObj $trigger -SavePath $dbSavePath -WriteProgressActivity $activity -WriteProgressCount $cnt -WriteProgressTotal $total
            }

            $Scripter.Options.Permissions = $false
            # also script out the database definition itself
            $cnt = ScriptOutDbObj -scripter $Scripter -dbObj $db -SavePath $dbSavePath -WriteProgressActivity $activity -WriteProgressCount $cnt -WriteProgressTotal $total

            Write-Progress -Activity $activity -Completed
            Write-InformationColorized "FINISHED $activity" -ForegroundColor Yellow
        }
    }
}