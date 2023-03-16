CREATE VIEW [dbo].[xref_User_Reports] AS
SELECT
    [Pk_User_Reports],
    [User_ID],
    [ReportID],
    [GroupID]
FROM [$(HRPReporting)].[dbo].[xref_User_Reports]