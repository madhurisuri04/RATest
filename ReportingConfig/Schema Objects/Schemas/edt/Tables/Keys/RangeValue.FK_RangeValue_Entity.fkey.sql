ALTER TABLE [edt].[RangeValue]  WITH CHECK ADD  CONSTRAINT [FK_RangeValue_Entity] FOREIGN KEY([ValueEntity])
REFERENCES [dve].[Entity] ([ID])