ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_CriteriaType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_CriteriaType] ([ID])