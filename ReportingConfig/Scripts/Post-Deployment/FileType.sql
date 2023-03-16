-- =============================================
-- Script Template
-- =============================================

BEGIN TRANSACTION;

SET IDENTITY_INSERT [dbo].[FileType] ON

MERGE dbo.FileType AS target
USING (
	SELECT f.[ID], f.[Name] 
	From HRPPortalConfig.dbo.FileType f WITH(NOLOCK) 
	INNER JOIN HRPPortalConfig.dbo.FileTypeApplicationXref x WITH(NOLOCK) on x.FileTypeID = f.ID
	WHERE x.ApplicationCode in ('RPT')
	
) AS source
ON (target.ID = source.ID)
WHEN MATCHED THEN 
    UPDATE SET Name = source.Name
WHEN NOT MATCHED THEN	
    INSERT (ID, Name)
    VALUES (source.ID, source.Name);

SET IDENTITY_INSERT [dbo].[FileType] OFF

COMMIT;
GO
