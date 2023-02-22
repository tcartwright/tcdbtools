# Get-DBInClauseParams
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/ado/Get-DBInClauseParams.ps1)

## Synopsis
Can be used to create a set of parameters that can be used with an IN clause.

## Description
Can be used to create a set of parameters that can be used with an IN clause.

## Syntax
    Get-DBInClauseParams 
        [-prefix] <String> 
        [-values] <Object> 
        [-type]  <System.Data.SqlDbType>
        [[-size] <Int32>] 
        [[-scale] <Int32>] 
        [[-precision] <Int32>] 
        [<CommonParameters>]

## Parameters
    -prefix <String>
        The prefix to place in front of the parameter name. Must make the 
        parameter name unique.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -values <Object>
        The list of values to place into the parameters.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -type <System.Data.SqlDbType>
        The SqlDbType of the parameters.

        Required?                    true
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -size <Int32>
        The maximum size, in bytes, of the data within the column.

        Required?                    false
        Position?                    4
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -scale <Int32>
        The number of decimal places to which Value is resolved.

        Required?                    false
        Position?                    5
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -precision <Int32>
        The maximum number of digits used to represent the Value property.

        Required?                    false
        Position?                    6
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
$list = 1..15
$params = Get-DBInClauseParams `
    -prefix "p" `
    -values $list `
    -type Int `
    -InformationAction Continue
$params
```

<br/>
<br/>
  
[Back](/README.md)
