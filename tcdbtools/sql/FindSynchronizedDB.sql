IF HAS_PERMS_BY_NAME(null, null, 'VIEW SERVER STATE') = 1 BEGIN
    SELECT TOP (1) db.name
    FROM sys.dm_hadr_database_replica_states rs
    JOIN sys.databases db 
        ON rs.database_id = db.database_id
    WHERE db.database_id > 4
        AND HAS_DBACCESS(db.name) = 1
        AND rs.synchronization_state_desc IN ('SYNCHRONIZED', 'SYNCHRONIZING')
        AND rs.synchronization_health_desc = 'HEALTHY'
END ELSE BEGIN 
    SELECT TOP (1) db.name
    FROM sys.databases db
    WHERE db.database_id > 4
        AND HAS_DBACCESS(db.name) = 1
        AND db.replica_id IS NOT NULL
END