# Get-InClauseString
**Author** Tim Cartwright

## Synopsis
Creates the string representation of the parameters that can be used with an IN clause.

## Description
Creates the string representation of the parameters that can be used with an IN clause.

## Syntax
    Get-InClauseString 
        [-parameters] <SqlParameter[]> 
        [[-delimiter] <String>] 
        [<CommonParameters>]

## Parameters
    -parameters <SqlParameter[]>
        The IN clause parameters created by using Get-InClauseParams.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -delimiter <String>
        The delimiter to use between the parameter names. Defaults to ",".

        Required?                    false
        Position?                    2
        Default value                ,
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
$params = Get-InClauseParams -prefix "p_" -values $someList -type [System.Data.SqlDbType]::VarChar -size 50
$paramString = Get-InClauseString -parameters $params

# Assuming the list has 3 values in it, Get-InClauseParams should return "@p_0,@p_1,@p_2". This string can now be concatenated to the original query like so that the query looks like this example: "SELECT * FROM dbo.SomeTable AS [t] WHERE [t].id IN (@p_0,@p_1,@p_2)" 

# If multiple parameter lists are needed for multiple IN clauses, then different prefixes should be utilized for each list.
```
### Example

```powershell
$list = 1..15
$params = Get-InClauseParams -prefix "p" -values $list -type Int
$paramStr = Get-InClauseString -parameters $params
# now you can concatenate the $paramStr to your in clause, and add $params to your commands parameters collection
$params
$paramStr
```

[Back](/README.md)