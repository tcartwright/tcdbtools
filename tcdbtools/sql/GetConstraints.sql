SELECT [t].[schema_name],
        [t].[table_name],
        [t].[object_name],
        [t].[details1],
        [t].[details2],
        [t].[details3],
        RTRIM([t].[type]) AS [type]
FROM (
    SELECT
        [schema_name]		= SCHEMA_NAME(fk.[schema_id]),
        [table_name]		= OBJECT_NAME(fk.[parent_object_id]),
        [object_name]		= fk.[name],
        [fk].[object_id],
        [details1]			= OBJECT_SCHEMA_NAME(fk.[referenced_object_id]),
        [details2]			= OBJECT_NAME(fk.[referenced_object_id]),
        [details3]			= NULL,
        [o].[type]
    FROM sys.[foreign_keys] fk
    INNER JOIN sys.[objects] o ON fk.[object_id] = o.[object_id]
    WHERE OBJECTPROPERTY(fk.[parent_object_id], 'IsMSShipped') = 0

    UNION ALL

    SELECT
        [schema_name]		= SCHEMA_NAME(o.[schema_id]),
        [table_name]		= OBJECT_NAME(i.[object_id]),
        [object_name]		= i.[name],
        [i].[object_id],
        [details1]			= COL_NAME(i.[object_id], ic.[column_id]),
        [details2]			= fn.[names],
        [details3]			= CASE
                                    WHEN i.[type] = 1 THEN 'Clustered index'
                                    WHEN i.[type] = 2 THEN 'Nonclustered unique index'
                                    WHEN i.[type] = 3 THEN 'XML index'
                                    WHEN i.[type] = 4 THEN 'Spatial index'
                                    WHEN i.[type] = 5 THEN 'Clustered columnstore index'
                                    WHEN i.[type] = 6 THEN 'Nonclustered columnstore index'
                                    WHEN i.[type] = 7 THEN 'Nonclustered hash index'
                                END,
        [type]				=	CASE
                                WHEN i.[is_primary_key] = 1 THEN 'PK'
                                WHEN i.[is_unique_constraint] = 1 THEN 'UQ'
                                WHEN i.[is_unique] = 1 THEN 'UX'
                                ELSE 'NC'
                            END
    FROM  sys.[indexes] i
    INNER JOIN sys.[objects] o ON i.[object_id] = o.[object_id]
    INNER JOIN sys.[index_columns] AS [ic]
        ON [ic].[object_id] = [i].[object_id]
            AND [ic].[index_id] = [i].[index_id]
            AND ic.[index_column_id] = 1
    CROSS APPLY (
        SELECT STUFF((
            SELECT CONCAT(', ', COL_NAME(i.[object_id], ic2.[column_id]))
            FROM sys.[index_columns] AS [ic2]
                WHERE [ic2].[object_id] = [i].[object_id]
                AND [ic2].[index_id] = [i].[index_id]
            FOR XML PATH('')
        ), 1, 2, '')  AS [names]
    ) fn
    WHERE i.type > 0
        AND OBJECTPROPERTY(o.[object_id], 'IsMSShipped') = 0
        AND OBJECTPROPERTYEX(o.[object_id], 'BaseType') <> 'TT' -- ignore table types as their constraints cannot be named


    UNION ALL

    SELECT [schema_name]		= SCHEMA_NAME([c].[schema_id]),
            [table_name]		= OBJECT_NAME([c].[parent_object_id]),
            [object_name]		= [c].[name],
            [c].[object_id],
            [details1]			= COL_NAME([c].[parent_object_id], [c].[parent_column_id]),
            [details2]			= NULL,
            [details3]			= NULL,
            [type]				= 'D'
    FROM sys.[default_constraints] AS [c]
    WHERE OBJECTPROPERTY([c].[parent_object_id], 'IsMSShipped') = 0
        AND OBJECTPROPERTYEX([c].[parent_object_id], 'BaseType') <> 'TT' -- ignore table types as their constraints cannot be named

    UNION ALL

    SELECT [schema_name]		= SCHEMA_NAME([c].[schema_id]),
            [table_name]		= OBJECT_NAME([c].[parent_object_id]),
            [object_name]		= [c].[name],
            [c].[object_id],
            [details1]			= COL_NAME([c].[parent_object_id], [c].[parent_column_id]),
            [details2]			= c.[definition],
            [details3]			= NULL,
            [type]				= 'C'
    FROM sys.[check_constraints] AS [c]
    WHERE OBJECTPROPERTY([c].[parent_object_id], 'IsMSShipped') = 0
        AND OBJECTPROPERTYEX([c].[parent_object_id], 'BaseType') <> 'TT' -- ignore table types as their constraints cannot be named
) t
ORDER BY [t].[schema_name],
    [t].[table_name],
    [t].[type],
    [t].[object_id]
