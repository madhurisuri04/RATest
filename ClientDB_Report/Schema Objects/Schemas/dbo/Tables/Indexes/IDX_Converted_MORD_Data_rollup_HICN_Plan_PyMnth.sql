CREATE NONCLUSTERED INDEX IDX_Converted_MORD_Data_rollup_HICN_Plan_PyMnth
ON [dbo].[Converted_MORD_Data_rollup] 
(
[HICN] ASC
)
INCLUDE ([PlanIdentifier],[Payment_Month],[Name],[RecordType],[Comm])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, 
DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO

 