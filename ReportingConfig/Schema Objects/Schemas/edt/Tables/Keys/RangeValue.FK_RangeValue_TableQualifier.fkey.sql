ALTER TABLE [edt].[RangeValue]  WITH CHECK ADD  CONSTRAINT [FK_RangeValue_TableQualifier] FOREIGN KEY([ValueEntityQualifier])
REFERENCES [dve].[TableQualifier] ([ID])
