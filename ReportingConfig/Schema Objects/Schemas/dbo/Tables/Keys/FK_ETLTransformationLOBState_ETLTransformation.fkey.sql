ALTER TABLE [dbo].[ETLTransformationLOBState]
    ADD CONSTRAINT [FK_ETLTransformationLOBState_ETLTransformation] FOREIGN KEY ([ETLTransformationID]) REFERENCES [dbo].[ETLTransformation] ([ETLTransformationID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

