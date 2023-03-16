ALTER TABLE [dve].[_CriteriaColumnMap]  WITH CHECK ADD  CONSTRAINT [FK__CriteriaColumnMap_CriteriaGroup] FOREIGN KEY([GroupID])
REFERENCES [dve].[_CriteriaGroup] ([GroupID])