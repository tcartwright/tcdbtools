
function ConvertFrom-DataRows {
    <#
        .LINK https://www.stefanroth.net/2018/04/11/powershell-create-clean-customobjects-from-datatable-object/
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [AllowNull()]
        [System.Data.DataRow[]]$DataRows
    )
    begin {
        $Objects = @()
    }
    process {
        if (-not $dataTable) {
            $dataTable = ($DataRows | Select-Object -First 1).Table
        }
        foreach ($row in $DataRows) {
            $Properties = @{}
            foreach ($name in $dataTable.Columns.ColumnName) {
                $Properties.Add($name, $row[$name])
            }
            $Objects += New-Object -TypeName PSObject -Property $Properties
        }
    }
    end {
        # select the objects using the column name array so the properties will output in the same order
        return $Objects | Select-Object -Property $dataTable.Columns.ColumnName
    }
}