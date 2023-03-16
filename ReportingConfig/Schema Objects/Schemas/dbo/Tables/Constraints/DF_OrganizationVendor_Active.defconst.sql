ALTER TABLE [dbo].[OrganizationVendor]
    ADD CONSTRAINT [DF_OrganizationVendor_Active] DEFAULT ((1)) FOR [Active];

