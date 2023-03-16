ALTER TABLE [dbo].[RollupTable] 
	ADD CONSTRAINT [df_RollupTable_FilterValuesStartWithYear]  
		DEFAULT ((1)) FOR [FilterValuesStartWithYear]