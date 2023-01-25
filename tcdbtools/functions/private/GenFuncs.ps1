#Requires -Version 5.0
using namespace System.Management.Automation

Function Write-InformationColorized {
    <#
        .SYNOPSIS
            Writes messages to the information stream, optionally with
            color when written to the host.
        .DESCRIPTION
            An alternative to Write-Host which will write to the information stream
            and the host (optionally in colors specified) but will honor the
            $InformationPreference of the calling context.
            In PowerShell 5.0+ Write-Host calls through to Write-Information but
            will _always_ treats $InformationPreference as 'Continue', so the caller
            cannot use other options to the preference variable as intended.

        .LINK
            https://blog.kieranties.com/2018/03/26/write-information-with-colours
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]$MessageData,
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor, # Make sure we use the current colours by default
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        [Switch]$NoNewline
    )

    $msg = [HostInformationMessage]@{
        Message         = $MessageData
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $NoNewline.IsPresent
    }

    Write-Information $msg
}

function GetSQLFileContent {
    param ([string]$fileName)
    return Get-Content -Path ([System.IO.Path]::Combine($script:tcdbtools_SqlDir, $fileName)) -Raw
}

function InstallPackage {
    param (
        [System.IO.DirectoryInfo]$path,
        [string]$packageName,
        [string]$packageSourceName,
        [string]$version,
        [switch]$SkipDependencies
    )

    $packageArgs = @{
        Name = $packageName
        ProviderName = "NuGet"
        Source = $packageSourceName
    }

    if ($version) {
        $packageArgs.Add("RequiredVersion", $version)
    }

    if (-not (Test-Path $path.FullName -PathType Container)) {
        New-Item $path.FullName -ErrorAction SilentlyContinue -Force -ItemType Directory
    }

    $package = Find-Package @packageArgs
    $packagePath = "$($path.FullName)\$($package.Name).$($package.Version)"

    if (-not (Test-Path $packagePath -PathType Container)) {
        # remove any older versions of the package
        Remove-Item "$($path.FullName)\$($package.Name)*" -Recurse -Force
        Write-Verbose "Installing Package: $($packageName)"
        $package = Install-Package @packageArgs -Scope CurrentUser -Destination $path.FullName -Force -SkipDependencies:$SkipDependencies.IsPresent
    }

    return $packagePath
}

function LoadAssembly {
    param ([System.IO.FileInfo]$path)
    # list loaded assemblies:
    # [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object Location | Sort-Object -Property FullName | Select-Object -Property FullName, Location, GlobalAssemblyCache, IsFullyTrusted | Out-GridView

    # load the assembly bytes so as to not lock the file
    Write-Verbose "Loading assembly: $($path.FullName)"

    # Add-Type -Path $path.FullName
    # $bytes = [System.IO.File]::ReadAllBytes($path.FullName)
    # [System.Reflection.Assembly]::Load($bytes) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($path.FullName) | Out-Null
    # Write-Host $ass | Format-List
}

function LoadAssemblies {
    param ([string]$path)

    $tmpPath = Get-Item $path
    $dllPaths = (Get-ChildItem -Path $tmpPath.FullName -Filter "*.dll")

    foreach ($dllPath in $dllPaths) {
        LoadAssembly -path $dllPath
    }
}

function ReplaceInvalidPathChars($str) {
    $str = $str.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $str = $str.Split([IO.Path]::GetInvalidPathChars()) -join '_'
    $str = $str -replace '\[|\]', ''
    return $str
}

function ConvertTo-Markdown {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]]$InputObject
    )

    begin {
        $sbMain = [System.Text.StringBuilder]::new()
        $sbDivider = [System.Text.StringBuilder]::new()
        $sbValues = [System.Text.StringBuilder]::new()
    }

    process {
        # test this in case the object was piped in, as we only want to do this once
        if ($sbMain.Length -eq 0) {
            ($InputObject | Select-Object -First 1).PSObject.Properties | ForEach-Object {
                $sbMain.Append("| $($_.Name) ") | Out-Null
                $sbDivider.Append("| $("-" * $_.Name.Length) ") | Out-Null
            }

            $sbMain.AppendLine("|") | Out-Null
            $sbDivider.Append("|") | Out-Null

            $sbMain.AppendLine($sbDivider.ToString()) | Out-Null
        }

        $InputObject | ForEach-Object {
            $_.PSObject.Properties | ForEach-Object {
                $sbValues.Append("| $($_.Value) ") | Out-Null
            }
            $sbValues.AppendLine("|") | Out-Null
        }
    }

    end {
        $sbMain.AppendLine($sbValues.ToString()) | Out-Null
        return $sbMain.ToString()
    }
}

function DataTableToCustomObject {
    <#
        .LINK https://www.stefanroth.net/2018/04/11/powershell-create-clean-customobjects-from-datatable-object/
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $True)]
        [AllowNull()]
        [System.Data.DataTable]$DataTable
    )
    if (-not $DataTable) {
        return $null
    }
    $Objects = @()
    foreach ($row in $DataTable.Rows) {
        $Properties = @{}
        foreach ($name in $DataTable.Columns.ColumnName) {
            $Properties.Add($name, $row[$name])
        }
        $Objects += New-Object -TypeName PSObject -Property $Properties
    }
    # select the objects using the column name array so the properties will output in the same order
    return $Objects | Select-Object -Property $DataTable.Columns.ColumnName
}

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