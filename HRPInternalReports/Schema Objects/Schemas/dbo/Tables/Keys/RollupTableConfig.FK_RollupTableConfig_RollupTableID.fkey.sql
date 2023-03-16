ALTER TABLE [dbo].[RollupTableConfig]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableConfig_RollupTableID] FOREIGN KEY([RollupTableID])
REFERENCES [dbo].[RollupTable] ([RollupTableID])