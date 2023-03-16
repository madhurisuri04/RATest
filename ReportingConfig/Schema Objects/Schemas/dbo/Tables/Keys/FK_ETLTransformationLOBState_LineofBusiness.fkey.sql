ALTER TABLE [dbo].[ETLTransformationLOBState]
    ADD CONSTRAINT [FK_ETLTransformationLOBState_LineofBusiness] FOREIGN KEY ([LineOfBusinessID]) REFERENCES [ref].[LineofBusiness] ([LineofBusinessID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

