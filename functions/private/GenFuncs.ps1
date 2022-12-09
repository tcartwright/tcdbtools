function InitSqlConnection($ServerInstance, $UserName, $Password){
    # these sql cmd arguments will be used to splat the Invoke-SqlCmd arguments
    $SqlCmdArguments = @{
        ServerInstance = $ServerInstance
        Database = "master"
    }
    if($UserName -and $Password) {
        $SqlCmdArguments.Add("UserName", $UserName) | Out-Null
        $SqlCmdArguments.Add("Password", $Password) | Out-Null
    }

    $serverConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
    $serverConnection.ServerInstance = $ServerInstance
    if($UserName -and $Password) {
        $serverConnection.LoginSecure = $false
        $serverConnection.Login = $UserName
        $serverConnection.Password = $Password
    }

    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverConnection)
    if ($server.Version -eq  $null ) { 
        throw "Unable to connect to: $ServerInstance" 
        exit 1
    }

    return [PSCustomObject] @{
        SqlCmdArguments = $SqlCmdArguments
        Server = $server
    }
}

function GetConnectionString {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database, 
        [string]$UserName, 
        [string]$Password,
        [string]$AppName = "tcdbtools"
    )

    # in powershell you cannot use the propery names of the builder, you have to use the dictionary keys
    $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder["Data Source"] = $ServerInstance
    $builder["Initial Catalog"] = $Database 
    if ($AppName) {
        $builder["Application Name"] = $AppName
    }
    if ($UserName -and $Password) {
        $builder["Integrated Security"] = $false
        $builder["User ID"] = $UserName
        $builder["Password"] = $Password
    } else {
        $builder["Integrated Security"] = $true
    }
    return $builder.ConnectionString
}

function MoveIndexes ($SqlCmdArguments, $db, $fromFG, $toFG, $indicator, $timeout) {
    # using sql to scan for the indexes to move instead of scanning SMO, as SMO is very, very slow scanning the tables
    # especially if some of the tables do not have indexes in the fromFG

    $sql = "
        SELECT OBJECT_SCHEMA_NAME(i.[object_id]) AS [schema_name], 
	        OBJECT_NAME(i.[object_id]) AS [object_name]
            ,i.[index_id] 
            ,i.[name] AS [index_name]
            ,i.[type_desc] AS [index_type]
        FROM [$($db.Name)].[sys].[indexes] i
        INNER JOIN [$($db.Name)].[sys].[filegroups] f
            ON f.[data_space_id] = i.[data_space_id]
        WHERE OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1
	        AND [f].[name] = '$fromFG'
        ORDER BY OBJECT_NAME(i.[object_id])
            ,i.[index_id]"
    Write-Verbose $sql
    $indexes = Invoke-Sqlcmd @SqlCmdArguments -Query $sql -QueryTimeout $timeout

    $indexCounter = 0
    $indexCountTotal = $indexes.Count
    $activity = "MOVING ($indexCountTotal) INDEXES FROM FILEGROUP [$fromFG] TO FILEGROUP [$toFG] FOR DATABASE: [$($db.Name)]"
    Write-Host "[$($sw.Elapsed.ToString($swFormat))] $activity" -ForegroundColor Yellow

    foreach ($tbl in ($indexes | Group-Object -Property schema_name,object_name)) {
        $table = $db.Tables.Item($tbl.Group[0].object_name, $tbl.Group[0].schema_name)
        $tableName = "[$($table.Schema)].[$($table.Name)]"

        Write-Host "[$($sw.Elapsed.ToString($swFormat))] `tTABLE: $tableName $indicator"

        # the table is a heap so we have to basically create a non-unique clustered index to move it..... then drop the index
        if (-not $table.HasClusteredIndex) {
            $firstColumn = $table.Columns | Select-Object -First 1  
            $indexName =  "PK_$([Guid]::NewGuid().ToString("N"))" 
            $sql = "CREATE CLUSTERED INDEX $indexName ON $tableName ($($firstColumn.Name)) WITH (DATA_COMPRESSION = PAGE) ON [$toFG];
                DROP INDEX $indexName ON $tableName"

            Write-Verbose "$sql"
            Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
        }

        foreach ($index in $table.Indexes) {
            if ($index.FileGroup -ieq $fromFG) {
                $indexCounter++

                Write-Progress -Activity $activity `
                    -Status “Moving index $indexCounter of $indexCountTotal [$($index.Name)] ” `
                    -PercentComplete (([decimal]$indexCounter / [decimal]$indexCountTotal) * 100.00)

                    Write-Host "[$($sw.Elapsed.ToString($swFormat))] `t`tINDEX: [$($index.Name)] ($indexCounter of $indexCountTotal)"

                    # set the new filegroup, and the dropexisting property so the script will generate properly
                    $index.FileGroup = $toFG
                    $index.DropExistingIndex = $true
                    $sql = $index.Script() 
                    Write-Verbose "$sql"
                    Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
            }
        }
    }
    Write-Progress -Activity $activity -Completed
}


# If the script has a hard time finding SMO, you can install the dbatools module and import it. Which ensures that SMO can be found.
if (Get-Module -ListAvailable -Name dbatools) {
    Write-Verbose "Importing dbatools"
    Import-Module dbatools
}

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null


