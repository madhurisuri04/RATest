ALTER TABLE [dve].[_CriteriaTypeGroup]  WITH CHECK ADD  CONSTRAINT [FK__CriteriaTypeGroup_CriteriaGroup] FOREIGN KEY([GroupID])
REFERENCES [dve].[_CriteriaGroup] ([GroupID])
