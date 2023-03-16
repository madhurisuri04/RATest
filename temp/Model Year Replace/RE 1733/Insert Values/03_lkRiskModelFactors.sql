use HRPReporting

--------------------------
drop table #combination
select distinct paymentyear, RAFactorType, ModelVersion, APCCFlag 
into #combination
from [dbo].[lkRiskModelsMaster]
where paymentyear > 2016


select * from #combination

--------------------------


INSERT INTO [dbo].[lkRiskModelsFactors] (
	[PaymentYear] 
	,[ModelVersion]
	,[FactorType]
	,[PartCDFlag]	
	,[OREC]
	,[LI]
	,[MedicaidFlag]	
	,[DemoRiskType]
	,[FactorDescription]
	,[HCCNumber]
	,[Gender]
	,[Factor] 
	,[Aged]
	,[APCCFlag]
	,[LoadID] 
	,[LoadDate]
)
select 
	[Payment_Year] 
	,c.[ModelVersion]
	,[Factor_Type]
	,[Part_C_D_Flag]	
	,[OREC]
	,[LI]
	,[Medicaid_Flag]	
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[HCCNumber] = cast(cast (case when [Demo_Risk_Type] = 'RISK' then LTRIM(REVERSE(LEFT(REVERSE([Factor_Description]), PATINDEX('%[A-Z]%',REVERSE([Factor_Description])) - 1))) else null end as int) as varchar)
	,[Gender]
	,[Factor] 
	,[Aged]
	,c.[APCCFlag]
	,0
	,getdate()
from HRPReporting.dbo.lk_risk_models lk
join #combination c
on lk.Payment_Year = c.PaymentYear
and lk.Factor_Type = c.RAFactorType
where Payment_Year > 2016

INSERT INTO [dbo].[lkRiskModelsFactors] (
	[PaymentYear] 
	,[ModelVersion]
	,[FactorType]
	,[PartCDFlag]	
	,[OREC]
	,[LI]
	,[MedicaidFlag]	
	,[DemoRiskType]
	,[FactorDescription]
	,[HCCNumber] = cast(cast (case when [Demo_Risk_Type] = 'RISK' then LTRIM(REVERSE(LEFT(REVERSE([Factor_Description]), PATINDEX('%[A-Z]%',REVERSE([Factor_Description])) - 1))) else null end as int) as varchar)
	,[HCCNumber]
	,[Gender]
	,[Factor] 
	,[Aged]
	,[APCCFlag]
	,[LoadID] 
	,[LoadDate]
)
select 
	[Payment_Year] 
	,[ModelVersion] = 5
	,[Factor_Type]
	,[Part_C_D_Flag]	
	,[OREC]
	,[LI]
	,[Medicaid_Flag]	
	,[Demo_Risk_Type]
	,[Factor_Description]
	,[Gender]
	,[Factor] 
	,[Aged]
	,'N'
	,0
	,getdate()
from HRPReporting.dbo.lk_risk_models lk
where Payment_Year > 2016
and Factor_Type in ('D4','D5','D6','D7','D8','D9')


update .[dbo].[lkRiskModelsFactors]
set DemoRiskType = 'APCC',
HCCNumber = null
where
FactorDescription in ('D1','D2','D3','D4','D5','D6','D7','D8','D9','D10P','D10')

/* 
/* TEST */

select PaymentYear, FactorType, PartCDFlag, OREC, LI, MedicaidFlag, DemoRiskType, FactorDescription, GEnder, Factor, Aged from [dbo].[lkRiskModelsFactors]
except
select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016

select Payment_Year, Factor_Type, Part_C_D_Flag, OREC, LI, Medicaid_Flag, Demo_Risk_Type, Factor_Description, GEnder, Factor, Aged from HRPReporting.dbo.lk_risk_models
where Payment_Year > 2016
except
select PaymentYear, FactorType, PartCDFlag, OREC, LI, MedicaidFlag, DemoRiskType, FactorDescription, GEnder, Factor, Aged from [dbo].[lkRiskModelsFactors]
*/