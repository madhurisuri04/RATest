CREATE VIEW [dbo].[lk_Factors_PartC] AS
SELECT
	[FactorID],
	[Payment_Year],
	[HCC_Label],
	[Description],
	[Comm],
	[Inst],
	[ShortDescription],
	[HCC_is_Chronic],
	[ESRD_Dialysis],
	[ESRD_Comm],
	[ESRD_Inst],
	[HCC_Number],
	[ModifiedDate]
FROM [$(HRPReporting)].[dbo].[lk_Factors_PartC]