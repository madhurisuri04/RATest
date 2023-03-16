ALTER TABLE [dve].[Entity]  WITH CHECK ADD  CONSTRAINT [FK_Entity_TableDefinition] FOREIGN KEY([TableDefinitionID])
REFERENCES [dve].[TableDefinition] ([ID])