CREATE VIEW [dbo].[xref_ReportsReportGroups] AS
SELECT
    [ReportGroupID],
    [ReportID]
FROM [$(HRPReporting)].[dbo].[xref_ReportsReportGroups]