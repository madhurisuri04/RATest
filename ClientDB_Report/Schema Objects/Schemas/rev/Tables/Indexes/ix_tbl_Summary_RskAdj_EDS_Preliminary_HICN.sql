CREATE NONCLUSTERED INDEX [ix_tbl_Summary_RskAdj_EDS_Preliminary_HICN] ON [rev].[tbl_Summary_RskAdj_EDS_Preliminary]
(
	[HICN] ASC
)
INCLUDE ( 
		[MAO004ResponseDiagnosisCodeID]
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) 
	ON [pscheme_SummPY](PaymentYear)
GO
 