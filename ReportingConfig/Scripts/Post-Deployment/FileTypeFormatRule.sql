-- =============================================
-- Script Template
-- =============================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;
SET IDENTITY_INSERT dbo.FileTypeFormatRule ON;

MERGE dbo.FileTypeFormatRule AS target
USING (
	SELECT f.[ID], f.[FileTypeFormatID], f.[FileTypeFormatRuleTypeID], f.[RuleDefinition], f.[DisabledDateTime] 
	FROM HRPPortalConfig.dbo.FileTypeFormatRule f WITH(NOLOCK)
	INNER JOIN HRPPortalConfig.dbo.FileTypeFormat t WITH(NOLOCK) on f.FileTypeFormatID = t.ID
	INNER JOIN HRPPortalConfig.dbo.FileTypeApplicationXref x WITH(NOLOCK) on t.FileTypeID = x.FileTypeID
	WHERE x.ApplicationCode in ('RPT')
) AS source
ON (target.ID = source.ID)
WHEN MATCHED THEN 
	UPDATE SET
		FileTypeFormatID = source.FileTypeFormatID, 
		FileTypeFormatRuleTypeID = source.FileTypeFormatRuleTypeID,
		RuleDefinition = source.RuleDefinition,
		DisabledDateTime = source.DisabledDateTime
WHEN NOT MATCHED THEN	
	INSERT (ID, FileTypeFormatID, FileTypeFormatRuleTypeID, RuleDefinition, DisabledDateTime)
	VALUES (source.ID, source.FileTypeFormatID, source.FileTypeFormatRuleTypeID, source.RuleDefinition, source.DisabledDateTime);

SET IDENTITY_INSERT dbo.FileTypeFormatRule OFF;

COMMIT;
