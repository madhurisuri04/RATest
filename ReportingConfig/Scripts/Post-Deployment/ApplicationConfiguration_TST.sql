IF @@SERVERNAME = 'HRPCNTESTDB01'
BEGIN
PRINT 'Updating Application configuration'

-- HIM Edge Reporting Application Settings
Begin
	MERGE dbo.ApplicationConfiguration AS target
	USING (

	-- New England Health (Demo)
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCNTESTDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'NewEnglandHealth_EdgeReports' AS [ConfigurationValue] UNION ALL
	
	-- MVP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCNTESTDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'MVP_EdgeReports' AS [ConfigurationValue]
			) AS source
	ON (target.[OrganizationID] = source.[OrganizationID]
		and target.[ConfigurationDefinitionID] = source.[ConfigurationDefinitionID])
	WHEN MATCHED THEN 
		UPDATE SET
			ConfigurationValue = source.ConfigurationValue,
			ApplicationCode = 'HIM'
	WHEN NOT MATCHED THEN	
		INSERT ([OrganizationID], [ConfigurationDefinitionID], ConfigurationValue, ApplicationCode)
		VALUES (source.[OrganizationID], source.[ConfigurationDefinitionID], source.ConfigurationValue, 'HIM');
End

END