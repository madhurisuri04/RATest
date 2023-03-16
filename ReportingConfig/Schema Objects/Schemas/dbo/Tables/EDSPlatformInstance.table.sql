CREATE TABLE [dbo].[EDSPlatformInstance] (
    [EDSPlatformInstanceID] INT  IDENTITY (1, 1) NOT NULL,
    [OrganizationID]        INT      NOT NULL,
    [EDSPlatformAppCode]    CHAR (3) NOT NULL
);

