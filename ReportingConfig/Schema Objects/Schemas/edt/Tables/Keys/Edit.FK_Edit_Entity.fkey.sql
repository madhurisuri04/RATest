ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_Entity] FOREIGN KEY([EntityID])
REFERENCES [dve].[Entity] ([ID])