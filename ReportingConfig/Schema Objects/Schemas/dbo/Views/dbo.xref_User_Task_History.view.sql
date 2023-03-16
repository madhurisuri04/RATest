CREATE VIEW [dbo].[xref_User_Task_History] AS
SELECT
    [History_ID],
    [User_ID],
    [Task_ID],
    [Action_Text],
    [Date_Logged],
    [Exported_To_User_Report],
    [Exported_HRP_Report],
    [Exported_To_Alert_Log]
FROM [$(HRPReporting)].[dbo].[xref_User_Task_History]