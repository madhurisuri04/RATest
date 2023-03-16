ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_CriteriaType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_CriteriaType] ([ID])