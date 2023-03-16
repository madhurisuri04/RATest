ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_TableQualifier] FOREIGN KEY([ValueEntityQualifier])
REFERENCES [dve].[TableQualifier] ([ID])
