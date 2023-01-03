DECLARE @sanityCounter INT = 1

WHILE EXISTS (
    SELECT [job].[name],
        job.job_id,
        [job].[originating_server],
        [activity].[run_requested_date],
        DATEDIFF(SECOND, [activity].[run_requested_date], 
        GETDATE()) AS elapsed
    FROM msdb.dbo.sysjobs_view AS job
    JOIN msdb.dbo.sysjobactivity AS activity ON job.job_id = activity.job_id
    JOIN msdb.dbo.syssessions AS sess ON sess.session_id = activity.session_id
    JOIN (
        SELECT MAX(agent_start_date) AS max_agent_start_date
        FROM msdb.dbo.syssessions
    ) AS sess_max ON [sess].[agent_start_date] = [sess_max].[max_agent_start_date]
    WHERE [activity].[run_requested_date] IS NOT NULL
        AND [activity].[stop_execution_date] IS NULL
        AND [job].[name] = '{0}') BEGIN

    RAISERROR('WAITING LOOP %d FOR JOB [%s] TO STOP', 0, 1, @sanityCounter, '{0}') WITH NOWAIT
    -- wait at max 2 minutes
    SET @sanityCounter += 1
    IF @sanityCounter > 24 BEGIN
        RAISERROR('SANITY LOOP COUNTER EXCEEDED WAITING FOR JOB [%s] TO STOP, EXITING.', 0, 1, '{0}') WITH NOWAIT
        BREAK
    END
    WAITFOR DELAY '00:00:05'
END
