ALTER TABLE [edt].[Condition]  WITH CHECK ADD  CONSTRAINT [FK_Condition_Range] FOREIGN KEY([RangeID])
REFERENCES [edt].[Range] ([ID])