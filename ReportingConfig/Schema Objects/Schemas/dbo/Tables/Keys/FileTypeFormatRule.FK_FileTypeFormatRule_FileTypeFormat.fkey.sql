ALTER TABLE [dbo].[FileTypeFormatRule]
    ADD CONSTRAINT [FK_FileTypeFormatRule_FileTypeFormat] FOREIGN KEY ([FileTypeFormatID]) REFERENCES [dbo].[FileTypeFormat] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

