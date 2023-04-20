# New-DBSqlConnection
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/ado/New-DBSqlConnection.ps1)

## Synopsis
Creates a Microsoft.Data.SqlClient.SqlConnection

## Description
Creates a Microsoft.Data.SqlClient.SqlConnection

## Syntax
    New-DBSqlConnection 
        [-ServerInstance] <String> 
        [-Database] <String> 
        [[-Credentials] <PSCredential>] 
        [[-AuthenticationMethod] ] 
        [-MultipleActiveResultSets ] 
        [[-ApplicationIntent] ] 
        [[-ApplicationName] <String>] 
        [[-Encrypt] <String>] 
        [-TrustServerCertificate ] 
        [[-ColumnEncryptionSetting] ] 
        [[-ConnectTimeout] <Int32>] 
        [[-CommandTimeout] <Int32>] 
        [[-LoadBalanceTimeout] <Int32>] 
        [[-WorkstationID] <String>] 
        [[-MinPoolSize] <Int32>] 
        [[-MaxPoolSize] <Int32>] 
        [[-Pooling] <Boolean>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        Specifies the database server hostname.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Database <String>
        Specifies the name of the database.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -AuthenticationMethod <>
        The authentication method used for Connecting to SQL Database By Using Azure Active Directory Authentication.

        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MultipleActiveResultSets <SwitchParameter>
        When true, an application can maintain multiple active result sets (MARS). When false, an application must process or cancel all result sets from one batch before it can execute any other batch on that connection.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ApplicationIntent <>
        Specifies a value for ApplicationIntent. Possible values are ReadWrite and ReadOnly.

        Required?                    false
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ApplicationName <String>
        The application name that will be supplied to the connection.

        Required?                    false
        Position?                    7
        Default value                tcdbtools
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Encrypt <String>
        A SqlConnectionEncryptOption value since version 5.0 or a Boolean value for the earlier versions that indicates whether TLS encryption is required for all data sent between the client and server.

        Required?                    false
        Position?                    8
        Default value                Optional
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -TrustServerCertificate <SwitchParameter>
        A value that indicates whether the channel will be encrypted while bypassing walking the certificate chain to validate trust.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ColumnEncryptionSetting <>
        The column encryption settings for the connection string builder.

        Required?                    false
        Position?                    9
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ConnectTimeout <Int32>
        Gets or sets the length of time (in seconds) to wait for a connection to the server before terminating the attempt and generating an error.

        Required?                    false
        Position?                    6
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CommandTimeout <Int32>
        The default wait time (in seconds) before terminating the attempt to execute a command and generating an error. The default is 30 seconds.

        Required?                    false
        Position?                    10
        Default value                30
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -LoadBalanceTimeout <Int32>
        The minimum time, in seconds, for the connection to live in the connection pool before being destroyed.

        Required?                    false
        Position?                    11
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -WorkstationID <String>
        The name of the workstation connecting to SQL Server.

        Required?                    false
        Position?                    12
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MinPoolSize <Int32>
        The minimum number of connections allowed in the connection pool for this specific connection string.

        Required?                    false
        Position?                    13
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MaxPoolSize <Int32>
        The maximum number of connections allowed in the connection pool for this specific connection string.

        Required?                    false
        Position?                    14
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Pooling <Boolean>
        A Boolean value that indicates whether the connection will be pooled or explicitly opened every time that the connection is requested.

        Required?                    false
        Position?                    15
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

<br/>
<br/>
  
[Back](/README.md)
