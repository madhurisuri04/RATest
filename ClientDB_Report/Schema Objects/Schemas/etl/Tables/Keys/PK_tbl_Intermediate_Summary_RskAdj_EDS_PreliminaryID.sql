ALTER TABLE [etl].[tbl_Intermediate_Summary_RskAdj_EDS_Preliminary] ADD  CONSTRAINT [PK_tbl_Intermediate_Summary_RskAdj_EDS_PreliminaryID] PRIMARY KEY CLUSTERED 
(
[tbl_Intermediate_RskAdj_EDS_PreliminaryId] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) 
