CREATE NONCLUSTERED INDEX [IX_tbl_Intermediate_EDS_INT_01] ON [rev].[tbl_Intermediate_EDS_INT]
(
	[HICN] ASC,
	[RAFT] ASC,
	[HCC] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON  ) 

