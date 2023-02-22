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

