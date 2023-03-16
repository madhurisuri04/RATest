CREATE VIEW [dbo].[lk_MSDRG] AS
SELECT
	[MSDRGID],
	[MSDRG],
	[Year],
	[FinalRulePostAcuteDRG],
	[FinalRuleSpecialPayDRG],
	[MDC],
	[TYPE],
	[MSDRGTitle],
	[Weights],
	[GeometricMeanLOS],
	[ArithmeticMeanLOS]
FROM [$(HRPReporting)].[dbo].[lk_MSDRG]