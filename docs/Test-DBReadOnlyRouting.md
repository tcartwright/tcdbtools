# Test-DBReadOnlyRouting
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/Test-DBReadOnlyRouting.ps1)

## Synopsis
Tests read only routing for an availability group, and returns whether or not the routing is valid.

## Description
Tests read only routing for an availability group, and returns whether or not the routing is valid.

## Syntax
    Test-DBReadOnlyRouting 
        [-ServerInstances] <String[]> 
        [[-Database] <String>] 
        [[-Credentials] <PSCredential>] 
        [<CommonParameters>]

## Parameters
    -ServerInstances <String[]>
        The sql server instances to connect to. This should be the listener name 
        of the AG group.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Database <String>
        The database. This database must be a synchronized database. If left 
        empty, the the script will attempt to discover a synchronized database.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used. This authentication will be used 
        for each server.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example 

```powershell
Test-DBReadOnlyRouting `
    -ServerInstances "listener1", "listener2" `
    -InformationAction Continue | Format-Table
```

### Example Output

| ListenerName | Database | ReadOnlyServer | ReadWriteServer | ReadOnlyIsValid | Reason |
| ------------ | -------- | -------------- | --------------- | --------------- | ------ |
| SERVER1 | SampleDB | SERVER1-1 | SERVER1-2 | False | SERVERS ARE EQUAL |
| SERVER2 |  |  |  | False | EXCEPTION: Login failed. The login is from an untrusted domain and cannot be used with Integrated authentication. |
| SERVER3 |  |  |  | False | NO SYNCHRONIZED DBS |
| SERVER4 |  |  |  | False | NO SYNCHRONIZED DBS |

<br/>
<br/>
  
[Back](/README.md)
