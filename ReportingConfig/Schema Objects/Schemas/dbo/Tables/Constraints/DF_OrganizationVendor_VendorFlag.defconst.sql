ALTER TABLE [dbo].[OrganizationVendor]
    ADD CONSTRAINT [DF_OrganizationVendor_VendorFlag] DEFAULT ((1)) FOR [VendorFlag];

