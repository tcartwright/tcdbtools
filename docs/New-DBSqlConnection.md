# New-DBSqlConnection
**Author** Tim Cartwright

## Synopsis
Creates a SqlConnection

## Description
Creates a SqlConnection

## Syntax
    New-DBSqlConnection 
        [-ServerInstance] <String> 
        [-Database] <String> 
        [[-Credentials] <PSCredential>] 
        [-MultipleActiveResultSets ] 
        [-ApplicationIntent] <String>
        [[-ConnectTimeout] <Int32>] 
        [[-ApplicationName] <String>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        The name or network address of the instance of SQL Server to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Database <String>
        The name of the database associated with the connection.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
		then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MultipleActiveResultSets <SwitchParameter>
        When true, an application can maintain multiple active result sets 
		(MARS). When false, an application must process or cancel all result 
		sets from one batch before it can execute any other batch on that 
		connection.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ApplicationIntent <String>
        Specifies a value for ApplicationIntent. Possible values are ReadWrite 
		and ReadOnly.

        Required?                    false
        Position?                    4
        Default value                ReadWrite
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ConnectTimeout <Int32>
        Gets or sets the length of time (in seconds) to wait for a connection 
		to the server before terminating the attempt and generating an error.

        Required?                    false
        Position?                    5
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ApplicationName <String>
        The name of the application associated with the connection string.

        Required?                    false
        Position?                    6
        Default value                tcdbtools
        Accept pipeline input?       false
        Accept wildcard characters?  false

[Back](/README.md)