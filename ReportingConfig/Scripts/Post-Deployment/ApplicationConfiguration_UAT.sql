IF @@SERVERNAME = 'HRPSTGDB001'
BEGIN
PRINT 'Updating Application configuration'


-- HIM Edge Reporting Application Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (
	
	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_EdgeReports' AS [ConfigurationValue] UNION ALL

	--Humana
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'Humana_EdgeReports' AS [ConfigurationValue] UNION ALL

	--BCBSMIHMO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'BCBSMI HMO_EdgeReports' AS [ConfigurationValue] UNION ALL

	--BCBSMIPPO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'BCBSMI PPO_EdgeReports' AS [ConfigurationValue] UNION ALL

	--INHMOH
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'INHMOH_EdgeReports' AS [ConfigurationValue] UNION ALL

	--IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'IND_Health_EdgeReports' AS [ConfigurationValue] UNION ALL

	--Caresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'CareSource_EdgeReports' AS [ConfigurationValue] UNION ALL

	--CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'CGHC_EdgeReports' AS [ConfigurationValue] UNION ALL

	--PreferredCare
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'PreferredCare_EdgeReports' AS [ConfigurationValue] UNION ALL

	--HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'HFHP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--TrustMark
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'TrustMark_EdgeReports' AS [ConfigurationValue] UNION ALL

	--WellPoint
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'WellPoint_EdgeReports' AS [ConfigurationValue] UNION ALL

	--Excellus
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'Excellus_EdgeReports' AS [ConfigurationValue] UNION ALL

	--CoreSource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'CoreSource_EdgeReports' AS [ConfigurationValue] UNION ALL


	--PHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'PHP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'SmokeTest_EdgeReports' AS [ConfigurationValue] UNION ALL

	--REG
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'Reg_EdgeReports' AS [ConfigurationValue] UNION ALL

	--BSCA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'BSCA_EdgeReports' AS [ConfigurationValue] UNION ALL

	--RMHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'RMHP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--BCBSAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'BCBSAZ_EdgeReports' AS [ConfigurationValue] UNION ALL

	--HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'HAMP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--BCBSKC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'BCBSKC_EdgeReports' AS [ConfigurationValue] UNION ALL

	--CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'CCHP_EdgeReports' AS [ConfigurationValue] UNION ALL

	--VIVA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'VIVA_EdgeReports' AS [ConfigurationValue] UNION ALL

	--Samaritan Health Plan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'Samaritan_EdgeReports' AS [ConfigurationValue] UNION ALL

	--BCBSHRZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseServerName') AS [ConfigurationDefinitionID]
				,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
				,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_EdgeReport_DatabaseName') AS [ConfigurationDefinitionID]
				,N'BCBSHRZ_EdgeReports' AS [ConfigurationValue]

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


	--HIM Application
	MERGE dbo.ApplicationConfiguration AS target
	USING   ( 
	
	-- Aetna
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Aetna_Provider_Depot' AS [ConfigurationValue] UNION ALL

	-- MVP Health Care
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PreferredCare_Provider_Depot' AS [ConfigurationValue] UNION ALL

	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CCHP_Provider_Depot' AS [ConfigurationValue] UNION ALL

   -- BCBSMI HMO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIHMO_Provider_Depot' AS [ConfigurationValue] UNION ALL

      -- BCBSMI PPO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSMIPPO_Provider_Depot' AS [ConfigurationValue] UNION ALL

   --Regence
   SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Reg_Provider_Depot' AS [ConfigurationValue] UNION ALL

	--BCBSAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSAZ_Provider_Depot' AS [ConfigurationValue] UNION ALL

	--BCBSKC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSKC_Provider_Depot' AS [ConfigurationValue] UNION ALL
				
	--BCBSHRZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'BCBSHRZ_Provider_Depot' AS [ConfigurationValue] UNION ALL
			
	--CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CGHC_Provider_Depot' AS [ConfigurationValue] UNION ALL

   --Caresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Caresource_Provider_Depot' AS [ConfigurationValue] UNION ALL

	--Coresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coresource') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Coresource_Provider_Depot' AS [ConfigurationValue] UNION ALL
			
   --CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'CHC_Provider_Depot' AS [ConfigurationValue] UNION ALL
		   
   --HAMP
   SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HAMP_Provider_Depot' AS [ConfigurationValue] UNION ALL
		   
	--HFHP
   SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'HFHP_Provider_Depot' AS [ConfigurationValue] UNION ALL

	--INHMOH
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'INHMOH_Provider_Depot' AS [ConfigurationValue] UNION ALL
				
	--IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'IND_Health_Provider_Depot' AS [ConfigurationValue] UNION ALL
		   
    --Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Sanford_Provider_Depot' AS [ConfigurationValue] UNION ALL

	 --Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Samaritan_Provider_Depot' AS [ConfigurationValue] UNION ALL
   
   --TrustMark
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'TrustMark_Provider_Depot' AS [ConfigurationValue] UNION ALL

   --VIVA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'VIVA_Provider_Depot' AS [ConfigurationValue] UNION ALL

		   --Presbyterian Health Plan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'PHP_Provider_Depot' AS [ConfigurationValue] UNION ALL

	-- Humana
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Humana_Provider_Depot' AS [ConfigurationValue] UNION ALL

	-- Wellpoint
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Wellpoint') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Wellpoint_Provider_Depot' AS [ConfigurationValue] UNION ALL
				
   -- RMHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'RMHP_Provider_Depot' AS [ConfigurationValue] UNION ALL

	-- Excellus
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'Excellus_Provider_Depot' AS [ConfigurationValue] UNION ALL
				
	 --SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMember_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Member_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Pre_dbo_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientMedical_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Medical_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientDrug_Depot_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_Drug_Depot' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPSTGDB001' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'GlobalReference_DatabaseName') AS [ConfigurationDefinitionID]
		, N'GlobalReference' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientSuspectsDM_DatabaseName') AS [ConfigurationDefinitionID]
		, N'SmokeTest_SuspectsDM' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
		, (SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientProvider_Depot_DatabaseServerName') AS [ConfigurationDefinitionID]
		, N'HRPUATDBS911' AS [ConfigurationValue] UNION ALL
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

-- Tier1 Member HIM Application Settings
	MERGE dbo.ApplicationConfiguration AS target
	USING (

	-- Aetna
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Aetna_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSAZ_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- BCBSHRZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSHRZ_Member_HIM' AS [ConfigurationValue] UNION ALL				
	-- BCBSKC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSKC_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSMIHMO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIHMO_Member_HIM' AS [ConfigurationValue] UNION ALL		
	-- BCBSMIPPO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIPPO_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- BSCA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BSCA_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- Caresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Caresource_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Member_HIM' AS [ConfigurationValue] UNION ALL			
	-- CoreSource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CoreSource_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- Excellus
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Excellus_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Member_HIM' AS [ConfigurationValue] UNION ALL			
	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- Humana
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Humana_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- INHMOH
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'INHMOH_Member_HIM' AS [ConfigurationValue] UNION ALL	
   	-- PHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PHP_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- PreferredCare
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PreferredCare_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- REG
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'REG_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- RMHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'RMHP_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Member_HIM' AS [ConfigurationValue] UNION ALL		
	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Member_HIM' AS [ConfigurationValue] UNION ALL
	-- TrustMark
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'TrustMark_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- VIVA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'VIVA_Member_HIM' AS [ConfigurationValue] UNION ALL	
	-- WellPoint
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'WellPoint_Member_HIM' AS [ConfigurationValue] UNION ALL

	-- CRAReportTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Member_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CRAReportTest_Member_HIM' AS [ConfigurationValue] 																																									

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

	-- Aetna
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Aetna_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSAZ_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- BCBSHRZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSHRZ_Medical_HIM' AS [ConfigurationValue] UNION ALL				
	-- BCBSKC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSKC_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSMIHMO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIHMO_Medical_HIM' AS [ConfigurationValue] UNION ALL		
	-- BCBSMIPPO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIPPO_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- BSCA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BSCA_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- Caresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Caresource_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Medical_HIM' AS [ConfigurationValue] UNION ALL			
	-- CoreSource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CoreSource_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- Excellus
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Excellus_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- HealthChoiceAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'HealthChoiceAZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'HealthChoiceAZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HealthChoiceAZ_Medical_HIM' AS [ConfigurationValue] UNION ALL							
	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- Humana
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Humana_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- INHMOH
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'INHMOH_Medical_HIM' AS [ConfigurationValue] UNION ALL
   	-- PHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PHP_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- PreferredCare
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PreferredCare_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- REG
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'REG_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- RMHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'RMHP_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Medical_HIM' AS [ConfigurationValue] UNION ALL		
	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Medical_HIM' AS [ConfigurationValue] UNION ALL
	-- TrustMark
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'TrustMark_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- VIVA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'VIVA_Medical_HIM' AS [ConfigurationValue] UNION ALL	
	-- WellPoint
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'WellPoint_Medical_HIM' AS [ConfigurationValue] UNION ALL

	-- CRAReportTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Medical_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CRAReportTest_Medical_HIM' AS [ConfigurationValue] 																																									
 																																									
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

	-- Aetna
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Aetna_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSAZ_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- BCBSHRZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSHRZ_Report_HIM' AS [ConfigurationValue] UNION ALL				
	-- BCBSKC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSKC_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSMIHMO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIHMO_Report_HIM' AS [ConfigurationValue] UNION ALL		
	-- BCBSMIPPO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIPPO_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- BSCA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BSCA_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- Caresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Caresource_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Report_HIM' AS [ConfigurationValue] UNION ALL			
	-- CoreSource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CoreSource_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- Excellus
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Excellus_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- HealthChoiceAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'HealthChoiceAZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'HealthChoiceAZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HealthChoiceAZ_Report_HIM' AS [ConfigurationValue] UNION ALL							
	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- Humana
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Humana_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- INHMOH
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'INHMOH_Report_HIM' AS [ConfigurationValue] UNION ALL
   	-- PHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PHP_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- PreferredCare
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PreferredCare_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- REG
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'REG_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- RMHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'RMHP_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Report_HIM' AS [ConfigurationValue] UNION ALL		
	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Report_HIM' AS [ConfigurationValue] UNION ALL
	-- TrustMark
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'TrustMark_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- VIVA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'VIVA_Report_HIM' AS [ConfigurationValue] UNION ALL	
	-- WellPoint
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'WellPoint_Report_HIM' AS [ConfigurationValue]  UNION ALL

	-- CRAReportTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Report_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CRAReportTest_Report_HIM' AS [ConfigurationValue] 																																									

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

	-- Aetna
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Aetna_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS AZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSAZ_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- BCBSHRZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS Horizon') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSHRZ_Drug_HIM' AS [ConfigurationValue] UNION ALL				
	-- BCBSKC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBS KC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSKC_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- BCBSMIHMO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIHMO_Drug_HIM' AS [ConfigurationValue] UNION ALL		
	-- BCBSMIPPO
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMIPPO_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- BSCA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Shield of California') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'BSCA_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- Caresource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Caresource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Caresource_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- CCHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- CGHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CGHC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CGHC_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- CHC
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Community Health Choice') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CHC_Drug_HIM' AS [ConfigurationValue] UNION ALL			
	-- CoreSource
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CoreSource') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CoreSource_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- Excellus
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Excellus_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- HAMP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health Alliance Medical Plans') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HAMP_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- HealthChoiceAZ
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'HealthChoiceAZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'HealthChoiceAZ') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HealthChoiceAZ_Drug_HIM' AS [ConfigurationValue] UNION ALL							
	-- HFHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- Humana
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Humana_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- IND_Health
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- INHMOH
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'INHMOH') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'INHMOH_Drug_HIM' AS [ConfigurationValue] UNION ALL
   	-- PHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PHP_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- PreferredCare
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'MVP Health Care') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'PreferredCare_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- REG
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'REG_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- RMHP
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Rocky Mountain Health Plans Foundation') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'RMHP_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- Samaritan
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Samaritan Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Samaritan_Drug_HIM' AS [ConfigurationValue] UNION ALL		
	-- Sanford
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- SmokeTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'SmokeTest') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'SmokeTest_Drug_HIM' AS [ConfigurationValue] UNION ALL
	-- TrustMark
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'TrustMark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'TrustMark_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- VIVA
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'VIVA Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'VIVA_Drug_HIM' AS [ConfigurationValue] UNION ALL	
	-- WellPoint
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'WellPoint') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'WellPoint_Drug_HIM' AS [ConfigurationValue] UNION ALL

	-- CRAReportTest
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CRA Report Test') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_Drug_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'CRAReportTest_Drug_HIM' AS [ConfigurationValue] 																																									
 
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
			,N'HRPUATDBS601' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Reporting Internal Clients') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseName') AS [ConfigurationDefinitionID]
			,N'RptOpsMetrics_HIM' AS [ConfigurationValue] UNION ALL

-- Tier 3 RptOpsMetrics_HIM Settings

	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Reporting Internal Clients') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBS651' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Reporting Internal Clients') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseName') AS [ConfigurationDefinitionID]
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


			-- REC Extract Settings :

	MERGE dbo.ApplicationConfiguration AS target
	USING (
	--Aetna

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Aetna_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Aetna_ClientDB' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\shares\ClientData\UAT\Aetna\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Aetna') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
	--Anthem

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Anthem') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Anthem') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Anthem_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Anthem') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Anthem') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Anthem_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Anthem') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Anthem\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Anthem') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL


	--BCBSMI HMO

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMI_HMO_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMI_HMO_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\BCBSMIHMO\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI HMO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--BCBSMI PPO

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMI_PPO_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMI_PPO_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\BCBSMIPPO\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'BCBSMI PPO') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--Blue Cross and Blue Shield of MI

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of MI') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of MI') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMI_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of MI') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of MI') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSMI_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of MI') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\BCBSMI\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of MI') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--Blue Cross and Blue Shield of NC

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of NC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of NC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSNC_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of NC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of NC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSNC_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of NC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\BCBSNC\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of NC') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
				
	--Blue Cross and Blue Shield of TN

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of TN') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of TN') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSTN_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of TN') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of TN') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'BCBSTN_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of TN') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\BCBSTN\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Blue Cross and Blue Shield of TN') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--CCHP

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'CCHP_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\CCHP\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'CCHP') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--Coventry

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Coventry_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Coventry_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Coventry\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Coventry') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			

			
	--Excellus

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Excellus_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Excellus_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Excellus\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Excellus') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--HFHP

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'HFHP_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\HFHP\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Health First Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--Highmark

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Highmark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Highmark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Highmark_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Highmark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Highmark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Highmark_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Highmark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Highmark\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Highmark') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--Humana

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Humana_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Humana_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Humana\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Humana') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--Independent Health

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'IND_Health_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Independent_Health\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Independent Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--Innovation Health

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Innovation Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Innovation Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'AEITH_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Innovation Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Innovation Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'AEITH_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Innovation Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\AETIH\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Innovation Health') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--Johns Hopkins Healthcare

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Johns Hopkins Healthcare') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Johns Hopkins Healthcare') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'JHHC_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Johns Hopkins Healthcare') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Johns Hopkins Healthcare') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'JHHC_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Johns Hopkins Healthcare') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\JHHC\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Johns Hopkins Healthcare') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--PHP

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'PHP_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'PHP_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\PHP\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Presbyterian Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--The Regence Group

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'REG_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'REG_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\REG\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'The Regence Group') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
			
	--Sanford Health Plan

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'Sanford_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\Sanford\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Sanford Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
	--Santa Clara

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Santa Clara Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Santa Clara Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'SCFHP_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Santa Clara Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Santa Clara Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'SCFHP_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Santa Clara Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\SCFHP\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Santa Clara Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
		--Universal American

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Universal American') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Universal American') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'UAM_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Universal American') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Universal American') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'UAM_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Universal American') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\UAM\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Universal American') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue] UNION ALL
			
			
		--Vantage Health Plan

    SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Vantage Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Vantage Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'Client_ReportDatabaseName') AS [ConfigurationDefinitionID]
			,N'VHP_Report' AS [ConfigurationValue] UNION ALL
     SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Vantage Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseServerName') AS [ConfigurationDefinitionID]
			,N'HRPUATDBs901' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Vantage Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ClientLevelDatabaseName') AS [ConfigurationDefinitionID]
			,N'VHP_ClientLevel' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Vantage Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'ExtractInternalLocation') AS [ConfigurationDefinitionID]
			,N'\\hrp.local\Shares\ClientData\UAT\VHP\Extracts\' AS [ConfigurationValue] UNION ALL
	SELECT (SELECT [OrganizationID] FROM dbo.Organization WITH(NOLOCK) WHERE [Name] = 'Vantage Health Plan') AS [OrganizationID]
			,(SELECT [ID] FROM dbo.ConfigurationDefinition WITH(NOLOCK) WHERE [ConfigurationType] = 'UserFTPLiteFolder') AS [ConfigurationDefinitionID]
			,N'\\hrpstgweb001\MY_FILES\' AS [ConfigurationValue]
		) AS source
	ON (target.[OrganizationID] = source.[OrganizationID]
		and target.[ConfigurationDefinitionID] = source.[ConfigurationDefinitionID])
	WHEN MATCHED THEN 
		UPDATE SET
			ConfigurationValue = source.ConfigurationValue,
			ApplicationCode = 'REC'
	WHEN NOT MATCHED THEN	
		INSERT ([OrganizationID], [ConfigurationDefinitionID], ConfigurationValue, ApplicationCode)
		VALUES (source.[OrganizationID], source.[ConfigurationDefinitionID], source.ConfigurationValue, 'REC');



END
