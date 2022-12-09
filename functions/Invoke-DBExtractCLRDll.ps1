function Invoke-DBExtractCLRDLL {
    <#
    .SYNOPSIS
        Will extract all user CLR assemblies from a SQL SERVER database as DLL files, and or PDB files.

    .DESCRIPTION
        Will extract all user CLR assemblies from a SQL SERVER database as DLL files, and or PDB files.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Database
        The database containing the CLR dlls. 

    .PARAMETER SavePath
        Specifies the directory where you want to store the generated dll object.

    .PARAMETER UserName
        Specifies username to connect to the database with. If supplied, then password must be also. If not supplied then a trusted connection will be used.

    .PARAMETER Password
        Specifies the password to connect to the database with.

    .INPUTS
        None. You cannot pipe objects to this script.

    .OUTPUTS
        Returns the list of files that were extracted.

    .EXAMPLE
        PS> .\Invoke-DBExtractCLRDLL -ServerInstance "servername" -Database "AdventureWorks2012" 

    .EXAMPLE
        PS> .\Invoke-DBExtractCLRDLL -ServerInstance "servername" -Database "AdventureWorks2012" -UserName "user.name" -Password "ilovelamp" 

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [System.IO.DirectoryInfo]$SavePath,
        [string]$UserName,
        [string]$Password
    )    

    begin {
        if (-not $SavePath) {
            $path = [System.IO.Path]::Combine($env:TEMP, $database)
        } else {
            $path = $SavePath.FullName    
        }

        $query = "
        SELECT a.name, af.content, af.file_id, af.name AS [file_name], a.clr_name, a.permission_set_desc, a.create_date, a.modify_date
        FROM sys.assemblies a 
        INNER JOIN sys.assembly_files af 
            ON a.assembly_id = af.assembly_id 
        WHERE a.is_user_defined = 1"
    
        $connectionString = GetConnectionString -ServerInstance $ServerInstance -Database $Database -UserName $UserName -Password $Password
        $assemblies = New-Object System.Collections.ArrayList
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString);
    }

    process {
        try {
            # using an old style reader here as the data sizes can exceed the capabilities of Invoke-SqlCmd
            $connection.Open();        
            $command = $connection.CreateCommand()
            $command.CommandType = "Text";
            $command.CommandText = $query;
            $reader = $command.ExecuteReader();

            if ($reader.HasRows) {
                # create the output directory if it doesnt exist
                if (!(Test-Path -Path $path -PathType Container)) {
                    New-Item -Path $path -ItemType Directory | Out-Null
                }
        
                # get the ordinals of the fields as an object to use in retrieving data from the reader
                $fields = [PSCustomObject]@{}
                for ($i = 0; $i -le ($reader.FieldCount - 1); $i++){
                    $fields | Add-Member -MemberType NoteProperty $reader.GetName($i) -Value $i
                }
        
                while ($reader.Read()) {
                    # determine what type of file we are dealing with, 1 == dll, 2 == ??? something else
                    $fileId = $reader.GetInt32($fields.file_id)
                    
                    if ($fileId -eq 1) {
                        $fileName = "$($reader.GetString($fields.name)).dll"
                    } elseif ($fileId -ge 2) {
                        # get the original file name and extension from the data
                        $fileName = [System.Io.Path]::GetFileName("$($reader.GetString($fields.file_name))")
                    }
        
                    $fileName = [System.IO.Path]::Combine($path, $fileName)
                    # extract the bytes from a column into an arry
                    [byte[]]$bytes = $reader.GetSqlBytes($fields.content).Buffer
                    # write the byte array to a file
                    Write-Verbose "Writing file: $fileName"
                    [System.Io.File]::WriteAllBytes($fileName, $bytes)
        
                    $temp = New-Object System.Object
                    $temp | Add-Member -MemberType NoteProperty -Name "name" -Value $reader.GetString($fields.name)
                    $temp | Add-Member -MemberType NoteProperty -Name "file_id" -Value $reader.GetInt32($fields.file_id)
                    $temp | Add-Member -MemberType NoteProperty -Name "file_name" -Value $fileName
                    $temp | Add-Member -MemberType NoteProperty -Name "clr_name" -Value $reader.GetString($fields.clr_name)
                    $temp | Add-Member -MemberType NoteProperty -Name "permission_set_desc" -Value $reader.GetString($fields.permission_set_desc)
                    $temp | Add-Member -MemberType NoteProperty -Name "create_date" -Value $reader.GetDateTime($fields.create_date)
                    $temp | Add-Member -MemberType NoteProperty -Name "modify_date" -Value $reader.GetDateTime($fields.modify_date)
                    $assemblies.Add($temp) | Out-Null
                }
        
                $assemblies | Export-Csv -Path "$path\Assemblies.csv" -Force -Encoding ASCII -NoTypeInformation  
        
                # open up explorer, highlighting the first file name we found
                # Invoke-Expression "explorer.exe '/select,$path\Assemblies.csv'"
            } else {
                Write-Warning "No assemblies found to export" 
            }
        } catch {
            throw
        } finally {
            if ($reader) { $reader.Dispose() }
            if ($command) { $command.Dispose() }
            if ($connection) { $connection.Dispose() }
        }
    }

    end {
        return $assemblies
    }
}