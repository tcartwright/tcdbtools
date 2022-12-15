function Invoke-DBScriptObjects {
    <#
    .SYNOPSIS
        Generate file-per-object scripts of specified server and database.

    .DESCRIPTION
        Generate file-per-object scripts of specified server and database to specified directory. Attempts to create specified directory if not found.

    .PARAMETER ServerName
        Specifies the database server hostname.

    .PARAMETER Database
        Specifies the name of the database you want to script as objects to files.

    .PARAMETER SavePath
        Specifies the directory where you want to store the generated scripts.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .NOTES
        Adapted from http://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/
        Editor: Tim Cartwright:
        - Changed to script SB objects.
        - Also to script into folders, instead of one flat folder
        - Ability to use username and password instead of trusted. Trusted can still be used.

        Example directory structure:
            ├───dbo
            │   ├───StoredProcedures
            │   │       dbo.proc1.sql
            │   │       dbo.proc2.sql
            │   │		...
            │   ├───Tables
            │   │       dbo.table1.sql
            │   │       dbo.table2.sql
            │   │       ...
            │   └───Views
            │   │       dbo.view1.sql
            │   │       dbo.view2.sql
            │   │       ...


    .LINK
        https://github.com/tcartwright/tcdbtools
    #>

    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$ServerInstance,
        [Parameter(Mandatory = $true, Position = 2)]
        [string[]]$Databases,
        [Parameter(Mandatory = $true, Position = 3)]
        [string]$SavePath,
        [pscredential]$Credentials
    )

    begin {
        $sqlCon = InitSqlObjects -ServerInstance $ServerInstance -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
        $server = $sqlCon.server

        # create scripter object (used by the function ScriptOutDbObj())
        $scripter = New-Object "Microsoft.SqlServer.Management.Smo.Scripter" $server #create the scripter

        # https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.scriptingoptions?view=sql-smo-160
        $scripter.Options.AllowSystemObjects = $false
        $scripter.Options.AnsiFile = $true
        $scripter.Options.AnsiPadding = $false # true = SET ANSI_PADDING statements
        $scripter.Options.Default = $true
        $scripter.Options.DriAll = $true
        $scripter.Options.Encoding = New-Object "System.Text.ASCIIEncoding"
        $scripter.Options.ExtendedProperties = $true
        $scripter.Options.IncludeDatabaseContext = $false # true = USE <databasename> statements
        $scripter.Options.IncludeHeaders = $false
        $scripter.Options.NoCollation = $false # true = don't script verbose collation info in table scripts
        $scripter.Options.Permissions = $true
        $scripter.Options.ScriptSchema = $true
        $scripter.Options.SchemaQualify = $true
        $scripter.Options.SchemaQualifyForeignKeysReferences = $true
        $scripter.Options.ScriptDrops = $false
        $scripter.Options.ToFileOnly = $true
        $scripter.Options.Triggers = $true
        $scripter.Options.Indexes = $true
        $scripter.Options.XmlIndexes = $true
        $scripter.Options.FullTextIndexes = $true
        $scripter.Options.ClusteredIndexes = $true
        $scripter.Options.NonClusteredIndexes = $true
        $scripter.Options.WithDependencies = $false
        $scripter.Options.ContinueScriptingOnError = $true

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
            $dbSavePath = [System.IO.Path]::Combine($SavePath, $Database)

            if (!(Test-Path -Path $dbSavePath)) {
                Write-Verbose "Creating directory at '$dbSavePath'"
                New-Item $dbSavePath -Type Directory -Force -ErrorAction Stop | Out-Null
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

            Write-InformationColored "$activity" -ForegroundColor Yellow

            #  write out each scriptable object as a file in the directory you specify
            $objects | ForEach-Object {
                #for every object we have in the datatable.
                $cnt = ScriptOutDbObj -scripter $scripter -dbObj $_ -SavePath $dbSavePath -WriteProgressActivity $activity -WriteProgressCount $cnt -WriteProgressTotal $total
            }

            # Next, script out Database Triggers (DatabaseDdlTrigger) separately because they are not returned by Database.EnumObjects()
            foreach ($trigger in $db.Triggers) {
                $cnt = ScriptOutDbObj -scripter $scripter -dbObj $trigger -SavePath $dbSavePath -WriteProgressActivity $activity -WriteProgressCount $cnt -WriteProgressTotal $total
            }

            $scripter.Options.Permissions = $false
            # also script out the database definition itself
            $cnt = ScriptOutDbObj -scripter $scripter -dbObj $db -SavePath $dbSavePath -WriteProgressActivity $activity -WriteProgressCount $cnt -WriteProgressTotal $total

            Write-Progress -Activity $activity -Completed
            Write-InformationColored "FINISHED $activity" -ForegroundColor Yellow
        }
    }
}