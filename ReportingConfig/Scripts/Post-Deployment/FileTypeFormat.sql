-- =============================================
-- Script Template
-- =============================================


SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;
SET IDENTITY_INSERT dbo.FileTypeFormat ON;

MERGE dbo.FileTypeFormat AS target
USING (
	SELECT f.[ID], f.[FileTypeID], f.[Name], f.[DisabledDateTime], f.[ImportPackage], f.[ExternalTransform], f.[ExternalTransformUnprocessedPath], f.[ExternalTransformProcessedPath], f.[ExternalTransformPreProcessPackage], f.[ExternalTransformPostProcessPackage] 
	FROM HRPPortalConfig.dbo.FileTypeFormat f WITH(NOLOCK)
	INNER JOIN HRPPortalConfig.dbo.FileTypeApplicationXref x WITH(NOLOCK) on x.FileTypeID = f.FileTypeID
	WHERE x.ApplicationCode in ('RPT')
) AS source
ON (target.ID = source.ID)
WHEN MATCHED THEN 
	UPDATE SET
		FileTypeID = source.FileTypeID, 
		Name = source.Name,
		DisabledDateTime = source.DisabledDateTime,
		ImportPackage = source.ImportPackage,
		ExternalTransform = source.ExternalTransform,
		ExternalTransformUnprocessedPath = source.ExternalTransformUnprocessedPath,
		ExternalTransformProcessedPath = source.ExternalTransformProcessedPath, 
		ExternalTransformPreProcessPackage = source.ExternalTransformPreProcessPackage, 
		ExternalTransformPostProcessPackage = source.ExternalTransformPostProcessPackage
WHEN NOT MATCHED THEN	
	INSERT (ID, FileTypeID, Name, DisabledDateTime, ImportPackage, ExternalTransform, ExternalTransformUnprocessedPath, ExternalTransformProcessedPath, ExternalTransformPreProcessPackage, ExternalTransformPostProcessPackage)
	VALUES (source.ID, source.FileTypeID, source.Name, source.DisabledDateTime, source.ImportPackage, source.ExternalTransform, source.ExternalTransformUnprocessedPath, source.ExternalTransformProcessedPath, source.ExternalTransformPreProcessPackage, source.ExternalTransformPostProcessPackage);

SET IDENTITY_INSERT dbo.FileTypeFormat OFF;

COMMIT;


GO