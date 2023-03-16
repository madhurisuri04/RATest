ALTER TABLE [edt].[EditCondition]  WITH CHECK ADD  CONSTRAINT [FK_EditCondition_Condition] FOREIGN KEY([ConditionID])
REFERENCES [edt].[Condition] ([ID])