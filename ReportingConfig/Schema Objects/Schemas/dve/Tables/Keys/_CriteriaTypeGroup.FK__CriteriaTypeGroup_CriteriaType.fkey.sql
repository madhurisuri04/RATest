ALTER TABLE [dve].[_CriteriaTypeGroup]  WITH CHECK ADD  CONSTRAINT [FK__CriteriaTypeGroup_CriteriaType] FOREIGN KEY([TypeID])
REFERENCES [dve].[_CriteriaType] ([ID])