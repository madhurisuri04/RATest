ALTER TABLE [dbo].[RollupMinMaxValues] ADD CONSTRAINT [PK_RollupMinMaxValues_ID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) WITH (PAD_INDEX = ON, FILLFACTOR = 100 ) ON [PRIMARY]