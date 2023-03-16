
--Pull in the global properties
BEGIN TRANSACTION;

MERGE dbo.ConfigurationDefinition AS target
	USING (SELECT ID, ConfigurationType, ConfigurationDescription, DefaultValue
			FROM HRPPortalConfig.dbo.ConfigurationDefinition) AS source
	ON (target.ID = source.ID)
	WHEN MATCHED THEN 
		UPDATE SET
			target.ConfigurationType = source.ConfigurationType,
			target.ConfigurationDescription = source.ConfigurationDescription,
			target.DefaultValue = source.DefaultValue,
			target.LastUpdateUserID = -200,
			target.LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT (ID, ConfigurationType, ConfigurationDescription, DefaultValue, CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
			VALUES (source.ID, 
				source.ConfigurationType, 
				source.ConfigurationDescription, 
				source.DefaultValue,
				-200, 
				GETDATE(),
				-200,
				GETDATE());

/*
Add Edge Report specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'1'  AS [ID], N'Client_EdgeReport_DatabaseServerName' AS [ConfigurationType], N'Client Edge Report Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'2'  AS [ID], N'Client_EdgeReport_DatabaseName' AS [ConfigurationType], N'Client Edge Report  Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, getDate(), -200, getDate());


/*
Add Depot specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING   ( 
			SELECT N'76'  AS [ID], N'ClientMember_Pre_dbo_DatabaseServerName' AS [ConfigurationType], N'HIM Client Member Pre dbo Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	UNION ALL SELECT N'77'  AS [ID], N'ClientMember_Pre_dbo_DatabaseName' AS [ConfigurationType], N'HIM Client Member Pre dbo Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	
	UNION ALL SELECT N'78'  AS [ID], N'ClientMedical_Pre_dbo_DatabaseServerName' AS [ConfigurationType], N'HIM Client Medical Pre dbo Database Server Name' AS [ConfigurationDescription],NULL AS [DefaultValue]
	UNION ALL SELECT N'79'  AS [ID], N'ClientMedical_Pre_dbo_DatabaseName' AS [ConfigurationType], N'HIM Client Medical Pre dbo Database Name' AS [ConfigurationDescription],NULL AS [DefaultValue] 
	
	UNION ALL SELECT N'80'  AS [ID], N'ClientDrug_Pre_dbo_DatabaseServerName' AS [ConfigurationType], N'HIM Client Pharmacy Pre dbo Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	UNION ALL SELECT N'81'  AS [ID], N'ClientDrug_Pre_dbo_DatabaseName' AS [ConfigurationType], N'HIM Client Pharmacy Pre dbo Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 


	UNION ALL SELECT N'92'  AS [ID], N'ClientMember_Depot_DatabaseServerName' AS [ConfigurationType], N'HIM Client Member Depot Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	UNION ALL SELECT N'93'  AS [ID], N'ClientMember_Depot_DatabaseName' AS [ConfigurationType], N'HIM Client Member Depot Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 

	UNION ALL SELECT N'94'  AS [ID], N'ClientMedical_Depot_DatabaseServerName' AS [ConfigurationType], N'HIM Client Medical Depot Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	UNION ALL SELECT N'95'  AS [ID], N'ClientMedical_Depot_DatabaseName' AS [ConfigurationType], N'HIM Client Medical Depot Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	
	UNION ALL SELECT N'96'  AS [ID], N'ClientDrug_Depot_DatabaseServerName' AS [ConfigurationType], N'HIM Client Pharmacy Depot Database Server Name' AS [ConfigurationDescription],NULL  AS [DefaultValue] 
	UNION ALL SELECT N'97'  AS [ID], N'ClientDrug_Depot_DatabaseName' AS [ConfigurationType], N'HIM Client Pharmacy Depot Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 

	UNION ALL SELECT N'109'  AS [ID], N'ClientProvider_Depot_DatabaseServerName' AS [ConfigurationType], N'HIM Client Provider Depot Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	UNION ALL SELECT N'110'  AS [ID], N'ClientProvider_Depot_DatabaseName' AS [ConfigurationType], N'HIM Client Provider Depot Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]

	UNION ALL SELECT N'200'  AS [ID], N'ClientSuspectsDM_DatabaseServerName' AS [ConfigurationType], N'HIM Client SuspectsDM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	UNION ALL SELECT N'201'  AS [ID], N'ClientSuspectsDM_DatabaseName' AS [ConfigurationType], N'HIM Client SuspectsDM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 

	UNION ALL SELECT N'300'  AS [ID], N'GlobalReference_DatabaseServerName' AS [ConfigurationType], N'GlobalReference Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	UNION ALL SELECT N'301'  AS [ID], N'GlobalReference_DatabaseName' AS [ConfigurationType], N'GlobalReference Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue] 

		) AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, GETDATE(), -200, getDate());

/*
Add Tier1 Member HIM specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'12'  AS [ID], N'Tier1_Member_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier1 Member HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'13'  AS [ID], N'Tier1_Member_HIM_DatabaseName' AS [ConfigurationType], N'Tier1 Member HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, getDate(), -200, getDate());
		
/*
Add Tier1 Medical HIM specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'14'  AS [ID], N'Tier1_Medical_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier1 Medical HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'15'  AS [ID], N'Tier1_Medical_HIM_DatabaseName' AS [ConfigurationType], N'Tier1 Medical HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, getDate(), -200, getDate());		
/*
Add Tier1 Report HIM specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'16'  AS [ID], N'Tier1_Report_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier1 Report HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'17'  AS [ID], N'Tier1_Report_HIM_DatabaseName' AS [ConfigurationType], N'Tier1 Report HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, getDate(), -200, getDate());		

/*
Add Tier1 Drug HIM specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'18'  AS [ID], N'Tier1_Drug_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier1 Drug HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'19'  AS [ID], N'Tier1_Drug_HIM_DatabaseName' AS [ConfigurationType], N'Tier1 Drug HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, getDate(), -200, getDate());
		
/*
Add Tier1 RptOpsMetrics_HIM specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'20'  AS [ID], N'Tier1_RptOpsMetrics_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier1 RptOpsMetrics_HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'21'  AS [ID], N'Tier1_RptOpsMetrics_HIM_DatabaseName' AS [ConfigurationType], N'Tier1 RptOpsMetrics_HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, GETDATE(), -200, GETDATE());
		
/*
Add Tier3 RptOpsMetrics_HIM specific properties below
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'22'  AS [ID], N'Tier3_RptOpsMetrics_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier3 RptOpsMetrics_HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'23'  AS [ID], N'Tier3_RptOpsMetrics_HIM_DatabaseName' AS [ConfigurationType], N'Tier3 RptOpsMetrics_HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, GETDATE(), -200, GETDATE());		


		
/*
Add ClientLevel and Reporting DatabaseName
*/

MERGE dbo.ConfigurationDefinition AS target
	USING
	(
		SELECT N'22'  AS [ID], N'Tier3_RptOpsMetrics_HIM_DatabaseServerName' AS [ConfigurationType], N'Tier3 RptOpsMetrics_HIM Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue] UNION ALL
		SELECT N'23'  AS [ID], N'Tier3_RptOpsMetrics_HIM_DatabaseName' AS [ConfigurationType], N'Tier3 RptOpsMetrics_HIM Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]  UNION ALL
		SELECT N'24'  AS [ID], N'Client_ReportDatabaseServerName' AS [ConfigurationType], N'Client Report Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue]  UNION ALL
		SELECT N'25'  AS [ID], N'Client_ReportDatabaseName' AS [ConfigurationType], N'Client Report Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]  UNION ALL
		SELECT N'26'  AS [ID], N'ClientLevelDatabaseServerName' AS [ConfigurationType], N'Client Level Database Server Name' AS [ConfigurationDescription], NULL AS [DefaultValue]  UNION ALL
		SELECT N'27'  AS [ID], N'ClientLevelDatabaseName' AS [ConfigurationType], N'Client Level Database Name' AS [ConfigurationDescription], NULL AS [DefaultValue]  UNION ALL
		SELECT N'28'  AS [ID], N'ExtractInternalLocation' AS [ConfigurationType], N'Extract Internal Location' AS [ConfigurationDescription], NULL AS [DefaultValue]   UNION ALL
		SELECT N'29'  AS [ID], N'UserFTPLiteFolder' AS [ConfigurationType], N'User FTP Lite Folder' AS [ConfigurationDescription], NULL AS [DefaultValue] 
	)
	AS source
	ON (target.[ID] = source.[ID])
	WHEN MATCHED THEN 
		UPDATE SET
			[ConfigurationType] = source.[ConfigurationType],
			[ConfigurationDescription] = source.[ConfigurationDescription],
			[DefaultValue] = source.[DefaultValue],
			LastUpdateUserID = -200,
			LastUpdateDateTime = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ID], [ConfigurationType], [ConfigurationDescription], [DefaultValue],CreateUserID, CreateDateTime, LastUpdateUserID, LastUpdateDateTime)
		VALUES (source.[ID], source.[ConfigurationType], source.[ConfigurationDescription], source.[DefaultValue], -200, GETDATE(), -200, GETDATE());		

COMMIT TRANSACTION;
GO
