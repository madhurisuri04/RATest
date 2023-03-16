ALTER TABLE [dbo].[RollupTableFileTypeXref]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableFileTypeXref_RollupTableID] FOREIGN KEY([RollupTableID])
REFERENCES [dbo].[RollupTable] ([RollupTableID])