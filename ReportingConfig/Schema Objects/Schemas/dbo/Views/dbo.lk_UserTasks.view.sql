CREATE VIEW [dbo].[lk_UserTasks] AS
SELECT
    [Task_ID],
    [Task_Description],
    [Task_Description_Long]
FROM [$(HRPReporting)].[dbo].[lk_UserTasks]