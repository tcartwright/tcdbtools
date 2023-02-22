function Get-AllUserDatabases {
    <#
        .DESCRIPTION
            If the first value in $Databases is "ALL_USER_DATABASES" then a list of all user databases
            is returned. Else the original list of databases is passed back.

        .PARAMETER Databases
            The list of databases.

        .PARAMETER SqlCmdArguments
            The sqlcmd arguments to use. Can be created using New-DBSqlCmdArguments.

        .EXAMPLE
            Get all user databases:
            PS> Get-AllUserDatabases -Databases "ALL_USER_DATABASES" -SqlCmdArguments (New-DBSqlCmdArguments -ServerInstance "ServerName")

        .EXAMPLE
            Just return the list of databases passed in
            PS> Get-AllUserDatabases -Databases "DBName1", "DBName2" -SqlCmdArguments (New-DBSqlCmdArguments -ServerInstance "ServerName")

    #>
    param ([string[]] $Databases, $SqlCmdArguments)

    if ($Databases[0] -ieq "ALL_USER_DATABASES") {
        $dbsQuery = GetSQLFileContent -fileName "AllUserDatabases.sql"
        $Databases = Invoke-Sqlcmd @SqlCmdArguments -Query $dbsQuery -OutputAs DataRows | Select-Object -ExpandProperty name -Unique
        Write-Information "ALL_USER_DATABASES specified. Databases found: `r`n$Databases"
    }
    return $Databases
}
