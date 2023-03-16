CREATE NONCLUSTERED INDEX [IDX_tbl_RAPS_Detail_rollup_PlanIdentifier_tbl_RAPS_Detail_rollupID]
ON [dbo].[tbl_RAPS_Detail_rollup] 
	(
	[PlanIdentifier] ASC,
	[tbl_RAPS_Detail_rollupID] ASC
	)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO