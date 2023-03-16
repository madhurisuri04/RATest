ALTER TABLE [edt].[RuleCondition]  WITH CHECK ADD  CONSTRAINT [FK_RuleCondition_Condition] FOREIGN KEY([ConditionID])
REFERENCES [edt].[Condition] ([ID])