ALTER TABLE [dbo].[ETLTransformationLOBState]
    ADD CONSTRAINT [FK_ETLTransformationLOBState_StateCode] FOREIGN KEY ([StateCodeID]) REFERENCES [ref].[StateCode] ([StateCodeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

