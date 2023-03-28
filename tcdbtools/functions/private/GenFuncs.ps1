using namespace System.Management.Automation

function GetSQLFileContent {
    param ([string]$fileName)
    $sql = Get-Content -Path ([System.IO.Path]::Combine($script:tcdbtools_SqlDir, $fileName)) -Raw
    # strip of the signature block if there is one.
    $sql = $sql -ireplace "# SIG # Begin signature block[\W\w\d\r\n]*?# SIG # End signature block", ""
    return $sql
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


function GetPercentComplete {
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$counter,
        [Parameter(Mandatory = $true)]
        [int]$total
    )
    $pct = ([decimal]$counter / [decimal]$total) * 100.00
    return [Convert]::ToInt32([Math]::Min(100, $pct))
}