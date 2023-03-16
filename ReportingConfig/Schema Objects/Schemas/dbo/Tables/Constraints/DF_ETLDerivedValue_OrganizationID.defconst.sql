ALTER TABLE [dbo].[ETLDerivedValue]
    ADD CONSTRAINT [DF_ETLDerivedValue_OrganizationID] DEFAULT ((0)) FOR [OrganizationID];

