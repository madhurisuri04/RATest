IF @@SERVERNAME = 'HRPDEVDB01'
BEGIN
PRINT 'Updating Application configuration'

-- HIM Edge Reporting Application Settings
Begin
	MERGE dbo.ApplicationConfiguration AS target
	USING (

	-- New England Health (Demo)
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'NewEnglandHealth_EdgeReports' AS [ConfigurationValue] UNION ALL

	-- MVP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
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

-- Tier1 Member HIM Application Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (

		-- New England Health (Demo)
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'NewEnglandHealth_Member_HIM' AS [ConfigurationValue] UNION ALL
	
		-- MVP
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'MVP_Member_HIM' AS [ConfigurationValue]

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
			
-- Tier1 Medical HIM Application Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (

		-- New England Health (Demo)
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'NewEnglandHealth_Medical_HIM' AS [ConfigurationValue] UNION ALL
	
		-- MVP
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] ='Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'MVP_Medical_HIM' AS [ConfigurationValue]

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
		
-- Tier1 Report HIM Application Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (

		-- New England Health (Demo)
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'NewEnglandHealth_Report_HIM' AS [ConfigurationValue] UNION ALL
	
		-- MVP
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] ='Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'MVP_Report_HIM' AS [ConfigurationValue]

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

-- Tier1 Drug HIM Application Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (

		-- New England Health (Demo)
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Plan of New England (Demo)') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'NewEnglandHealth_Drug_HIM' AS [ConfigurationValue] UNION ALL
	
		-- MVP
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPDEVDB01' AS [ConfigurationValue] UNION ALL
		SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] ='Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
				,N'MVP_Drug_HIM' AS [ConfigurationValue]

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


-- REC Extrac Settings :

	MERGE dbo.ApplicationConfiguration AS target
	USING (
	--NewEnglandHealth

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPDevDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'NewEnglandHealth_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPDevDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'NewEnglandHealth_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'New England Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\shares\ClientData\DEV\NewEnglandHealth\Extracts\' AS [ConfigurationValue] 
	
		) AS source
	ON (target.[OrganizationID] = source.[OrganizationID]
		and target.[ConfigurationDefinitionID] = source.[ConfigurationDefinitionID])
	WHEN MATCHED THEN 
		UPDATE SET
			ConfigurationValue = source.ConfigurationValue,
			ApplicationCode = 'REC'
	WHEN NOT MATCHED THEN	
		INSERT ([OrganizationID], [ConfigurationDefinitionID], ConfigurationValue, ApplicationCode)
		VALUES (source.[OrganizationID], source.[ConfigurationDefinitionID], source.ConfigurationValue, 'REC');;



END