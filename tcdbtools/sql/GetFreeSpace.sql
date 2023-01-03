SELECT DB_NAME() AS [db_name],
    f.[name] AS [filegroup_name],
    df.[name] AS [file_name],
    fn.[size] AS current_size_mb,
    fn.[space_used] AS used_space_mb,
    fn.[size] - fn.[space_used] AS free_space_mb
FROM [{0}].sys.[database_files] df
INNER JOIN [{0}].sys.[filegroups] AS [f]
    ON [f].[data_space_id] = [df].[data_space_id]
CROSS APPLY (
    SELECT CAST(CAST(FILEPROPERTY(df.name,'SpaceUsed') AS INT) / 128.0 AS INT) AS [space_used],
        CAST(df.[size] / 128.0 AS INT) AS [size]

) fn
WHERE [df].[type_desc] = 'ROWS'
    AND [f].[name] IN (@FileGroupName, 'SHRINK_DATA_TEMP');
