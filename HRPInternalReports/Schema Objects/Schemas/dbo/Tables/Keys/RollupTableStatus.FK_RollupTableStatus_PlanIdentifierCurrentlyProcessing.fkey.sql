﻿ALTER TABLE [dbo].[RollupTableStatus]  WITH CHECK ADD  CONSTRAINT [FK_RollupTableStatus_PlanIdentifierCurrentlyProcessing] FOREIGN KEY([PlanIdentifierCurrentlyProcessing])
REFERENCES [dbo].[RollupPlan] ([PlanIdentifier])