ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_TableQualifier2] FOREIGN KEY([ValueEntityQualifier])
REFERENCES [dve].[TableQualifier] ([ID])
