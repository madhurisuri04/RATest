ALTER TABLE [dbo].[RollupTableConfig] 
	ADD CONSTRAINT [df_RollupTableConfig_IncludeNullDates]  
		DEFAULT ((0)) FOR [IncludeNullDates]

