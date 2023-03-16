CREATE NONCLUSTERED INDEX [IX_tbl_Summary_RskAdj_MMR_Alternate] ON [rev].[tbl_Summary_RskAdj_MMR]
(
[HICN],
[SCC] ,
[PBP] ,
[PaymStart] ,
[PlanID] ,
[PartCRAFTProjected] ,
[PaymentYear] 
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
 ) 


