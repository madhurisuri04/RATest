ALTER TABLE [edt].[Range]  WITH CHECK ADD  CONSTRAINT [FK_Range_RangeType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_RangeType] ([ID])