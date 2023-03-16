USE ReportingConfig
GO

IF @@SERVERNAME = 'HRPDEVDB01'
BEGIN
	MERGE dbo.RptOpsMetricsConfiguration AS TARGET
	USING
	(
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseServerName'
		) AS [ConfigurationDefinitionID]
		, N'HRPDEVDB01' AS [ConfigurationValue] 
		
		UNION ALL
	
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseName'
		) AS [ConfigurationDefinitionID]
		, N'RptOpsMetrics_HIM' AS [ConfigurationValue]
		
		UNION ALL
		
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseServerName'
		) AS [ConfigurationDefinitionID]
		, N'HRPDEVDB01' AS [ConfigurationValue] 
		
		UNION ALL
	
		SELECT 
		(
			SELECT [ID]
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseName'
		) AS [ConfigurationDefinitionID]
		, N'RptOpsMetrics_HIM' AS [ConfigurationValue]
	) AS SOURCE
	ON 
		(
		TARGET.[ConfigurationDefinitionID] = SOURCE.[ConfigurationDefinitionID]
		)
	WHEN MATCHED THEN 
		UPDATE SET
			TARGET.ConfigurationValue = SOURCE.ConfigurationValue,
			TARGET.UserID = SUSER_NAME(),
			TARGET.LoadDate = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ConfigurationDefinitionID], ConfigurationValue, UserID, LoadID, LoadDate)
		VALUES (SOURCE.[ConfigurationDefinitionID], SOURCE.ConfigurationValue, SUSER_NAME(), -9223000000000000001, GETDATE());
END

IF @@SERVERNAME = 'HRPSTGDB001'
BEGIN
	MERGE dbo.RptOpsMetricsConfiguration AS TARGET
	USING
	(
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseServerName'
		) AS [ConfigurationDefinitionID]
		, N'HRPUATDBS601' AS [ConfigurationValue] 
		
		UNION ALL
	
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseName'
		) AS [ConfigurationDefinitionID]
		, N'RptOpsMetrics_HIM' AS [ConfigurationValue]
		
		UNION ALL
		
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseServerName'
		) AS [ConfigurationDefinitionID]
		, N'HRPUATDBS651' AS [ConfigurationValue] 
		
		UNION ALL
	
		SELECT 
		(
			SELECT [ID]
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseName'
		) AS [ConfigurationDefinitionID]
		, N'RptOpsMetrics_HIM' AS [ConfigurationValue]
	) AS SOURCE
	ON 
		(
		TARGET.[ConfigurationDefinitionID] = SOURCE.[ConfigurationDefinitionID]
		)
	WHEN MATCHED THEN 
		UPDATE SET
			TARGET.ConfigurationValue = SOURCE.ConfigurationValue,
			TARGET.UserID = SUSER_NAME(),
			TARGET.LoadDate = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ConfigurationDefinitionID], ConfigurationValue, UserID, LoadID, LoadDate)
		VALUES (SOURCE.[ConfigurationDefinitionID], SOURCE.ConfigurationValue, SUSER_NAME(), -9223000000000000001, GETDATE());
END

IF @@SERVERNAME = 'HRPDB001'
BEGIN
	MERGE dbo.RptOpsMetricsConfiguration AS TARGET
	USING
	(
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseServerName'
		) AS [ConfigurationDefinitionID]
		, N'HRPPRDDBS601' AS [ConfigurationValue] 
		
		UNION ALL
	
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier1_RptOpsMetrics_HIM_DatabaseName'
		) AS [ConfigurationDefinitionID]
		, N'RptOpsMetrics_HIM' AS [ConfigurationValue]
		
		UNION ALL
		
		SELECT 
		(
			SELECT [ID] 
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseServerName'
		) AS [ConfigurationDefinitionID]
		, N'HRPPRDDBS651' AS [ConfigurationValue] 
		
		UNION ALL
	
		SELECT 
		(
			SELECT [ID]
			FROM dbo.ConfigurationDefinition WITH(NOLOCK) 
			WHERE [ConfigurationType] = 'Tier3_RptOpsMetrics_HIM_DatabaseName'
		) AS [ConfigurationDefinitionID]
		, N'RptOpsMetrics_HIM' AS [ConfigurationValue]
	) AS SOURCE
	ON 
		(
		TARGET.[ConfigurationDefinitionID] = SOURCE.[ConfigurationDefinitionID]
		)
	WHEN MATCHED THEN 
		UPDATE SET
			TARGET.ConfigurationValue = SOURCE.ConfigurationValue,
			TARGET.UserID = SUSER_NAME(),
			TARGET.LoadDate = GETDATE()
	WHEN NOT MATCHED THEN	
		INSERT ([ConfigurationDefinitionID], ConfigurationValue, UserID, LoadID, LoadDate)
		VALUES (SOURCE.[ConfigurationDefinitionID], SOURCE.ConfigurationValue, SUSER_NAME(), -9223000000000000001, GETDATE());
END