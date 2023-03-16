ALTER TABLE [edt].[RuleCondition]  WITH CHECK ADD  CONSTRAINT [FK_RuleCondition_Rule] FOREIGN KEY([RuleID])
REFERENCES [edt].[Rule] ([ID])