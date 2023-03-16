CREATE VIEW [dbo].[lk_ClmStatusReasonWPC] AS
SELECT
	[ClmStatusReasonWPCID],
	[Code],
	[Description],
	[EffectiveDate],
	[DeactivationDate],
	[LastModifiedDate],
	[Notes]
FROM [$(HRPReporting)].[dbo].[lk_ClmStatusReasonWPC]