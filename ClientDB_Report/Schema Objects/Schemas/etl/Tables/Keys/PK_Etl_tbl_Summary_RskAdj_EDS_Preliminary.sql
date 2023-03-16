Alter TABLE [Etl].[tbl_Summary_RskAdj_EDS_Preliminary] ADD CONSTRAINT [PK_Etl_tbl_Summary_RskAdj_EDS_Preliminary] PRIMARY KEY CLUSTERED 
(
	[tbl_Summary_RskAdj_EDS_PreliminaryId] ASC,
	[PaymentYear] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) 
ON [pscheme_SummPY](PaymentYear)
 

