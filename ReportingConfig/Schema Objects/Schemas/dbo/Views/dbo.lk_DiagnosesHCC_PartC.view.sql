CREATE VIEW [dbo].[lk_DiagnosesHCC_PartC] AS
SELECT
	[DiagnosesHCCID],
	[ICD9],
	[HCC_Label],
	[Payment_Year],
	[HCC_Number],
	[ModifiedDate]
FROM [$(HRPReporting)].[dbo].[lk_DiagnosesHCC_PartC]



