CREATE VIEW [dbo].[lk_Bill_Types] AS
SELECT
	[BillTypeID],
	[Bill_Type],
	[Provider_Type],
	[Provider_Type_code],
	[BillTypeDescription],
	[Raps_Acceptable],
	[CMS_Acceptable],
	[Effective_Date],
	[Termination_Date]
FROM [$(HRPReporting)].[dbo].[lk_Bill_Types]


