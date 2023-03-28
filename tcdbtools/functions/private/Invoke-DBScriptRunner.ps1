[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$ScriptRunnerBlock = {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("AvoidAssignmentToAutomaticVariable", '', Scope="Function", Target="*")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", '', Scope="Function", Target="*")]
    param(
        [String]$ServerInstance,
        [String]$Database,
        [pscredential]$Credentials,
        [string]$Query,
        [int]$timeout = 300
    )
    $ret = [PSCustomObject] @{
        ServerInstance = $ServerInstance
        Database = $Database
        Results = [System.Data.DataTable]$null
        Messages = [string]$null
        Success = $false
        Exception = [System.Exception]$null
    }
    try {
        $sb = [System.Text.StringBuilder]::new()
        $connection = New-DBSqlConnection -ServerInstance $ServerInstance -Database $Database -Credentials $Credentials
        $connection.Open()

        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
            param($sender, $event)
            $sb.AppendLine($event.Message) | Out-Null
        };
        $connection.add_InfoMessage($handler);

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
