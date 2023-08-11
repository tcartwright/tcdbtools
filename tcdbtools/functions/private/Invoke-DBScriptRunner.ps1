[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$ScriptRunnerBlock = {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("AvoidAssignmentToAutomaticVariable", '', Scope="Function", Target="*")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", '', Scope="Function", Target="*")]
    param(
        [TCDbTools.DBServer]$server,
        [string]$Query,
        [int]$timeout = 300
    )
    $ret = [PSCustomObject] @{
        ServerInstance = $server.ServerInstance
        Database = $server.Database
        Results = [System.Data.DataTable]$null
        Messages = [string]$null
        Success = $false
        Exception = [System.Exception]$null
    }
    try {
        $sb = [System.Text.StringBuilder]::new()
        $connection = New-DBSqlConnection -ServerInstance $server.ServerInstance -Database $server.Database -Credentials $server.Credentials
        $connection.Open()

        $handler = [Microsoft.Data.SqlClient.SqlInfoMessageEventHandler] {
            param($sender, $event)
            $sb.AppendLine($event.Message) | Out-Null
        };
        $connection.add_InfoMessage($handler);

        # we are imitating sql cmd args. we don't really want to use sql cmd, just the args part
        foreach ($arg in $server.SqlCmdArgs.GetEnumerator()) {
            $Query = $Query -ireplace "\$\($($arg.Name)\)", $arg.Value
        }

        $ret.Results = Invoke-DBDataTableQuery -conn $connection -sql $Query -CommandType Text -timeout $timeout
        $ret.Messages = $sb.ToString()
        $ret.Success = $true
    } catch {
        $ret.Exception = $_.Exception
    } finally {
        if ($connection) { $connection.Dispose(); }
    }

    return $ret
}
