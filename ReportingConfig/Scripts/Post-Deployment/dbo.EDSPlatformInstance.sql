
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
DELETE FROM dbo.EDSPlatformInstance;

SET IDENTITY_INSERT [dbo].EDSPlatformInstance ON;
GO

insert into dbo.EDSPlatformInstance (EDSPlatformInstanceID, OrganizationID, EDSPlatformAppCode)
SELECT OrganizationID, OrganizationID, 'EDS' from dbo.Organization

insert into dbo.EDSPlatformInstance (EDSPlatformInstanceID, OrganizationID, EDSPlatformAppCode)
SELECT OrganizationID+10000, OrganizationID, 'HIM' from dbo.Organization

insert into dbo.EDSPlatformInstance (EDSPlatformInstanceID, OrganizationID, EDSPlatformAppCode)
SELECT OrganizationID+20000, OrganizationID, 'HHL' from dbo.Organization 

insert into dbo.EDSPlatformInstance (EDSPlatformInstanceID, OrganizationID, EDSPlatformAppCode)
SELECT OrganizationID+30000, OrganizationID, 'PLC' from dbo.Organization

SET IDENTITY_INSERT [dbo].EDSPlatformInstance OFF;
GO

COMMIT TRANSACTION;
go