ALTER TABLE [dbo].[FileTypeFormat]
    ADD CONSTRAINT [FK_FileTypeFormat_FileType] FOREIGN KEY ([FileTypeID]) REFERENCES [dbo].[FileType] ([ID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

