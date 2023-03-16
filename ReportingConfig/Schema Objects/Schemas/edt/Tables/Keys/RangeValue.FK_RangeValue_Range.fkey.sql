ALTER TABLE [edt].[RangeValue]  WITH CHECK ADD  CONSTRAINT [FK_RangeValue_Range] FOREIGN KEY([RangeID])
REFERENCES [edt].[Range] ([ID])