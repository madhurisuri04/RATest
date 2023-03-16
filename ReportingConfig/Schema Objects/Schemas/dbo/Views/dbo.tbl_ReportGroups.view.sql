CREATE VIEW [dbo].[tbl_ReportGroups] AS
SELECT
    [ReportGroupID],
    [ReportGroupName],
    [ReportGroupOrderBy]
FROM [$(HRPReporting)].[dbo].[tbl_ReportGroups]