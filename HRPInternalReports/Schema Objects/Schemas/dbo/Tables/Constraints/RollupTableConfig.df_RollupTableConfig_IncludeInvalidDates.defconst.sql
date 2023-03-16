ALTER TABLE [dbo].[RollupTableConfig] 
	ADD CONSTRAINT [df_RollupTableConfig_IncludeInvalidDates]  
		DEFAULT ((0)) FOR [IncludeInvalidDates]	