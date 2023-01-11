[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$QueryTableScriptBlock = {
    param($connection, $sql, $parameters)
    try {
        $cmd = New-Object system.Data.SqlClient.SqlCommand($sql, $connection)
        $cmd.CommandType = "Text"
        $cmd.CommandTimeout = 300
        foreach($p in $parameters){
            $cmd.Parameters.Add($p) | Out-Null
        }
        $reader = $cmd.ExecuteReader()
        $table = New-Object System.Data.DataTable
        $table.Load($reader)
        return $table
    } finally {
        if ($reader) {
            $reader.Dispose();
        }
    }
}

