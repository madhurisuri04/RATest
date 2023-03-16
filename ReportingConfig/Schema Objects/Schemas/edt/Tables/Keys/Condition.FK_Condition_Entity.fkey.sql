ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_Entity] FOREIGN KEY([ValueEntity])
REFERENCES [dve].[Entity] ([ID])