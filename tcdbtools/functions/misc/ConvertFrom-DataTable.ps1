function ConvertFrom-DataTable {
    [Alias("DataTableToCustomObject")]
    <#
        .LINK https://www.stefanroth.net/2018/04/11/powershell-create-clean-customobjects-from-datatable-object/
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [AllowNull()]
        [System.Data.DataTable]$DataTable
    )
    begin {
        $Objects = @()
    }
    process {
        foreach ($row in $DataTable.Rows) {
            $Properties = @{}
            foreach ($name in $DataTable.Columns.ColumnName) {
                $Properties.Add($name, $row[$name])
            }
            $Objects += New-Object -TypeName PSObject -Property $Properties
        }
    }
    end {
        # select the objects using the column name array so the properties will output in the same order
        return $Objects | Select-Object -Property $DataTable.Columns.ColumnName
    }
}
