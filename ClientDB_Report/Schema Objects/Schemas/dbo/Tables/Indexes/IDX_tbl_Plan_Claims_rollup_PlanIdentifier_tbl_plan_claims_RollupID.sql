CREATE NONCLUSTERED INDEX [IDX_tbl_Plan_Claims_rollup_PlanIdentifier_tbl_plan_claims_RollupID]
ON [dbo].[tbl_plan_claims_Rollup] 
	(
	[PlanIdentifier] ASC,
	[tbl_plan_claims_RollupID] ASC
	)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
