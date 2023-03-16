CREATE TABLE [dbo].[ETLTransformationOrganizationSpecific](
	[ETLTransformationOrganizationSpecificID] [int] IDENTITY(1,1) NOT NULL, 
	[ETLTransformationID] INT NOT NULL, 
	[OrganizationID] INT NOT NULL, 
	[Active] [bit] NOT NULL
)