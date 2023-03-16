SET IDENTITY_INSERT [dbo].Organization ON;
GO

MERGE dbo.Organization AS target
USING (
		SELECT DISTINCT o.[ID] as [OrganizationID], o.[Name], o.[Internal] ,o.ClientAlphaID
		FROM HRPPortalConfig.dbo.Organization o WITH(NOLOCK)
)
		AS source
ON (target.[OrganizationID] = source.[OrganizationID])
WHEN MATCHED AND (target.Name <> source.Name or target.Internal <> source.Internal or ISNULL(source.ClientAlphaID,'') <> ISNULL(target.ClientAlphaID,'') ) THEN 
    UPDATE SET 
		Name = source.Name,
		Internal = source.Internal,
		ClientAlphaID=source.ClientAlphaID
WHEN NOT MATCHED THEN	
    INSERT ([OrganizationID], Name, Internal, Active ,ClientAlphaID)
    VALUES (source.[OrganizationID], source.Name, source.Internal, 0,source.ClientAlphaID);

SET IDENTITY_INSERT [dbo].Organization OFF;
GO