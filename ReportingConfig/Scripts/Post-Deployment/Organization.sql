UPDATE dbo.Organization
set Active = 0
GO

UPDATE Org
SET Org.Active = 1
FROM dbo.Organization Org
INNER JOIN HRPPortalConfig.dbo.OrganizationApplicationXref x WITH(NOLOCK) on org.OrganizationID = x.OrganizationID
WHERE x.ApplicationCode in ('HIM') -- Add new applications to this list to populate based on application client list

GO