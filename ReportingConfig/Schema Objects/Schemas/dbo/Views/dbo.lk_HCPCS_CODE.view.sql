CREATE VIEW [dbo].[lk_HCPCS_CODE] AS
SELECT
    [HCPCS_ID],
    [HCPCS_Code],
    [CodeStatus],
    [Short_Description],
    [Full_Description],
    [CoverageInstAndRef],
    [Include_In_Raps],
	[Coverage_Code],
    [StartDate],
    [EndDate]
FROM [$(HRPReporting)].[dbo].[lk_HCPCS_CODE]