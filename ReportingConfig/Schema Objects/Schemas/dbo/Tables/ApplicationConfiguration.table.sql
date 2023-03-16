CREATE TABLE [dbo].[ApplicationConfiguration] (
    [ID]                        INT           IDENTITY (1, 1) NOT NULL,
    [ApplicationCode]           VARCHAR (12)  NOT NULL,
    [OrganizationID]            INT           NOT NULL,
    [ConfigurationDefinitionID] INT           NOT NULL,
    [ConfigurationValue]        VARCHAR (256) NOT NULL,
    [DisabledDateTime]          DATETIME2 (7) NULL
);
