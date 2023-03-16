ALTER TABLE [dbo].[RollupTableConfig]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableConfig_ClientIdentifier] FOREIGN KEY([ClientIdentifier])
REFERENCES [dbo].[RollupClient] ([ClientIdentifier])