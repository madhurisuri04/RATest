ALTER TABLE [dbo].[ETLTransformationOrganizationVendor]
    ADD CONSTRAINT [FK_ETLTransformationOrganizationVendor_ETLTransformation] FOREIGN KEY ([ETLTransformationID]) REFERENCES [dbo].[ETLTransformation] ([ETLTransformationID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

