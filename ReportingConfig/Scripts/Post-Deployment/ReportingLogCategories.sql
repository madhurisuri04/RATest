BEGIN TRANSACTION

	MERGE dbo.ReportingLogCategories  AS target
	USING (
		select 'HIM' 'ApplicationCode', 'ETL' 'ProcessCode', 'Member' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'ETL' 'ProcessCode', 'Medical' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'CLMTRKSwap' 'ProcessCode', 'Medical' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'RiskModel' 'ProcessCode', 'Member' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'RiskModel' 'ProcessCode', 'Medical' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SA' 'ProcessCode', 'Member' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SA' 'ProcessCode', 'Medical' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SA' 'ProcessCode', 'Provider' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SA' 'ProcessCode', 'Drug' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SASwap' 'ProcessCode', 'Medical' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SASwap' 'ProcessCode', 'Drug' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SASwap' 'ProcessCode', 'Provider' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SASync' 'ProcessCode', 'Member' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SASync' 'ProcessCode', 'Medical' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'SASync' 'ProcessCode', 'Drug' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'AR' 'ProcessCode', 'ClmsFilter' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'Crosswalks' 'ProcessCode', 'MedMemRx' 'Category'
		union all
		select 'HIM' 'ApplicationCode', 'Crosswalks' 'ProcessCode', 'PlanBillTp' 'Category'

	)	 AS source
	ON (target.ApplicationCode = source.ApplicationCode
	and target.ProcessCode=Source.ProcessCode
	and target.Category=Source.Category 
	)
	WHEN NOT MATCHED THEN	
		INSERT (ApplicationCode, ProcessCode, Category, 
				CreateUserID ,  
				CreatedDatetime ,
				LastUpdateUserID ,
				LastUpdateDateTime )
		VALUES (source.ApplicationCode,Source.ProcessCode,Source.Category,suser_sname(), getdate(),suser_sname(), getdate());

COMMIT;