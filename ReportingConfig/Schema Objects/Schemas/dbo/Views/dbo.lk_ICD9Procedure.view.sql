CREATE VIEW [dbo].[lk_ICD9Procedure] AS
SELECT
	[ICD9ProcedureID],
	[Code],
	[ChangeIndicator],
	[CodeStatus],
	[ShortDesc],
	[MediumDesc],
	[LongDesc],
	[CodeNoDecimal]
FROM [$(HRPReporting)].[dbo].[lk_ICD9Procedure]