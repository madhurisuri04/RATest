ALTER TABLE [dbo].[tbl_Existing_Conditions_rollup] ADD  CONSTRAINT [PK_tbl_Existing_Conditions_rollup_tbl_Existing_Conditions_rollupID] PRIMARY KEY CLUSTERED 
(
	[tbl_Existing_Conditions_rollupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
