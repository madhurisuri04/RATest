-- =============================================
-- Script Template
-- =============================================
If @@SERVERNAME = 'HRPDB001'
BEGIN
	SET IDENTITY_INSERT dbo.EnvironmentIndicator ON
	 MERGE dbo.EnvironmentIndicator AS target
      USING (
				SELECT	1 AS ID,
						'PROD' AS VALUE 
				 
                   ) as source
      ON (target.ID = source.ID and
			target.Value = source.Value) 
      WHEN MATCHED THEN
            UPDATE SET				  
				  target.Value = source.Value 
      WHEN NOT MATCHED THEN 
            INSERT (ID,Value) 
            VALUES (source.ID, source.Value); 
	SET IDENTITY_INSERT dbo.EnvironmentIndicator OFF
END


