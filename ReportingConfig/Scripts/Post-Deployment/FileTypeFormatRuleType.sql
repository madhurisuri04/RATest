-- =============================================
-- Script Template
-- =============================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;
SET IDENTITY_INSERT dbo.FileTypeFormatRuleType ON;

MERGE dbo.FileTypeFormatRuleType AS target
USING (
	SELECT [ID], [Name] FROM HRPPortalConfig.dbo.FileTypeFormatRuleType
) AS source
ON (target.ID = source.ID)
WHEN MATCHED THEN 
	UPDATE SET
		Name = source.Name
WHEN NOT MATCHED THEN	
	INSERT (ID, Name)
	VALUES (source.ID, source.Name);

SET IDENTITY_INSERT dbo.FileTypeFormatRuleType OFF;

COMMIT;