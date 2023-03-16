CREATE VIEW [dbo].[lk_ValueCode] AS
SELECT
	ValueCodeID,
	[Code],
	[Description],
	[EffectiveDate],
	[TerminationDate]
FROM [$(HRPReporting)].[dbo].[lk_ValueCode]