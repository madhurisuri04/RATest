CREATE VIEW [dbo].[lk_DischargeNUBC] AS
SELECT
	[DischargeNUBCID],
	[Code],
	[Description],
	[EffectiveDate],
	[TerminationDate]
FROM [$(HRPReporting)].[dbo].[lk_DischargeNUBC]