DECLARE @FilePath VARCHAR(255),
@SSISPath VARCHAR(255) = '\HRP\Reporting\HIM\EdgeReports\'

DECLARE @XMLArchivePath VARCHAR(100) = '\EdgeResponse\Archive\ReportArchive\'
DECLARE @XMLErrorPath VARCHAR(100) = '\EdgeResponse\ReportError\'
DECLARE @XMLPath VARCHAR(100) = '\EdgeResponse\ReportXML\'
DECLARE @XMLRootPath VARCHAR(100) = '\EdgeResponse\ReportRoot\'

DECLARE
	@CCHP INT = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP'),
	@CGHC INT = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC'),
	@CHC INT = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice'),
	@HAMP INT = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans'),
	@HFHP INT = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan'),
	@IndHealth INT  = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health'),
	@Samaritan INT = (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan')

IF @@SERVERNAME like 'HRPDB001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\PRD\'
END
ELSE IF @@SERVERNAME like 'HRPSTGDB001'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\UAT\'
END
ELSE IF @@SERVERNAME like 'HRPDEVDB01'
BEGIN
	SELECT @FilePath = '\\hrp.local\Shares\ClientData\DEV\'
END

MERGE dbo.[EdgeReportClientConfiguration] AS target
USING (
		
/* CCHP */

	--RACSD
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CCHP AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CCHP AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CCHP AS 'OrganizationID'
	
	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RADVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RADVPSF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RADVPSFRoot.xml' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CCHP AS 'OrganizationID'

	--RAPHCCER
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CCHP AS 'OrganizationID'		
		
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CCHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CCHP' + @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CCHP AS 'OrganizationID'

/* CGHC */
	
	--RACSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CGHC AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CGHC AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CGHC AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CGHC AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CGHC AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CGHC AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CGHC AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CGHC AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CGHC AS 'OrganizationID'
	
	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RADVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CGHC AS 'OrganizationID'
		
	--RAPHCCER
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CGHC AS 'OrganizationID'				
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CGHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CGHC' + @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CGHC AS 'OrganizationID'
				
		
/* Community Health Choice */

	--RACSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@CHC AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@CHC AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@CHC AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@CHC AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@CHC AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@CHC AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@CHC AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@CHC AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@CHC AS 'OrganizationID'
	
	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RADVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@CHC AS 'OrganizationID'

	--RADVPSF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RADVPSFRoot.xml' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@CHC AS 'OrganizationID'
		
	--RAPHCCER
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@CHC AS 'OrganizationID'
	
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CHC AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'CHC' + @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@CHC AS 'OrganizationID'
						
/* HAMP */

	--RACSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HAMP AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HAMP AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HAMP AS 'OrganizationID'

	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RADVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HAMP AS 'OrganizationID'	

	--RADVPSF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RADVPSFRoot.xml' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HAMP AS 'OrganizationID'
		
	--RAPHCCER
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HAMP AS 'OrganizationID'			
	
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HAMP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HAMP' + @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HAMP AS 'OrganizationID'	

/* HFHP */
	
	--RACSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@HFHP AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@HFHP AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@HFHP AS 'OrganizationID'
	
	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RADVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@HFHP AS 'OrganizationID'

	--RADVPSF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RADVPSFRoot.xml' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@HFHP AS 'OrganizationID'
		
	--RAPHCCER
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@HFHP AS 'OrganizationID'
	
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HFHP AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'HFHP' + @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@HFHP AS 'OrganizationID'
	
/* Independent_Health */

	--RACSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@IndHealth AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@IndHealth AS 'OrganizationID'
	
	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RADVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@IndHealth AS 'OrganizationID'

	--RADVPSF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RADVPSFRoot.xml' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@IndHealth AS 'OrganizationID'
		
	--RAPHCCER
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@IndHealth AS 'OrganizationID'				
	
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@IndHealth AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Independent_Health' + @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@IndHealth AS 'OrganizationID'

/* Samaritan Health Plan */
	
	UNION
	--RACSD
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RACSD' 'ConfigurationValue',
		'RACSD' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RACSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RACSS' 'ConfigurationValue',
		'RACSS' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RARSS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RARSS' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RARSSRoot.xml' 'ConfigurationValue',
		'RARSS' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RARSD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RARSD' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RARSDRoot.xml' 'ConfigurationValue',
		'RARSD' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RIDE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RIDE' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RIDERoot.xml' 'ConfigurationValue',
		'RIDE' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--HCRP
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @XMLArchivePath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @XMLErrorPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @XMLPath + 'HCRP' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan' + @XMLRootPath + 'HCRPDetailRoot.xml' 'ConfigurationValue',
		'HCRP' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RISR
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RISR' 'ConfigurationValue',
		'RISR' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RISRRoot.xml' 'ConfigurationValue',
		'RISR' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RATEE
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RATEE' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RATEERoot.xml' 'ConfigurationValue',
		'RATEE' 'ReportType',
		@Samaritan AS 'OrganizationID'
	
	--ECD
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'ECD' 'ConfigurationValue',
		'ECD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'ECDRoot.xml' 'ConfigurationValue',
		'ECD' 'ReportType',
		@Samaritan AS 'OrganizationID'
	
	--RADVPS
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RADVPS' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RADDVPSRoot.xml' 'ConfigurationValue',
		'RADVPS' 'ReportType',
		@Samaritan AS 'OrganizationID'

	--RADVPSF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RADVPSF' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RADDVPSFRoot.xml' 'ConfigurationValue',
		'RADVPSF' 'ReportType',
		@Samaritan AS 'OrganizationID'
		
 --RAPHCCER
   UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RAPHCCER' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RAPHCCERRoot.xml' 'ConfigurationValue',
		'RAPHCCER' 'ReportType',
		@Samaritan AS 'OrganizationID'
	
	--RAUF
	UNION
	SELECT
		'ArchiveFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLArchivePath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'ErrorFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLErrorPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'XMLFolder' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLPath + 'RAUF' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@Samaritan AS 'OrganizationID'
	UNION
	SELECT
		'RootNodeXML' 'ConfigurationDefinition',
		@FilePath + 'Samaritan'+ @XMLRootPath + 'RAUserFeeRoot.xml' 'ConfigurationValue',
		'RAUF' 'ReportType',
		@Samaritan AS 'OrganizationID'		
)
AS source
ON (target.ConfigurationDefinition = source.ConfigurationDefinition 
	and target.ReportType = source.ReportType 
	and target.OrganizationID = source.OrganizationID )
WHEN MATCHED THEN 
    UPDATE SET 
		ConfigurationValue = source.ConfigurationValue
WHEN NOT MATCHED THEN	
    INSERT (ConfigurationDefinition,ConfigurationValue,ReportType, OrganizationID )
    VALUES (source.ConfigurationDefinition, source.ConfigurationValue, source.ReportType, source.OrganizationID);