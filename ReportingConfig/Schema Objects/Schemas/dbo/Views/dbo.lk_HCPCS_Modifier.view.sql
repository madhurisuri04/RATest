CREATE VIEW [dbo].[lk_HCPCS_Modifier] AS
SELECT
	[HCPCSModID],
	[Modifier],
	[Full_Description],
	[EffectiveDate],
	[TerminationDate],
	[CreatedDate],
	[LastModifiedDate]
FROM [$(HRPReporting)].[dbo].[lk_HCPCS_Modifier]