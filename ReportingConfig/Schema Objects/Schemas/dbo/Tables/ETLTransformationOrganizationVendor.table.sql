CREATE TABLE [dbo].[ETLTransformationOrganizationVendor] (
    [ETLTransformationOrganizationVendorID] INT IDENTITY (1, 1) NOT NULL,
    [ETLTransformationID]                   INT NOT NULL,
    [OrganizationID]                        INT NOT NULL,
    [OrganizationVendorID]                  INT NOT NULL
);

