ALTER TABLE [dbo].[RollupTableStatusPlanHistory]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableStatusPlanHistory_RollupTableStatusID] FOREIGN KEY([RollupTableStatusID])
REFERENCES [dbo].[RollupTableStatus] ([RollupTableStatusID])

