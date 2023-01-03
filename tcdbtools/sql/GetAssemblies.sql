SELECT a.name, 
    af.content, 
    af.file_id, 
    af.name AS [file_name], 
    a.clr_name, 
    a.permission_set_desc, 
    a.create_date, 
    a.modify_date
FROM sys.assemblies a
INNER JOIN sys.assembly_files af
    ON a.assembly_id = af.assembly_id
WHERE a.is_user_defined = 1