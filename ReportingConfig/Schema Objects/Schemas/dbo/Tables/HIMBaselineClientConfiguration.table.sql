CREATE TABLE [dbo].[HIMBaselineClientConfiguration]
(
	[HIMBaselineClientConfigurationID] [int] IDENTITY(1,1) NOT NULL,
	[ConfigurationDefinition] VARCHAR(30) NULL,
	[ConfigurationValue] VARCHAR(255) NULL,
	[OrganizationID] INT NULL,
	[UserID] VARCHAR(30) NOT NULL,
	[LoadID] BIGINT NOT NULL,
	[LoadDate] DATETIME2 NOT NULL
)