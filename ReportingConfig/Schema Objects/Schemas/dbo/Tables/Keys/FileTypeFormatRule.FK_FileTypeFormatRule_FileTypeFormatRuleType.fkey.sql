ALTER TABLE [dbo].[FileTypeFormatRule]
    ADD CONSTRAINT [FK_FileTypeFormatRule_FileTypeFormatRuleType] FOREIGN KEY ([FileTypeFormatRuleTypeID]) REFERENCES [dbo].[FileTypeFormatRuleType] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

