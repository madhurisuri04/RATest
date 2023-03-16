CREATE VIEW [dbo].[lk_RemitRmkWPC] AS
SELECT
	[RemitRmkWPCID],
	[Code],
	[Description],
	[EffectiveDate],
	[DeactivationDate],
	[LastModifiedDate],
	[Notes]
FROM [$(HRPReporting)].[dbo].[lk_RemitRmkWPC]