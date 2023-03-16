CREATE NONCLUSTERED INDEX [IX_tbl_Summary_RskAdj_RAPS_Alternative02] ON [dbo].[tbl_Summary_RskAdj_RAPS] 
(
[HICN] ASC,
[PaymStart] ASC,
[PlanID] ASC,
[Model_Year] ASC,
[PaymentYear] ASC,
[Factor_category] ASC
)
INCLUDE ( [Factor_Desc],
[Factor],
[Factor_Desc_ORIG],
[HCC_Number],
[RAFT]) WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100)



