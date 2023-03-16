MERGE dbo.[EdgeReportClientStatus] AS target
USING (
		SELECT 	OrganizationID 'OrganizationID',
				RT.ReportType 'ReportType' ,
				1 'EnableFlag'
		 from dbo.Organization
		inner join (
						SELECT 'RARSS' 'ReportType'  
						UNION 
						SELECT 'RARSD' 'ReportType'  
						UNION
						SELECT 'RACSS' 'ReportType'  
						UNION
						SELECT 'RACSD' 'ReportType'  
						UNION
						SELECT 'RISR' 'ReportType'   
						UNION
						SELECT 'RIDE' 'ReportType'   
						UNION
						SELECT 'RATEE' 'ReportType'  
						UNION
						SELECT 'ECD' 'ReportType'    
						UNION
						SELECT 'RADVPS' 'ReportType'
						UNION
						SELECT 'RAPHCCER' 'ReportType'
						UNION
						SELECT 'RAUF' 'ReportType'
						UNION
						SELECT 'RADVPSF' 'ReportType'
						UNION 
						SELECT 'HCRP' 'ReportType'
				) RT
		on 1=1
		where name in 
		(
				'Independent Health',
				'Health First Health Plan',
				'Scott and White Health Plan',
				'Excellus',
				'Health Alliance Medical Plans',
				'CCHP',
				'Rocky Mountain Health Plans Foundation',
				'CoreSource',
				'Community Health Choice',
				'CareSource',
				'INHMOH',
				'CGHC',
				'Trustmark',
				'Samaritan Health Plan'
		)
	
)
		AS source
ON (target.OrganizationID = source.OrganizationID
	and target.ReportType = source.ReportType )
WHEN MATCHED THEN 
    UPDATE SET 
		EnableFlag = source.EnableFlag
WHEN NOT MATCHED THEN	
    INSERT (OrganizationID,ReportType,EnableFlag )
    VALUES (source.OrganizationID, source.ReportType, source.EnableFlag);