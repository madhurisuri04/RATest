ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_TableQualifier] FOREIGN KEY([TableQualifierID])
REFERENCES [dve].[TableQualifier] ([ID])
