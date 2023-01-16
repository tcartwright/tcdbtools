function New-DBScripterObject {
    <#
    .SYNOPSIS
        Creates a database scripting object that can be modified and used by Invoke-DBScriptObjects

    .DESCRIPTION
        Creates a database scripting object that can be modified and used by Invoke-DBScriptObjects

    .PARAMETER ServerInstance
        Specifies the database server hostname.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .INPUTS
        None. You cannot pipe objects to this script.

    .OUTPUTS
        None.

    .EXAMPLE
        PS> $scripter = New-DBScripterObject -ServerInstance "ServerName"

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [pscredential]$Credentials
    )

    begin {

    }

    process {
        $server = New-DBSMOServer -ServerInstance $ServerInstance -Credentials $Credentials
        $Scripter = New-Object "Microsoft.SqlServer.Management.Smo.Scripter" $Server #create the scripter

        # https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.management.smo.scriptingoptions?view=sql-smo-160
        $Scripter.Options.AllowSystemObjects = $false
        $Scripter.Options.AnsiFile = $true
        $Scripter.Options.AnsiPadding = $false # true = SET ANSI_PADDING statements
        $Scripter.Options.Default = $true
        $Scripter.Options.DriAll = $true
        $Scripter.Options.Encoding = New-Object "System.Text.ASCIIEncoding"
        $Scripter.Options.ExtendedProperties = $true
        $Scripter.Options.IncludeDatabaseContext = $false # true = USE <DatabaseName> statements
        $Scripter.Options.IncludeHeaders = $false
        $Scripter.Options.NoCollation = $false # true = don't script verbose collation info in table scripts
        $Scripter.Options.Permissions = $true
        $Scripter.Options.ScriptSchema = $true
        $Scripter.Options.SchemaQualify = $true
        $Scripter.Options.SchemaQualifyForeignKeysReferences = $true
        $Scripter.Options.ScriptDrops = $false
        $Scripter.Options.ToFileOnly = $true
        $Scripter.Options.Triggers = $true
        $Scripter.Options.Indexes = $true
        $Scripter.Options.XmlIndexes = $true
        $Scripter.Options.FullTextIndexes = $true
        $Scripter.Options.ClusteredIndexes = $true
        $Scripter.Options.NonClusteredIndexes = $true
        $Scripter.Options.WithDependencies = $false
        $Scripter.Options.ContinueScriptingOnError = $true
    }

    end {
        return $Scripter
    }
}