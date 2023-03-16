ALTER TABLE [dve].[TableQualifier]  WITH CHECK ADD  CONSTRAINT [FK_TableQualifier_TableDefinition] FOREIGN KEY([TableDefinitionID])
REFERENCES [dve].[TableDefinition] ([ID])