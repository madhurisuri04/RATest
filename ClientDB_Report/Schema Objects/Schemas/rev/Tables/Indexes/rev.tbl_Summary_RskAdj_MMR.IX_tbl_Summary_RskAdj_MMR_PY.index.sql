CREATE NONCLUSTERED INDEX [IX_tbl_Summary_RskAdj_MMR_PY]
ON [rev].[tbl_Summary_RskAdj_MMR] ([PaymentYear])
INCLUDE ([PlanID],
         [HICN],
         [PaymStart],
         [RskAdjAgeGrp],
         [PartCRAFTProjected],
         [ORECRestated],
         [HOSP],
         [PriorPaymentYear],
         [Aged])
 WITH (PAD_INDEX  = ON, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
