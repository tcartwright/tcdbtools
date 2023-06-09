function Invoke-DBSynchronizeSQLLogins {
    <#
    .SYNOPSIS
        Will synchronize sql logins between servers. Synchronizes both the [HASHED](https://sqlity.net/en/2344/create-login-with-hashed-password/) password and the SID.
        Very useful for synchronizing logins between Availability Group Servers.

    .DESCRIPTION
        Will synchronize sql logins between servers. Synchronizes:

        - [HASHED](https://sqlity.net/en/2344/create-login-with-hashed-password/) password
        - SID
        - Default Database
        - Default Language

        The password hashes are backwards compatible, but they are not forward compatible. That means that if you script out
        the login on an older server it will NOT be deployable against a newer server. If you have a mix of older and newer
        servers, it is advised you use the AuthorityServer method, and have your logins synchronize out from there.

        There are two methods of determining what logins will be scripted out:

        - Default method:
            By default all logins will be compared, and the login with the latest modified date will be chosen to be deployed to all
            the servers.

        - Authority Server method:
            This method will only use a single server as the source for all logins to be deployed out. Example: if an authorityServer
            of "server1" is passed in, then only logins from "server1" will be scripted, and then deployed to all the other servers.

        NOTE: Extra logins that are not on the AuthorityServer are ignored when scripted out, and not dropped. Only logins available on the
        AuthorityServer are synchronized.

    .PARAMETER Servers
        Collection of server / database names to run the query against. An array of type TCDbTools.DbServer.

        NOTE: The ctor has this signature:
        public DBServer(string serverInstance, string database = "master", PSCredential credentials = null)

    .PARAMETER IgnoreRegex
        A regex that will be applied to all of the login names. Any name that matches the regex will be ignored and not scripted out.

    .PARAMETER AuthorityServer
        The authority server to use for scripting logins. When null all logins from all servers will be compared using the latest modified
        date. When a valid value is passed in, then only logins from the AuthorityServer will be scripted and deployed.

    .PARAMETER DoNotAddAutoFix
        By default a script is added to the end of each login to auto fix all of the database users. Uses sp_MSForeachdb to
        loop all of the databases. Passing this switch in will disable that part of the script generation.

    .PARAMETER DropIfExists
        Normally a login is only dropped if found, but the SID is different. If this switch is present, then the login is always
        dropped and recreated.

    .PARAMETER DoNotInvoke
        When this switch is enabled then the script that is generated is NOT executed against the servers.

    .PARAMETER CreateAlterLoginSqlOutputVar
        Allows for capture of the sql that is run by use of a [ref] parameter. See examples.

    .OUTPUTS
        A table of the servers updated, and the logins synched to each and whether deploying to that server was successful.

        Optionally a reference parameter can be utilized to grab the login alter / create sql.

    .EXAMPLE
        Uses the authority server to synchronize logins to the other servers

        $authorityServer = "server1"

        $serverList = @()

        $serverList += [TCDbTools.DBServer]::new("server1")
        $serverList += [TCDbTools.DBServer]::new("server2")
        $serverList += [TCDbTools.DBServer]::new("server3")

        $retVal = Invoke-DBSynchronizeSQLLogins -Servers $serverList -AuthorityServer $authorityServer -InformationAction Continue
        $retVal

    .EXAMPLE
        Grabs the latest logins from each server to synchronize to the other servers. Ignores any logins with an underscore in the name.

        $serverList = @()

        $serverList += [TCDbTools.DBServer]::new("server1")
        $serverList += [TCDbTools.DBServer]::new("server2")
        $serverList += [TCDbTools.DBServer]::new("server3")

        $retVal = Invoke-DBSynchronizeSQLLogins -Servers $serverList -InformationAction Continue -IgnoreRegex "^[^_]*?_.*"
        $retVal

    .EXAMPLE
        Generates the change sql, but does not run it against the server list. Grabs the sql into a variable.

        $serverList = @()

        $serverList += [TCDbTools.DBServer]::new("server1")
        $serverList += [TCDbTools.DBServer]::new("server2")
        $serverList += [TCDbTools.DBServer]::new("server3")

        [string]$loginSql = ""

        $retVal = Invoke-DBSynchronizeSQLLogins -Servers $serverList -DoNotInvoke -InformationAction Continue -CreateAlterLoginSqlOutputVar ([ref]$loginSql)
        $retVal
        $loginSql

    .EXAMPLE
        An example of the script that is generated for a single login when DoNotAddAutoFix is not enabled, and DropIfExists is not enabled.
        The password has been truncated.

        DECLARE @checked BIT = 0
        /******************************************************************************************************************************************/
        /******************************* Login: FOO generated from: SERVER1 on: 2023-05-01 15:49:32 ***********************************************/
        /******************************************************************************************************************************************/
        SET @checked = (SELECT [is_policy_checked] FROM sys.sql_logins WHERE name = 'FOO')
        IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = OFF END
        IF NOT EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = 'FOO' AND sp.sid = 0xA5D09CAA8D73364BBEBC172F0C033C64) BEGIN
            RAISERROR('********************************[FOO]********************************', 0, 1) WITH NOWAIT;
            IF EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = 'FOO') BEGIN;
                RAISERROR('DROPPING LOGIN [FOO]', 0, 1) WITH NOWAIT;
                DROP LOGIN [FOO];
            END;
            RAISERROR('CREATING LOGIN [FOO]', 0, 1) WITH NOWAIT;
            CREATE LOGIN [FOO]
                    WITH PASSWORD = 0x02001867BC72D30F... HASHED,
                    DEFAULT_DATABASE = [master],
                    DEFAULT_LANGUAGE = [us_english],
                    SID = 0xA5D09CAA8D73364BBEBC172F0C033C64;
        END ELSE BEGIN
            RAISERROR('ALTERING LOGIN [FOO]', 0, 1) WITH NOWAIT;
            ALTER LOGIN [FOO]
                WITH PASSWORD = 0x02001867BC72D30F... HASHED,
                DEFAULT_DATABASE = [master],
                DEFAULT_LANGUAGE = [us_english];
        END

        RAISERROR('AUTO FIXING LOGIN [FOO]', 0, 1) WITH NOWAIT;
        EXEC sys.sp_MSForeachdb N'
            USE [?];
            IF EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = ''?'' AND d.is_read_only = 0) BEGIN
                IF EXISTS (SELECT 1 FROM sys.database_principals dp WHERE dp.name = ''FOO'') BEGIN
                    EXEC sys.sp_change_users_login @Action = ''Update_One'', @UserNamePattern = ''FOO'', @LoginName = ''FOO''
                END
            END
        '

        IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = ON END;

    .EXAMPLE
        An example of the script that is generated for a single login when DoNotAddAutoFix is enabled, and DropIfExists is enabled.
        The password has been truncated.

        DECLARE @checked BIT = 0;
        /******************************************************************************************************************************************/
        /******************************* Login: FOO generated from: SERVER1 on: 2023-05-01 15:49:32 ***********************************************/
        /******************************************************************************************************************************************/
        SET @checked = (SELECT [is_policy_checked] FROM sys.sql_logins WHERE name = 'FOO')
        IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = OFF END

        RAISERROR('********************************[FOO]********************************', 0, 1) WITH NOWAIT;
        IF EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = 'FOO') BEGIN;
            RAISERROR('DROPPING LOGIN [FOO]', 0, 1) WITH NOWAIT;
            DROP LOGIN [FOO];
        END;
        RAISERROR('CREATING LOGIN [FOO]', 0, 1) WITH NOWAIT;
        CREATE LOGIN [FOO]
                WITH PASSWORD = 0x02001867BC72D30F... HASHED,
                DEFAULT_DATABASE = [master],
                DEFAULT_LANGUAGE = [us_english],
                SID = 0xA5D09CAA8D73364BBEBC172F0C033C64;

        IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = ON END	;

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateCount(2, 999)]
        [TCDbTools.DBServer[]]$Servers,
        [string]$IgnoreRegex = $null,
        [string]$AuthorityServer = $null,
        [switch]$DoNotAddAutoFix,
        [switch]$DropIfExists,
        [switch]$DoNotInvoke,
        [ref]$CreateAlterLoginSqlOutputVar
    )

    begin {
        $sql = (GetSQLFileContent -fileName "GetSqlLogins.sql")
        $ret = [System.Collections.ArrayList]::new()
        $list = New-Object System.Collections.Generic.Dictionary"[String,Object]"
        $logins = [System.Collections.Generic.List[System.Object]]::new() 
    }

    process {
        # first lets get the create / alter logins sql from the servers, or the authority server if specified
        foreach ($server in $servers | Where-Object { -not $authorityServer -or $_.ServerInstance -ieq $authorityServer}) {
            $connection = New-DBSqlConnection -ServerInstance $server.ServerInstance -Credentials $server.Credentials -Database "master"
            try {
                $connection.Open()
                $parameters = @(
                    (New-DBSqlParameter -name "@gen_auto_fix" -type Bit -value (-not $DoNotAddAutoFix.IsPresent)),
                    (New-DBSqlParameter -name "@drop_if_exists" -type Bit -value ($DropIfExists.IsPresent))
                )
                Write-Information "Processing server: $($server.ServerInstance)"
                $queryResults = Invoke-DBDataTableQuery -conn $connection -sql $sql -parameters $parameters
                $logins.AddRange(($queryResults | ConvertFrom-DataRows)) | Out-Null
            } catch {
                throw
            } finally {
                if ($connection) { $connection.Dispose() }
            }
        }

        if (-not $logins) {
            throw "No logins were found to synchronize."
        }

        # if we did not use an authority server remove any from the list where we cant find any differences on the other servers by SID, PASSWORD, 
        # if the login count matches the server count, as we do not need to deploy out any logins that match across all of the servers
        if (-not $AuthorityServer) {
            $grouped = $logins | Group-Object name | Where-Object { $_.Count -eq $servers.Count }

            foreach ($grp in $grouped) {
                $diffs = $grp.Group | Group-Object login_sid, pwd_hash
                # all of the sids / passwords match for this login across all the servers, so remove it
                if ($diffs.Count -eq 1) {
                    foreach ($item in $grp.Group) {
                        $logins.Remove($item) 
                    }
                }
            }
        }

        # now lets build up the latest unique list based upon modify date.
        foreach ($row in $logins | Sort-Object Name ) {
            if ( $IgnoreRegex -and $row.name -imatch $IgnoreRegex ) { continue }
            if (-not $list.ContainsKey($row.Name)) {
                $list.Add($row.Name, $row)
                continue
            } else {
                $orig = $list.Item($row.Name)
                if($row.modify_date -gt $orig.modify_date) {
                    $list[$row.Name] = $row
                }
            }
        }

        if ($list.Count -eq 0) {
            Write-Warning "No suitable logins found to synchronize."
            return $null
        }

        [string]$sql = $list.Values.create_or_alter_sql -join "`r`n"
        $synchedLogins = $list.Values.name | Sort-Object
        $CreateAlterLoginSqlOutputVar.Value = "DECLARE @checked BIT = 0;`r`n$sql"

        # now send the logins back out to each server
        foreach ($server in $Servers) {
            $connection = New-DBSqlConnection -ServerInstance $server.ServerInstance -Credentials $server.Credentials -Database "master"
            try {
                $connection.Open()
                $parameters = @(
                    (New-DBSqlParameter -name "@checked" -type Bit -value 0)
                )
                $val = [PSCustomObject] @{
                    ServerInstance = $server.ServerInstance
                    SynchedLogins = $synchedLogins
                    Success = $false
                    Error = $null
                }
                $ret.Add($val) | Out-Null
                if (-not $DoNotInvoke.IsPresent) {
                    Invoke-DBNonQuery -conn $connection -sql $sql -parameters $parameters | Out-Null
                }
                $val.Success = $true
            } catch {
                $val.Error = $_.Exception
            } finally {
                if ($connection) { $connection.Dispose() }
            }
        }
    }

    end {
        if ($ret -and $ret.Count -gt 0) {
            Write-Output $ret | Sort-Object -property @{ Expression={$_.ServerInstance} }
        } else {
            Write-Warning "No suitable logins found to synchronize."
        }
    }
}
