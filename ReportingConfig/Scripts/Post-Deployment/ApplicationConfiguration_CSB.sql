IF @@SERVERNAME = 'HRPCSBDBS001'
BEGIN
PRINT 'Updating Application configuration'

-- HIM Edge Reporting Application Settings (do not add any clients that are EDS or HMP)
	MERGE dbo.ApplicationConfiguration AS target
	USING (
	--CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_EdgeReports' AS [ConfigurationValue] UNION ALL	

	--CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_EdgeReports' AS [ConfigurationValue] UNION ALL

	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
		,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
		,N'CHC_EdgeReports' AS [ConfigurationValue] UNION ALL

	--HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_EdgeReports' AS [ConfigurationValue] UNION ALL

	--Samaritan Health Plan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'Samaritan_EdgeReports' AS [ConfigurationValue] UNION ALL

	--Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'Sanford_EdgeReports' AS [ConfigurationValue] UNION ALL

	--SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'SmokeTest_EdgeReports' AS [ConfigurationValue]

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


	--HIM Application (do not add any clients that are EDS or HMP)
	MERGE dbo.ApplicationConfiguration AS target
	USING   ( 
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Provider_Depot' AS [ConfigurationValue] UNION ALL

	--CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Provider_Depot' AS [ConfigurationValue] UNION ALL

   --CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Provider_Depot' AS [ConfigurationValue] UNION ALL
		   
   --HAMP
   SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Provider_Depot' AS [ConfigurationValue] UNION ALL
		   
	--IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Provider_Depot' AS [ConfigurationValue] UNION ALL
		   
	--Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Provider_Depot' AS [ConfigurationValue] UNION ALL

    --Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Provider_Depot' AS [ConfigurationValue] UNION ALL

	--SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDB01' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPCSBDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Provider_Depot' AS [ConfigurationValue] 
				
	) AS source
	ON (target.[OrganizationID] = source.[OrganizationID]
		and target.[ConfigurationDefinitionID] = source.[ConfigurationDefinitionID])
		and target.[ApplicationCode] = 'HIM'
	WHEN MATCHED THEN 
		UPDATE SET
			ConfigurationValue = source.ConfigurationValue,
			ApplicationCode = 'HIM'
	WHEN NOT MATCHED THEN	
		INSERT ([OrganizationID], [ConfigurationDefinitionID], ConfigurationValue, ApplicationCode)
		VALUES (source.[OrganizationID], source.[ConfigurationDefinitionID], source.ConfigurationValue, 'HIM');


-- Tier1 Member HIM Application Settings (do not add any clients that are EDS or HMP)
	MERGE dbo.ApplicationConfiguration AS target
	USING (
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Member_HIM' AS [ConfigurationValue] UNION ALL	

	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Member_HIM' AS [ConfigurationValue] UNION ALL

	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Member_HIM' AS [ConfigurationValue] UNION ALL			

	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Member_HIM' AS [ConfigurationValue] UNION ALL

	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Member_HIM' AS [ConfigurationValue] UNION ALL

	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Member_HIM' AS [ConfigurationValue] UNION ALL	

	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Member_HIM' AS [ConfigurationValue] UNION ALL		

	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Member_HIM' AS [ConfigurationValue] UNION ALL	

	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Member_HIM' AS [ConfigurationValue]
																																									
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

-- Tier1 Medical HIM Application Settings (do not add any clients that are EDS or HMP)
	MERGE dbo.ApplicationConfiguration AS target
	USING (
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Medical_HIM' AS [ConfigurationValue] UNION ALL	

	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Medical_HIM' AS [ConfigurationValue] UNION ALL

	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Medical_HIM' AS [ConfigurationValue] UNION ALL			

	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Medical_HIM' AS [ConfigurationValue] UNION ALL

	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Medical_HIM' AS [ConfigurationValue] UNION ALL

	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Medical_HIM' AS [ConfigurationValue] UNION ALL	

	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Medical_HIM' AS [ConfigurationValue] UNION ALL		

	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Medical_HIM' AS [ConfigurationValue] UNION ALL	

	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Medical_HIM' AS [ConfigurationValue]

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

-- Tier1 Drug HIM Application Settings (do not add any clients that are EDS or HMP)
	MERGE dbo.ApplicationConfiguration AS target
	USING (
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Drug_HIM' AS [ConfigurationValue] UNION ALL	

	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Drug_HIM' AS [ConfigurationValue] UNION ALL

	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Drug_HIM' AS [ConfigurationValue] UNION ALL			

	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Drug_HIM' AS [ConfigurationValue] UNION ALL

	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Drug_HIM' AS [ConfigurationValue] UNION ALL

	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Drug_HIM' AS [ConfigurationValue] UNION ALL	

	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Drug_HIM' AS [ConfigurationValue] UNION ALL		

	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Drug_HIM' AS [ConfigurationValue] UNION ALL	

	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Drug_HIM' AS [ConfigurationValue]
																																										
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

-- Tier1 Report HIM Application Settings (do not add any clients that are EDS or HMP)
	MERGE dbo.ApplicationConfiguration AS target
	USING (
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Report_HIM' AS [ConfigurationValue] UNION ALL	

	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Report_HIM' AS [ConfigurationValue] UNION ALL

	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Report_HIM' AS [ConfigurationValue] UNION ALL			

	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Report_HIM' AS [ConfigurationValue] UNION ALL
					
	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Report_HIM' AS [ConfigurationValue] UNION ALL

	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Report_HIM' AS [ConfigurationValue] UNION ALL	

	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Report_HIM' AS [ConfigurationValue] UNION ALL		

	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Report_HIM' AS [ConfigurationValue] UNION ALL	

	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Report_HIM' AS [ConfigurationValue]
																																												
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

-- Tier1 RptOpsMetrics_HIM Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (

	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Reporting Internal Clients') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPCSBDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Reporting Internal Clients') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'RptOpsMetrics_HIM' AS [ConfigurationValue]
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
END