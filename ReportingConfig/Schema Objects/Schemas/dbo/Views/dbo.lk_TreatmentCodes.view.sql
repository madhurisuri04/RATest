CREATE VIEW [dbo].[lk_TreatmentCodes] AS
SELECT
	[TreatmentCodesID],
	[Code],
	[Description]
FROM [$(HRPReporting)].[dbo].[lk_TreatmentCodes]