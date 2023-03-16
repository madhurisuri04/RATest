ALTER TABLE [dbo].[RollupTableStatusHistory]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableStatusHistory_RollupTableStatusID] FOREIGN KEY([RollupTableStatusID])
REFERENCES [dbo].[RollupTableStatus] ([RollupTableStatusID])

