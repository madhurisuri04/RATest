ALTER TABLE [dbo].[ETLValidationLOBState]
    ADD CONSTRAINT [FK_ETLValidationLOBState_ETLValidation] FOREIGN KEY ([ETLValidationID]) REFERENCES [dbo].[ETLValidation] ([ETLValidationID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

