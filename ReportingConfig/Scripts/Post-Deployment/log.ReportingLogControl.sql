BEGIN TRANSACTION;
	MERGE [log].[ReportingLogControl]  AS target
	USING (
		select o.OrganizationID, r.ApplicationCode,r.ProcessCode,r.Category
		from Organization o
		inner join ReportingLogCategories r
		on 1=1
	)	 AS source
	ON (target.OrganizationID = source.OrganizationID
	and target.ApplicationCode = source.ApplicationCode
	and target.ProcessCode=Source.ProcessCode
	and target.Category=Source.Category 
	)
	WHEN NOT MATCHED THEN	
		INSERT ([OrganizationID]      ,ApplicationCode      ,ProcessCode      ,Category
,LastSuccessfulDepotPullDate      ,RunDate      )
		VALUES (source.OrganizationID, source.ApplicationCode,Source.ProcessCode,Source.Category,'1900-01-01','1900-01-01');

COMMIT;