USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT = 0

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs j WHERE j.name = '<<job_name>>') 
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_delete_job @job_name = '<<job_name>>', @delete_unused_schedule=1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END