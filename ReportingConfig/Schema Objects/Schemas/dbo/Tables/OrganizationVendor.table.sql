CREATE TABLE [dbo].[OrganizationVendor] (
    [OrganizationVendorID] INT          IDENTITY (1, 1) NOT NULL,
    [OrganizationID]       INT          NOT NULL,
    [VendorCode]           VARCHAR (50) NOT NULL,
    [VendorFlag]           BIT          NOT NULL,
    [Active]               BIT          NOT NULL
);

