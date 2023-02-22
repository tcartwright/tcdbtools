# Invoke-DBCompareServerSettings
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/Invoke-DBCompareServerSettings.ps1)

## Synopsis
Compares all server settings for each instance passed in to generate a report showing differences. The user options are also compared individually. Any user option will have its name suffixed with (options).

## Description
Compares all server settings for each instance passed in to generate a report showing differences.

## Syntax
    Invoke-DBCompareServerSettings 
        [-ServerInstances] <String[]> 
        [[-Credentials] <PSCredential>] 
        [-IgnoreVersionDifferences ] 
        [<CommonParameters>]

## Parameters
    -ServerInstances <String[]>
        The sql server instances to connect to and compare.  At least two 
        servers must be passed in.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IgnoreVersionDifferences <SwitchParameter>
        If a SQL Server does not support a particular setting because it is an 
        older version  then the value will be a dash: "-". If this switch is 
        present, then any setting value with a dash will not be considered a 
        difference.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example Output


| NAME | DIFFS | SERVER1 | SERVER2 | SERVER3 | SERVER4 |
| ---- | ----- | ----- | ----- | ----- | ----- |
| server version | 1 | 2017 | 2014 | 2019 | 2019 |
| access check cache bucket count |  | 0 | 0 | 0 | 0 |
| access check cache quota |  | 0 | 0 | 0 | 0 |
| Ad Hoc Distributed Queries |  | 0 | 0 | 0 | 0 |
| ADR cleaner retry timeout (min) |  | 0 | 0 | - | - |
| ADR Preallocation Factor |  | 0 | 0 | - | - |
| affinity I/O mask |  | 0 | 0 | 0 | 0 |
| affinity mask |  | 0 | 0 | 0 | 0 |
| affinity64 I/O mask |  | 0 | 0 | 0 | 0 |
| affinity64 mask |  | 0 | 0 | 0 | 0 |
| Agent XPs |  | 1 | 1 | 1 | 1 |
| allow filesystem enumeration |  | 1 | 1 | - | - |
| allow polybase export |  | 0 | 0 | 0 | - |
| allow updates |  | 0 | 0 | 0 | 0 |
| ANSI_NULL_DFLT_OFF (options) |  | 0 | 0 | 0 | 0 |
| ANSI_NULL_DFLT_ON (options) |  | 0 | 0 | 0 | 0 |
| ANSI_NULLS (options) |  | 0 | 0 | 0 | 0 |
| ANSI_PADDING (options) |  | 0 | 0 | 0 | 0 |
| ANSI_WARNINGS (options) |  | 0 | 0 | 0 | 0 |
| ARITHABORT (options) |  | 0 | 0 | 0 | 0 |
| ARITHIGNORE (options) |  | 0 | 0 | 0 | 0 |
| automatic soft-NUMA disabled |  | 0 | 0 | 0 | - |
| backup checksum default |  | 0 | 0 | 0 | 0 |
| backup compression default |  | 0 | 0 | 0 | 0 |
| blocked process threshold (s) | 1 | 3 | 0 | 0 | 0 |
| c2 audit mode |  | 0 | 0 | 0 | 0 |
| clr enabled | 1 | 1 | 1 | 0 | 0 |
| clr strict security |  | 1 | 1 | 1 | - |
| column encryption enclave type |  | 0 | 0 | - | - |
| common criteria compliance enabled |  | 0 | - | - | - |
| CONCAT_NULL_YIELDS_NULL (options) |  | 0 | 0 | 0 | 0 |
| contained database authentication |  | 0 | 0 | 0 | 0 |
| cost threshold for parallelism | 1 | 75 | 75 | 5 | 50 |
| cross db ownership chaining |  | 0 | 0 | 0 | 0 |
| cursor threshold |  | -1 | -1 | -1 | -1 |
| CURSOR_CLOSE_ON_COMMIT (options) |  | 0 | 0 | 0 | 0 |
| Database Mail XPs | 1 | 0 | 1 | 0 | 0 |
| default full-text language |  | 1033 | 1033 | 1033 | 1033 |
| default language |  | 0 | 0 | 0 | 0 |
| default trace enabled |  | 1 | 1 | 1 | 1 |
| DISABLE_DEF_CNST_CHK (options) |  | 0 | 0 | 0 | 0 |
| disallow results from triggers |  | 0 | 0 | 0 | 0 |
| EKM provider enabled |  | 0 | 0 | - | - |
| external scripts enabled |  | 0 | 0 | 0 | - |
| filestream access level |  | 0 | 0 | 0 | 0 |
| fill factor (%) |  | 0 | 0 | 0 | 0 |
| ft crawl bandwidth (max) |  | 100 | 100 | 100 | 100 |
| ft crawl bandwidth (min) |  | 0 | 0 | 0 | 0 |
| ft notify bandwidth (max) |  | 100 | 100 | 100 | 100 |
| ft notify bandwidth (min) |  | 0 | 0 | 0 | 0 |
| hadoop connectivity |  | 0 | 0 | 0 | - |
| IMPLICIT_TRANSACTIONS (options) |  | 0 | 0 | 0 | 0 |
| index create memory (KB) |  | 0 | 0 | 0 | 0 |
| in-doubt xact resolution |  | 0 | 0 | 0 | 0 |
| lightweight pooling |  | 0 | 0 | 0 | 0 |
| locks |  | 0 | 0 | 0 | 0 |
| max degree of parallelism | 1 | 2 | 0 | 8 | 4 |
| max full-text crawl range |  | 4 | 4 | 4 | 4 |
| max server memory (MB) | 1 | 6144 | 3072 | 2048 | 6000 |
| max text repl size (B) |  | 65536 | 65536 | 65536 | 65536 |
| max worker threads |  | 0 | 0 | 0 | 0 |
| media retention |  | 0 | 0 | 0 | 0 |
| min memory per query (KB) |  | 1024 | 1024 | 1024 | 1024 |
| min server memory (MB) |  | 0 | 0 | 0 | 0 |
| nested triggers |  | 1 | 1 | 1 | 1 |
| network packet size (B) |  | 4096 | 4096 | 4096 | 4096 |
| NOCOUNT (options) |  | 0 | 0 | 0 | 0 |
| NUMERIC_ROUNDABORT (options) |  | 0 | 0 | 0 | 0 |
| Ole Automation Procedures |  | 0 | 0 | 0 | 0 |
| open objects |  | 0 | 0 | 0 | 0 |
| optimize for ad hoc workloads |  | 0 | 0 | 0 | 0 |
| PH timeout (s) |  | 60 | 60 | 60 | 60 |
| polybase enabled |  | 0 | 0 | - | - |
| polybase network encryption |  | 1 | 1 | 1 | - |
| precompute rank |  | 0 | 0 | 0 | 0 |
| priority boost |  | 0 | 0 | 0 | 0 |
| query governor cost limit |  | 0 | 0 | 0 | 0 |
| query wait (s) |  | -1 | -1 | -1 | -1 |
| QUOTED_IDENTIFIER (options) |  | 0 | 0 | 0 | 0 |
| recovery interval (min) |  | 0 | 0 | 0 | 0 |
| remote access |  | 1 | 1 | 1 | 1 |
| remote admin connections | 1 | 1 | 1 | 0 | 0 |
| remote data archive |  | 0 | 0 | 0 | - |
| remote login timeout (s) |  | 10 | 10 | 10 | 10 |
| remote proc trans |  | 0 | 0 | 0 | 0 |
| remote query timeout (s) |  | 600 | 600 | 600 | 600 |
| Replication XPs |  | 0 | 0 | 0 | 0 |
| scan for startup procs |  | 0 | 0 | 0 | 0 |
| server trigger recursion |  | 1 | 1 | 1 | 1 |
| set working set size |  | 0 | 0 | 0 | 0 |
| show advanced options |  | 0 | 0 | 0 | 0 |
| SMO and DMO XPs |  | 1 | 1 | 1 | 1 |
| tempdb metadata memory-optimized |  | 0 | 0 | - | - |
| transform noise words |  | 0 | 0 | 0 | 0 |
| two digit year cutoff |  | 2049 | 2049 | 2049 | 2049 |
| user connections |  | 0 | 0 | 0 | 0 |
| user options |  | 0 | 0 | 0 | 0 |
| version high part of SQL Server |  | 0 | 0 | - | - |
| version low part of SQL Server |  | 0 | 0 | - | - |
| XACT_ABORT (options) |  | 0 | 0 | 0 | 0 |
| xp_cmdshell |  | 0 | 0 | 0 | 0 |


<br/>
<br/>
  
[Back](/README.md)
