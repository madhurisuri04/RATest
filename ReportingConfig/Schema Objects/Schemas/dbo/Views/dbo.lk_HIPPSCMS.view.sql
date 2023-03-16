CREATE VIEW [dbo].[lk_HIPPSCMS] AS
SELECT
	[HIPPSCMSID],
	[HIPPSCode],
	[CodeEffectiveFromDate],
	[CodeEffectiveThroughDate],
	[PaymentSystemIndicator],
	[Description]
FROM [$(HRPReporting)].[dbo].[lk_HIPPSCMS]