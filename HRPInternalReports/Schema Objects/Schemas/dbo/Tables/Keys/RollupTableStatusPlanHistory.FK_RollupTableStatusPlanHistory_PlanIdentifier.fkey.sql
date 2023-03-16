ALTER TABLE [dbo].[RollupTableStatusPlanHistory]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableStatusPlanHistory_PlanIdentifier] FOREIGN KEY([PlanIdentifier])
REFERENCES [dbo].[RollupPlan] ([PlanIdentifier])
