DECLARE 
	@FilePath VARCHAR(255)

DECLARE @ArchivePath VARCHAR(100) = '\Baseline\Archive\'
DECLARE @ErrorPath VARCHAR(100) = '\Baseline\ReportError\'
DECLARE @SourcePath VARCHAR(100) = '\Baseline\'

IF @@SERVERNAME LIKE 'HRPDB001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\PRD\'
END
ELSE IF @@SERVERNAME LIKE 'HRPSTGDB001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\UAT\'
END
ELSE IF @@SERVERNAME LIKE 'HRPDEVDB01'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\DEV\'
END

MERGE dbo.[HIMBaselineClientConfiguration] AS TARGET
USING 
(
-- Caresource
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CareSource' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CareSource') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CareSource' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CareSource') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'CareSource' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CareSource') AS 'OrganizationID'
			
-- CoreSource
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CoreSource' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CoreSource' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'CoreSource' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS 'OrganizationID'
						
-- CCHP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS 'OrganizationID'

-- CGHC
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS 'OrganizationID'
		
-- Community Health Choice (CHC)
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS 'OrganizationID'
					
-- Excellus
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Excellus' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Excellus' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'Excellus' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS 'OrganizationID'
						
-- Health Alliance Medical Plans (HAMP)
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS 'OrganizationID'
			
-- Health First Health Plan (HFHP)
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS 'OrganizationID'
			
-- INHMOH
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'INHMOH' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'INHMOH' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'INHMOH' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS 'OrganizationID'
			
-- Rocky Mountain Health Plans Foundation (RMHP)
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'RMHP' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'RMHP' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'RMHP' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS 'OrganizationID'

-- Scott and White Health Plan (Scott_White)
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Scott_White' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Scott and White Health Plan') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Scott_White' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Scott and White Health Plan') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'Scott_White' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Scott and White Health Plan') AS 'OrganizationID'
	
-- Independent_Health
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS 'OrganizationID'
	
-- TrustMark
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'TrustMark' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'TrustMark' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'TrustMark' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS 'OrganizationID'

-- Samaritan Health Plan (Samaritan)
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @ArchivePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @ErrorPath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS 'OrganizationID'
	UNION
	SELECT
		'SourceFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @SourcePath AS 'ConfigurationValue',
		(SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS 'OrganizationID'
)
	AS SOURCE
ON 
	(
		TARGET.ConfigurationDefinition = SOURCE.ConfigurationDefinition 
	AND TARGET.OrganizationID = SOURCE.OrganizationID
	)
WHEN MATCHED THEN 
    UPDATE SET 
		ConfigurationValue = SOURCE.ConfigurationValue
WHEN NOT MATCHED THEN	
    INSERT 
		(
		ConfigurationDefinition,
		ConfigurationValue, 
		OrganizationID,
		UserID,
		LoadID,
		LoadDate
		)
    VALUES 
		(
		SOURCE.ConfigurationDefinition, 
		SOURCE.ConfigurationValue, 
		SOURCE.OrganizationID,
		SYSTEM_USER,
		-2147483600,
		GETDATE()
		);