ALTER TABLE [edt].[EditCondition]  WITH CHECK ADD  CONSTRAINT [FK_EditCondition_Edit] FOREIGN KEY([EditID])
REFERENCES [edt].[Edit] ([ID])