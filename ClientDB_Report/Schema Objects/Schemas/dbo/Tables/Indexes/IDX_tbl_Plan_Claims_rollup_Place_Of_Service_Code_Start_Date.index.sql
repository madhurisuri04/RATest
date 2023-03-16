CREATE NONCLUSTERED INDEX [IDX_tbl_Plan_Claims_rollup_Place_Of_Service_Code_Start_Date] ON [dbo].[tbl_Plan_Claims_rollup] 
(
	[Place_Of_Service_Code] ASC,
	[Start_Date] ASC,
	[Procedure_Code] ASC,
	[Plan_Provider_ID] ASC,
	[HICN] ASC,
	[Plan_Claim_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

