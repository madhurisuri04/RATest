ALTER TABLE [dbo].[RollupPlan]  WITH CHECK ADD  CONSTRAINT [FK_RollupPlan_ClientIdentifierID] FOREIGN KEY([ClientIdentifier])
REFERENCES [dbo].[RollupClient] ([ClientIdentifier])