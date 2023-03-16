CREATE TABLE [dbo].[Organization] (
    [OrganizationID] INT           IDENTITY (1, 1) NOT NULL,
    [Name]           VARCHAR (255) NOT NULL,
    [Internal]       BIT           NOT NULL,
    [ClientAlphaID]  VARCHAR (20)  NULL,
    [Active]         BIT           NOT NULL DEFAULT 1
);
