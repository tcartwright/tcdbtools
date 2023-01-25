# Get-DBInClauseString
**Author** Tim Cartwright

## Synopsis
Creates the string representation of the parameters that can be used with an IN clause.

## Description
Creates the string representation of the parameters that can be used with an IN clause.

## Syntax
    Get-DBInClauseString 
        [-parameters] <SqlParameter[]> 
        [[-delimiter] <String>] 
        [<CommonParameters>]

## Parameters
    -parameters <SqlParameter[]>
        The IN clause parameters created by using Get-DBInClauseParams.

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
$someList = "867", "5", "309"
$params = Get-DBInClauseParams `
    -prefix "p_" `
    -values $someList `
    -type VarChar `
    -size 50 `
    -InformationAction Continue
$paramString = Get-DBInClauseString `
    -parameters $params `
    -InformationAction Continue

# Assuming the list has 3 values in it, Get-DBInClauseParams should return "@p_0,@p_1,@p_2". This string can 
# now be concatenated to the original query like so that the query looks like this example: 
#    
#   "SELECT * FROM dbo.SomeTable AS [t] WHERE [t].SomeColumn IN (@p_0,@p_1,@p_2)" 

$query = "SELECT * FROM dbo.SomeTable AS [t] WHERE [t].SomeColumn IN ({0})" -f $paramString
Write-Information $query -InformationAction Continue

# If multiple parameter lists are needed for multiple IN clauses, then different prefixes should be utilized for each list.
```
### Example

```powershell
$list = 1..7
$params = Get-DBInClauseParams `
    -prefix "p" `
    -values $list `
    -type Int `
    -InformationAction Continue
$paramStr = Get-DBInClauseString `
    -parameters $params `
    -InformationAction Continue
# now you can concatenate the $paramStr to your in clause, and add $params to your commands parameters collection
Write-Information $params -InformationAction Continue
Write-Information $paramStr -InformationAction Continue
```

<br/>
<br/>
  
[Back](/README.md)
