CREATE VIEW [dbo].[lk_Revenue_code] AS
SELECT
	[Rev_Code],
	[Rev_Description],
	[EffectiveDate],
	[TerminationDate]
FROM [$(HRPReporting)].[dbo].[lk_Revenue_code]