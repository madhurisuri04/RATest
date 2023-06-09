CREATE NONCLUSTERED INDEX [IDX_SummaryRskAdjMORSourcePartC_HICN_HCC]
ON [rev].[SummaryRskAdjMORSourcePartC]
	(
	[HICN] ASC,
	[HCC] ASC
	)
INCLUDE ([RecordType],[PayMonth],[PlanID])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO
