﻿ALTER TABLE [edt].[Edit]  WITH CHECK ADD  CONSTRAINT [FK_Edit_Range] FOREIGN KEY([RangeID])
REFERENCES [edt].[Range] ([ID])