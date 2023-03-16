CREATE NONCLUSTERED INDEX [IDX_IntermediarySupplemental_ServiceEndDate]
ON [rev].[IntermediarySupplemental]
	(
	[ServiceEndDate] ASC,
	[VendorID] ASC,
	[SubProjectID] ASC,
	[SupplementalID] ASC
	)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO