CREATE VIEW [dbo].[lk_normalization_factors] AS
SELECT
	[Year],
	[PartC_Factor],
	[PartD_Factor],
	[ESRD_Dialysis_Factor],
	[FunctioningGraft_Factor],
	[Run_Receivable_Calc],
	[CodingIntensity],
	[Run_PartD_Recon],
	[ESRD_MSP_Reduction],
	[MSP_Reduction],
	[ModifiedDate]
FROM [$(HRPReporting)].[dbo].[lk_normalization_factors]